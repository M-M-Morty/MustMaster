// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "VisionerCustomView/VisionerCustomView.h"
#include "Kismet/KismetMathLibrary.h"
#include "HiViewConfig_DoubleObject.h"
#include "Characters/VisionerCustomView/HiCameraProcessor_DoubleObject.h"

#include "HiVisionerView_DoubleObject.generated.h"


UENUM(BlueprintType)
enum class EHiTargetLockState : uint8
{
	/** The target is not in view, fully unlocked. */
	Free = 0,
	/** The target is in view, not in the best display position.
			Keep the display position in view and try to adjust the state to the Optimal State. */
	Common = 1,
	/** The target is in view, in the best display position.
			Keep the camera in its current state. */
	Optimal = 2,
};


UCLASS()
class UHiVisionerView_DoubleObject : public UVisionerCustomView
{
	GENERATED_UCLASS_BODY()

public:
	//~ Begin  UVisionerCustomView interface
	virtual void Initialize_Implementation(const FVisionerInitializeContext& Context) override;
	virtual void Update_Implementation(FVisionerUpdateContext& Context) override;
	virtual void EvaluateRotation_Implementation(FVisionerRotationContext& Output) override;
	virtual void EvaluateView_Implementation(FVisionerViewContext& Output) override;
	//~ End  UVisionerCustomView interface

	void ReInitializeView(FVisionerUpdateContext& Context);

	void IgnoreSmooth();

public:

	void Reinitialize(ACharacter* InControlCharacter, ACharacter* InTargetCharacter, float InAspectRatio, float ViewPitchMin, float ViewPitchMax, const FMinimalViewInfo& CameraPOV);

	UFUNCTION(BlueprintCallable, Category = "Double Object")
	void SetCameraSchemeConfig(const FHiViewConfig_DoubleObject& Config) { CameraSchemeConfig = Config; }

	const FHiViewConfig_DoubleObject& GetCameraSchemeConfig() { return CameraSchemeConfig; }

	float GetDrivenWeight() { return DrivenByTargetWeight; }

	//void SetControlledCharacter(TObjectPtr<ACharacter> Character) { ControlledCharacter = Character; }

	//FORCEINLINE ACharacter* GetTargetCharacter() { return TargetCharacter; }

public:
	/* External controls for animation events */
	void LockControlPitch(bool bEnabled, float InLockTargetViewPitch = 0.0f);

	void LockControlYaw(bool bEnabled);

private:

	void EnterDrivenByTarget(const FVisionerViewContext& Output);

	void LeaveDrivenByTarget();

	float CalculatePlayerToTargetYaw();

	bool CalculateBestCameraWithYawView(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& Output);

	/* Update target lock state by current view */
	void UpdateTargetLockStateWithRotation(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerViewContext& Output);

	void UpdateTargetLockStateWithoutRotation(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerViewContext& Output);

	void UpdateTargetLockStateWithTimer(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& Output);

public:

	EHiTargetLockState GetTargetLockState() const { return TargetLockState; }

	FVector GetPreviousPlayerCenterLocation() const { return PreviousPlayerCenter; }

	FVector GetPreviousTargetCenterLocation() const { return PreviousTargetCenter; }

	bool IsSchemeNotLeaving() const { return TargetDrivenWeight >= DrivenByTargetWeight; }

	bool IsAutoLeaveDriven() const { return bEnableAutoLeaveDrivenTimer; }

	bool IsResetFrame() const { return bIsResetFrame; }

public:
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "CameraNode")
	FHiViewConfig_DoubleObject CameraSchemeConfig;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "CameraNode")
	bool bEnableCircleMove = true;

public:
	FORCEINLINE FVector GetCachedCameraLocation() { return CachedLocation; }
	FORCEINLINE void SetCachedCameraLocation(const FVector& InLocation) { CachedLocation = InLocation; }

	FORCEINLINE FRotator GetCachedCameraOrientation() { return CachedOrientation; }
	FORCEINLINE void SetCachedCameraOrientation(const FRotator& InOrientation) { CachedOrientation = InOrientation; }

	FORCEINLINE float GetCachedCameraFOV() { return CachedFOV; }
	FORCEINLINE void SetCachedCameraFOV(const float InFOV) { CachedFOV = InFOV; }

	FORCEINLINE void SetCachedCameraView(const FVisionerViewContext& ViewContext)
	{
		SetCachedCameraLocation(ViewContext.GetViewLocation());
		SetCachedCameraOrientation(ViewContext.GetViewOrientation());
		SetCachedCameraFOV(ViewContext.GetViewFOV());
	}

private:
	// Cache camera properties
	FVector CachedLocation;
	FRotator CachedOrientation;
	float CachedFOV;

private:

	FCameraProcessor_PlayerViewPitch PlayerViewPitchProcessor;

	FCameraProcessor_PlayerForwardOffset PlayerForwardOffsetProcessor;

	FCameraProcessor_CameraPitch CameraPitchProcessor;

	// TODO: Too many parameters, need to split into different processors

	// Cached Character
	UPROPERTY(Transient)
	TObjectPtr<ACharacter> TargetCharacter = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<ACharacter> ControlledCharacter = nullptr;

	EHiTargetLockState TargetLockState = EHiTargetLockState::Free;

	FRotator InputDeltaRotation;

	/* Basic */
	bool bIsResetFrame = false;

	float AspectRatio = 1.0f;

	float CircleMoveAjustAngle = 0.0f;

	/* Timer */
	bool bEnableAutoLeaveDrivenTimer = false;

	bool bEnableAutoFaceTargetTimer = false;

	bool bEnableAutoRecoveryPlayerViewYawTimer = false;

	float DrivenByTargetWeight = 0.0f;

	float TargetDrivenWeight = 0.0f;

	float AutoCorrectRotateYaw = 0.0f;

	float LeftUnlockTargetSightDuration = 0.0f;

	float PlayerViewYawRecoveryLeft = 0.0f;

	float PlayerViewYawRecoveryTarget = 0.0f;

	float PlayerViewYawRecoveryDuration = 0.0f;

	/* Previous parameters */
	float PreviousPlayerViewYaw = 0.0f;

	float PreviousTargetViewYaw = 0.0f;

	FVector PreviousPlayerCenter;

	FVector PreviousTargetCenter;

	bool bLockPlayerControlYaw = false;
};
