// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/AnimationUpdater/HiGroundMovementAnimationUpdater.h"
#include "Characters/Animation/HiCharacterAnimInstance.h"
#include "Characters/HiCharacter.h"
#include "GameFramework/CharacterMovementComponent.h"

void UHiGroundMovementAnimationUpdater::NativeUpdateAnimation(float DeltaSeconds)
{
	if (AnimInstanceOwner->MovementState == EHiMovementState::Grounded)
	{
		UpdateMovementValues(DeltaSeconds);

		auto &CharacterInformation = AnimInstanceOwner->CharacterInformation;
		CharacterInformation.DirectionYaw = CalculateMovementDirection();
	}
}

float UHiGroundMovementAnimationUpdater::CalculateMovementDirection()
{
	auto &CharacterInformation = AnimInstanceOwner->CharacterInformation;
	// Calculate the Movement Direction. This value represents the direction the character is moving relative to the camera
	// during the Looking Cirection / Aiming rotation modes, and is used in the Cycle Blending Anim Layers to blend to the
	// appropriate directional states.
	if (CharacterInformation.RotationMode == EHiRotationMode::VelocityDirection)
	{
		return 0.0f;
	}

	auto &Character = AnimInstanceOwner->Character;

	float VelocityYaw = Character->GetCharacterMovement()->Velocity.ToOrientationRotator().Yaw;
	float DeltaYaw = VelocityYaw - Character->GetActorRotation().Yaw;
	DeltaYaw = FRotator::NormalizeAxis(DeltaYaw);		// (-180,180]

	return FRotator::NormalizeAxis(DeltaYaw);
}

void UHiGroundMovementAnimationUpdater::UpdateMovementValues(float DeltaSeconds)
{
	// Set the Play Rates
	AnimInstanceOwner->Grounded.StandingPlayRate = CalculateStandingPlayRate();
}

float UHiGroundMovementAnimationUpdater::CalculateStandingPlayRate() const
{
	// Calculate the Play Rate by dividing the Character's speed by the Animated Speed for each gait.
	// The lerps are determined by the "W_Gait" anim curve that exists on every locomotion cycle so
	// that the play rate is always in sync with the currently blended animation.
	// The value is also divided by the Stride Blend and the mesh scale so that the play rate increases as the stride or scale gets smaller
	float PlayRate = 1.0f;
	auto &CharacterInformation = AnimInstanceOwner->CharacterInformation;
	auto &Config = AnimInstanceOwner->GroundedConfig;
	switch (AnimInstanceOwner->LogicGait)
	{
	case EHiGait::Walking:
		PlayRate = CharacterInformation.Speed / Config.AnimatedWalkSpeed;
		break;
	case EHiGait::Running:
		PlayRate = CharacterInformation.Speed / Config.AnimatedRunSpeed;
		break;
	case EHiGait::Sprinting:
		PlayRate = CharacterInformation.Speed / Config.AnimatedSprintSpeed;
		break;
	default:
		break;
	}

	return FMath::Clamp(PlayRate / AnimInstanceOwner->GetOwningComponent()->GetComponentScale().Z, 0.0f, 3.0f);
}