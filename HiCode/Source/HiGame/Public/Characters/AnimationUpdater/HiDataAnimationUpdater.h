// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "HiAnimationUpdater.h"
#include "HiDataAnimationUpdater.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiDataAnimationUpdater : public UHiAnimationUpdater
{
	GENERATED_BODY()

public:

	virtual void NativeUpdateAnimation(float DeltaSeconds) override;
	
	/** Updating data for animation from the character blueprint, including displacement data, logic state, etc. */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void UpdateCharacterInformation(float DeltaSeconds);
};
