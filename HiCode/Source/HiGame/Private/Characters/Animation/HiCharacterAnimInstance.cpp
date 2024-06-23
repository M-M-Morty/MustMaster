// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiCharacterAnimInstance.h"
#include "Component/HiLocomotionComponent.h"
#include "Characters/HiCharacter.h"
#include "Characters/AnimationUpdater/HiAnimationUpdater.h"
#include "GameFramework/CharacterMovementComponent.h"

void UHiCharacterAnimInstance::NativeBeginPlay()
{
	Super::NativeBeginPlay();

	for (auto UpdaterClass : AnimationUpdaterClasses)
	{
		if (!IsValid(UpdaterClass))
		{
			continue;
		}
		UHiAnimationUpdater *Updater = NewObject<UHiAnimationUpdater>(this, UpdaterClass);
		AnimationUpdaters.Emplace(Updater);
	}

	for (auto AnimUpdater : AnimationUpdaters)
	{
		AnimUpdater->Initialize(this);
	}
}

void UHiCharacterAnimInstance::NativeUninitializeAnimation()
{
	for (auto AnimUpdater : AnimationUpdaters)
	{
		AnimUpdater->UnInitialize(this);
	}

	AnimationUpdaters.Reset();
	
	Super::NativeUninitializeAnimation();
}

// float UHiCharacterAnimInstance::Montage_Play_With_PoseSearch_Implementation(UAnimMontage* MontageToPlay, float InPlayRate, EMontagePlayReturnType ReturnValueType, float InTimeToStartMontageAt, bool bStopAllMontages)
// {
// 	return 0.0f;
// }

void UHiCharacterAnimInstance::NativeUpdateAnimation(float DeltaSeconds)
{
	Super::NativeUpdateAnimation(DeltaSeconds);

	if (!LocomotionComponent || !Character)
	{
		return;
	}

	float NewRootYawOffset = 0.0f;
	MovementDirection = CalculateMovementDirection(NewRootYawOffset);

	RootYawOffset =  FMath::FInterpTo(RootYawOffset, NewRootYawOffset, DeltaSeconds, RootYawOffsetInterpSpeed);
	
	for (auto AnimUpdater : AnimationUpdaters)
	{
		AnimUpdater->NativeUpdateAnimation(DeltaSeconds);
	}
}

void UHiCharacterAnimInstance::NativePostEvaluateAnimation()
{
	for (auto AnimUpdater : AnimationUpdaters)
	{
		AnimUpdater->NativePostEvaluateAnimation();
	}
}

UHiAnimationUpdater* UHiCharacterAnimInstance::GetAnimationUpdater(FName Tag)
{
	for (auto &AnimationUpdate: AnimationUpdaters)
	{
		if (AnimationUpdate->Tag == Tag)
		{
			return AnimationUpdate;
		}
	}
	return nullptr;
}

void UHiCharacterAnimInstance::WalkStop_Implementation()
{
	
}

EHiMovementDirection UHiCharacterAnimInstance::CalculateMovementDirection(float &NewRootYawOffset)
{
	if (Character->GetLocalRole() == ROLE_Authority && Character->GetNetMode() != NM_Standalone)
	{
		return EHiMovementDirection::Forward;
	}

	// Calculate the Movement Direction. This value represents the direction the character is moving relative to the camera
	// during the Looking Cirection / Aiming rotation modes, and is used in the Cycle Blending Anim Layers to blend to the
	// appropriate directional states.
	

	float VelocityYaw = Character->GetCharacterMovement()->Velocity.ToOrientationRotator().Yaw;
	float DeltaYaw = VelocityYaw - Character->GetActorRotation().Yaw;
	DeltaYaw = FRotator::NormalizeAxis(DeltaYaw);		// (-180,180]

	if (LocomotionComponent->GetRotationMode() == EHiRotationMode::VelocityDirection)
	{
		NewRootYawOffset = DeltaYaw;		// (-180,180]
		return EHiMovementDirection::Forward;
	}
	//UE_LOG(LogTemp, Warning, L"[ZL] delta yaw: %.2f", DeltaYaw);

	float FThreshold = 45.0f;
	float BThreshold = 135.0f;
	float DirectionYaw = Character->GetActorRotation().Yaw;
	EHiMovementDirection CurrentMovementDirection = EHiMovementDirection::Backward;
	if (FThreshold >= DeltaYaw && DeltaYaw >= -FThreshold)
	{
		CurrentMovementDirection = EHiMovementDirection::Forward;
	}
	else if (-FThreshold >= DeltaYaw && DeltaYaw >= -BThreshold)
	{
		DirectionYaw -= 90.0f;
		CurrentMovementDirection = EHiMovementDirection::Right;
	}
	else if (BThreshold >= DeltaYaw && DeltaYaw >= FThreshold)
	{
		DirectionYaw += 90.0f;
		CurrentMovementDirection = EHiMovementDirection::Left;
	}
	else
	{
		DirectionYaw -= -180.0f;
		CurrentMovementDirection = EHiMovementDirection::Backward;
	}
	NewRootYawOffset = FRotator::NormalizeAxis(VelocityYaw - DirectionYaw);
	//UE_LOG(LogTemp, Warning, L"[ZL] yawoffset %.2f,  actor %.2f   vel: %.2f   move: %d", NewRootYawOffset, Character->GetActorRotation().Yaw, Character->GetCharacterMovement()->Velocity.ToOrientationRotator().Yaw, CurrentMovementDirection);
	return CurrentMovementDirection;
}
