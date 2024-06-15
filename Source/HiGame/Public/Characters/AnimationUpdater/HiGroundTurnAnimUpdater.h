// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "HiAnimationUpdater.h"
#include "Animation/AnimInstance.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "HiGroundTurnAnimUpdater.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiGroundTurnAnimUpdater : public UHiAnimationUpdater
{
	GENERATED_BODY()

public:
	virtual void NativeUpdateAnimation(float DeltaSeconds) override;

	void TurnInPlaceCheck(float DeltaSeconds);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void TurnInPlace(float DeltaYaw, float PlayRateScale = 1.0f, float StartTime = 0.0f);

	UFUNCTION()
	void OnMontageEnded(UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	FHiTurnInPlaceAsset GetTurnInPlaceAsset(float DeltaYaw);

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName WarpTargetName;
	
	UPROPERTY(BlueprintReadOnly)
	bool bPlayingTurnInPlace = false;

	FOnMontageEnded MontageEndedDelegate;
	
};
