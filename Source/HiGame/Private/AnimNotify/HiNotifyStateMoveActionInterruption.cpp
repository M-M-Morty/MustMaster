// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiNotifyStateMoveActionInterruption.h"

#include "Characters/HiLocomotionCharacter.h"
#include "Component/HiAvatarLocomotionAppearance.h"


void UHiNotifyStateMoveActionInterruption::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                                float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
	
	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	if (!BaseCharacter)
	{
		return;
	}
	UHiAvatarLocomotionAppearance* LocomotionComponent = Cast<UHiAvatarLocomotionAppearance>(BaseCharacter->GetLocomotionComponent());
	if (!LocomotionComponent)
	{
		return;
	}
	LocomotionComponent->SetMoveInterruptionConstraint(true, MinimumInterruptionAngle);
}

void UHiNotifyStateMoveActionInterruption::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                              const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);

	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	if (!BaseCharacter)
	{
		return;
	}
	UHiAvatarLocomotionAppearance* LocomotionComponent = Cast<UHiAvatarLocomotionAppearance>(BaseCharacter->GetLocomotionComponent());
	if (!LocomotionComponent)
	{
		return;
	}
	LocomotionComponent->SetMoveInterruptionConstraint(false);
}

FString UHiNotifyStateMoveActionInterruption::GetNotifyName_Implementation() const
{
	FString Name(TEXT("Move action interruption"));
	return Name;
}
