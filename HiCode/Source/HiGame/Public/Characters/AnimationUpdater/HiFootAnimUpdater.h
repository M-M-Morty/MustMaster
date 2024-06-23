// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HiAnimationUpdater.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "Component/HiCharacterDebugComponent.h"
#include "HiFootAnimUpdater.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiFootAnimUpdater : public UHiAnimationUpdater
{
	GENERATED_BODY()

public:
	
	void Initialize(UHiCharacterAnimInstance* InAnimInstance);
	
	virtual void NativeUpdateAnimation(float DeltaSeconds);

	virtual void NativePostEvaluateAnimation();

	void UpdateAnimatedFootLock(float DeltaSeconds, EHiGait LogicGait);
	
public:

	void SetDebugComponent(TObjectPtr<UHiCharacterDebugComponent> InDebugComponent) { DebugComponent = InDebugComponent; };

	EHiBodySide SelectLockFoot(const EHiBodySide FrontFoot, const float PendingRotateYawDegrees);

	void ForceLockFoot(const EHiBodySide Foot, const float FullWeightDuration);

	void StopLockFoot();

	void CacheFeetTransform(const FHiFootAnimValues& EvaluateValues);

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiGait PreviousLogicGait = EHiGait::Idle;				// Idle / Walking / Running / Sprinting

private:

	struct FootLockParameters
	{
		FTransform PreviousTransform;
		float ForceLockDuration = 0.0f;
		bool bIsTouchedGround = false;
	};

private:

	void SetFootLocking(const float DeltaSeconds, const FName &FootLockCurve, bool UseFootLock, const FTransform PreviousTransform, FHiFootLockValues& OutFootLockValues);

	void SetPelvisIKOffset(float DeltaSeconds, FVector FootOffsetLTarget, FVector FootOffsetRTarget, FHiFootLockValues& OutEvaluateValues);

	void ResetIKOffsets(float DeltaSeconds, FHiFootLockValues& OutEvaluateValues);

	//void SetFootLockOffsets(float DeltaSeconds, FVector& LocalLoc, FRotator& LocalRot);

	//void SetFootOffsets(float DeltaSeconds, FName EnableFootIKCurve, FName IKFootBone, FName RootBone,
	//	FVector& CurLocationTarget, FVector& CurLocationOffset, FRotator& CurRotationOffset);

	void UpdateFootLockTransform(FootLockParameters& OutFootLock, const FVector CompLocation, const FTransform FootWorldTransform);

private:

	TObjectPtr<UHiCharacterDebugComponent> DebugComponent = nullptr;

	FHiFootAnimConfig Config;

	FootLockParameters LeftFootLock;
	FootLockParameters RightFootLock;
};
