/******Auto generator of gen_cpp_struct_by_meta.py ***************/
# pragma once

#include "CoreMinimal.h"
#include "Math/GenericOctree.h"
#include "GenericQuadTree.h"

#include "HiEdRuntimeStruct.generated.h"

USTRUCT(BlueprintType)
struct FEdVector
{
	GENERATED_BODY()
public:
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double x = 0.0;
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double y = 0.0;
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double z = 0.0;
};


USTRUCT(BlueprintType)
struct FEdQuat
{
    GENERATED_BODY()
public:
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double x = 0.0f;
    UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double y = 0.0f;
    UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double z = 0.0f;
    UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	double w = 1.0f;
};

USTRUCT(BlueprintType)
struct FEdTransform
{
	GENERATED_BODY()
public:
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	FEdVector translation;
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	FEdQuat rotation;
	UPROPERTY(BlueprintReadWrite, Category = HiEdRuntime)
	FEdVector scale3D;
};

/** 查询actor坐标距离给八叉树使用的结构**/
struct FObjectInfo
{
    const FString EditorID;
    const FVector Location;

	/** Initialization constructor. */
	FObjectInfo(const FString& EditorID_, const FVector& Location_)
		: EditorID(EditorID_), Location(Location_)
	{}
};

struct FEdOctreeSemantics
{
	enum { MaxElementsPerLeaf = 16 };
	enum { MaxNodeDepth = 24 };
	enum { LoosenessDenominator = 16 };

	typedef TInlineAllocator<MaxElementsPerLeaf * 8> ElementAllocator;

	FORCEINLINE static FBoxCenterAndExtent GetBoundingBox(const FObjectInfo& ObjectInfo)
	{
		return FBoxCenterAndExtent(ObjectInfo.Location, FVector(0,0,0));
	}

	FORCEINLINE static bool AreElementsEqual(const FObjectInfo& A, const FObjectInfo& B)
	{
		return A.EditorID == B.EditorID;
	}

	/** Ignored for this implementation */
	FORCEINLINE static void SetElementId( const FObjectInfo& Element, FOctreeElementId2 Id )
	{
	}
};
/** 查询actor坐标距离给八叉树使用的结构**/
