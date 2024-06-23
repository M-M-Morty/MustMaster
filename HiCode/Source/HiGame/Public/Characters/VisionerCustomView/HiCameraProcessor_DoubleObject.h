// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Kismet/KismetMathLibrary.h"


// The variables that will not be changed by calculation in one frame update 
class UHiVisionerView_DoubleObject;

struct FHiCameraUpdateContext_DoubleObject
{
	UHiVisionerView_DoubleObject* Scheme;

	FVector PlayerCenter;

	FVector TargetCenter;

	FVector TargetUpper;

	FVector TargetLower;

	FVector WatchForwardLowerPoint;

	FVector WatchForwardUpperPoint;

	FRotator InputDeltaRotation;

	float DeltaTime = 0.0f;

	float PlayerHeight = 0.0f;

	float VerticalFOV = 0.0f;

	float PlayerViewPitch = 0.0f;

	EMovementMode PlayerMovementMode = EMovementMode::MOVE_Walking;

	bool bHasPlayerVelocity = false;

	bool bIsTargetHidden = false;
};

// Player View Pitch
struct FCameraProcessor_PlayerViewPitch
{
	void Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	/*
	 * Update current player view pitch
	 *  - Based on previous camera location, current player location, previous player view pitch
	 *  - Only adjust the camera vertically to match the current player's view pitch
	 */
	void Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	float SmoothGroundPitch(float NewValue, float DeltaTime);

	float PreviousPlayerViewPitch = 0.0f;

	float UnstableGroundDuration = 0.0f;

	float UnstableAveragePlayerViewPitch = 0.0f;

	float UnstableMaxRecordingDuration = 0.6f;

	float TolerancePlayerViewPitch = 1.0f;
};

// Player Forward Offset
struct FCameraProcessor_PlayerForwardOffset
{
	void Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	/*
	 * Update current player forward offset
	 *  - Based on previous camera location, current player location, previous player view pitch
	 */
	void Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	float PreviousPlayerForwardOffset = 0.0f;
};

// Player Forward Offset
struct FCameraProcessor_CameraPitch
{
	void Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	/*
	 *  Calculate camera pitch & update camera location
	 */
	void Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	void LockControlPitch(bool bEnabled, float InLockTargetViewPitch);
	/*
	 *  Calculate Estimated Best Camera Pitch
	 *  - Predicting a camera based on character height & target height
	 *  - Generally, when the bottom heights of two targets are the same, the best pitch is fixed.
	 *  - Generally, when the top heights of two targets are the same, the best pitch is 0.
	 *
	 * 	@return
	 *		EstimatedBestPitch: best camera pitch
	 *      EstimatedTargetViewPitch: best target view pitch
	 */
	void CalculateEstimatedBestCameraPitch(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	/*
	 *  Move camera location to suit view angle with Fixed player view
	 *  - InputPOV
	 *        rotation is the control result of the current frame
	 *        location is the value of BestCameraWithPlayerViewPitch
	 *
	 * 	@return Best camera pitch
	 */
	void CalculateBestCameraWithDynamicPitchView(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	/*
	 *  Move camera location to suit view angle with Fixed player view
	 *  - InputPOV
	 *        rotation is the control result of the current frame
	 *        location is the value of BestCameraWithPlayerViewPitch
	 *
	 * 	@return Best camera pitch
	 */
	void CalculateBestCameraWithFixedPitchView(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& InOutContext);

	// Current estimated best pitch
	float CurrentEstimatedBestPitch = 0.0f;
	// Cached previous estimated best pitch
	float PreviousEstimatedBestPitch = 0.0f;

	float EstimatedTargetViewPitch = 0.0f;

	/* External controls */
	bool bLockPlayerControlPitch = false;

	float LockTargetViewPitch = 0.0f;
};

