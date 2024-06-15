// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Characters/HiCharacterStructLibrary.h"

//#include "HiAirAnimationUpdater.generated.h"

class UHiLocomotionAnimInstance;

class HiInAirAnimationUpdater
{

public:

	void NativeInitialize(UHiLocomotionAnimInstance* InAnimInstance, FHiInAirAnimConfig& InConfig);

	void NativeUpdate(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues);

	void NativeGlideUpdate(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues);
	
	void OnJumped(const EHiJumpState JumpState, const int JumpCount, const EHiBodySide JumpFoot);

public:

	void OnMovementStateChanged(EHiMovementState PreviousMovementState, EHiMovementState CurrentMovementState);

private:

	void UpdateKeepGroundAnim(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues);

	void UpdatePredictLanding(float DeltaSeconds, FHiInAirAnimValues& OutEvaluateValues);

	float PredictLandingDuration(const float FallSpeed, const float MaxLandPredictionTime) const;

	FHiLeanAmount CalcAirLeanAmount(const float FallSpeed) const;

	float CalcJumpFeetPosition(const FVector Velocity) const;

	int CalcLandSelect(const float FallSpeed, const float LandingDuration) const;

private:

	UHiLocomotionAnimInstance* OwnerAnimInstance;

	FHiInAirAnimConfig Config;

	EHiBodySide StartJumpFoot = EHiBodySide::None;

	bool bNeedReselectLandAnimation = true;

	bool bCheckPredictLand_KeepGroundAnim = false;

	// The results of preprocessing landing data
	TArray<FHiLandingAnimConfig> LandingAnimArray;

	// The results of preprocessing landing data
	float MaxPreLandingAnimTime = 0.0f;

	int LandingAnimSelectIndex = 0;
};
