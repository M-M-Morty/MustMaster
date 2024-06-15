// Copyright Epic Games, Inc. All Rights Reserved.

#include "AnimNodes/HiAnimNode_TranslateBone.h"
#include "Animation/AnimTrace.h"

#include UE_INLINE_GENERATED_CPP_BY_NAME(HiAnimNode_TranslateBone)

/////////////////////////////////////////////////////
// FHiAnimNode_TranslateBone

void FHiAnimNode_TranslateBone::Initialize_AnyThread(const FAnimationInitializeContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Initialize_AnyThread)
	FAnimNode_Base::Initialize_AnyThread(Context);

	BasePose.Initialize(Context);
}

void FHiAnimNode_TranslateBone::CacheBones_AnyThread(const FAnimationCacheBonesContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(CacheBones_AnyThread)
	BasePose.CacheBones(Context);
}

void FHiAnimNode_TranslateBone::Update_AnyThread(const FAnimationUpdateContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Update_AnyThread)
	GetEvaluateGraphExposedInputs().Execute(Context);
	BasePose.Update(Context);

	TRACE_ANIM_NODE_VALUE(Context, TEXT("Translation"), Translation);
}

void FHiAnimNode_TranslateBone::Evaluate_AnyThread(FPoseContext& Output)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Evaluate_AnyThread)
	// Evaluate the input
	BasePose.Evaluate(Output);

	const FBoneContainer& BoneContainer = Output.Pose.GetBoneContainer();
	FCompactPoseBoneIndex CompactPoseBoneToModify = BoneToModify.GetCompactPoseIndex(BoneContainer);

	if (CompactPoseBoneToModify != INDEX_NONE)
	{
		// Apply delta translation to modify bone.
		Output.Pose[CompactPoseBoneToModify].SetTranslation(Output.Pose[CompactPoseBoneToModify].GetTranslation() + Translation);
	}
}


void FHiAnimNode_TranslateBone::GatherDebugData(FNodeDebugData& DebugData)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(GatherDebugData)
	FString DebugLine = DebugData.GetNodeName(this);

	DebugLine += FString::Printf(TEXT("Translation(%s)"), *Translation.ToString());
	DebugData.AddDebugItem(DebugLine);

	BasePose.GatherDebugData(DebugData);
}

FHiAnimNode_TranslateBone::FHiAnimNode_TranslateBone()
	: Translation(FVector::ZeroVector)
{
}

