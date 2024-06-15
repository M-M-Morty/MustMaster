// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyState_MovementMode.h"
#include "GameFramework/Character.h"
#include "GameFramework/CharacterMovementComponent.h"


void UHiAnimNotifyState_MovementMode::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);

	ACharacter* OwnerCharacter = Cast<ACharacter>(MeshComp->GetOwner());
	if (OwnerCharacter)
	{
		OwnerCharacter->GetCharacterMovement()->SetMovementMode(EnterMovementMode);
	}
}

void UHiAnimNotifyState_MovementMode::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);

	ACharacter* OwnerCharacter = Cast<ACharacter>(MeshComp->GetOwner());
	if (OwnerCharacter)
	{
		OwnerCharacter->GetCharacterMovement()->SetMovementMode(LeaveMovementMode);
	}
}

FString UHiAnimNotifyState_MovementMode::GetNotifyName_Implementation() const
{
	static UEnum* MovementModeEnum = StaticEnum<EMovementMode>();
	FString Name = FString::Printf(TEXT("Movement Mode  <Enter %s -- Leave %s>")
		, *MovementModeEnum->GetNameStringByValue(EnterMovementMode)
		, *MovementModeEnum->GetNameStringByValue(LeaveMovementMode));
	return Name;
}

