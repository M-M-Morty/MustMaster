// Fill out your copyright notice in the Description page of Project Settings.


#include "Camera/HiCameraModifier.h"

UHiCameraModifier::UHiCameraModifier(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UHiCameraModifier::DisableModifier(bool bImmediate)
{
	Super::DisableModifier(bImmediate);
	if (bImmediate)
		Alpha = -DelayEnableTime;
}

void UHiCameraModifier::SetDelayEnableTime(float DelayTime)
{
	DelayEnableTime = DelayTime;
	if (Alpha < 0.f)
	{
		Alpha = -DelayEnableTime;
	}
}

void UHiCameraModifier::DelayEnableModifier()
{
	Super::EnableModifier();
}

void UHiCameraModifier::EnableModifier()
{
	Super::EnableModifier();
	if (Alpha < 0.f)
	{
		Alpha = 0.0f;
	}
}

void UHiCameraModifier::UpdateAlpha(float DeltaTime)
{
	float TargetAlpha = 0.f;
	float BlendTime = 0.f;
	if (Alpha >= 0.f)
	{
		TargetAlpha = GetTargetAlpha();
		BlendTime = (TargetAlpha == 0.f) ? AlphaOutTime : AlphaInTime;
	}
	else
	{
		TargetAlpha = 0.f;
		BlendTime = DelayEnableTime;
	}

	// interpolate!
	if (BlendTime <= 0.f)
	{
		// no blendtime means no blending, just go directly to target alpha
		Alpha = TargetAlpha;
	}
	else if (Alpha > TargetAlpha)
	{
		// interpolate downward to target, while protecting against overshooting
		Alpha = FMath::Max<float>(Alpha - DeltaTime / BlendTime, TargetAlpha);
	}
	else
	{
		// interpolate upward to target, while protecting against overshooting
		Alpha = FMath::Min<float>(Alpha + DeltaTime / BlendTime, TargetAlpha);
	}
}

void UHiCameraModifier::SetAlphaTime(float InTime, float OutTime)
{
	AlphaInTime = InTime;
	AlphaOutTime = OutTime;
}