// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Camera/HiCameraViewUpdater.h"
#include "Characters/HiPlayerCameraManager.h"
#include "Characters/HiPlayerController.h"


void UHiCameraViewUpdater::StartUpdater(AHiPlayerCameraManager* InPlayerCameraManager)
{
	PlayerCameraManager = InPlayerCameraManager;
	OnUpdaterStarted(InPlayerCameraManager);
}

void UHiCameraViewUpdater::StopUpdater()
{
	OnUpdaterStopped();
	PlayerCameraManager = nullptr;
}

void UHiCameraViewUpdater::OnUpdaterStarted_Implementation(AHiPlayerCameraManager* InPlayerCameraManager)
{	
}

void UHiCameraViewUpdater::OnUpdaterStopped_Implementation()
{
}

void UHiCameraViewUpdater::OnUpdaterFullyBlended_Implementation()
{
}

FRotator UHiCameraViewUpdater::ProcessInputRotation_Implementation(float DeltaTime, FRotator ViewRotation, FRotator DeltaRot)
{
	FRotator OutViewRotation = AddViewRotationDelta(ViewRotation, DeltaRot);
	return OutViewRotation;
}

FMinimalViewInfo UHiCameraViewUpdater::ProcessCameraView_Implementation(const float DeltaTime)
{
	check(PlayerCameraManager);
	FMinimalViewInfo OutCameraView = PlayerCameraManager->GetCameraCacheView();
	if (APlayerController *PlayerController = PlayerCameraManager->GetOwningPlayerController())
	{
		OutCameraView.Rotation = PlayerController->GetControlRotation();
	}
	return OutCameraView;
}

FRotator UHiCameraViewUpdater::AddViewRotationDelta(FRotator ViewRotation, FRotator DeltaRot, bool bLimitRotation/* = true*/)
{
	check(PlayerCameraManager);
	// Add Delta Rotation
	FRotator OutViewRotation = ViewRotation + DeltaRot;
	// Limit Player View Axes
	if (bLimitRotation)
	{
		PlayerCameraManager->LimitViewPitch(OutViewRotation, ViewPitchMin, ViewPitchMax);
		PlayerCameraManager->LimitViewYaw(OutViewRotation, ViewYawMin, ViewYawMax);
		PlayerCameraManager->LimitViewRoll(OutViewRotation, ViewRollMin, ViewRollMax);
	}
	return OutViewRotation;
}
