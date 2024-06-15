// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Component/HiTriggerComponent.h"
#include "HiSubAreaTriggerComponent.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiSubAreaTriggerComponent : public UHiTriggerComponent
{
	GENERATED_BODY()
#if WITH_EDITOR
	virtual void PreEditChange(FProperty* PropertyAboutToChange) override;
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TObjectPtr<class UHiWorldSoundPrimaryDataAsset> BGM;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TObjectPtr<UHiWorldSoundPrimaryDataAsset> AmbientSound;
};
