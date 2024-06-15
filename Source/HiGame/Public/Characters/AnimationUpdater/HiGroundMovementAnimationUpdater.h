// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiAnimationUpdater.h"
#include "HiGroundMovementAnimationUpdater.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiGroundMovementAnimationUpdater : public UHiAnimationUpdater
{
	GENERATED_BODY()

public:
	virtual void NativeUpdateAnimation(float DeltaSeconds) override;

	void UpdateMovementValues(float DeltaSeconds);

	float CalculateMovementDirection();

	float CalculateStandingPlayRate() const;
};
