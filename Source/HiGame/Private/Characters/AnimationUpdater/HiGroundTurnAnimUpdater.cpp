// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/AnimationUpdater/HiGroundTurnAnimUpdater.h"
#include "Characters/Animation/HiCharacterAnimInstance.h"
#include "MotionWarpingComponent.h"
#include "PlayMontageCallbackProxy.h"
#include "Characters/HiCharacter.h"

DEFINE_LOG_CATEGORY_STATIC(HiGroundTurnAnimUpdater, Log, All)

void UHiGroundTurnAnimUpdater::NativeUpdateAnimation(float DeltaSeconds)
{
	// if (!AnimInstanceOwner->CharacterInformation.bIsMoving && !AnimInstanceOwner->Grounded.bWalkStop)
	// {
	// 	TurnInPlaceCheck(DeltaSeconds);
	// }
}

void UHiGroundTurnAnimUpdater::TurnInPlaceCheck(float DeltaSeconds)
{
	auto &TurnInPlaceValues = AnimInstanceOwner->TurnInPlaceValues;
	auto &CharacterInformation = AnimInstanceOwner->CharacterInformation;

	FRotator Delta = CharacterInformation.AimingRotation - CharacterInformation.CharacterActorRotation;
	Delta.Normalize();
	
	if (FMath::Abs(Delta.Yaw) <= TurnInPlaceValues.TurnCheckMinAngle)
	{
		TurnInPlaceValues.ElapsedDelayTime = 0.0f;
		return;
	}
	
	// UE_LOG(HiGroundTurnAnimUpdater, Log, TEXT("UHiGroundTurnAnimUpdater::TurnInPlaceCheck NetMode: %d, Char: %s, Speed = %f, AimingRotation = %s, CharacterActorRotation = %s"),
	// (int32)AnimInstanceOwner->GetOwningActor()->GetWorld()->GetNetMode(), *GetNameSafe(AnimInstanceOwner->GetOwningActor()), CharacterInformation.Speed, *CharacterInformation.AimingRotation.ToCompactString(), *CharacterInformation.CharacterActorRotation.ToCompactString());

	TurnInPlaceValues.ElapsedDelayTime += DeltaSeconds;
	
	const float ClampedAimAngle = FMath::GetMappedRangeValueClamped<float, float>({TurnInPlaceValues.TurnCheckMinAngle, 180.0f},
																	{
																		TurnInPlaceValues.MinAngleDelay,
																		TurnInPlaceValues.MaxAngleDelay
																	},
																	Delta.Yaw);
	//
	// Step 2: Check if the Elapsed Delay time exceeds the set delay (mapped to the turn angle range). If so, trigger a Turn In Place.
	if (TurnInPlaceValues.ElapsedDelayTime > ClampedAimAngle && AnimInstanceOwner->GetSlotMontageGlobalWeight("Move") == 0.0f)
	{
		TurnInPlace(Delta.Yaw, 1.0f, 0.0f);
	}
}

FHiTurnInPlaceAsset UHiGroundTurnAnimUpdater::GetTurnInPlaceAsset_Implementation(float TurnAngle)
{
	auto &TurnInPlaceValues = AnimInstanceOwner->TurnInPlaceValues;
	FHiTurnInPlaceAsset TargetTurnAsset;
	if (FMath::Abs(TurnAngle) < TurnInPlaceValues.Turn180Threshold)
	{
		TargetTurnAsset = TurnAngle < 0.0f
							  ? TurnInPlaceValues.N_TurnIP_L90
							  : TurnInPlaceValues.N_TurnIP_R90;
	}
	else
	{
		TargetTurnAsset = TurnAngle < 0.0f
							  ? TurnInPlaceValues.N_TurnIP_L180
							  : TurnInPlaceValues.N_TurnIP_R180;
	}

	return TargetTurnAsset;
}

void UHiGroundTurnAnimUpdater::OnMontageEnded(UAnimMontage* Montage, bool bInterrupted)
{
	bPlayingTurnInPlace = false;
}

void UHiGroundTurnAnimUpdater::TurnInPlace_Implementation(float TurnAngle, float PlayRateScale, float StartTime)
{
	if (bPlayingTurnInPlace)
	{
		return;
	}
	FHiTurnInPlaceAsset TargetTurnAsset = GetTurnInPlaceAsset(TurnAngle);

	bPlayingTurnInPlace = true;
	
	// UE_LOG(HiGroundTurnAnimUpdater, Log, TEXT("UHiGroundTurnAnimUpdater::TurnInPlace_Implementation NetMode: %d, Char: %s"),
	// (int32)AnimInstanceOwner->GetOwningActor()->GetWorld()->GetNetMode(), *GetNameSafe(AnimInstanceOwner->GetOwningActor()));
	

	const float MontageLength = AnimInstanceOwner->Montage_Play(TargetTurnAsset.Animation, PlayRateScale, EMontagePlayReturnType::MontageLength, StartTime);
	bool bPlayedSuccessfully = (MontageLength > 0.f);
	if (bPlayedSuccessfully)
	{
		MontageEndedDelegate.BindUObject(this, &UHiGroundTurnAnimUpdater::OnMontageEnded);
		AnimInstanceOwner->Montage_SetEndDelegate(MontageEndedDelegate, TargetTurnAsset.Animation);
		Cast<AHiCharacter>(AnimInstanceOwner->GetOwningActor())->Client_PlayMontage(TargetTurnAsset.Animation, PlayRateScale);
	}
	else
	{
		OnMontageEnded(TargetTurnAsset.Animation, true);
	}
	
	
	UMotionWarpingComponent *MotionWarpingComponent = Cast<UMotionWarpingComponent>(AnimInstanceOwner->GetOwningActor()->GetComponentByClass(UMotionWarpingComponent::StaticClass()));
	
	FRotator TargetRotator(0, TurnAngle, 0);
	FTransform MantleTarget;
	MantleTarget.SetRotation(TargetRotator.Quaternion());
	MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(WarpTargetName, MantleTarget);
}