// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/EngineTypes.h"
#include "AlphaBlend.h"
#include "Camera/PlayerCameraManager.h"
#include "Camera/HiScreenZoneType.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Kismet/KismetMathLibrary.h"
#include "GameplayCameraManager.h"
#include "HiPlayerCameraManager.generated.h"

// forward declarations
class UHiCharacterDebugComponent;
class AHiCharacter;
class ACharacter;
class UVisionerInstance;

class UCameraPostProcessorBase;
class UHiCameraViewUpdater;

/**
 * Player camera manager class
 */
UCLASS(Blueprintable, BlueprintType)
class HIGAME_API AHiPlayerCameraManager : public AGameplayCameraManager
{
	GENERATED_BODY()

public:
	AHiPlayerCameraManager();

	virtual void BeginPlay() override;

	virtual void BeginDestroy() override;

	virtual void PostRegisterAllComponents() override;

public:
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Camera")
	void OnPossess(AHiCharacter* NewCharacter);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Camera")
	void OnUnPossess();

	UFUNCTION(BlueprintCallable, Category = "Camera")
	float GetCameraBehaviorParam(FName CurveName) const;

	/** Implemented debug logic in BP */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent, Category = "Camera")
	void DrawDebugTargets(FVector PivotTargetLocation);

	UFUNCTION(BlueprintCallable, Category = "Control")
	void SetTargetCameraRotation(FRotator Rotation);

	UFUNCTION(BlueprintCallable, Category = "Control")
	void EnablePivotSmooth(bool enable);

public:

	/**
	 * Called to give PlayerCameraManager a chance to adjust view rotation updates before they are applied.
	 * @param DeltaTime - Frame time in seconds.
	 * @param InOutVelocity - Character velocity.
	 */
	void AdjustVelocityOrientation(const float DeltaTime, FVector& InOutVelocity);

protected:
	/**
	 * Called to give PlayerCameraManager a chance to adjust view rotation updates before they are applied.
	 * e.g. The base implementation enforces view rotation limits using LimitViewPitch, et al.
	 * @param DeltaTime - Frame time in seconds.
	 * @param OutViewRotation - In/out. The view rotation to modify.
	 * @param OutDeltaRot - In/out. How much the rotation changed this frame.
	 */
	virtual void ProcessViewRotation(float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot) override;

	/**
	 * Performs per-tick camera update. Called once per tick after all other actors have been ticked.
	 * Non-local players replicate the POV if bUseClientSideCameraUpdates is true.
	 */
	virtual void UpdateCamera(float DeltaTime);

	/** Internal function conditionally called from UpdateCamera to do the actual work of updating the camera. */
	virtual void DoUpdateCamera(float DeltaTime) override;

	// Do ProcessViewRotation with modifiers
	void ProcessModifierViewRotation(float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot);

	void ProcessLimitRotation(FRotator& OutViewRotation);

private:
	void ResetCameraTarget();

	/** Same as #DoUpdateCamera in parent class. It will be gradually abandoned. */
	void DoUpdateClassicCamera(const float DeltaTime, FMinimalViewInfo& InOutView);

private:

	void EvaluateVisionerRotation(const float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot);

	void EvaluateVisionerView(const float DeltaTime, FMinimalViewInfo& InOutView);

	void ChangeVisionerViewTarget(class AActor* NewViewTarget);

public:
	UFUNCTION(BlueprintCallable, Category = "View")
	const EHiCameraViewMode GetCurrentViewMode() { return CurrentViewMode; }

protected:
	/** Change the camera orientation immediately with no transition */
	UFUNCTION(BlueprintCallable, Category = "Control")
	void ApplyWorldRotation(FRotator InRotation);

public:
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Category = "View")
	TObjectPtr<AHiCharacter> ControlledCharacter = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "View|Classic")
	TObjectPtr<USkeletalMeshComponent> CameraBehavior = nullptr;

public:
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Category = "View|Classic")
	float DistanceScale = 1.0f;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "View|Classic")
	FTransform SmoothedPivotTarget;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "View|Classic")
	FVector PivotLocation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "View|Classic")
	FVector TargetCameraLocation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "View|Classic")
	FRotator TargetCameraRotation;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "View|Classic")
	float SmoothedFov;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	TArray<TEnumAsByte<EEasingFunc::Type>> PivotSmoothEasingFunc{EEasingFunc::Type::EaseOut, EEasingFunc::Type::EaseOut, EEasingFunc::Type::EaseOut};

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	FVector PivotSmoothAlpha{0.5, 0.5, 0.5};
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	FRotator DebugViewRotation;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	FVector DebugViewOffset;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	float ObstructedViewSweepRadius = 40.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	float DistanceScaleFactor = 0.05f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	float MinDistance= 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "View|Classic")
	float MaxDistance= 1000.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "View|Classic")
	float GMFOV = 0.0f;

private:
	UPROPERTY()
	TObjectPtr<UHiCharacterDebugComponent> HiCharacterDebugComponent = nullptr;

public:

	UFUNCTION(BlueprintCallable, Category = "Custom View")
	void ApplyCustomViewUpdater(TSubclassOf<UHiCameraViewUpdater> ViewUpdaterClass, const FAlphaBlendArgs& BlendInArgs);

	UFUNCTION(BlueprintCallable, Category = "Custom View")
	FMinimalViewInfo ApplyCameraViewModifiers(float DeltaTime, FMinimalViewInfo InView);

	/** The active custom camera view updater. Only one will take effect */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Transient, Category = "Custom View")
	TObjectPtr<UHiCameraViewUpdater> CustomViewUpdater = nullptr;

	// The duration to cross-fade for
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Transient, Category = "Custom View", Meta = (ClampMin = "0.0"))
	FAlphaBlend CustomViewBlend;

	/** Cached previous custom camera view, used for transitions */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Transient, Category = "Custom View")
	FMinimalViewInfo CachedCustomCameraView;

public:

	/* The VisionerBlueprint class to use. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visioner")
	class TSubclassOf<UVisionerInstance> VisionerBlueprintClass;

	/** The active Visioner graph program instance. */
	UPROPERTY(VisibleInstanceOnly, Transient, NonTransactional)
	TObjectPtr<UVisionerInstance> VisionerScriptInstance = nullptr;

	UFUNCTION(BlueprintCallable, Category = "Visioner")
	UVisionerInstance* GetVisionerBP() { return VisionerScriptInstance; };

	UFUNCTION(BlueprintCallable, Category = "Visioner")
	UCameraPostProcessorBase* FindCameraPostProcessorByName(const FName PostProcessorName);

public:

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Instanced, Category = "Visioner", meta = (ShowInnerProperties))
	TArray<TObjectPtr<UCameraPostProcessorBase>> CameraPostProcessors;

private:

	EHiCameraViewMode CurrentViewMode = EHiCameraViewMode::Classic;

	bool bEnablePivotSmooth = false;
};
