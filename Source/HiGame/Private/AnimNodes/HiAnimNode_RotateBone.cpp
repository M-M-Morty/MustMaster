// Copyright Epic Games, Inc. All Rights Reserved.

#include "AnimNodes/HiAnimNode_RotateBone.h"
#include "Animation/AnimTrace.h"

#include UE_INLINE_GENERATED_CPP_BY_NAME(HiAnimNode_RotateBone)

/////////////////////////////////////////////////////
// FHiAnimNode_RotateBone

void FHiAnimNode_RotateBone::Initialize_AnyThread(const FAnimationInitializeContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Initialize_AnyThread)
	FAnimNode_Base::Initialize_AnyThread(Context);

	BasePose.Initialize(Context);
}

void FHiAnimNode_RotateBone::CacheBones_AnyThread(const FAnimationCacheBonesContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(CacheBones_AnyThread)
	BasePose.CacheBones(Context);
}

void FHiAnimNode_RotateBone::Update_AnyThread(const FAnimationUpdateContext& Context)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Update_AnyThread)
	GetEvaluateGraphExposedInputs().Execute(Context);
	BasePose.Update(Context);

	TRACE_ANIM_NODE_VALUE(Context, TEXT("Pitch"), Pitch);
	TRACE_ANIM_NODE_VALUE(Context, TEXT("Yaw"), Yaw);
	TRACE_ANIM_NODE_VALUE(Context, TEXT("Roll"), Roll);
}

void FHiAnimNode_RotateBone::Evaluate_AnyThread(FPoseContext& Output)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(Evaluate_AnyThread)
	// Evaluate the input
	BasePose.Evaluate(Output);

	const FBoneContainer& BoneContainer = Output.Pose.GetBoneContainer();
	FCompactPoseBoneIndex CompactPoseBoneToModify = BoneToModify.GetCompactPoseIndex(BoneContainer);

	if (CompactPoseBoneToModify != INDEX_NONE)
	{
		// Build our desired rotation
		const FRotator DeltaRotation(Pitch, Yaw, Roll);
		if (!DeltaRotation.IsNearlyZero())
		{
			const FQuat DeltaQuat(DeltaRotation);

			// Apply delta rotation to modify bone.
			Output.Pose[CompactPoseBoneToModify].SetRotation(Output.Pose[CompactPoseBoneToModify].GetRotation() * DeltaQuat);
			Output.Pose[CompactPoseBoneToModify].NormalizeRotation();
		}
	}
}

void FHiAnimNode_RotateBone::GatherDebugData(FNodeDebugData& DebugData)
{
	DECLARE_SCOPE_HIERARCHICAL_COUNTER_ANIMNODE(GatherDebugData)
	FString DebugLine = DebugData.GetNodeName(this);

	DebugLine += FString::Printf(TEXT("Pitch(%.2f) Yaw(%.2f) Roll(%.2f)"), Pitch, Yaw, Roll);
	DebugData.AddDebugItem(DebugLine);

	BasePose.GatherDebugData(DebugData);
}

FHiAnimNode_RotateBone::FHiAnimNode_RotateBone()
	: Pitch(0.0f)
	, Yaw(0.0f)
	, Roll(0.0f)
{
}

