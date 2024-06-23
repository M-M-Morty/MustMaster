// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/AnimationUpdater/HiFootAnimUpdater.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Animation/AnimInstance.h"
#include "Characters/HiCharacter.h"
#include "Component/HiLocomotionComponent.h"
#include "Characters/Animation/HiCharacterAnimInstance.h"
#include "Characters/Animation/HiLocomotionAnimInstance.h"
#include "Component/HiCharacterDebugComponent.h"


const FName NAME_Curve_FootIK_Enable_R(TEXT("Enable_FootIK_R"));
const FName NAME_Curve_FootIK_Enable_L(TEXT("Enable_FootIK_L"));
const FName NAME_Curve_FootLock_L(TEXT("FootLock_L"));
const FName NAME_Curve_FootLock_R(TEXT("FootLock_R"));
const FName NAME_Curve_FootIK_FootIK_Root(TEXT("root"));
const FName NAME_Curve_FootIK_RotationAmount(TEXT("RotationAmount"));

DEFINE_LOG_CATEGORY_STATIC(HiFootAnimUpdater, Log, All)

void UHiFootAnimUpdater::Initialize(UHiCharacterAnimInstance* InAnimInstance)
{
	Super::Initialize(InAnimInstance);
	Config = InAnimInstance->FootAnimConfig;

	UHiCharacterDebugComponent *HiCharacterDebugComponent = InAnimInstance->GetOwningActor()->FindComponentByClass<UHiCharacterDebugComponent>();
	if (HiCharacterDebugComponent)
	{
		SetDebugComponent(HiCharacterDebugComponent);
	}
}

void UHiFootAnimUpdater::NativeUpdateAnimation(float DeltaSeconds)
{
	if (AnimInstanceOwner->GetOwningActor()->GetLocalRole() != ROLE_Authority)
	{
		auto &FootAnimValues = AnimInstanceOwner->FootAnimValues;
			
		//UpdateAnimatedFootLock(DeltaSeconds, AnimInstanceOwner->LogicGait);
		
		/*if (LeftFootLock.ForceLockDuration > 0)
		{
			LeftFootLock.ForceLockDuration -= DeltaSeconds;
			LeftFootLockCurveVal += 1.0f;
		}
		if (RightFootLock.ForceLockDuration > 0)
		{
			RightFootLock.ForceLockDuration -= DeltaSeconds;
			RightFootLockCurveVal += 1.0f;
		}*/

		if (AnimInstanceOwner->MovementState == EHiMovementState::Grounded)
		{
			if (AnimInstanceOwner->Character->HasAnyRootMotion())
			{
				SetFootLocking(DeltaSeconds, NAME_Curve_FootLock_L, false, LeftFootLock.PreviousTransform, FootAnimValues.FootLock_Left);
				SetFootLocking(DeltaSeconds, NAME_Curve_FootLock_R, false, RightFootLock.PreviousTransform, FootAnimValues.FootLock_Right);
			}
			else
			{
				bool UseFootLock_L = AnimInstanceOwner->GetCurveValue(NAME_Curve_FootIK_Enable_L) > 0.01f;
				bool UseFootLock_R = AnimInstanceOwner->GetCurveValue(NAME_Curve_FootIK_Enable_R) > 0.01f;
				
				float LeftFootLockCurveVal = AnimInstanceOwner->GetCurveValue(NAME_Curve_FootLock_L);
				float RightFootLockCurveVal = AnimInstanceOwner->GetCurveValue(NAME_Curve_FootLock_R);
				
			
				// Currently, FootLocking is only effective on the ground.
				SetFootLocking(DeltaSeconds, NAME_Curve_FootLock_L, UseFootLock_L, LeftFootLock.PreviousTransform, FootAnimValues.FootLock_Left);
	// 			UE_LOG(HiFootAnimUpdater, Log, TEXT("UHiFootAnimUpdater::SetFootLocking LeftFootLock NetMode: %d, Char: %s, Alpha = %f, FootLockCurveVal = %f, Target = %s"),
	// (int32)AnimInstanceOwner->GetOwningActor()->GetWorld()->GetNetMode(), *GetNameSafe(AnimInstanceOwner->GetOwningActor()), FootAnimValues.FootLock_Left.Alpha, LeftFootLockCurveVal, *FootAnimValues.FootLock_Left.Location.ToCompactString());
				SetFootLocking(DeltaSeconds, NAME_Curve_FootLock_R, UseFootLock_R, RightFootLock.PreviousTransform, FootAnimValues.FootLock_Right);
	// 			UE_LOG(HiFootAnimUpdater, Log, TEXT("UHiFootAnimUpdater::SetFootLocking RightFootLock NetMode: %d, Char: %s, Alpha = %f, FootLockCurveVal = %f"),
	// (int32)AnimInstanceOwner->GetOwningActor()->GetWorld()->GetNetMode(), *GetNameSafe(AnimInstanceOwner->GetOwningActor()), FootAnimValues.FootLock_Right.Alpha, RightFootLockCurveVal);
			}
		}
	}
}

void UHiFootAnimUpdater::NativePostEvaluateAnimation()
{
	CacheFeetTransform(AnimInstanceOwner->FootAnimValues);
}

void UHiFootAnimUpdater::UpdateAnimatedFootLock(float DeltaSeconds, EHiGait NewLogicGait)
{
	if (AnimInstanceOwner->Character->HasAnyRootMotion())
	{
		return;
	}
	
	auto &LocomotionComponent = AnimInstanceOwner->LocomotionComponent;
	
	if (PreviousLogicGait == EHiGait::Idle && NewLogicGait != EHiGait::Idle)
	{
		EHiBodySide LockFoot = SelectLockFoot(LocomotionComponent->GetFrontFoot(), 0.0f);
		ForceLockFoot(LockFoot, Config.FootLockDurationWhenEnterMoving);
	}
	else if (PreviousLogicGait != EHiGait::Idle && NewLogicGait == EHiGait::Idle)
	{
		AnimInstanceOwner->FootAnimValues.StopFrontFoot = LocomotionComponent->GetFrontFoot();
		StopLockFoot();
	}
	
	PreviousLogicGait = NewLogicGait;
}

EHiBodySide UHiFootAnimUpdater::SelectLockFoot(const EHiBodySide FrontFoot, const float PendingRotateYawDegrees)
{
	EHiBodySide LockFoot = FrontFoot;

	// Check foot touchs ground 
	if (LockFoot == EHiBodySide::Left && !LeftFootLock.bIsTouchedGround)
	{
		LockFoot = EHiBodySide::None;
	}
	if (LockFoot == EHiBodySide::Right && !RightFootLock.bIsTouchedGround)
	{
		LockFoot = EHiBodySide::None;
	}
	return LockFoot;
}

void UHiFootAnimUpdater::ForceLockFoot(const EHiBodySide Foot, const float FullWeightDuration)
{
	if (Foot == EHiBodySide::Left)
	{
		LeftFootLock.ForceLockDuration = FullWeightDuration;
	}
	else if (Foot == EHiBodySide::Right)
	{
		RightFootLock.ForceLockDuration = FullWeightDuration;
	}
}

void UHiFootAnimUpdater::StopLockFoot()
{
	LeftFootLock.ForceLockDuration = -1;
	RightFootLock.ForceLockDuration = -1;
}

void UHiFootAnimUpdater::UpdateFootLockTransform(FootLockParameters& OutFootLock, const FVector CompLocation, const FTransform FootWorldTransform)
{
	OutFootLock.PreviousTransform = FootWorldTransform;
	// FVector LockLocation = FootWorldTransform.GetLocation();
	// const float AllowedFootLockHeight = LockLocation.Z - Config.FootHeight - Config.FootLockHeightDeviation;
	// if (AllowedFootLockHeight < CompLocation.Z)
	// {
	// 	OutFootLock.bIsTouchedGround = true;
	// }
	// else
	// {
	// 	OutFootLock.bIsTouchedGround = false;
	// }
	// // TODO: force on ground
	// LockLocation.Z = CompLocation.Z + Config.FootHeight;
	//OutFootLock.PreviousTransform.SetLocation(LockLocation);
}

void UHiFootAnimUpdater::CacheFeetTransform(const FHiFootAnimValues& EvaluateValues)
{
	USkeletalMeshComponent* SkeletalMesh = AnimInstanceOwner->GetOwningComponent();
	FVector CompLocation = SkeletalMesh->GetComponentLocation();

	FTransform LeftFootPreviousTransform = AnimInstanceOwner->GetOwningComponent()->GetSocketTransform(Config.FootLock_BoneName_Left, RTS_World);
	UpdateFootLockTransform(LeftFootLock, CompLocation, LeftFootPreviousTransform);
	//FRotator LeftFootRotator = LeftFootPreviousTransform.Rotator();
	//LeftFootRotator.Pitch = 12.094115;
	//LeftFootRotator.Roll = -93.354628;
	//LeftFootPreviousTransform.SetRotation(LeftFootRotator.Quaternion());

	FTransform RightFootPreviousTransform = AnimInstanceOwner->GetOwningComponent()->GetSocketTransform(Config.FootLock_BoneName_Right, RTS_World);
	UpdateFootLockTransform(RightFootLock, CompLocation, RightFootPreviousTransform);
	//FRotator RightFootRotator = RightFootPreviousTransform.Rotator();
	//RightFootRotator.Pitch = -12.110914;
	//RightFootRotator.Roll = 86.629702;
	//RightFootPreviousTransform.SetRotation(RightFootRotator.Quaternion());

	// Debug
	if (DebugComponent && DebugComponent->GetShowFootLock())
	{
		UWorld* World = AnimInstanceOwner->GetWorld();//->GetWorld();
		check(World);
		FVector FootBoxSize(5, 20, 10);

		if (EvaluateValues.FootLock_Right.Alpha > 0.0f)
		{
			// Draw foot box
			::DrawDebugBox(World, EvaluateValues.FootLock_Right.Location, FootBoxSize, EvaluateValues.FootLock_Right.Rotator.Quaternion(), FColor::Green);
			// Draw IK Line
			::DrawDebugLine(World, EvaluateValues.FootLock_Right.Location, RightFootPreviousTransform.GetTranslation(), FColor::Red);
		}

		if (EvaluateValues.FootLock_Left.Alpha > 0.0f)
		{
			// Draw foot box
			::DrawDebugBox(World, EvaluateValues.FootLock_Left.Location, FootBoxSize, EvaluateValues.FootLock_Left.Rotator.Quaternion(), FColor::Green);
			// Draw IK Line
			::DrawDebugLine(World, EvaluateValues.FootLock_Left.Location, LeftFootPreviousTransform.GetTranslation(), FColor::Red);
		}
	}
}

void UHiFootAnimUpdater::SetFootLocking(const float DeltaSeconds, const FName &FootLockCurve, bool UseFootLock, const FTransform PreviousTransform, FHiFootLockValues& OutFootLockValues)
{
	// Step 1: Only update the FootLock Alpha if the new value is less than the current, or it equals 1. This makes it
	// so that the foot can only blend out of the locked position or lock to a new position, and never blend in.

	float FootLockCurveVal = 0.0f;
	
	if (UseFootLock)
	{
		FootLockCurveVal = AnimInstanceOwner->GetCurveValue(FootLockCurve) * (1.f / AnimInstanceOwner->GetSkelMeshComponent()->AnimUpdateRateParams->UpdateRate);
	}
	else
	{
		FootLockCurveVal = 0.0f;
	}

	if (FootLockCurveVal >= 0.99f && OutFootLockValues.Alpha <=0.99f)
	{
		OutFootLockValues.Location = PreviousTransform.GetLocation();
		OutFootLockValues.Rotator = PreviousTransform.Rotator();
	}
	
	if (FootLockCurveVal >= 0.99f || FootLockCurveVal < OutFootLockValues.Alpha)
	{
		OutFootLockValues.Alpha = FootLockCurveVal;
	}
	
	// if (OutFootLockValues.Alpha < 0.001f && NewFootLockCurveVal > 0.99f)
	// {
	// 	// Update transform
	// 	OutFootLockValues.Location = PreviousTransform.GetLocation();
	// 	OutFootLockValues.Rotator = PreviousTransform.Rotator();
	//
	// 	OutFootLockValues.Alpha = FMath::Min(NewFootLockCurveVal, 1.0f);
	// }
	// else if (NewFootLockCurveVal < OutFootLockValues.Alpha)
	// {
	// 	OutFootLockValues.Alpha = FMath::Min(NewFootLockCurveVal, 1.0f);
	// 	//OutFootLockValues.Alpha = FMath::Max(NewFootLockCurveVal, OutFootLockValues.Alpha - DeltaSeconds / Config.FootLockAutoDecayDuration);
	// }
}

//void UHiFootAnimUpdater::SetFootLockOffsets(float DeltaSeconds, FVector& LocalLoc, FRotator& LocalRot)
//{
//	FRotator RotationDifference = FRotator::ZeroRotator;
//	// Use the delta between the current and last updated rotation to find how much the foot should be rotated
//	// to remain planted on the ground.
//	if (OwnerAnimInstance->Character->GetCharacterMovement()->IsMovingOnGround())
//	{
//		RotationDifference = OwnerAnimInstance->CharacterInformation.CharacterActorRotation - OwnerAnimInstance->Character->GetCharacterMovement()->GetLastUpdateRotation();
//		RotationDifference.Normalize();
//	}
//
//	// Get the distance traveled between frames relative to the mesh rotation
//	// to find how much the foot should be offset to remain planted on the ground.
//	const FVector& LocationDifference = OwnerAnimInstance->GetOwningComponent()->GetComponentRotation().UnrotateVector(
//		OwnerAnimInstance->CharacterInformation.Velocity * DeltaSeconds);
//
//	// Subtract the location difference from the current local location and rotate
//	// it by the rotation difference to keep the foot planted in component space.
//	LocalLoc = (LocalLoc - LocationDifference).RotateAngleAxis(RotationDifference.Yaw, FVector::DownVector);
//
//	// Subtract the Rotation Difference from the current Local Rotation to get the new local rotation.
//	FRotator Delta = LocalRot - RotationDifference;
//	Delta.Normalize();
//	LocalRot = Delta;
//}

void UHiFootAnimUpdater::SetPelvisIKOffset(float DeltaSeconds, FVector FootOffsetLTarget, FVector FootOffsetRTarget, FHiFootLockValues& OutEvaluateValues)
{
	// Calculate the Pelvis Alpha by finding the average Foot IK weight. If the alpha is 0, clear the offset.
	//OutEvaluateValues.PelvisAlpha =
	//	(OwnerAnimInstance->GetCurveValue(NAME_FootIK_Enable_L) + OwnerAnimInstance->GetCurveValue(NAME_FootIK_Enable_R)) / 2.0f;

	//if (OutEvaluateValues.PelvisAlpha > 0.0f)
	//{
	//	// Step 1: Set the new Pelvis Target to be the lowest Foot Offset
	//	const FVector PelvisTarget = FootOffsetLTarget.Z < FootOffsetRTarget.Z ? FootOffsetLTarget : FootOffsetRTarget;

	//	// Step 2: Interp the Current Pelvis Offset to the new target value.
	//	//Interpolate at different speeds based on whether the new target is above or below the current one.
	//	const float InterpSpeed = PelvisTarget.Z > OutEvaluateValues.PelvisOffset.Z ? 10.0f : 15.0f;
	//	OutEvaluateValues.PelvisOffset =
	//		FMath::VInterpTo(OutEvaluateValues.PelvisOffset, PelvisTarget, DeltaSeconds, InterpSpeed);
	//}
	//else
	//{
	//	OutEvaluateValues.PelvisOffset = FVector::ZeroVector;
	//}
}

void UHiFootAnimUpdater::ResetIKOffsets(float DeltaSeconds, FHiFootLockValues& OutEvaluateValues)
{
	// Interp Foot IK offsets back to 0
	//OutEvaluateValues.FootOffset_L_Location = FMath::VInterpTo(OutEvaluateValues.FootOffset_L_Location,
	//	FVector::ZeroVector, DeltaSeconds, 15.0f);
	//OutEvaluateValues.FootOffset_R_Location = FMath::VInterpTo(OutEvaluateValues.FootOffset_R_Location,
	//	FVector::ZeroVector, DeltaSeconds, 15.0f);
	//OutEvaluateValues.FootOffset_L_Rotation = FMath::RInterpTo(OutEvaluateValues.FootOffset_L_Rotation,
	//	FRotator::ZeroRotator, DeltaSeconds, 15.0f);
	//OutEvaluateValues.FootOffset_R_Rotation = FMath::RInterpTo(OutEvaluateValues.FootOffset_R_Rotation,
	//	FRotator::ZeroRotator, DeltaSeconds, 15.0f);
}

//void UHiFootAnimUpdater::SetFootOffsets(float DeltaSeconds, FName EnableFootIKCurve, FName IKFootBone,
//	FName RootBone, FVector& CurLocationTarget, FVector& CurLocationOffset,
//	FRotator& CurRotationOffset)
//{
//	// Only update Foot IK offset values if the Foot IK curve has a weight. If it equals 0, clear the offset values.
//	if (OwnerAnimInstance->GetCurveValue(EnableFootIKCurve) <= 0)
//	{
//		CurLocationOffset = FVector::ZeroVector;
//		CurRotationOffset = FRotator::ZeroRotator;
//		return;
//	}
//
//	// Step 1: Trace downward from the foot location to find the geometry.
//	// If the surface is walkable, save the Impact Location and Normal.
//	USkeletalMeshComponent* OwnerComp = OwnerAnimInstance->GetOwningComponent();
//	FVector IKFootFloorLoc = OwnerComp->GetSocketLocation(IKFootBone);
//	IKFootFloorLoc.Z = OwnerComp->GetSocketLocation(RootBone).Z;
//
//	UWorld* World = OwnerAnimInstance->GetWorld();
//	check(World);
//
//	FCollisionQueryParams Params;
//	Params.AddIgnoredActor(OwnerAnimInstance->Character);
//
//	const FVector TraceStart = IKFootFloorLoc + FVector(0.0, 0.0, Config.IK_TraceDistanceAboveFoot);
//	const FVector TraceEnd = IKFootFloorLoc - FVector(0.0, 0.0, Config.IK_TraceDistanceBelowFoot);
//
//	FHitResult HitResult;
//	const bool bHit = World->LineTraceSingleByChannel(HitResult,
//		TraceStart,
//		TraceEnd,
//		ECC_Visibility, Params);
//
//	//if (OwnerAnimInstance->HiCharacterDebugComponent && OwnerAnimInstance->HiCharacterDebugComponent->GetShowTraces())
//	//{
//	//	UHiCharacterDebugComponent::DrawDebugLineTraceSingle(
//	//		World,
//	//		TraceStart,
//	//		TraceEnd,
//	//		EDrawDebugTrace::Type::ForOneFrame,
//	//		bHit,
//	//		HitResult,
//	//		FLinearColor::Red,
//	//		FLinearColor::Green,
//	//		5.0f);
//	//}
//
//	FRotator TargetRotOffset = FRotator::ZeroRotator;
//	if (OwnerAnimInstance->Character->GetCharacterMovement()->IsWalkable(HitResult))
//	{
//		FVector ImpactPoint = HitResult.ImpactPoint;
//		FVector ImpactNormal = HitResult.ImpactNormal;
//
//		// Step 1.1: Find the difference in location from the Impact point and the expected (flat) floor location.
//		// These values are offset by the nomrmal multiplied by the
//		// foot height to get better behavior on angled surfaces.
//		CurLocationTarget = (ImpactPoint + ImpactNormal * Config.FootHeight) -
//			(IKFootFloorLoc + FVector(0, 0, Config.FootHeight));
//
//		// Step 1.2: Calculate the Rotation offset by getting the Atan2 of the Impact Normal.
//		TargetRotOffset.Pitch = -FMath::RadiansToDegrees(FMath::Atan2(ImpactNormal.X, ImpactNormal.Z));
//		TargetRotOffset.Roll = FMath::RadiansToDegrees(FMath::Atan2(ImpactNormal.Y, ImpactNormal.Z));
//	}
//
//	// Step 2: Interp the Current Location Offset to the new target value.
//	// Interpolate at different speeds based on whether the new target is above or below the current one.
//	const float InterpSpeed = CurLocationOffset.Z > CurLocationTarget.Z ? 30.f : 15.0f;
//	CurLocationOffset = FMath::VInterpTo(CurLocationOffset, CurLocationTarget, DeltaSeconds, InterpSpeed);
//
//	// Step 3: Interp the Current Rotation Offset to the new target value.
//	CurRotationOffset = FMath::RInterpTo(CurRotationOffset, TargetRotOffset, DeltaSeconds, 30.0f);
//}