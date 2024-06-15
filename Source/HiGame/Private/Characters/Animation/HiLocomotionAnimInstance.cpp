// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiLocomotionAnimInstance.h"

//#include "Library/ALSMathLibrary.h"
#include "Curves/CurveVector.h"
#include "Components/CapsuleComponent.h"
#include "HiLogChannels.h"
#include "KismetAnimationLibrary.h"
#include "Characters/HiCharacter.h"
#include "Component/HiGlideComponent.h"
#include "Component/HiJumpComponent.h"
#include "Component/HiLocomotionComponent.h"
#include "GameFramework/CharacterMovementComponent.h"


const FName NAME_Locomotion_Enable_Transition(TEXT("Enable_Transition"));
const FName NAME_Locomotion_Grounded___Slot(TEXT("Grounded Slot"));
const FName NAME_Locomotion_VB___foot_target_l(TEXT("VB foot_target_l"));
const FName NAME_Locomotion_VB___foot_target_r(TEXT("VB foot_target_r"));
const FName NAME_Locomotion_ALS_Enable_Transition(TEXT("Enable_Transition"));
const FName NAME_Locomotion_W_Gait(TEXT("W_Gait"));
const FName NAME_Locomotion_Feet_Position(TEXT("Feet_Position"));
//const FName NAME_Enable_FootLock_Curve(TEXT("Enable_FootLock"));

const float MinimumSpeedForYawLinearDecay = 60;		// degrees in one second
const float MinimumAngelForYawHalflifeDecay = 3;	// degrees threshold between Halflife Decay and Linear Decay
const float MaximumAngelForYawSmoothRestore = 1;	// degrees threshold

////////////////////////////////////////////////////////////////////////////////////////////////

void UHiLocomotionAnimInstance::NativeInitializeAnimation()
{
	Super::NativeInitializeAnimation();

	if (JumpComponent)
	{
		JumpComponent->OnJumpedDelegate.AddUniqueDynamic(this, &UHiLocomotionAnimInstance::OnJumped);
	}
	if (LocomotionComponent)
	{
		LocomotionComponent->OnMovementStateChangedDelegate.AddUniqueDynamic(this, &UHiLocomotionAnimInstance::OnMovementStateChanged);
	}

	FootAnimUpdater.NativeInitialize(this, FootAnimConfig);
	InAirAnimationUpdater.NativeInitialize(this, InAirConfig);

	if (FMath::IsNearlyEqual(GroundedConfig.AnimatedRunSpeed, GroundedConfig.AnimatedWalkSpeed))
	{
		UE_LOG(LogHiGame, Error, TEXT("[Animated Run Speed] is the same as [Animated Walk Speed], and the value is %f"), GroundedConfig.AnimatedRunSpeed);
		GroundedConfig.AnimatedRunSpeed = GroundedConfig.AnimatedWalkSpeed + 1;
	}

	MaxYawRestoreDecayAlpha = YawRestoreDecayAlpha = FGenericPlatformMath::Loge(2.0f) / GroundedConfig.YawRestoreHalfLife;
}

void UHiLocomotionAnimInstance::NativeUninitializeAnimation()
{
	Super::NativeUninitializeAnimation();
	if (JumpComponent)
	{
		JumpComponent->OnJumpedDelegate.RemoveDynamic(this, &UHiLocomotionAnimInstance::OnJumped);
	}
	if (LocomotionComponent)
	{
		LocomotionComponent->OnMovementStateChangedDelegate.RemoveDynamic(this, &UHiLocomotionAnimInstance::OnMovementStateChanged);
	}
}

void UHiLocomotionAnimInstance::OnUpdateComponent()
{
	UHiLocomotionComponent* NewLocomotionComponent = Character->FindComponentByClass<UHiLocomotionComponent>();
	if (NewLocomotionComponent != LocomotionComponent)
	{
		if (LocomotionComponent)
		{
			LocomotionComponent->OnMovementStateChangedDelegate.RemoveDynamic(this, &UHiLocomotionAnimInstance::OnMovementStateChanged);
		}
		LocomotionComponent = NewLocomotionComponent;
		if (LocomotionComponent)
		{
			LocomotionComponent->OnMovementStateChangedDelegate.AddUniqueDynamic(this, &UHiLocomotionAnimInstance::OnMovementStateChanged);
		}
	}
	UHiJumpComponent* NewJumpComponent = Character->FindComponentByClass<UHiJumpComponent>();
	if (NewJumpComponent != JumpComponent)
	{
		if (JumpComponent)
		{
			JumpComponent->OnJumpedDelegate.RemoveDynamic(this, &UHiLocomotionAnimInstance::OnJumped);
		}
		JumpComponent = NewJumpComponent;
		if (JumpComponent)
		{
			JumpComponent->OnJumpedDelegate.AddUniqueDynamic(this, &UHiLocomotionAnimInstance::OnJumped);
		}
	}
}

void UHiLocomotionAnimInstance::NativeBeginPlay()
{
	// it seems to be that the player pawn components are not really initialized
	// when the call to NativeInitializeAnimation() happens.
	// This is the reason why it is tried here to get the debug component.
	if (APawn* Owner = TryGetPawnOwner())
	{
		HiCharacterDebugComponent = Owner->FindComponentByClass<UHiCharacterDebugComponent>();
		if (HiCharacterDebugComponent)
		{
			FootAnimUpdater.SetDebugComponent(HiCharacterDebugComponent);
		}

		PreviousAimingYaw = PreviousAnimatedYawOrientation = Owner->GetActorRotation().Yaw;
	}
}

void UHiLocomotionAnimInstance::NativeUpdateAnimation(float DeltaSeconds)
{
	Super::NativeUpdateAnimation(DeltaSeconds);

	if (!LocomotionComponent || !Character || DeltaSeconds == 0.0f)
	{
		return;
	}

	UpdateCharacterInformation(DeltaSeconds);

	if (Character->GetLocalRole() != ROLE_Authority || Character->GetNetMode() == NM_Standalone)
	{
		UpdateAnimatedYawOffset(DeltaSeconds);
		UpdateAnimatedLeanAmount(DeltaSeconds);
		UpdateAnimatedFootLock(DeltaSeconds, LogicGait);
	}

	InAirState = LocomotionComponent->GetInAirState();
	MovementAction = LocomotionComponent->GetMovementAction();
	RotationMode = LocomotionComponent->GetRotationMode();
	LogicGait = LocomotionComponent->GetGait();
	LogicMoveGait = LocomotionComponent->GetMoveGait();
	GroundedEntryState = LocomotionComponent->GetGroundedEntryState();
	AnimatedMovementState = MovementState;

	GaitCurveValue = GetCurveValue(NAME_Locomotion_W_Gait);
	if(Character)
	{
		AutoJumpRateScale = Character->AutoJumpRateScale;
	}

	if (GlideComponent)
	{
		GlideValues.GlideState = GlideComponent->GlideState;
		if (GlideValues.GlideState != EHiGlideState::None)
		{
			UpdateGlideValues(DeltaSeconds);
			InAirAnimationUpdater.NativeGlideUpdate(DeltaSeconds, InAirValues);
		}
	}

	if (Character->GetLocalRole() != ROLE_Authority || Character->GetNetMode() == NM_Standalone)
	{
		FootAnimUpdater.NativeUpdate(DeltaSeconds, MovementState, FootAnimValues);
	}

	if (MovementState == EHiMovementState::Grounded)
	{
		UpdateInGroundValues(DeltaSeconds);
	}
	else
	{
		Grounded.bShouldMove = ShouldMoveCheck();
	}
	//else if (MovementState.InAirValues())
	//{
	//	// Do While InAirValues
	//	UpdateInAirValuesValues(DeltaSeconds);
	//}
	InAirAnimationUpdater.NativeUpdate(DeltaSeconds, InAirValues);

	if (bUseTargetedMovement)
	{
		UpdateTargetMoveValues(DeltaSeconds);
	}
}

void UHiLocomotionAnimInstance::NativePostEvaluateAnimation()
{
	FootAnimUpdater.CacheFeetTransform(FootAnimValues);

	// DeltaAimYaw update should be delayed, to match the camera rotation exactly
	PreviousAimingYaw = CharacterInformation.AimingRotation.Yaw;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void UHiLocomotionAnimInstance::UpdateCharacterInformation(float DeltaSeconds)
{
	// Update rest of character information. Others are reflected into anim bp when they're set inside character class
	CharacterInformation.MovementInputAmount = LocomotionComponent->GetMovementInputAmount();
	CharacterInformation.bHasMovementInput = LocomotionComponent->HasMovementInput();
	CharacterInformation.Acceleration = LocomotionComponent->GetAcceleration();
	CharacterInformation.AimYawRate = LocomotionComponent->GetAimYawRate();
	CharacterInformation.Speed = LocomotionComponent->GetSpeed();
	CharacterInformation.Velocity = Character->GetCharacterMovement()->Velocity;
	CharacterInformation.MovementInput = LocomotionComponent->GetMovementInput();
	CharacterInformation.AimingRotation = LocomotionComponent->GetAimingRotation();
	CharacterInformation.CharacterActorRotation = Character->GetActorRotation();
	CharacterInformation.MovementAction = LocomotionComponent->GetMovementAction();
	CharacterInformation.bIsMoving = LocomotionComponent->IsMoving();
	CharacterInformation.bInVehicle = LocomotionComponent->GetMovementState() == EHiMovementState::Ride;
	CharacterInformation.bIsInSkillAnim = LocomotionComponent->IsInSkillAnim();
}

void UHiLocomotionAnimInstance::UpdateAnimatedYawOffset(float DeltaSeconds)
{
	float CurrectCharacterYaw = Character->GetActorRotation().Yaw;
	// Calculate yaw
	float TargetYawOffset = CalculateTargetYawOffset(CurrectCharacterYaw);

	if (FMath::Abs(TargetYawOffset) < MaximumAngelForYawSmoothRestore)
	{
		Grounded.AnimatedYawOffset = PreviousAnimatedYawOffsetDecline = RemainingReverseYawTime = 0.0f;
		PreviousAnimatedYawOrientation = FMath::Wrap(CurrectCharacterYaw, 0.0f, 360.0f);
		return;
	}

	// Update yaw restore speed
	float RootYawRestoreSpeed = 0.0f;
	if (FMath::Abs(TargetYawOffset) > MinimumAngelForYawHalflifeDecay)
	{
		if (TargetYawOffset * PreviousAnimatedYawOffsetDecline > 0)	// Reverse the rotation direction
		{
			YawRestoreDecayAlpha = MaxYawRestoreDecayAlpha * GroundedConfig.ReverseYawAlphaFactor;
			RemainingReverseYawTime = GroundedConfig.ReverseYawAlphaIncreaseDuration;
		}
		else if (RemainingReverseYawTime > 0)
		{
			RemainingReverseYawTime -= DeltaSeconds;
			YawRestoreDecayAlpha = MaxYawRestoreDecayAlpha * GroundedConfig.ReverseYawAlphaFactor;
		}
		else
		{
			YawRestoreDecayAlpha = MaxYawRestoreDecayAlpha;
		}
		RootYawRestoreSpeed = -TargetYawOffset * YawRestoreDecayAlpha;
	}
	else
	{
		RootYawRestoreSpeed = -TargetYawOffset * MaxYawRestoreDecayAlpha;
		if (FMath::Abs(RootYawRestoreSpeed) < MinimumSpeedForYawLinearDecay)
		{
			RootYawRestoreSpeed = -FMath::Sign(TargetYawOffset) * MinimumSpeedForYawLinearDecay;
		}
		RemainingReverseYawTime = 0.0f;
	}

	// Update YawOffset
	PreviousAnimatedYawOffsetDecline = RootYawRestoreSpeed * DeltaSeconds;
	if (FMath::Abs(PreviousAnimatedYawOffsetDecline) > FMath::Abs(TargetYawOffset))
	{
		PreviousAnimatedYawOffsetDecline = -TargetYawOffset;
	}

	PreviousAnimatedYawOrientation = FMath::Wrap(PreviousAnimatedYawOrientation + PreviousAnimatedYawOffsetDecline, 0.0f, 360.0f);
	Grounded.AnimatedYawOffset = TargetYawOffset + PreviousAnimatedYawOffsetDecline;
}

void UHiLocomotionAnimInstance::UpdateAnimatedLeanAmount(float DeltaSeconds)
{
	FHiLeanAmount OldLeanAmount = Grounded.LeanAmount;
	FHiLeanAmount NewLeanAmount = OldLeanAmount;

	if (CharacterInformation.Acceleration.IsNearlyZero())
	{
		NewLeanAmount.FB = 0.0f;
		NewLeanAmount.LR = 0.0f;
	}
	else
	{
		const float MaxAcc = Character->GetCharacterMovement()->GetMaxAcceleration();
		FVector RelativeAcceleration = CharacterInformation.Acceleration.GetClampedToMaxSize(MaxAcc) / MaxAcc;
		RelativeAcceleration = Character->GetActorRotation().UnrotateVector(RelativeAcceleration);
		NewLeanAmount.LR = RelativeAcceleration.Y;
		NewLeanAmount.FB = RelativeAcceleration.X;
	}

	NewLeanAmount.FB *= GroundedConfig.LeanSpeedFactor.FB;
	NewLeanAmount.LR *= GroundedConfig.LeanSpeedFactor.LR;

	if (GroundedConfig.LeanFilteringDuration > DeltaSeconds)
	{
		// Kalman filtering can be considered here, and the effect will be better
		NewLeanAmount.LR = OldLeanAmount.LR + (NewLeanAmount.LR - OldLeanAmount.LR) * DeltaSeconds / GroundedConfig.LeanFilteringDuration;
	}

	Grounded.LeanAmount.FB = NewLeanAmount.FB * GroundedConfig.LeanSpeedFactor.FB;
	Grounded.LeanAmount.LR = NewLeanAmount.LR * GroundedConfig.LeanSpeedFactor.LR;
}

void UHiLocomotionAnimInstance::UpdateAnimatedFootLock(float DeltaSeconds, EHiGait PreviousLogicGait)
{
	if (!bPreviousHasMovementInput && CharacterInformation.bHasMovementInput)
	{
		EHiBodySide LockFoot = FootAnimUpdater.SelectLockFoot(LocomotionComponent->GetFrontFoot(), GetAnimatedRotateYawDegrees());
		FootAnimUpdater.ForceLockFoot(LockFoot, FootAnimConfig.FootLockDurationWhenEnterMoving);
	}
	else if ((bPreviousHasMovementInput && !CharacterInformation.bHasMovementInput) || MovementState != EHiMovementState::Grounded)
	{
		FootAnimValues.StopFrontFoot = LocomotionComponent->GetFrontFoot();
		FootAnimUpdater.StopLockFoot();
	}
	bPreviousHasMovementInput = CharacterInformation.bHasMovementInput;
}

void UHiLocomotionAnimInstance::UpdateTargetMoveValues(float DeltaSeconds)
{
	const FVector LocRelativeVelocityDir = CharacterInformation.CharacterActorRotation.UnrotateVector(CharacterInformation.Velocity.GetSafeNormal(0.1f));
	const float Sum = FMath::Abs(LocRelativeVelocityDir.X) + FMath::Abs(LocRelativeVelocityDir.Y) + FMath::Abs(LocRelativeVelocityDir.Z);
	const FVector RelativeDir = LocRelativeVelocityDir / Sum;
	
	float TargetBlendF = FMath::Clamp(RelativeDir.X, 0.0f, 1.0f);
	float TargetBlendB = FMath::Abs(FMath::Clamp(RelativeDir.X, -1.0f, 0.0f));
	float TargetBlendL = FMath::Abs(FMath::Clamp(RelativeDir.Y, -1.0f, 0.0f));
	float TargetBlendR = FMath::Clamp(RelativeDir.Y, 0.0f, 1.0f);
	
	TargetMoveValues.VelocityBlendForward = FMath::FInterpTo(TargetMoveValues.VelocityBlendForward, TargetBlendF, DeltaSeconds, VelocityBlendInterpSpeed);
	TargetMoveValues.VelocityBlendBack = FMath::FInterpTo(TargetMoveValues.VelocityBlendBack, TargetBlendB, DeltaSeconds, VelocityBlendInterpSpeed);
	TargetMoveValues.VelocityBlendLeft = FMath::FInterpTo(TargetMoveValues.VelocityBlendLeft, TargetBlendL, DeltaSeconds, VelocityBlendInterpSpeed);
	TargetMoveValues.VelocityBlendRight = FMath::FInterpTo(TargetMoveValues.VelocityBlendRight, TargetBlendR, DeltaSeconds, VelocityBlendInterpSpeed);

	TargetMoveValues.MoveDirection = UKismetAnimationLibrary::CalculateDirection(CharacterInformation.Velocity, CharacterInformation.CharacterActorRotation);
}

void UHiLocomotionAnimInstance::UpdateGlideValues(float DeltaSeconds)
{
	GlideValues.AccelerationDirection = GlideComponent->AccelerationDirection;
	GlideValues.ActorInterpSpeed = GlideComponent->ActorInterpSpeed;
	GlideValues.MinTurnYaw = GlideComponent->MinTurnYaw;
}

float UHiLocomotionAnimInstance::CalculateTargetYawOffset(float RotationYaw)
{
	// Aim yaw change must be ignored.
	float PreviousDeltaAimYaw = FMath::FindDeltaAngleDegrees(PreviousAimingYaw, CharacterInformation.AimingRotation.Yaw);
	float CurrentRotationYaw = CharacterInformation.bHasMovementInput ? RotationYaw - PreviousDeltaAimYaw : RotationYaw;
	float YawOffset = FMath::FindDeltaAngleDegrees(FMath::Wrap(CurrentRotationYaw, 0.0f, 360.0f), PreviousAnimatedYawOrientation);

	//if (RootYawRestoreSpeed > 5 && RootYawRestoreSpeed * YawOffset > 0)
	//{
	//	if (YawOffset < 0)
	//	{
	//		YawOffset += 360;
	//	}
	//	else if (YawOffset > 0)
	//	{
	//		YawOffset -= 360;
	//	}
	//}
	// Make sure to rotate toward the camera forward, when rotating for half a circle.
	if (FMath::FindDeltaAngleDegrees(CurrentRotationYaw, CharacterInformation.AimingRotation.Yaw) * YawOffset < 0)
	{
		if (YawOffset < -170)
		{
			YawOffset += 360;
		}
		else if (YawOffset > 170)
		{
			YawOffset -= 360;
		}
	}
	// The rotation direction will be reversed if the rotation amount of the same direction changes too much 
	if (YawOffset > 225)
	{
		YawOffset -= 360;
	}
	else if (YawOffset < -225)
	{
		YawOffset += 360;
	}
	return YawOffset;
}

void UHiLocomotionAnimInstance::UpdateInGroundValues(float DeltaSeconds)
{
	// Check If Moving Or Not & Enable Movement Animations if IsMoving and HasMovementInput, or if the Speed is greater than 150.
	const bool bPrevShouldMove = Grounded.bShouldMove;
	Grounded.bShouldMove = ShouldMoveCheck();

	if (Grounded.bShouldMove)
	{
		// Do While Moving
		UpdateMovementValues(DeltaSeconds);
	}
	else if (CanDynamicTransition())
	{
		DynamicTransitionCheck();
	}

	// Update running turns with pedals
	if (Character->GetLocalRole() != ROLE_Authority || Character->GetNetMode() == NM_Standalone)
	{
		UpdateRunningTurnValues(DeltaSeconds);
	}

	FTransform BodyBoneTransform = GetOwningComponent()->GetSocketTransform(GroundedConfig.BodyBone.BoneName, RTS_Component);
	Grounded.BodyBoneOffset = BodyBoneTransform.GetLocation();
}

bool UHiLocomotionAnimInstance::ShouldMoveCheck() const
{
	return (!CharacterInformation.bInVehicle && CharacterInformation.bIsMoving && CharacterInformation.bHasMovementInput)
		/*|| CharacterInformation.Speed > 150.0f*/;
}

void UHiLocomotionAnimInstance::UpdateMovementValues(float DeltaSeconds)
{
	// Set the Play Rates
	Grounded.StandingPlayRate = CalculateStandingPlayRate();
}

float UHiLocomotionAnimInstance::CalculateStandingPlayRate() const
{
	// Calculate the Play Rate by dividing the Character's speed by the Animated Speed for each gait.
	// The lerps are determined by the "W_Gait" anim curve that exists on every locomotion cycle so
	// that the play rate is always in sync with the currently blended animation.
	// The value is also divided by the Stride Blend and the mesh scale so that the play rate increases as the stride or scale gets smaller
	float PlayRate = 1.0f;
	switch (LogicGait)
	{
	case EHiGait::Walking:
		PlayRate = CharacterInformation.Speed / GroundedConfig.AnimatedWalkSpeed;
		break;
	case EHiGait::Running:
		PlayRate = CharacterInformation.Speed / GroundedConfig.AnimatedRunSpeed;
		break;
	case EHiGait::Sprinting:
		PlayRate = CharacterInformation.Speed / GroundedConfig.AnimatedSprintSpeed;
		break;
	default:
		break;
	}

	return FMath::Clamp(PlayRate / GetOwningComponent()->GetComponentScale().Z, 0.0f, 3.0f);
}

void UHiLocomotionAnimInstance::OnMovementStateChanged(EHiMovementState InMovementState)
{
	CharacterInformation.PrevMovementState = LocomotionComponent->GetPrevMovementState();
	MovementState = InMovementState;

	InAirAnimationUpdater.OnMovementStateChanged(CharacterInformation.PrevMovementState, MovementState);
}

void UHiLocomotionAnimInstance::UpdateRunningTurnValues(float DeltaSeconds)
{
	float PreviousControlRotateYawHistory = ControlRotateYawHistory;

	// Update the time window and pop up invalid items.
	for (RotateYawItem& ControlRotateYawItem : ControlRotateYawArray)
	{
		ControlRotateYawItem.TimeOffset += DeltaSeconds;
	}
	while (!ControlRotateYawArray.IsEmpty() && ControlRotateYawArray.First().TimeOffset > GroundedConfig.BreakControlRotateDuration)
	{
		ControlRotateYawHistory -= ControlRotateYawArray.First().Yaw;
		ControlRotateYawArray.PopFront();
	}

	// Reverse the rotation direction
	bool bIsReverseRotationDirection = false;
	if (PreviousControlRotateYawHistory * Grounded.AnimatedYawOffset > 0.1f)
	{
		ControlRotateYawArray.Reset();
		ControlRotateYawHistory = 0.0f;
		bIsReverseRotationDirection = true;
	}
	// Append new animated yaw offset item
	if (FMath::Abs(PreviousAnimatedYawOffsetDecline) > 0.1f)
	{
		RotateYawItem NewRotateYaw{ 0.0f, PreviousAnimatedYawOffsetDecline/* + DeltaAimYaw*/ };
		ControlRotateYawHistory += NewRotateYaw.Yaw;
		ControlRotateYawArray.Emplace(NewRotateYaw);
	}
	// Reverse the rotation direction too fast
	if (RemainingReverseYawTime > 0)
	{
		ControlRotateYawArray.Reset();
		ControlRotateYawHistory = 0.0f;
		bIsReverseRotationDirection = false;		// Do not trigger next pedal
	}
	Grounded.ControlRotateYaw = ControlRotateYawHistory - Grounded.AnimatedYawOffset;

	// Update pedal states
	if (Grounded.bIsTriggeredPedal)
	{
		// Triggered only once until the ControlRotateYaw is returns to zero
		Grounded.PedalRotationDirection = EHiBodySide::None;

		// When there is no controlled rotation, reset bIsTriggeredPedal to trigger the next pedal.
		// If it is a slow reverse rotation, reset bIsTriggeredPedal to trigger the next pedal.
		if (FMath::Abs(Grounded.ControlRotateYaw) < 0.1f || bIsReverseRotationDirection)
		{
			Grounded.bIsTriggeredPedal = false;
		}
	}
	else if (FMath::Abs(Grounded.AnimatedYawOffset) > 20.0f/* && CharacterInformation.Speed > GroundedConfig.PedalRotationMinSpeed*/)
	{
		// Trigger Pedal
		if (Grounded.ControlRotateYaw > GroundedConfig.PedalRotationMinAngle)
		{
			Grounded.PedalRotationDirection = EHiBodySide::Right;
			Grounded.bIsTriggeredPedal = true;
		}
		else if (Grounded.ControlRotateYaw < -GroundedConfig.PedalRotationMinAngle)
		{
			Grounded.PedalRotationDirection = EHiBodySide::Left;
			Grounded.bIsTriggeredPedal = true;
		}
	}
}

float UHiLocomotionAnimInstance::GetValueClamped(float Value, float Bias, float ClampMin, float ClampMax) const
{
	return FMath::Clamp(Value + Bias, ClampMin, ClampMax);
}

const float UHiLocomotionAnimInstance::GetAnimatedRotateYawDegrees() const
{
	return -Grounded.AnimatedYawOffset + PreviousAnimatedYawOffsetDecline;
}

const bool UHiLocomotionAnimInstance::IsTurningLeft() const 
{
	return GetAnimatedRotateYawDegrees() < -FootAnimConfig.AnimatedRotationMinAngle;
}

const bool UHiLocomotionAnimInstance::IsTurningRight() const 
{
	return GetAnimatedRotateYawDegrees() > FootAnimConfig.AnimatedRotationMinAngle;
}

const bool UHiLocomotionAnimInstance::IsLockingLeftFoot() const
{
	return (FootAnimValues.FootLock_Left.Alpha > 0.99f);
}

const bool UHiLocomotionAnimInstance::IsLockingRightFoot() const
{
	return (FootAnimValues.FootLock_Right.Alpha > 0.99f);
}

bool UHiLocomotionAnimInstance::CanDynamicTransition() const
{
	return GetCurveValue(NAME_Locomotion_Enable_Transition) >= 0.99f;
}

void UHiLocomotionAnimInstance::DynamicTransitionCheck()
{
	// Check each foot to see if the location difference between the IK_Foot bone and its desired / target location
	// (determined via a virtual bone) exceeds a threshold. If it does, play an additive transition animation on that foot.
	// The currently set transition plays the second half of a 2 foot transition animation, so that only a single foot moves.
	// Because only the IK_Foot bone can be locked, the separate virtual bone allows the system to know its desired location when locked.
	//FTransform SocketTransformA = GetOwningComponent()->GetSocketTransform(FootAnimConfig.IkFootL_BoneName, RTS_Component);
	//FTransform SocketTransformB = GetOwningComponent()->GetSocketTransform(
	//	NAME_Locomotion_VB___foot_target_l, RTS_Component);
	//float Distance = (SocketTransformB.GetLocation() - SocketTransformA.GetLocation()).Size();
	//if (Distance > Config.DynamicTransitionThreshold)
	//{
	//	FALSDynamicMontageParams Params;
	//	Params.Animation = TransitionAnim_R;
	//	Params.BlendInTime = 0.2f;
	//	Params.BlendOutTime = 0.2f;
	//	Params.PlayRate = 1.5f;
	//	Params.StartTime = 0.8f;
	//	PlayDynamicTransition(0.1f, Params);
	//}

	//SocketTransformA = GetOwningComponent()->GetSocketTransform(FootAnimConfig.IkFootR_BoneName, RTS_Component);
	//SocketTransformB = GetOwningComponent()->GetSocketTransform(NAME_Locomotion_VB___foot_target_r, RTS_Component);
	//Distance = (SocketTransformB.GetLocation() - SocketTransformA.GetLocation()).Size();
	//if (Distance > Config.DynamicTransitionThreshold)
	//{
	//	FALSDynamicMontageParams Params;
	//	Params.Animation = TransitionAnim_L;
	//	Params.BlendInTime = 0.2f;
	//	Params.BlendOutTime = 0.2f;
	//	Params.PlayRate = 1.5f;
	//	Params.StartTime = 0.8f;
	//	PlayDynamicTransition(0.1f, Params);
	//}
}

void UHiLocomotionAnimInstance::PlayDynamicTransition(float ReTriggerDelay, FHiDynamicMontageParams Parameters)
{
	if (bCanPlayDynamicTransition)
	{
		bCanPlayDynamicTransition = false;

		// Play Dynamic Additive Transition Animation
		PlayTransition(Parameters);

		UWorld* World = GetWorld();
		check(World);
		World->GetTimerManager().SetTimer(PlayDynamicTransitionTimer, this,
			&UHiLocomotionAnimInstance::PlayDynamicTransitionDelay,
			ReTriggerDelay, false);
	}
}

void UHiLocomotionAnimInstance::PlayTransition(const FHiDynamicMontageParams& Parameters)
{
	PlaySlotAnimationAsDynamicMontage(Parameters.Animation, NAME_Locomotion_Grounded___Slot,
		Parameters.BlendInTime, Parameters.BlendOutTime, Parameters.PlayRate, 1,
		0.0f, Parameters.StartTime);
}

void UHiLocomotionAnimInstance::PlayDynamicTransitionDelay()
{
	bCanPlayDynamicTransition = true;
}

//////////////////////////////////////////////////////////////////////////////////////////////

void UHiLocomotionAnimInstance::OnJumped(EHiJumpState JumpState, int JumpCount, EHiBodySide JumpFoot)
{
	InAirAnimationUpdater.OnJumped(JumpState, JumpCount, JumpFoot);
	//UE_LOG(LogTemp, Warning, L"[ZL] <Control: %d> Trigger JumpAnim @ OnJumped  in %s   State: %d   Count: %d   FlagSet: %d", TryGetPawnOwner() ? TryGetPawnOwner()->GetLocalRole() : -1, *GetFName().ToString(), JumpState, JumpCount, bool(JumpState != EHiJumpState::None));
}

void UHiLocomotionAnimInstance::ResetJumpState()
{
	InAirValues.bJumped = false;
	//UE_LOG(LogTemp, Warning, L"[ZL] <Control: %d> Reset JumpAnim @ OnJumped  in %s   FlagSet: 0", TryGetPawnOwner() ? TryGetPawnOwner()->GetLocalRole() : -1, *GetFName().ToString());
}
