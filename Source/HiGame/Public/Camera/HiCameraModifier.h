// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Camera/CameraModifier.h"
#include "HiCameraModifier.generated.h"

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable)
class HIGAME_API UHiCameraModifier : public UCameraModifier
{
	GENERATED_UCLASS_BODY()

	UFUNCTION(BlueprintCallable, Category=CameraModifier)
	void SetAlphaTime(float InTime, float OutTime);

	UFUNCTION(BlueprintCallable, Category=CameraModifier)
	void SetDelayEnableTime(float DelayTime);

	UFUNCTION(BlueprintCallable, Category = CameraModifier)
	virtual void DelayEnableModifier();

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = CameraModifier)
	float SmoothSpeed = 0.1f;		// Eg: halflife

	virtual void EnableModifier();

	virtual void DisableModifier(bool bImmediate = false);

	virtual void UpdateAlpha(float DeltaTime);

protected:
	float  DelayEnableTime = 0.0f;
};
