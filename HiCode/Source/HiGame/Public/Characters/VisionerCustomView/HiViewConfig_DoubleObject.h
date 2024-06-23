// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/EngineTypes.h"

#include "HiViewConfig_DoubleObject.generated.h"


/**
 *
 */
USTRUCT(BlueprintType)
struct HIGAME_API FHiViewConfig_DoubleObject
{
	GENERATED_BODY()

	/* Basic configuration */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float DistanceToPlayerPoint = 1000.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float LimitPlayerViewYaw = 12.5f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float LockTargetViewYaw = 15.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", DisplayName = "Objects Tan(Yaw) Ratio ( Target / Player )")
	float ObjectsYawTanRatio = 0.1f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float NearestLockTargetDistance = 2000.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerViewYawRecoverySpeed = 0.8f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", DisplayName = "Max Yaw Correct Speed (Degrees / s)")
	float MaxYawCorrectSpeed = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float LockTargetSmoothSpeed = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float AutoUnlockTargetSightDuration = 3.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float AutoCorrectRotateYawRatio = 0.3f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	FVector RotationScalar = FVector(1.0f, 1.0f, 1.0f);

	/* Player Forward Offset */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerForwardOffset_LerpSpeed = 2.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerForwardOffset_MaxOffset = 100.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerForwardOffset_MinOffset = -100.0f;

	/* Pitch Correct */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", DisplayName = "Pitch Correct Max Rotate Speed (Degress/s)")
	float PitchCorrect_MaxRotateSpeed = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PitchCorrect_AutoRotateScale = 3.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PitchCorrect_MaxPitch = 4.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PitchCorrect_MinPitch = -8.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PitchCorrect_CloseBestPitch = -5.0f;

	/* Player View Pitch */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "-100", ClampMax = "100"))
	float PlayerViewPitch_MinPercent = -24.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "-100", ClampMax = "100"))
	float PlayerViewPitch_GroundMaxPercent = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "-100", ClampMax = "100"))
	float PlayerViewPitch_MaxPercent = 18.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerViewPitch_InAirSmoothSpeed = 60.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView")
	float PlayerViewPitch_GroundSmoothSpeed = 2.0f;

	/* Target View Pitch */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "0", ClampMax = "50"))
	float TargetViewPitch_HeadPercent_Lowest = 35.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "0", ClampMax = "50"))
	float TargetViewPitch_HeadPercent_Highest = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraView", meta = (ForceUnits = "Percent", ClampMin = "0", ClampMax = "20"))
	float TargetViewPitch_OffsetTolerancePercent = 2.0f;
};

