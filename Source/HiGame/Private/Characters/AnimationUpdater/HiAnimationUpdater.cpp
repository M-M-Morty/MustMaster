// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/AnimationUpdater/HiAnimationUpdater.h"

void UHiAnimationUpdater::Initialize(UHiCharacterAnimInstance *AnimInstance)
{
	AnimInstanceOwner = AnimInstance;
}

void UHiAnimationUpdater::UnInitialize(UHiCharacterAnimInstance *AnimInstance)
{
	AnimInstanceOwner = nullptr;
}

void UHiAnimationUpdater::NativeUpdateAnimation(float DeltaSeconds)
{
	
}

void UHiAnimationUpdater::NativePostEvaluateAnimation()
{
	
}
