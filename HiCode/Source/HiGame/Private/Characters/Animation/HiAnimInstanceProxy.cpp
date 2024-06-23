// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/Animation/HiAnimInstanceProxy.h"
#include "Animation/AnimNodeBase.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Component/HiSkeletalMeshComponent.h"
FHiAnimInstanceProxy::FHiAnimInstanceProxy():
Super()
{
}

FHiAnimInstanceProxy::FHiAnimInstanceProxy(UAnimInstance* Instance):
Super(Instance)
{
}

void FHiAnimInstanceProxy::InitSyncAnimSequence(UAnimSequenceBase* Anim) const
{
	if (!Anim)
	{
		return;
	}
	//UE_LOG(LogAnimation, Log, TEXT("[%lld] InitSyncAnimSequence, %s"), GFrameCounter, Anim ? *Anim->GetName() : TEXT("None"));
	if (const UAnimInstance* AnimInstance = Cast<UAnimInstance>(GetAnimInstanceObject()))
	{
		UHiSkeletalMeshComponent* MeshComp = Cast<UHiSkeletalMeshComponent>(AnimInstance->GetSkelMeshComponent());
		if(MeshComp && MeshComp->NeedFillTargetSkeletonPose())
		{
			MeshComp->SyncAnimSequence(Anim);
		}
		if(const UHiAnimInstance* HiAnimInstance = Cast<UHiAnimInstance>(AnimInstance))
		{
			const_cast<UHiAnimInstance*>(HiAnimInstance)->OnAnimNodeInitialize(Anim);
		}
	}
	
}

void FHiAnimInstanceProxy::InitializeAnimNodeAnimSequence(UAnimInstance* AnimInstance)
{
	if (!IsNeedInitializeSyncAnimSequence())
	{
		return;
	}
	UHiSkeletalMeshComponent* MeshComp = Cast<UHiSkeletalMeshComponent>(AnimInstance->GetSkelMeshComponent());
	if(MeshComp && MeshComp->NeedFillTargetSkeletonPose())
	{
		// Init any nodes that need non-relevancy based initialization
		for (FStructProperty* Property :GetAnimClassInterface()->GetAnimNodeProperties())
		{
			if(Property->Struct->IsChildOf(FAnimNode_Base::StaticStruct()))
			{
				FAnimNode_Base* AnimNode = GetNodeFromProperty<FAnimNode_Base>(Property);
				if(AnimNode->HasAnimSequences())
				{
					AnimNode->InitializeAnimSequences(this);
				}
			}
		}
		isSyncAnimNodeInitialized = true;
	}
	
}
