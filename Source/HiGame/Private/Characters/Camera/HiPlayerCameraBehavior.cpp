// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Camera/HiPlayerCameraBehavior.h"


void UHiPlayerCameraBehavior::OnPossess_Implementation(ACharacter *Character)
{
	
}

void UHiPlayerCameraBehavior::SetRotationMode(EHiRotationMode RotationMode)
{
	bVelocityDirection = RotationMode == EHiRotationMode::VelocityDirection;
	bLookingDirection = RotationMode == EHiRotationMode::LookingDirection;
	bAiming = RotationMode == EHiRotationMode::Aiming;
}

void UHiPlayerCameraBehavior::NativeUpdateAnimation(float DeltaSeconds)
{
	Super::NativeUpdateAnimation(DeltaSeconds);
	LastChangeMovementStateDuration += DeltaSeconds;
	if (PendingGait != EHiGait::Pending && LastChangeMovementStateDuration > ChangeGaitDuration)
	{
		Gait = PendingGait;
	}
}

void UHiPlayerCameraBehavior::SetGait(const EHiGait& NewGait)
{
	if (LastChangeMovementStateDuration > ChangeGaitDuration)
	{
		Gait = NewGait;
		PendingGait = EHiGait::Pending;
	}
	else
	{
		PendingGait = NewGait;
	}
}

void UHiPlayerCameraBehavior::SetMovementState(const EHiMovementState NewMovementState)
{
	if (MovementState != NewMovementState)
	{
		MovementState = NewMovementState;
		LastChangeMovementStateDuration = 0.0f;
	}
}