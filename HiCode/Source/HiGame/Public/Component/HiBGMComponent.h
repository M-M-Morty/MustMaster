// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Component/HiPawnComponent.h"
#include "HiBGMComponent.generated.h"

/**
 * 
 */
class UHiWorldSoundPrimaryDataAsset;

UCLASS(Blueprintable, Meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiBGMComponent : public UHiPawnComponent
{
	GENERATED_BODY()

public:
#if WITH_EDITOR
	virtual void PreEditChange(FProperty* PropertyAboutToChange) override;
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TObjectPtr<UHiWorldSoundPrimaryDataAsset> BGM;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TObjectPtr<UHiWorldSoundPrimaryDataAsset> AmbientSound;
};
