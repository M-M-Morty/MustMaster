// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/Animation/HiAnimLayeredBlendInstanceProxy.h"
#include "Animation//AnimNode_LinkedAnimGraph.h"
#include "AnimNodes/AnimNode_CopyPoseFromMesh.h"
#pragma optimize( "", off )
void FHiAnimLayeredBlendInstanceProxy::Initialize(UAnimInstance* InAnimInstance)
{
	FAnimInstanceProxy::Initialize(InAnimInstance);
	FAnimationInitializeContext InitContext(this);
	BlendNode.Initialize_AnyThread(InitContext);
}

bool FHiAnimLayeredBlendInstanceProxy::Evaluate(FPoseContext& Output)
{
	BlendNode.Evaluate_AnyThread(Output);
	return true;
}

void FHiAnimLayeredBlendInstanceProxy::UpdateAnimationNode(const FAnimationUpdateContext& InContext)
{
	
	UpdateCounter.Increment();

	BlendNode.Update_AnyThread(InContext);
}

void FHiAnimLayeredBlendInstanceProxy::UpdateAnimationNode_WithRoot(const FAnimationUpdateContext& InContext,
	FAnimNode_Base* InRootNode, FName InLayerName)
{
	UpdateAnimationNode(InContext);
}

void FHiAnimLayeredBlendInstanceProxy::PostUpdate(UAnimInstance* InAnimInstance) const
{
	FAnimInstanceProxy::PostUpdate(InAnimInstance);
}

void FHiAnimLayeredBlendInstanceProxy::PreUpdate(UAnimInstance* InAnimInstance, float DeltaSeconds)
{
	FAnimInstanceProxy::PreUpdate(InAnimInstance, DeltaSeconds);
	BlendNode.PreUpdate(InAnimInstance);
}

void FHiAnimLayeredBlendInstanceProxy::InitializeObjects(UAnimInstance* InAnimInstance)
{
	FAnimInstanceProxy::InitializeObjects(InAnimInstance);
}

void FHiAnimLayeredBlendInstanceProxy::ClearObjects()
{
	FAnimInstanceProxy::ClearObjects();
}

void FHiAnimLayeredBlendInstanceProxy::AddLinkedAnimGraph(UAnimInstance* LinkedAnimInstance, int32 PoseIndex)
{
	FAnimNode_LinkedAnimGraph * Node = nullptr;
	if (PoseIndex == INDEX_NONE)
	{
		Node = new FAnimNode_LinkedAnimGraph();
		BlendNode.AddPose(Node);
	}
	if (BlendNode.BlendPoses.IsValidIndex(PoseIndex))
	{
		Node = new FAnimNode_LinkedAnimGraph();
		BlendNode.BlendPoses[PoseIndex].SetLinkNode(Node);
	}
	if (!Node)
	{
		return;;
	}
	Node->SetAnimClass(LinkedAnimInstance->GetClass(), LinkedAnimInstance);
}

void FHiAnimLayeredBlendInstanceProxy::SetBasePoseLinkedAnimGraph(UAnimInstance* LinkedAnimInstance)
{
	FAnimNode_LinkedAnimGraph * Node = new FAnimNode_LinkedAnimGraph();
	BlendNode.SetBasePoseLinkNode(Node);
	Node->SetAnimClass(LinkedAnimInstance->GetClass(), LinkedAnimInstance);
}

int32 FHiAnimLayeredBlendInstanceProxy::AddLinkedComponent(USkeletalMeshComponent* SourceMeshComponent, int32 PoseIndex)
{
	FAnimNode_CopyPoseFromMesh * Node = new FAnimNode_CopyPoseFromMesh();
	Node->SourceMeshComponent = SourceMeshComponent;
	if (BlendNode.BlendPoses.IsValidIndex(PoseIndex))
	{
		BlendNode.BlendPoses[PoseIndex].SetLinkNode(Node);
		return PoseIndex;
	}
	return BlendNode.AddPose(Node);
}

void FHiAnimLayeredBlendInstanceProxy::SetBasePoseLinkedComponent(USkeletalMeshComponent* SourceMeshComponent)
{
	FAnimNode_CopyPoseFromMesh * Node = new FAnimNode_CopyPoseFromMesh();
	Node->SourceMeshComponent = SourceMeshComponent;
	BlendNode.SetBasePoseLinkNode(Node);
}

void FHiAnimLayeredBlendInstanceProxy::SetLayeredBlendProfile(int32 PoseIndex, TObjectPtr<UBlendProfile> BlendProfile)
{
	if(BlendNode.BlendMasks.IsValidIndex(PoseIndex) && BlendProfile)
	{
		BlendNode.BlendMasks[PoseIndex] = BlendProfile;
	}
}

void FHiAnimLayeredBlendInstanceProxy::SetLayeredBoneMaskFilter(int32 PoseIndex, const FInputBlendPose& Filter)
{
	if(BlendNode.LayerSetup.IsValidIndex(PoseIndex))
	{
		BlendNode.LayerSetup[PoseIndex] = Filter;
	}
}

void FHiAnimLayeredBlendInstanceProxy::SetLayeredBoneBlendWeight(int32 PoseIndex, float BlendWeight)
{
	if(BlendNode.BlendWeights.IsValidIndex(PoseIndex))
	{
		BlendNode.BlendWeights[PoseIndex] = BlendWeight;
	}
}
