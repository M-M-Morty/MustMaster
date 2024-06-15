// Fill out your copyright notice in the Description page of Project Settings.


#include "Attributies/HiMMCBase.h"

UHiMMCBase::UHiMMCBase()
{
}

bool UHiMMCBase::BP_GetMagnitude(const FGameplayEffectAttributeCaptureDefinition& Def, const FGameplayEffectSpec& Spec, float& Magnitude) const
{
	// Gather the tags from the source and target as that can affect which buffs should be used
	const FGameplayTagContainer* SourceTags = Spec.CapturedSourceTags.GetAggregatedTags();
	const FGameplayTagContainer* TargetTags = Spec.CapturedTargetTags.GetAggregatedTags();

	FAggregatorEvaluateParameters EvaluationParams;
	EvaluationParams.SourceTags = SourceTags;
	EvaluationParams.TargetTags = TargetTags;
	
	return GetCapturedAttributeMagnitude(Def, Spec, EvaluationParams, Magnitude);
}

float UHiMMCBase::GetMagnitudeByTag(const FGameplayEffectSpec& EffectSpec, const FGameplayTag& Tag) const
{
	return EffectSpec.GetSetByCallerMagnitude(Tag, true, 0.0f);
}




