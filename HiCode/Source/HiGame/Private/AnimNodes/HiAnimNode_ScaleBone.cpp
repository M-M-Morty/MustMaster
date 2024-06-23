// Copyright Epic Games, Inc. All Rights Reserved.

#include "AnimNodes/HiAnimNode_ScaleBone.h"
#include "Animation/AnimTrace.h"

#include UE_INLINE_GENERATED_CPP_BY_NAME(HiAnimNode_ScaleBone)

/////////////////////////////////////////////////////
// FHiAnimNode_ScaleBone

void FHiAnimNode_ScaleBone::Initialize_AnyThread(const FAnimationInitializeContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Initialize_AnyThread)
	FAnimNode_Base::Initialize_AnyThread(Context);

	BasePose.Initialize(Context);
}

void FHiAnimNode_ScaleBone::CacheBones_AnyThread(const FAnimationCacheBonesContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(CacheBones_AnyThread)
	BasePose.CacheBones(Context);
}

void FHiAnimNode_ScaleBone::Update_AnyThread(const FAnimationUpdateContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Update_AnyThread)
	GetEvaluateGraphExposedInputs().Execute(Context);
	BasePose.Update(Context);

	TRACE_ANIM_NODE_VALUE(Context, TEXT("Scale"), Scale);
}

void FHiAnimNode_ScaleBone::Evaluate_AnyThread(FPoseContext& Output)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Evaluate_AnyThread)
	// Evaluate the input
	BasePose.Evaluate(Output);

	const FBoneContainer& BoneContainer = Output.Pose.GetBoneContainer();
	FCompactPoseBoneIndex CompactPoseBoneToModify = BoneToModify.GetCompactPoseIndex(BoneContainer);

	if (CompactPoseBoneToModify != INDEX_NONE)
	{
		// Apply scale to modify bone.
		Output.Pose[CompactPoseBoneToModify].SetScale3D(Scale);
	}
}


void FHiAnimNode_ScaleBone::GatherDebugData(FNodeDebugData& DebugData)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(GatherDebugData)
	FString DebugLine = DebugData.GetNodeName(this);

	DebugLine += FString::Printf(TEXT("Scale(%s)"), *Scale.ToString());
	DebugData.AddDebugItem(DebugLine);

	BasePose.GatherDebugData(DebugData);
}

FHiAnimNode_ScaleBone::FHiAnimNode_ScaleBone()
	: Scale(FVector::OneVector)
{
}

