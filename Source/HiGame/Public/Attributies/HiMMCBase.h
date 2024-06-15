// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayModMagnitudeCalculation.h"
#include "GameplayEffect.h"

#include "HiMMCBase.generated.h"

/**
 *  Extend UGameplayModMagnitudeCalculation and expose to blueprint.
 */
UCLASS()
class HIGAME_API UHiMMCBase : public UGameplayModMagnitudeCalculation
{
	GENERATED_BODY()

public:
	UHiMMCBase();
	
	UFUNCTION(BlueprintPure, Category = "Attribute", DisplayName = "GetMagnitude")
	bool BP_GetMagnitude(const FGameplayEffectAttributeCaptureDefinition& Def, const FGameplayEffectSpec& Spec, float& Magnitude) const;

	UFUNCTION(BlueprintPure, Category = "Ability|GameplayEffect")
	float GetMagnitudeByTag(const FGameplayEffectSpec& EffectSpec, const FGameplayTag& Tag) const;
};
