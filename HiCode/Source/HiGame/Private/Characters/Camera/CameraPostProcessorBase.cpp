// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Camera/CameraPostProcessorBase.h"


void UCameraPostProcessorBase::Initialize_Implementation(AHiPlayerCameraManager* PlayerCameraManager)
{
	
}

void UCameraPostProcessorBase::Process_Implementation(const float DeltaTime, const FPostProcessEvaluateContext& ViewContext)
{
}

void UCameraPostProcessorBase::OnTargetChanged_Implementation(AActor* NewTarget)
{
	
}

FName UCameraPostProcessorBase::GetIdentityName()
{
	return GetFName();
}