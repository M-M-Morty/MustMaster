// Fill out your copyright notice in the Description page of Project Settings.

#include "AnimNotify/HiAnimNotifyState_RootMotionOverrideType.h"

#include "Component/HiCharacterMovementComponent.h"
#include "Component/HiVehicleMovementComponent.h"


void UHiAnimNotifyState_RootMotionOverrideType::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);

	ACharacter* OwnerCharacter = Cast<ACharacter>(MeshComp->GetOwner());
	if (!OwnerCharacter)
	{
		return;
	}
	UHiCharacterMovementComponent* CharacterMovementComponent = Cast<UHiCharacterMovementComponent>(OwnerCharacter->GetCharacterMovement());
	if (!CharacterMovementComponent)
	{
		UHiVehicleMovementComponent* VehicleMovementComponent = Cast<UHiVehicleMovementComponent>(OwnerCharacter->GetCharacterMovement());
		if(VehicleMovementComponent)
		{
			VehicleMovementComponent->ChangeRootMotionOverrideType(Animation, RootMotionOverrideType);
		}
		return;
	}
	CharacterMovementComponent->ChangeRootMotionOverrideType(Animation, RootMotionOverrideType);
}

void UHiAnimNotifyState_RootMotionOverrideType::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);

	ACharacter* OwnerCharacter = Cast<ACharacter>(MeshComp->GetOwner());
	if (!OwnerCharacter)
	{
		return;
	}
	UHiCharacterMovementComponent* CharacterMovementComponent = Cast<UHiCharacterMovementComponent>(OwnerCharacter->GetCharacterMovement());
	if (!CharacterMovementComponent)
	{
		UHiVehicleMovementComponent* VehicleMovementComponent = Cast<UHiVehicleMovementComponent>(OwnerCharacter->GetCharacterMovement());
		if(VehicleMovementComponent)
		{
			VehicleMovementComponent->ResetRootMotionOverrideTypeToDefault(Animation);
		}
		return;
	}
	CharacterMovementComponent->ResetRootMotionOverrideTypeToDefault(Animation);
}

FString UHiAnimNotifyState_RootMotionOverrideType::GetNotifyName_Implementation() const
{
	FString Name(TEXT("Root Motion Override Type: "));
	Name.Append(GetEnumerationValueString(RootMotionOverrideType));
	return Name;
}
