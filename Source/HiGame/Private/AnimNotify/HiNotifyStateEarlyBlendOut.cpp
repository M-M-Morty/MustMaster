// Fill out your copyright notice in the Description page of Project Settings.

#include "AnimNotify/HiNotifyStateEarlyBlendOut.h"
#include "Engine/World.h"
#include "TimerManager.h"
#include "Characters/HiCharacter.h"
#include "Component/HiLocomotionComponent.h"
#include "GameFramework/CharacterMovementComponent.h"


void UHiNotifyStateEarlyBlendOut::NotifyBegin(USkeletalMeshComponent * MeshComp, UAnimSequenceBase * Animation, float TotalDuration,
							const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);

	if (BeginMovementMode != MOVE_None)
	{
		AHiCharacter* OwnerCharacter = Cast<AHiCharacter>(MeshComp->GetOwner());
		if (OwnerCharacter)
		{
			OwnerCharacter->GetCharacterMovement()->SetMovementMode(BeginMovementMode);
		}
	}
}

void UHiNotifyStateEarlyBlendOut::NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                              float FrameDeltaTime, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference);
	
	if (!MeshComp || !MeshComp->GetAnimInstance())
	{
		return;
	}

	UAnimInstance* AnimInstance = MeshComp->GetAnimInstance();
	AHiCharacter* OwnerCharacter = Cast<AHiCharacter>(MeshComp->GetOwner());
	if (!OwnerCharacter || !AnimInstance)
	{
		return;
	}

	UHiLocomotionComponent *LocomotionComponent = OwnerCharacter->GetLocomotionComponent();

	if (!LocomotionComponent)
	{
		return;
	}

	UAnimMontage *Montage = Cast<UAnimMontage>(Animation);
	if (!Montage)
	{
		return;
	}

	FAnimMontageInstance* MontageInstance = AnimInstance->GetActiveInstanceForMontage(Montage);
	if (!MontageInstance)
	{
		return;
	}

	bool bStopMontage = false;
	if (bCheckMovementState && LocomotionComponent->GetMovementState() == MovementStateEquals)
	{
		bStopMontage = true;
	}
	else if (bCheckMovementInput && LocomotionComponent->HasMovementInput())
	{
		bStopMontage = true;
	}
	else if (bReverseCheckMovementInput && !LocomotionComponent->HasMovementInput())
	{
		bStopMontage = true;
	}
	else if (bCheckFloor)
	{
		UCharacterMovementComponent *Component = OwnerCharacter->GetCharacterMovement();
		if (Component)
		{
			FFindFloorResult Result;
			Component->K2_FindFloor(OwnerCharacter->GetActorLocation(), Result);
			if (!(Result.bBlockingHit && Result.bWalkableFloor))
			{
				bStopMontage = true;
			}
		}
	}

	if (bStopMontage)
	{
		if (bDisableRootMotion)
		{
			MontageInstance->PushDisableRootMotion();
		}
		
		FMontageBlendSettings BlendOutSettings;
		//Grab all settings from the montage, except BlendTime
		BlendOutSettings.Blend = Montage->BlendOut;
		BlendOutSettings.Blend.BlendTime = BlendOutTime;
		BlendOutSettings.BlendMode = Montage->BlendModeOut;
		BlendOutSettings.BlendProfile = Montage->BlendProfileOut;

		MontageInstance->Stop(BlendOutSettings);
	}
}

FString UHiNotifyStateEarlyBlendOut::GetNotifyName_Implementation() const
{
	return FString(TEXT("Hi Early Blend Out"));
}
