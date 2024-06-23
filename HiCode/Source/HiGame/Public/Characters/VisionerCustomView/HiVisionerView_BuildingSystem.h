// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "VisionerCustomView/VisionerCustomView.h"
#include "Kismet/KismetMathLibrary.h"

#include "HiVisionerView_BuildingSystem.generated.h"


UCLASS()
class UHiVisionerView_BuildingSystem : public UVisionerCustomView
{
	GENERATED_UCLASS_BODY()

public:
	//~ Begin  UVisionerCustomView interface
	virtual void EvaluateView_Implementation(FVisionerViewContext& Output) override;
	//~ End  UVisionerCustomView interface
};
