// Fill out your copyright notice in the Description page of Project Settings.


#include "Camera/HiCameraDistanceScale.h"

#include "Characters/HiPlayerCameraManager.h"
#include "Kismet/KismetMathLibrary.h"

UHiCameraDistanceScale::UHiCameraDistanceScale(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	
}

bool UHiCameraDistanceScale::ProcessViewRotation(class AActor* ViewTarget, float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot)
{
	if (Alpha < 0.f)
		return false;
	
	AHiPlayerCameraManager *CameraManager = Cast<AHiPlayerCameraManager>(CameraOwner);
	if (!CameraManager)
	{
		return false;
	}

	if (!FMath::IsNearlyEqual(CameraManager->DistanceScale, 1.0f))
	{
		CameraManager->DistanceScale = UKismetMathLibrary::Ease(CameraManager->DistanceScale, 1.0f, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
	}

	return false;
}
