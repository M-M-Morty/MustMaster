// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Characters/HiCharacter.h"
#include "HiCameraCharacter.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType, config=Game)
class HIGAME_API AHiCameraCharacter : public AHiCharacter
{
	GENERATED_BODY()

		// Sets default values for this pawn's properties
	AHiCameraCharacter(const FObjectInitializer& ObjectInitializer);

public:


	UFUNCTION(BlueprintImplementableEvent)
	void OnControlled();
	UFUNCTION(BlueprintImplementableEvent)
	void OnUnControlled();
	
public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category=Targeting)
	TWeakObjectPtr<AHiCharacter> LastPossessed;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Debug")
	bool DrawDebug = false;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Debug")
	float SphereRadius = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float ZoomSensitivity = 50.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float MinArmDistance = 250.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float MaxArmDistance = 1500.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float FastMoveMultipiler = 1.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float MovementSpeedMin = 5.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float MovementSpeedMax = 25.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float SpeedFactorAboutCameraDist = 0.1f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float RotationSensitivity = 1.5f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float RotationMinAngle = -15.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float RotationMaxAngle = 85.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	FRotator InitalRotation = FRotator(-60.0f, 0.0, 0.0f);
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float InitalArmLength = 1000.0f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Building System|Camera|Settings")
	float CameraLagSpeed = 3.0f;
	
protected:
	/** The camera component for this camera */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DisplayName = "Sphere",AllowPrivateAccess = "true"), Category = "Building System|Camera")
	TObjectPtr<class USphereComponent> SphereComponent;	
	
	/** The camera component for this camera */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DisplayName = "Camera",AllowPrivateAccess = "true"), Category = "Building System|Camera")
	TObjectPtr<class UCameraComponent> CameraComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, meta = (DisplayName = "SpringArm",AllowPrivateAccess = "true"), Category = "Building System|Camera")
	TObjectPtr<class USpringArmComponent> SpringArmComponent;
	
};
