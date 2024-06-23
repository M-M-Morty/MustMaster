// Fill out your copyright notice in the Description page of Project Settings.

#include "AnimNotify/HiNotifyStateMovementAction.h"

#include "Characters/HiLocomotionCharacter.h"
#include "Component/HiLocomotionComponent.h"


void UHiNotifyStateMovementAction::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                                float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
	
	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	if (BaseCharacter && BaseCharacter->GetLocomotionComponent())
	{
		BaseCharacter->GetLocomotionComponent()->SetMovementAction(MovementAction);
	}
}

void UHiNotifyStateMovementAction::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                              const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);

	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	if (BaseCharacter && BaseCharacter->GetLocomotionComponent()
		&& BaseCharacter->GetLocomotionComponent()->GetMovementAction() == MovementAction)
	{
		BaseCharacter->GetLocomotionComponent()->SetMovementAction(EHiMovementAction::None);
	}
}

FString UHiNotifyStateMovementAction::GetNotifyName_Implementation() const
{
	FString Name(TEXT("Movement Action: "));
	Name.Append(GetEnumerationValueString(MovementAction));
	return Name;
}
