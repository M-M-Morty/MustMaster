// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Camera/HiCameraModifier.h"
#include "HiCameraDistanceScale.generated.h"

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable)
class HIGAME_API UHiCameraDistanceScale : public UHiCameraModifier
{
	GENERATED_UCLASS_BODY()

	virtual bool ProcessViewRotation(class AActor* ViewTarget, float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot);
};
