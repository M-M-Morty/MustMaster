// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Animation/AnimTypes.h"
#include "Animation/AnimNodeBase.h"
#include "Animation/AnimData/BoneMaskFilter.h"
#include "HiAnimNode_LayeredBoneBlend.generated.h"

enum class ELayeredBoneBlendMode:uint8;

struct FHiAnimLayeredBlendInstanceProxy;

USTRUCT(BlueprintInternalUseOnly)
struct HIGAME_API FHiAnimNode_LayeredBoneBlend: public FAnimNode_Base
{
	friend struct FHiAnimLayeredBlendInstanceProxy;
	
	GENERATED_USTRUCT_BODY()

private:
	/** Parent proxy */
	FHiAnimLayeredBlendInstanceProxy* Proxy;
	
public:
	/** The source pose */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category=Links)
	FPoseLink BasePose;

	/** Each layer's blended pose */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, editfixedsize, Category=Links, meta=(BlueprintCompilerGeneratedDefaults))
	TArray<FPoseLink> BlendPoses;

	/** Whether to use branch filters or a blend mask to specify an input pose per-bone influence */
	UPROPERTY(EditAnywhere, Category = Config)
	ELayeredBoneBlendMode BlendMode;

	/** 
	 * The blend masks to use for our layer inputs. Allows the use of per-bone alphas.
	 * Blend masks are used when BlendMode is BlendMask.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, editfixedsize, Category=Config, meta=(UseAsBlendMask=true))
	TArray<TObjectPtr<UBlendProfile>> BlendMasks;

	/** 
	 * Configuration for the parts of the skeleton to blend for each layer. Allows
	 * certain parts of the tree to be blended out or omitted from the pose.
	 * LayerSetup is used when BlendMode is BranchFilter.
	 */
	UPROPERTY(EditAnywhere, editfixedsize, Category=Runtime, meta=(BlueprintCompilerGeneratedDefaults, PinShownByDefault))
	TArray<FInputBlendPose> LayerSetup;

	/** The weights of each layer */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, editfixedsize, Category=Runtime, meta=(BlueprintCompilerGeneratedDefaults, PinShownByDefault))
	TArray<float> BlendWeights;

	/** Whether to blend bone rotations in mesh space or in local space */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category=Config)
	bool bMeshSpaceRotationBlend;

	/** Whether to blend bone scales in mesh space or in local space */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category=Config)
	bool bMeshSpaceScaleBlend;
	
	/** How to blend the layers together */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category=Config)
	TEnumAsByte<enum ECurveBlendOption::Type>	CurveBlendOption;

	/** Whether to incorporate the per-bone blend weight of the root bone when lending root motion */
	UPROPERTY(EditAnywhere, Category = Config)
	bool bBlendRootMotionBasedOnRootBone;

	bool bHasRelevantPoses;

	/*
 	 * Max LOD that this node is allowed to run
	 * For example if you have LODThreadhold to be 2, it will run until LOD 2 (based on 0 index)
	 * when the component LOD becomes 3, it will stop update/evaluate
	 * currently transition would be issue and that has to be re-visited
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Performance, meta = (DisplayName = "LOD Threshold"))
	int32 LODThreshold;

protected:
	// Per-bone weights for the skeleton. Serialized as these are only relative to the skeleton, but can potentially
	// be regenerated at runtime if the GUIDs dont match
	UPROPERTY()
	TArray<FPerBoneBlendWeight>	PerBoneBlendWeights;

	// Guids for skeleton used to determine whether the PerBoneBlendWeights need rebuilding
	UPROPERTY()
	FGuid SkeletonGuid;

	// Guid for virtual bones used to determine whether the PerBoneBlendWeights need rebuilding
	UPROPERTY()
	FGuid VirtualBoneGuid;

	// transient data to handle weight and target weight
	// this array changes based on required bones
	TArray<FPerBoneBlendWeight> DesiredBoneBlendWeights;
	TArray<FPerBoneBlendWeight> CurrentBoneBlendWeights;
	TArray<uint8> CurvePoseSourceIndices;

	// Serial number of the required bones container
	uint16 RequiredBonesSerialNumber;

public:	
	FHiAnimNode_LayeredBoneBlend();

	// FAnimNode_Base interface
	virtual void Initialize_AnyThread(const FAnimationInitializeContext& Context) override;
	virtual void CacheBones_AnyThread(const FAnimationCacheBonesContext& Context) override;
	virtual void Update_AnyThread(const FAnimationUpdateContext& Context) override;
	virtual void Evaluate_AnyThread(FPoseContext& Output) override;
	virtual void GatherDebugData(FNodeDebugData& DebugData) override;
	virtual int32 GetLODThreshold() const override { return LODThreshold; }
	virtual void PreUpdate(const UAnimInstance * InAnimInstance) override;
	// End of FAnimNode_Base interface

	// Set the blend mask for the specified input pose
	void SetBlendMask(int32 InPoseIndex, UBlendProfile* InBlendMask);
	
	// Invalidate the cached per-bone blend weights from the skeleton
	void InvalidatePerBoneBlendWeights() { RequiredBonesSerialNumber = 0; SkeletonGuid = FGuid(); VirtualBoneGuid = FGuid(); }
	
	// Invalidates the cached bone data so it is recalculated the next time this node is updated
	void InvalidateCachedBoneData() { RequiredBonesSerialNumber = 0; }

	/** This only used by custom handlers, and it is advanced feature. */
	void SetBasePoseLinkNode(FAnimNode_Base* NewLinkNode);
	
	/** This only used when dynamic linking other graphs to this one. */
	void SetBasePoseDynamicLinkNode(FPoseLinkBase* InPoseLink);

	int32 AddPose(FAnimNode_Base* NewLinkNode=nullptr, float BlendWeight=1.0, UBlendProfile* BlendProfile=nullptr);
	int32 AddPose(FAnimNode_Base* NewLinkNode, float BlendWeight, FInputBlendPose BranchFilter);
	
	void RemovePose(int32 PoseIndex)
	{
		BlendWeights.RemoveAt(PoseIndex);
		BlendPoses.RemoveAt(PoseIndex);

		if (BlendMasks.IsValidIndex(PoseIndex)) 
		{ 
			BlendMasks.RemoveAt(PoseIndex); 
		}

		if (LayerSetup.IsValidIndex(PoseIndex)) 
		{ 
			LayerSetup.RemoveAt(PoseIndex); 
		}
	}
private:
	// Rebuild cache per bone blend weights from the skeleton
	void RebuildPerBoneBlendWeights(const USkeleton* InSkeleton);

	// Check whether per-bone blend weights are valid according to the skeleton (GUID check)
	bool ArePerBoneBlendWeightsValid(const USkeleton* InSkeleton) const;

	// Update cached data if required
	void UpdateCachedBoneData(const FBoneContainer& RequiredBones, const USkeleton* Skeleton);

	friend class UHiAnimGraphNode_LayeredBoneBlend;

};
