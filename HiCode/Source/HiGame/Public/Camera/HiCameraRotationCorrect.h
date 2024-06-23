// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiCameraModifier.h"
#include "HiCameraRotationCorrect.generated.h"

UENUM(BlueprintType)
enum class EHiCameraRotationCorrectMode : uint8
{
	Override,
	Additive,
};

USTRUCT(BlueprintType)
struct FHiCameraRotationCorrectParams
{
	GENERATED_BODY()

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, meta = (AllowPrivateAccess = true), Category = "CameraModifier")
	float TargetYaw = 360.0f;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, meta = (AllowPrivateAccess = true), Category = "CameraModifier")
	float TargetPitch = 360.0f;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, meta = (AllowPrivateAccess = true), Category = "CameraModifier")
	float TargetRoll = 360.0f;

	//UPROPERTY()
};

// UENUM(BlueprintType)
// enum class EHiCameraRotationCorrectAction : uint8
// {
// 	Yaw = 1,
// 	Pitch = 1 << 1,
// 	Roll = 1 << 2,
// };

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable)
class HIGAME_API UHiCameraRotationCorrect : public UHiCameraModifier
{
	GENERATED_UCLASS_BODY()

	virtual bool ProcessViewRotation(class AActor* ViewTarget, float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot);

	virtual void ModifyCamera(float DeltaTime, FVector ViewLocation, FRotator ViewRotation, float FOV, FVector& NewViewLocation, FRotator& NewViewRotation, float& NewFOV);
	
	UFUNCTION(BlueprintCallable, Category=CameraModifier)
	void SetTargetYaw(float target_yaw);

	UFUNCTION(BlueprintCallable, Category=CameraModifier)
	void SetTargetPitch(float target_pitch);

	UFUNCTION(BlueprintCallable, Category=CameraModifier)
	void SetTargetRoll(float target_roll);

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = CameraModifier)
	EHiCameraRotationCorrectMode  RotationCorrectMode;
	
	bool UseTargetYaw = false;
	float TargetYaw = 0.0f;

	bool UseTargetPitch = false;
	float TargetPitch = 0.0f;

	bool UseTargetRoll = false;
	float TargetRoll = 0.0f;

	//UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = CameraModifier)
	//uint8  RotationCorrectAction = EHiCameraRotationCorrectAction::Yaw;
	
private:

	FRotator GetTargetRotator(const FRotator &ActorRotator, const FRotator &CurrentRotator) const;
};
