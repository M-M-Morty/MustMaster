//HiGame

#pragma once


#include "HiGameUpdateInfo.generated.h"

/*
* 理论上启动器相关代码应使用原生C++类编写，尽量不以来UObject系统，保持简单，
* 但其反射系统太方便了，尤其用于json序列化，可避免手写字段解析，减少失误概率
* 引入UObject后多线程操作需要格外小心了
* 
* 使用hsynz计算版本差异，小于1MB的文件直接计算本地hash和远程Hash对比
* 超过1MB的则计算其hindex文件的hash，和远程hash对比
* 
*/


USTRUCT()
struct FHiGameFileInfo
{
public:
	GENERATED_BODY()

	UPROPERTY()
	FString Name;

	UPROPERTY()
	FString Hash;

	UPROPERTY()
	int64 Size;

	//记录本地文件的时间戳，当实际文件时间戳和json中的信息不一致，说明文件被修改了
	//客户端文件更新结束，验证无误后会写入此字段
	UPROPERTY()
	int64 TimeStamp;


	int64 DownloadedSize = 0;
	int64 PatchSize = 0;

};

USTRUCT()
struct FHiGameVersionInfo
{
public:

	GENERATED_BODY()

	//版本号
	UPROPERTY()
	FString VersionStr;

	//简要描述
	UPROPERTY()
	FString VersionDesc;

	//预留数据
	UPROPERTY()
	FString CustomData;

	UPROPERTY()
	TArray<FHiGameFileInfo> FileList;

	TArray<FString> GetAllFileNames() const;

	const FHiGameFileInfo* GetFileItemInfoByName(const FString& InFileName) const;

};

enum class EUpdaterState : uint32
{
	None = 0,
	DownloadVersionInfo, //从服务器下载版本信息的json文件
	AnalyzeChangedFiles, //简单分析变更的文件
	DownloadIndexFiles, //下载变更文件的hash文件
	AnalyzePatchInfo, //根据hash文件分析需要下载的总大小，便于下载前告知下载大小
	DownloadPatch, //下载差异文件
	ApplyPatch, //合并。合并后的文件后缀为.hpatched
	VerifyAndMoveFile, //计算合并后的文件hash，并改名为原始文件名；并且写入本地版本json文件
	UpdateCompleted,
};

struct FUpdaterEventData
{
public:

	enum ESubEvent: uint8
	{
		SubEvent_None = 0,
		SubEvent_Begin,
		SubEvent_Update,
		SubEvent_DownloadPrepare,
		SubEvent_End,
		SubEvent_Error,
	};

	EUpdaterState State;

	ESubEvent SubEvent = SubEvent_None;

	int64 CurrentSize = 0;
	int64 TotalSize = 0;

	int32 ReturnCode = 0;

	FString ProcessingFileName;

	FString LocalVersion;
	FString ServerVersion;

	FString ErrorInfo;
};

enum class EUpdaterCommand : uint32
{
	None = 0,
	DownloadVersionInfo,
};