// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiInAirAnimationUpdater.h"
#include "Animation/AnimInstance.h"
#include "Characters/HiCharacter.h"
#include "Characters/Animation/HiLocomotionAnimInstance.h"
#include "Components/CapsuleComponent.h"
#include "Component/HiCharacterDebugComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include "GameFramework/PhysicsVolume.h"
#include "Component/HiCharacterDebugComponent.h"


const float LAND_PREDICTION_ACCURACY = 0.01f;
const int INVALID_LANDING_ANIM_INDEX = -1;


void HiInAirAnimationUpdater::NativeInitialize(UHiLocomotionAnimInstance* InAnimInstance, FHiInAirAnimConfig& InConfig)
{
	Config = InConfig;
	OwnerAnimInstance = InAnimInstance;

	// Preprocessing landing data
	for (const FHiLandingAnimConfig& LandingAnimConfig : Config.LandingAnimArray)
	{
		if (!LandingAnimConfig.LandingSequence)
		{
			continue;
		}
		const float PreLandingAnimTime = FMath::Min(LandingAnimConfig.LandingSequence->GetPlayLength(), LandingAnimConfig.PreLandingAnimTime);
		MaxPreLandingAnimTime = FMath::Max(MaxPreLandingAnimTime, PreLandingAnimTime);

		LandingAnimArray.Add(LandingAnimConfig);
		LandingAnimArray.Last().PreLandingAnimTime = PreLandingAnimTime;
	}

	if (!LandingAnimArray.IsEmpty())
	{
		OwnerAnimInstance->InAirValues.SelectLandingSequence = LandingAnimArray[0].LandingSequence;
	}
}

void HiInAirAnimationUpdater::NativeUpdate(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues)
{
	if (OwnerAnimInstance->MovementState != EHiMovementState::InAir)
	{
		return;
	}
	if (OwnerAnimInstance->Character->IsNetMode(NM_Client) || OwnerAnimInstance->Character->GetLocalRole() != ROLE_Authority)
	{
		// Update the fall speed. Setting this value only while in the air allows you to use it within the AnimGraph for the landing strength.
		// If not, the Z velocity would return to 0 on landing.
		// Reverse Velocity Z, which is easy to understand and use externally.
		OutEvaluateValues.FallSpeed = -OwnerAnimInstance->CharacterInformation.Velocity.Z;

		UpdateKeepGroundAnim(DeltaSeconds, OutEvaluateValues);
		UpdatePredictLanding(DeltaSeconds, OutEvaluateValues);
	}

	// TODO: remove to evaluate values
	// Interp and set the In Air Lean Amount
	const FHiLeanAmount InAirLeanAmount = CalcAirLeanAmount(OutEvaluateValues.FallSpeed);
	//OwnerAnimInstance->LeanAmount.LR = FMath::FInterpTo(OwnerAnimInstance->LeanAmount.LR, InAirLeanAmount.LR, DeltaSeconds, Config.InAirLeanInterpSpeed);
	//OwnerAnimInstance->LeanAmount.FB = FMath::FInterpTo(OwnerAnimInstance->LeanAmount.FB, InAirLeanAmount.FB, DeltaSeconds, Config.InAirLeanInterpSpeed);
}

void HiInAirAnimationUpdater::NativeGlideUpdate(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues)
{
	if (OwnerAnimInstance->Character->IsNetMode(NM_Client) || OwnerAnimInstance->Character->GetLocalRole() != ROLE_Authority)
	{
		// Update the fall speed. Setting this value only while in the air allows you to use it within the AnimGraph for the landing strength.
		// If not, the Z velocity would return to 0 on landing.
		// Reverse Velocity Z, which is easy to understand and use externally.
		OutEvaluateValues.FallSpeed = -OwnerAnimInstance->CharacterInformation.Velocity.Z;

		UpdateKeepGroundAnim(DeltaSeconds, OutEvaluateValues);
		UpdatePredictLanding(DeltaSeconds, OutEvaluateValues);
	}
}

void HiInAirAnimationUpdater::UpdateKeepGroundAnim(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues)
{
	if (bCheckPredictLand_KeepGroundAnim)
	{
		float KeepAnimPredictLandingTime = PredictLandingDuration(OutEvaluateValues.FallSpeed, Config.MaxPredictedLandingTime_KeepGroundAnimation);
		if (KeepAnimPredictLandingTime < Config.MaxPredictedLandingTime_KeepGroundAnimation)
		{
			// Keep land animation
			OwnerAnimInstance->AnimatedMovementState = EHiMovementState::Grounded;
		}
		else
		{
			bCheckPredictLand_KeepGroundAnim = false;
		}
	}
}

void HiInAirAnimationUpdater::UpdatePredictLanding(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues)
{
	if (OutEvaluateValues.FallSpeed <= 0.0f)
	{
		// Do not make predictions for landing during the upward phase
		return;
	}

	// Predict the animation time of landing
	float PrevPredictLandingAnimTime = OutEvaluateValues.LandPrediction;
	float AnimatedPredictLandingTime = 0.0f;	// Total animation time in configuration
	if (bNeedReselectLandAnimation)
	{
		// When unsure which landing animation to choose, choose the longest time to make predictions
		AnimatedPredictLandingTime = MaxPreLandingAnimTime;
	}
	else
	{
		// Choose a certain landing animation duration for prediction
		AnimatedPredictLandingTime = LandingAnimArray[LandingAnimSelectIndex].PreLandingAnimTime;
	}
	float LeftPredictLandingDuration = PredictLandingDuration(OutEvaluateValues.FallSpeed, AnimatedPredictLandingTime * Config.AnimatedLandLeadScale) / Config.AnimatedLandLeadScale;

	// Select landing animation when max prediction is successful
	if (bNeedReselectLandAnimation && LeftPredictLandingDuration < AnimatedPredictLandingTime)
	{
		const int NewLandingAnimSelectIndex = CalcLandSelect(OutEvaluateValues.FallSpeed, LeftPredictLandingDuration);

		if (INVALID_LANDING_ANIM_INDEX != NewLandingAnimSelectIndex)
		{
			AnimatedPredictLandingTime = LandingAnimArray[NewLandingAnimSelectIndex].PreLandingAnimTime;
			LeftPredictLandingDuration = PredictLandingDuration(OutEvaluateValues.FallSpeed, AnimatedPredictLandingTime * Config.AnimatedLandLeadScale) / Config.AnimatedLandLeadScale;

			if (LeftPredictLandingDuration < AnimatedPredictLandingTime)
			{
				OutEvaluateValues.SelectLandingSequence = LandingAnimArray[NewLandingAnimSelectIndex].LandingSequence;
				LandingAnimSelectIndex = NewLandingAnimSelectIndex;
				OutEvaluateValues.AnimatedPredictLandingTime = AnimatedPredictLandingTime;
				bNeedReselectLandAnimation = false;
			}
		}
	}
	// Update new predict landing anim time
	OutEvaluateValues.LandPrediction = AnimatedPredictLandingTime - LeftPredictLandingDuration;
	if (!bNeedReselectLandAnimation && PrevPredictLandingAnimTime > OutEvaluateValues.LandPrediction)
	{
		// Play the selected land animation backward
		OutEvaluateValues.LandPrediction -= FMath::Min(DeltaSeconds, PrevPredictLandingAnimTime - OutEvaluateValues.LandPrediction);
		if (OutEvaluateValues.LandPrediction < 0)
		{
			//OutEvaluateValues.SelectLandingSequence = nullptr;
			bNeedReselectLandAnimation = true;
		}
	}

	OutEvaluateValues.LandPredictAnimationRate = FMath::IsNearlyZero(DeltaSeconds, UE_KINDA_SMALL_NUMBER) ? 0.0f : (OutEvaluateValues.LandPrediction - PrevPredictLandingAnimTime) / DeltaSeconds;

	// Select jump start pose based on speed and feet position
	float JumpFeetPosition = CalcJumpFeetPosition(OwnerAnimInstance->CharacterInformation.Velocity);
	OutEvaluateValues.JumpFeetPosition = FMath::FInterpTo(OutEvaluateValues.JumpFeetPosition, JumpFeetPosition, DeltaSeconds, Config.InAirLeanInterpSpeed);
}

void HiInAirAnimationUpdater::OnJumped(const EHiJumpState JumpState, const int JumpCount, const EHiBodySide JumpFoot)
{
	FHiInAirAnimValues& InAirValues = OwnerAnimInstance->InAirValues;
	StartJumpFoot = JumpFoot;
	InAirValues.bJumped = bool(JumpState != EHiJumpState::None);
	InAirValues.JumpState = JumpState;
	InAirValues.JumpFeetPosition = CalcJumpFeetPosition(OwnerAnimInstance->CharacterInformation.Velocity);
}

float HiInAirAnimationUpdater::PredictLandingDuration(const float FallSpeed, const float MaxLandPredictionTime) const
{
	// Calculate the land prediction weight by tracing in the velocity direction to find a walkable surface the character
	// is falling toward, and getting the 'Time' (range of 0 - MaxLandPredictionTime + LAND_PREDICTION_ACCURACY, 0 being about to land) till impact.
	// The Land Prediction Curve is used to control how the time affects the final weight for a smooth blend. 
	UCharacterMovementComponent* CharacterMovementComponent = Cast<UCharacterMovementComponent>(OwnerAnimInstance->Character->GetCharacterMovement());
	check(CharacterMovementComponent);
	const float GravityAcceleration = CharacterMovementComponent->GetGravityZ();
	const float MaxTerminalVelocity = CharacterMovementComponent->GetPhysicsVolume()->TerminalVelocity;

	if (FallSpeed <= GravityAcceleration * MaxLandPredictionTime * 0.5f)
	{
		return MaxLandPredictionTime + LAND_PREDICTION_ACCURACY;
	}

	UWorld* World = OwnerAnimInstance->GetWorld();
	check(World);

	const UCapsuleComponent* CapsuleComp = OwnerAnimInstance->Character->GetCapsuleComponent();
	const FVector& CapsuleWorldLoc = CapsuleComp->GetComponentLocation();
	FVector HorizontalVelocity = OwnerAnimInstance->CharacterInformation.Velocity;
	HorizontalVelocity.Z = 0;
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerAnimInstance->Character);

	float PredictionTime = MaxLandPredictionTime;
	// Multiple iterations to obtain more accurate solutions
	for (int IterationCount = 0; IterationCount < Config.LandPredictionIterations; ++IterationCount)
	{
		// Default for Uniformly Accelerated Motion
		float PredictFallSpeed = FallSpeed - GravityAcceleration * PredictionTime;
		float AccFallTime = PredictionTime;
		float AccFallDistance = PredictionTime * (FallSpeed + PredictFallSpeed) * 0.5f;
		float PredictFallDistance = AccFallDistance;
		// Exceeding the speed limit
		if (PredictFallSpeed > MaxTerminalVelocity)
		{
			AccFallTime = -(MaxTerminalVelocity - FallSpeed) / GravityAcceleration;
			if (AccFallTime < 0)
			{
				// Under special situations, such as program logic or physical pushing, the falling speed may exceed the maximum terminal speed
				AccFallTime = 0.0f;
				AccFallDistance = 0.0f;
			}
			else
			{
				AccFallDistance = AccFallTime * (FallSpeed + MaxTerminalVelocity) * 0.5f;
			}
			PredictFallDistance = AccFallDistance + (PredictionTime - AccFallTime) * MaxTerminalVelocity;
		}

		const FVector TraceDir = FVector(HorizontalVelocity.X * PredictionTime, HorizontalVelocity.Y * PredictionTime, -PredictFallDistance);
		FHitResult HitResult;
		const FCollisionShape CapsuleCollisionShape = FCollisionShape::MakeCapsule(
			CapsuleComp->GetUnscaledCapsuleRadius(), CapsuleComp->GetUnscaledCapsuleHalfHeight());
		const bool bHit = World->SweepSingleByChannel(HitResult, CapsuleWorldLoc, CapsuleWorldLoc + TraceDir, FQuat::Identity,
			ECC_Pawn, CapsuleCollisionShape, Params);

		if (HitResult.bStartPenetrating || HitResult.Time < UE_SMALL_NUMBER)
		{
			PredictionTime = 0.0f;
			break;
		}
		else if (CharacterMovementComponent->IsWalkable(HitResult))
		{
			float HitFallDistance = HitResult.Time * PredictFallDistance;
			if (HitFallDistance >= AccFallDistance)
			{
				PredictionTime = AccFallTime + (HitFallDistance - AccFallDistance) / MaxTerminalVelocity;
			}
			else
			{
				// [(FallSpeed) + (FallSpeed + #PredictionTime * GravityAcceleration)] * 0.5 * #PredictionTime = HitFallDistance
				PredictionTime = (-2 * FallSpeed + FMath::Sqrt(4 * FallSpeed * FallSpeed - 8 * GravityAcceleration * HitFallDistance)) / (2 * -GravityAcceleration);
				check(PredictionTime >= 0.0f);
			}

			// Draw Hit Location
			//::DrawDebugCapsule(World, HitResult.Location
			//	, CapsuleCollisionShape.GetCapsuleHalfHeight(), CapsuleCollisionShape.GetCapsuleRadius()
			//	, FQuat::Identity, FLinearColor::Green.ToFColor(true), false, 0.3f);

			// Not the last iteration, 
			if (IterationCount < Config.LandPredictionIterations - 1)
			{
				// Add some precision distances
				PredictionTime += LAND_PREDICTION_ACCURACY;
			}
		}
		else
		{
			PredictionTime += LAND_PREDICTION_ACCURACY;
			break;
		}
	}
	return PredictionTime;
}

FHiLeanAmount HiInAirAnimationUpdater::CalcAirLeanAmount(const float FallSpeed) const
{
	// Use the relative Velocity direction and amount to determine how much the character should lean while in air.
	// The Lean In Air curve gets the Fall Speed and is used as a multiplier to smoothly reverse the leaning direction
	// when transitioning from moving upwards to moving downwards.
	FHiLeanAmount CalcLeanAmount;
	if (!OwnerAnimInstance->LeanInAirCurve)
	{
		return CalcLeanAmount;
	}
	const FVector& UnrotatedVel = OwnerAnimInstance->CharacterInformation.CharacterActorRotation.UnrotateVector(
		OwnerAnimInstance->CharacterInformation.Velocity) / 350.0f;
	FVector2D InversedVect(UnrotatedVel.Y, UnrotatedVel.X);
	InversedVect *= OwnerAnimInstance->LeanInAirCurve->GetFloatValue(FallSpeed);
	CalcLeanAmount.LR = InversedVect.X;
	CalcLeanAmount.FB = InversedVect.Y;
	return CalcLeanAmount;
}

float HiInAirAnimationUpdater::CalcJumpFeetPosition(const FVector Velocity) const
{
	FVector HorizontalVelocity = FVector(Velocity.X, Velocity.Y, 0);
	float HorizontalSpeed = HorizontalVelocity.Size();
	if (HorizontalSpeed < 50)		// TODO: remove head code
	{
		return 0;
	}
	float JumpFeetPosition = HorizontalSpeed / OwnerAnimInstance->GroundedConfig.AnimatedWalkSpeed;
	if (StartJumpFoot == EHiBodySide::Left)
	{
		// Left foot jump start
		JumpFeetPosition = -JumpFeetPosition;
	}
	return JumpFeetPosition;
}

int HiInAirAnimationUpdater::CalcLandSelect(const float FallSpeed, const float LandingDuration) const
{
	UHiCharacterMovementComponent* CharacterMovementComponent = Cast<UHiCharacterMovementComponent>(OwnerAnimInstance->Character->GetCharacterMovement());
	check(CharacterMovementComponent);
	float PredictLandingSpeed = FallSpeed - CharacterMovementComponent->GetGravityZ() * LandingDuration;
	PredictLandingSpeed = FMath::Min(PredictLandingSpeed, CharacterMovementComponent->GetPhysicsVolume()->TerminalVelocity);
	
	int SelectLandingAnimIndex = INVALID_LANDING_ANIM_INDEX;
	float SelectEffectiveLandingSpeed = -1.0f;
	for (int LandingAnimIndex = 0; LandingAnimIndex < LandingAnimArray.Num(); ++LandingAnimIndex)
	{
		// Select Max Effective Landing Speed
		const FHiLandingAnimConfig& LandingAnimConfig = LandingAnimArray[LandingAnimIndex];
		if (PredictLandingSpeed > LandingAnimConfig.EffectiveLandingSpeed && LandingAnimConfig.EffectiveLandingSpeed > SelectEffectiveLandingSpeed)
		{
			SelectLandingAnimIndex = LandingAnimIndex;
		}
	}
	return SelectLandingAnimIndex;
}

void HiInAirAnimationUpdater::OnMovementStateChanged(EHiMovementState PreviousMovementState, EHiMovementState CurrentMovementState)
{
	if (PreviousMovementState != EHiMovementState::InAir && CurrentMovementState == EHiMovementState::InAir && OwnerAnimInstance)
	{
		if (!OwnerAnimInstance->InAirValues.bJumped)
		{
			bCheckPredictLand_KeepGroundAnim = true;
		}

		OwnerAnimInstance->InAirValues.LandPrediction = -LAND_PREDICTION_ACCURACY;
		//OwnerAnimInstance->InAirValues.SelectLandingSequence = nullptr;
		bNeedReselectLandAnimation = true;
	}
}
