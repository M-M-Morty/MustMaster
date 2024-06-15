// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/CullDistanceVolume.h"
#include "HiGlobalCullDistanceVolume.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API AHiGlobalCullDistanceVolume : public ACullDistanceVolume
{
	GENERATED_UCLASS_BODY()
public:
	/** @returns true if a sphere/point (with optional radius CheckRadius) overlaps this volume */
	virtual bool EncompassesPoint(FVector Point, float SphereRadius=0.f, float* OutDistanceToPoint = 0) override;

};
