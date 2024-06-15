// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Camera/CameraTypes.h"
#include "HiCameraViewUpdater.generated.h"


class AHiPlayerCameraManager;


UCLASS(BlueprintType, Blueprintable, Abstract, EditInlineNew)
class UHiCameraViewUpdater : public UObject
{
	GENERATED_BODY()

public:
	void StartUpdater(AHiPlayerCameraManager* InPlayerCameraManager);
	void StopUpdater();

public:
	/* 
	 * Process rotation input
	 *  - Calling from: PlayerCameraManager::ProcessViewRotation
	 *  - Default logic: Apply input rotation to the rotation of the current PlayerController and return
	 *  - Network behavior: Only execute on the client side
	 *  --- [Input] DeltaTime: Time interval between two frames
	 *  --- [Input] ViewRotation: current PlayerController rotation
	 *  --- [Input] DeltaRot: input delta rot in this frame
	 *  --- [Output] (FRotator): output rotation, will be applied to the PlayerController. (Not the rotation presented by the camera in rendering)
	 */
	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Custom View")
	FRotator ProcessInputRotation(float DeltaTime, FRotator ViewRotation, FRotator DeltaRot);

	/* 
	 * Process camera view
	 *  - Calling from: PlayerCameraManager::UpdateCamera
	 *  - Default logic: Returns the camera parameters from the previous frame, only the rotation used in the current Controller
	 *  - Network behavior: Execute on the client side and the server side
	 *  --- [Input] DeltaTime: Time interval between two frames
	 *  --- [Output] (FMinimalViewInfo): output view parameters, will be used by the final camera.
	 */
	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Custom View")
	FMinimalViewInfo ProcessCameraView(const float DeltaTime);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Custom View")
	void OnUpdaterStarted(AHiPlayerCameraManager* InPlayerCameraManager);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Custom View")
	void OnUpdaterStopped();

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Custom View")
	void OnUpdaterFullyBlended();

	UFUNCTION(BlueprintCallable, Category = "Custom View")
	FRotator AddViewRotationDelta(FRotator ViewRotation, FRotator DeltaRot, bool bLimitRotation = true);

public:

	UPROPERTY(BlueprintReadOnly, Transient, Category = "Custom View")
	AHiPlayerCameraManager* PlayerCameraManager = nullptr;

public:
	/** Minimum view pitch, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewPitchMin = -89.9f;

	/** Maximum view pitch, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewPitchMax = 89.9f;

	/** Minimum view yaw, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewYawMin = 0.f;

	/** Maximum view yaw, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewYawMax = 359.999f;

	/** Minimum view roll, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewRollMin = -89.9f;

	/** Maximum view roll, in degrees. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Custom View")
	float ViewRollMax = 89.9f;
};
