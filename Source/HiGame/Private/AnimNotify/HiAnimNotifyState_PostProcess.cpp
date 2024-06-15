// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyState_PostProcess.h"
#include "Components/PostProcessComponent.h"


void UHiAnimNotifyState_PostProcess::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	if (!IsValidChecked(MeshComp))
	{
		return;
	}

	if (MeshComp->GetWorld()->GetNetMode() == NM_DedicatedServer)
	{
		return;
	}
	//get origin materials from mesh component	
	Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
}

void UHiAnimNotifyState_PostProcess::NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float FrameDeltaTime, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference);
}

void UHiAnimNotifyState_PostProcess::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	if (!IsValid(MeshComp))
	{
		return;
	}

	if (MeshComp->GetWorld()->GetNetMode() == NM_DedicatedServer)
	{
		return;
	}

	Received_NotifyEnd(MeshComp, Animation, EventReference);
}

UPostProcessComponent* UHiAnimNotifyState_PostProcess::TryGetPostProcessComponent(AActor* InActor)
{
	if (IsValid(InActor))
	{
		return Cast<UPostProcessComponent>(InActor->GetComponentByClass(UPostProcessComponent::StaticClass()));		 
	}
	return nullptr;
}

