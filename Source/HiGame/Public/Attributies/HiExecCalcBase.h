// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffectExecutionCalculation.h"
#include "HiExecCalcBase.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiExecCalcBase : public UGameplayEffectExecutionCalculation
{
	GENERATED_BODY()

public:
	UHiExecCalcBase();

	UFUNCTION(BlueprintCallable, Category = "Attribute", DisplayName = "AttemptCalculateMagnitude")
	bool BP_AttemptCalculateMagnitude(const FGameplayEffectCustomExecutionParameters& ExecutionParams, const FGameplayEffectAttributeCaptureDefinition& InCaptureDef, float& OutMagnitude) const;

	UFUNCTION(BlueprintCallable, Category = "Attribute", DisplayName = "AddOutputModifier")
	static void BP_AddOutputModifier(FGameplayEffectCustomExecutionOutput &Output, const FGameplayModifierEvaluatedData& InOutputMod);
};
