// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiNpcLocomotionAppearance.h"

#include "Characters/HiLocomotionCharacter.h"
#include "Kismet/KismetMathLibrary.h"
#include "Utils/MathHelper.h"

const FName NAME_NpcYawOffset(TEXT("YawOffset"));


UHiNpcLocomotionAppearance::UHiNpcLocomotionAppearance(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UHiNpcLocomotionAppearance::InitializeComponent()
{
	Super::InitializeComponent();
	MyCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(CharacterOwner->GetMovementComponent());
}

void UHiNpcLocomotionAppearance::TickLocomotion(float DeltaTime)
{
	SetEssentialValues(DeltaTime);

	switch (MovementState)
	{
	case EHiMovementState::Grounded:
		UpdateCharacterMovement();
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::InAir:
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::Ragdoll:
		RagdollUpdate(DeltaTime);
		break;
	default:
		break;
	}

	// Cache values
	PreviousVelocity = CharacterOwner->GetVelocity();
	PreviousAimingYaw = AimingRotation.Yaw;

	if(bHasCacheBones)
	{
		CacheBoneTransforms();
	}
}

void UHiNpcLocomotionAppearance::RagdollStart()
{
	Super::RagdollStart();
}

void UHiNpcLocomotionAppearance::RagdollEnd()
{
	Super::RagdollEnd();
}

void UHiNpcLocomotionAppearance::BeginPlay()
{
	Super::BeginPlay();

	MyCharacterMovementComponent->SetMovementSettings(GetTargetMovementSettings());
}

void UHiNpcLocomotionAppearance::OnRotationModeChanged(EHiRotationMode PreviousRotationMode)
{
	Super::OnRotationModeChanged(PreviousRotationMode);
	MyCharacterMovementComponent->SetMovementSettings(GetTargetMovementSettings());
}

void UHiNpcLocomotionAppearance::OnSpeedScaleChanged(float PrevSpeedScale)
{
	Super::OnSpeedScaleChanged(PrevSpeedScale);

	if (MyCharacterMovementComponent->GetSpeedScale() != SpeedScale)
	{
		//UE_LOG(LogALS, Warning, TEXT("AALSBaseCharacter::SetSpeedScale %f"), scale);
		MyCharacterMovementComponent->SetSpeedScale(SpeedScale);
	}
}

void UHiNpcLocomotionAppearance::UpdateCharacterMovement()
{
	// Set the Allowed Gait
	const EHiGait AllowedGait = GetAllowedGait();

	if (AllowedGait != Gait)
	{
		SetGait(AllowedGait);
	}

	// Update the Character Max Walk Speed to the configured speeds based on the currently Allowed Gait.
	MyCharacterMovementComponent->SetAllowedGait(AllowedGait);

	SetRotationMode(DesiredRotationMode);
}

void UHiNpcLocomotionAppearance::UpdateCharacterRotation(float DeltaTime)
{
	if (CharacterOwner->HasAnyRootMotion())
	{
		return;
	}

	// Calculate target orientation
	FRotator NewTargetOrientation;
	switch (RotationMode)
	{
	case EHiRotationMode::VelocityDirection:
		NewTargetOrientation = { LastVelocityRotation.Pitch, LastVelocityRotation.Yaw, 0.0f };
		break;
	case EHiRotationMode::LookingDirection:
		NewTargetOrientation = { 0, AimingRotation.Yaw + GetAnimCurveValue(NAME_NpcYawOffset), 0.0f };
		break;
	case EHiRotationMode::Aiming:
		NewTargetOrientation = { AimingRotation.Pitch, AimingRotation.Yaw, 0.0f };
		break;
	}
	if (MovementState == EHiMovementState::Grounded || InAirState == EHiInAirState::Falling || InAirState == EHiInAirState::Fly)
	{
		NewTargetOrientation.Pitch = 0.0f;
	}

	if (!bEnableCustomizedRotationWithRootMotion && CharacterOwner->IsPlayingNetworkedRootMotionMontage())
	{
		TargetRotation = NewTargetOrientation;
		return;
	}
	if (MovementAction == EHiMovementAction::None)
	{
		const bool bCanUpdateMovingRot = ((bIsMoving && bHasMovementInput && InAirState != EHiInAirState::Falling) || Speed > 20.0f);
		if (bCanUpdateMovingRot)
		{
			//bUseCustomRotation = false;
			float ActorInterpSpeed = DefaultActorRotationSpeed;
			//if (RotationMode == EHiRotationMode::Aiming)
			//{
			//	ActorInterpSpeed = 5.0f;
			//}
			if (bUseCustomRotation)
			{
				ActorInterpSpeed = CustomSmoothContext.ActorInterpSpeed;
			}

			TargetRotation = NewTargetOrientation;
			const FRotator ResultActorRotation = UMathHelper::RNearestInterpTo(CharacterOwner->GetActorRotation(), TargetRotation, DeltaTime, ActorInterpSpeed * RotationSpeedScale);
			CharacterOwner->SetActorRotation(ResultActorRotation);
		}
	}

	// Other actions are ignored...
}

EHiGait UHiNpcLocomotionAppearance::GetActualGait(EHiGait AllowedGait) const
{
	// Get the Actual Gait. This is calculated by the actual movement of the character,  and so it can be different
	// from the desired gait or allowed gait. For instance, if the Allowed Gait becomes walking,
	// the Actual gait will still be running untill the character decelerates to the walking speed.

	const float LocWalkSpeed = MyCharacterMovementComponent->CurrentMovementSettings.WalkSpeed;
	const float LocRunSpeed = MyCharacterMovementComponent->CurrentMovementSettings.RunSpeed;

	if (Speed > LocRunSpeed + 10.0f)
	{
		if (AllowedGait == EHiGait::Sprinting)
		{
			return EHiGait::Sprinting;
		}
		return EHiGait::Running;
	}

	if (Speed >= LocWalkSpeed + 10.0f)
	{
		return EHiGait::Running;
	}

	return EHiGait::Walking;
}
