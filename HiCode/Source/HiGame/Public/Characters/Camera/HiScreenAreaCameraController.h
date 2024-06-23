// Fill out your copyright notice in the Description page of Project Settings.

#include "CoreMinimal.h"
#include "HiCameraControllerInterface.h"
#include "HiScreenZoneType.h"

#pragma once

class AActor;

class HiScreenAreaCameraController : public HiCameraControllerInterface
{
public:
	HiScreenAreaCameraController() {};

	virtual ~HiScreenAreaCameraController() {};

	void InitParameters(AActor* InActor, FHiScreenZoneType& InLimitZone, FHiScreenZoneType& InComfortZone, double InHalflife);

	virtual void ProcessCameraBehavior(const HiCameraBehaviorContext& InCameraBehaviorContext, const FVector& InCameraLocation, const FRotator& InCameraRotation, float& InOutFOV, FRotator& OutDeltaRotation) override;

private:
	void StartAutoRotator(const HiCameraBehaviorContext& InCameraBehaviorContext, const FVector& InCameraLocation, const FRotator& InCameraRotation, float& InOutFOV);

private:
	/** Camera Target */
	AActor* TargetActor = nullptr;

	/** The target cannot move out of this rectangular area. */
	FHiScreenZoneType LimitZone;

	/** The target moves freely in this rectangular area, but may be constrained outside this area. */
	FHiScreenZoneType ComfortZone;

	double SmoothSpeed = 0.1;		// Eg: halflife

	FRotator PreviousRemainRotator;

	bool bLockTarget = false;
};