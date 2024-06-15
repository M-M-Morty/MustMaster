// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NameTypes.h"
#include "Characters/HiCharacterStructLibrary.h"

class UHiLocomotionAnimInstance;
class UHiCharacterDebugComponent;


class HiFootAnimUpdater
{

public:

	void NativeInitialize(UHiLocomotionAnimInstance* InAnimInstance, FHiFootAnimConfig& InConfig);

	void NativeUpdate(float DeltaSeconds, EHiMovementState MovementState, FHiFootAnimValues& OutEvaluateValues);

public:

	void SetDebugComponent(TObjectPtr<UHiCharacterDebugComponent> InDebugComponent) { DebugComponent = InDebugComponent; };

	EHiBodySide SelectLockFoot(const EHiBodySide FrontFoot, const float PendingRotateYawDegrees);

	void ForceLockFoot(const EHiBodySide Foot, const float FullWeightDuration);

	void StopLockFoot();

	void CacheFeetTransform(const FHiFootAnimValues& EvaluateValues);

private:

	struct FootLockParameters
	{
		FTransform PreviousTransform;
		float ForceLockDuration = 0.0f;
		bool bIsTouchedGround = false;
	};

private:

	void SetFootLocking(const float DeltaSeconds, const float NewFootLockCurveVal, const FTransform PreviousTransform, FHiFootLockValues& OutFootLockValues);

	void SetPelvisIKOffset(float DeltaSeconds, FVector FootOffsetLTarget, FVector FootOffsetRTarget, FHiFootLockValues& OutEvaluateValues);

	void ResetIKOffsets(float DeltaSeconds, FHiFootLockValues& OutEvaluateValues);

	//void SetFootLockOffsets(float DeltaSeconds, FVector& LocalLoc, FRotator& LocalRot);

	//void SetFootOffsets(float DeltaSeconds, FName EnableFootIKCurve, FName IKFootBone, FName RootBone,
	//	FVector& CurLocationTarget, FVector& CurLocationOffset, FRotator& CurRotationOffset);

	void UpdateFootLockTransform(FootLockParameters& OutFootLock, const FVector CompLocation, const FTransform FootWorldTransform);

private:

	TObjectPtr<UHiCharacterDebugComponent> DebugComponent = nullptr;

	FHiFootAnimConfig Config;
	UHiLocomotionAnimInstance* OwnerAnimInstance;

	FootLockParameters LeftFootLock;
	FootLockParameters RightFootLock;
};
