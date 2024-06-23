// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

struct HiCameraBehaviorContext
{
	/** Time difference between the current frame and the previous frame. */
	float DeltaTime;

	/** Value on the forward axis of the camera */
	float ArmOffset;

	/** Source actor location. */
	FVector SourceLocation;

	/** Camera actor location. */
	FVector PivotLocation;

	/** Camera information. */
	FMinimalViewInfo POV;

	/** Get some rendering parameters from PlayerControl. */
	APlayerController* PlayerControl;

	/** Minimum view pitch, in degrees. */
	float ViewPitchMin;

	/** Maximum view pitch, in degrees. */
	float ViewPitchMax;
};

class HiCameraControllerInterface
{
public:
	virtual void ProcessCameraBehavior(const HiCameraBehaviorContext& InCameraBehaviorContext, const FVector& InCameraLocation, const FRotator& InCameraRotation, float& InOutFOV, FRotator& OutDeltaRotation) = 0;
	virtual ~HiCameraControllerInterface() {};

	inline double GetAutoStopRotateThreshold() { return AutoStopRotateThreshold; }

private:
	double AutoStopRotateThreshold = 0.01;
};