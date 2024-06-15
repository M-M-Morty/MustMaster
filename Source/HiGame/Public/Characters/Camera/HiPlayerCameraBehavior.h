// Fill out your copyright notice in the Description page of Project Settings.


#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstance.h"
#include "Characters/HiCharacterEnumLibrary.h"

#include "HiPlayerCameraBehavior.generated.h"


/**
 * Main class for player camera movement behavior
 */
UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiPlayerCameraBehavior : public UAnimInstance
{
	GENERATED_BODY()

public:
	void SetRotationMode(EHiRotationMode RotationMode);

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementState MovementState;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementAction MovementAction;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	bool bLookingDirection = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	bool bVelocityDirection = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	bool bAiming = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiGait Gait;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiStance Stance;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Read Only Data|Character Information")
	bool bDebugView = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	float ChangeGaitDuration = 0.5f;

	void SetGait(const EHiGait &NewGait);

	UFUNCTION(BlueprintCallable, Category = "Hi|Event")
	void SetMovementState(const EHiMovementState NewMovementState);

	virtual void NativeUpdateAnimation(float DeltaSeconds);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void OnPossess(ACharacter* NewCharacter);

private:
	float LastChangeMovementStateDuration = 0;

	EHiGait PendingGait = EHiGait::Pending;
};
