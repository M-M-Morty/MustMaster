// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "VisionerCustomView/VisionerCustomView.h"
#include "Kismet/KismetMathLibrary.h"

#include "HiVisionerView_Classic.generated.h"


UCLASS()
class UHiVisionerView_Classic : public UVisionerCustomView
{
	GENERATED_UCLASS_BODY()

public:
	//~ Begin  UVisionerCustomView interface
	virtual void EvaluateView_Implementation(FVisionerViewContext& Output) override;
	//~ End  UVisionerCustomView interface

private:
	float GetCameraBehaviorParam(APlayerCameraManager* PlayerCameraManager, const FName ParamName);
	float GetVisionerCurveValue(APlayerCameraManager* PlayerCameraManager, const FName ParamName);

	FVector CalculateAxisIndependentLag(FVector CurrentLocation, FVector TargetLocation,
		FRotator CameraRotation, FVector LagSpeeds,
		const FVector& PivotSmoothAlpha, const TArray<TEnumAsByte<EEasingFunc::Type>>& PivotSmoothEasingFunc,
		float DeltaTime);

public:
	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "VisionerView")
	FTransform SmoothedPivotTarget;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "VisionerView")
	FVector PivotLocation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "VisionerView")
	FVector TargetCameraLocation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "VisionerView")
	FRotator TargetCameraRotation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "VisionerView")
	float SmoothedFov;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	FRotator DebugViewRotation;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	FVector DebugViewOffset;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	bool bEnablePivotSmooth = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	TArray<TEnumAsByte<EEasingFunc::Type>> PivotSmoothEasingFunc{ EEasingFunc::Type::EaseOut, EEasingFunc::Type::EaseOut, EEasingFunc::Type::EaseOut };

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	FVector PivotSmoothAlpha{ 0.5, 0.5, 0.5 };

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	float DistanceScaleFactor = 0.05f;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Category = "VisionerView")
	float DistanceScale = 1.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	float MinDistance = 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "VisionerView")
	float MaxDistance = 1000.0f;
};
