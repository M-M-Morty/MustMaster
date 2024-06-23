// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "Containers/Array.h"
#include "Containers/Map.h"
#include "Containers/UnrealString.h"
#include "CoreMinimal.h"
#include "HAL/PlatformCrt.h"
#include "Math/NumericLimits.h"
#include "Math/UnrealMathSSE.h"
#include "Misc/Optional.h"
#include "Misc/IEngineCrypto.h"
#include "Templates/Tuple.h"

class FArchive;
struct FFileRegion;
struct FKeyChain;
struct FPakEntryPair;
struct FPakInfo;

/**
* Defines the order mapping for files within a pak.
* When read from the files present in the pak, Indexes will be [0,NumFiles).  This is important for detecting gaps in the order between adjacent files in a patch .pak.
* For new files being added into the pak, the values can be arbitrary, and will be usable only for relative order in an output list.
* Due to the arbitrary values for new files, the FPakOrderMap can contain files with duplicate Order values.
*/
class FPakOrderMap
{
public:
	FPakOrderMap()
		: MaxPrimaryOrderIndex(MAX_uint64)
		, MaxIndex(0)
	{}

	void Empty()
	{
		OrderMap.Empty();
		MaxPrimaryOrderIndex = MAX_uint64;
		MaxIndex = 0;
	}

	int32 Num() const
	{
		return OrderMap.Num();
	}

	/** Add the given filename with the given Sorting Index */
	void Add(const FString& Filename, uint64 Index)
	{
		OrderMap.Add(Filename, Index);
		MaxIndex = FMath::Max(MaxIndex, Index);
	}

	/**
	* Add the given filename with the given Offset interpreted as Offset in bytes in the Pak File.  This version of Add is only useful when all Adds are done by offset, and are converted
	* into Sorting Indexes at the end by a call to ConvertOffsetsToOrder
	*/
	void AddOffset(const FString& Filename, uint64 Offset)
	{
		OrderMap.Add(Filename, Offset);
		MaxIndex = FMath::Max(MaxIndex, Offset);
	}

	/** Remaps all the current values in the OrderMap onto [0, NumEntries).  Useful to convert from Offset in Pak file bytes into an Index sorted by Offset */
	void ConvertOffsetsToOrder()
	{
		TArray<TPair<FString, uint64>> FilenameAndOffsets;
		for (auto& FilenameAndOffset : OrderMap)
		{
			FilenameAndOffsets.Add(FilenameAndOffset);
		}
		FilenameAndOffsets.Sort([](const TPair<FString, uint64>& A, const TPair<FString, uint64>& B)
		{
			return A.Value < B.Value;
		});
		int64 Index = 0;
		for (auto& FilenameAndOffset : FilenameAndOffsets)
		{
			OrderMap[FilenameAndOffset.Key] = Index;
			++Index;
		}
		MaxIndex = Index - 1;
	}

	bool PAKPATCHUTILITIES_API ProcessOrderFile(const TCHAR* ResponseFile, bool bSecondaryOrderFile = false, bool bMergeOrder = false, TOptional<uint64> InOffset = {});

	// Merge another order map into this one where the files are not already ordered by this map. Steals the strings and empties the other order map.
	void PAKPATCHUTILITIES_API MergeOrderMap(FPakOrderMap&& Other);

	uint64 PAKPATCHUTILITIES_API GetFileOrder(const FString& Path, bool bAllowUexpUBulkFallback, bool* OutIsPrimary=nullptr) const;

	void PAKPATCHUTILITIES_API WriteOpenOrder(FArchive* Ar);

	uint64 PAKPATCHUTILITIES_API GetMaxIndex() { return MaxIndex; }

private:
	FString RemapLocalizationPathIfNeeded(const FString& PathLower, FString& OutRegion) const;

	TMap<FString, uint64> OrderMap;
	uint64 MaxPrimaryOrderIndex;
	uint64 MaxIndex;
};


PAKPATCHUTILITIES_API bool ExecutePakPatch(const TCHAR* CmdLine);

/** Input and output data for WritePakFooter */
struct FPakFooterInfo
{
	FPakFooterInfo(const TCHAR* InFilename, const FString& InMountPoint, FPakInfo& InInfo, TArray<FPakEntryPair>& InIndex)
		: Filename(InFilename)
		, MountPoint(InMountPoint)
		, Info(InInfo)
		, Index(InIndex)
	{
	}
	void SetEncryptionInfo(const FKeyChain& InKeyChain, uint64* InTotalEncryptedDataSize)
	{
		KeyChain = &InKeyChain;
		TotalEncryptedDataSize = InTotalEncryptedDataSize;
	}
	void SetFileRegionInfo(bool bInFileRegions, TArray<FFileRegion>& InAllFileRegions)
	{
		bFileRegions = bInFileRegions;
		AllFileRegions = &InAllFileRegions;
	}

	const TCHAR* Filename;
	const FString& MountPoint;
	FPakInfo& Info;
	TArray<FPakEntryPair>& Index;

	const FKeyChain* KeyChain = nullptr;
	uint64* TotalEncryptedDataSize = nullptr;
	bool bFileRegions = false;
	TArray<FFileRegion>* AllFileRegions = nullptr;

	int64 PrimaryIndexSize = 0;
	int64 PathHashIndexSize = 0;
	int64 FullDirectoryIndexSize = 0;
};

/** Write the index and other data at the end of a pak file after all the entries */
PAKPATCHUTILITIES_API void WritePakFooter(FArchive& PakHandle, FPakFooterInfo& FooterInfo);

/** Take an existing pak file and regenerate the signature file */
PAKPATCHUTILITIES_API bool SignPakFile(const FString& InPakFilename, const FRSAKeyHandle InSigningKey);

//RPG Begin

class PAKPATCHUTILITIES_API FPakPatchUtilities
{
public:
	//对比2个pak生成差异包，相比UnrealPak,此方法仅对比entry中的hash（加密压缩后内容的hash），速度极快
	//但相对UnrealPak，无法应对原始内容不变，但压缩算法或加密算法变化导致最终hash变化的情况
	static int32 DiffPak(const FString& InOldPak, const FString& InNewPak, const FString& InPatchPak);

	//对pak打补丁（或合并2个pak文件），原引擎的Patch文件放在单独pak，随着多次版本更新，会有大量冗余，通过合并，利用原pak废弃空间，可大幅降低冗余
	//相比steam，xdelta3，hdiffpatch等方案把整个pak写入一次，此方法磁盘写入量较小，仅涉及复制patch中文件到原pak合适位置
	static int32 PatchPak(const FString& InSourcePak, const FString& InPatchPak);

	static TArray<FPakEntryPair> ParsePakIndexFromCSV(const FString& InCsvFile);

	//传统游戏版本更新，通常是v1_to_v2.patch, v2_to_v3.patch
	//对于长时间不开游戏的客户端，更新内容冗余较多（多个patch中可能对某个文件更新多次，而客户端只需要最新版本）
	//可以采用对比文件列表方案，客户端对比CDN文件列表找出不一样的并下载
	//游戏客户端通常会对游戏注意封装成较大的文件包，不能直接以封装后的文件包对比差异，下载，
	//可以把文件包作为虚拟磁盘对待，细化到包内文件的对比，因此这种方法具有较强的专用性，
	//此处主要针对虚幻pak包实现内文件项的对比和更新，
	//此方案只能保证pak包内文件内容等价，不能保证pak文件一致（如本地pak和CDN端pak内文件顺序不一致）
	static int32 DiffPakByCSV(const FString& InOldPak, const FString& InNewPakCSV);
};
//RPG End