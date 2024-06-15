// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/VisionerCustomView/HiVisionerView_BuildingSystem.h"
#include "GameFramework/Character.h"


UHiVisionerView_BuildingSystem::UHiVisionerView_BuildingSystem(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UHiVisionerView_BuildingSystem::EvaluateView_Implementation(FVisionerViewContext& Output)
{	
	if (ACharacter* ControlledCharacter = Cast<ACharacter>(Output.ViewTarget))
	{
		FMinimalViewInfo TempView;
		ControlledCharacter->CalcCamera(Output.DeltaTime, TempView);
		Output.SetViewLocation(TempView.Location);
		Output.SetViewOrientation(TempView.Rotation);
	}
}
