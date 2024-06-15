// Fill out your copyright notice in the Description page of Project Settings.


#include "Attributies/HiExecCalcBase.h"

UHiExecCalcBase::UHiExecCalcBase()
{
	
}

bool UHiExecCalcBase::BP_AttemptCalculateMagnitude(const FGameplayEffectCustomExecutionParameters& ExecutionParams, const FGameplayEffectAttributeCaptureDefinition& InCaptureDef, float& OutMagnitude) const
{
	const FGameplayEffectSpec& Spec = ExecutionParams.GetOwningSpec();

	// Gather the tags from the source and target as that can affect which buffs should be used
	const FGameplayTagContainer* SourceTags = Spec.CapturedSourceTags.GetAggregatedTags();
	const FGameplayTagContainer* TargetTags = Spec.CapturedTargetTags.GetAggregatedTags();

	FAggregatorEvaluateParameters EvaluationParams;
	EvaluationParams.SourceTags = SourceTags;
	EvaluationParams.TargetTags = TargetTags;

	return ExecutionParams.AttemptCalculateCapturedAttributeMagnitude(InCaptureDef, EvaluationParams, OutMagnitude);
}

void UHiExecCalcBase::BP_AddOutputModifier(FGameplayEffectCustomExecutionOutput& Output, const FGameplayModifierEvaluatedData& InOutputMod)
{
	Output.AddOutputModifier(InOutputMod);
}
