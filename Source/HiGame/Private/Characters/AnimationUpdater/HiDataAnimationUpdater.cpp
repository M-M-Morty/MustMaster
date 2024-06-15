// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/AnimationUpdater/HiDataAnimationUpdater.h"
#include "Characters/Animation/HiCharacterAnimInstance.h"
#include "Characters/HiCharacter.h"
#include "Component/HiLocomotionComponent.h"
#include "GameFramework/CharacterMovementComponent.h"

DEFINE_LOG_CATEGORY_STATIC(HiDataAnimationUpdater, Log, All)

void UHiDataAnimationUpdater::NativeUpdateAnimation(float DeltaSeconds)
{
	UpdateCharacterInformation(DeltaSeconds);
}
	
/** Updating data for animation from the character blueprint, including displacement data, logic state, etc. */
void UHiDataAnimationUpdater::UpdateCharacterInformation_Implementation(float DeltaSeconds)
{
	// Update rest of character information. Others are reflected into anim bp when they're set inside character class
	if (!AnimInstanceOwner)
	{
		return;
	}
	
	auto & CharacterInformation = AnimInstanceOwner->CharacterInformation;
	auto & LocomotionComponent = AnimInstanceOwner->LocomotionComponent;
	auto & Character = AnimInstanceOwner->Character;

	if (!LocomotionComponent || !Character)
	{
		return;
	}
	
	CharacterInformation.MovementInputAmount = LocomotionComponent->GetMovementInputAmount();
	CharacterInformation.bHasMovementInput = LocomotionComponent->HasMovementInput();
	CharacterInformation.Acceleration = LocomotionComponent->GetAcceleration();
	CharacterInformation.AimYawRate = LocomotionComponent->GetAimYawRate();
	CharacterInformation.Speed = LocomotionComponent->GetSpeed();
	CharacterInformation.Velocity = Character->GetCharacterMovement()->Velocity;
	CharacterInformation.bIsAccelerating = CharacterInformation.Acceleration.Dot(CharacterInformation.Velocity) > 0;
	CharacterInformation.MovementInput = LocomotionComponent->GetMovementInput();
	CharacterInformation.AimingRotation = LocomotionComponent->GetAimingRotation();
	CharacterInformation.CharacterActorRotation = Character->GetActorRotation();
	CharacterInformation.PrevMovementState = LocomotionComponent->GetPrevMovementState();
	CharacterInformation.MovementAction = LocomotionComponent->GetMovementAction();
	CharacterInformation.bIsMoving = LocomotionComponent->IsMoving();
	CharacterInformation.RotationMode = LocomotionComponent->GetRotationMode();

	// UE_LOG(HiDataAnimationUpdater, Log, TEXT("UHiGroundTurnAnimUpdater::TurnInPlace_Implementation NetMode: %d, Char: %s, Speed: %f, Velocity: %s"),
	// (int32)AnimInstanceOwner->GetOwningActor()->GetWorld()->GetNetMode(), *GetNameSafe(AnimInstanceOwner->GetOwningActor()), CharacterInformation.Speed, *CharacterInformation.Velocity.ToCompactString());
	
	AnimInstanceOwner->MovementState = LocomotionComponent->GetMovementState();
	AnimInstanceOwner->LogicGait = LocomotionComponent->GetGait();
	
}