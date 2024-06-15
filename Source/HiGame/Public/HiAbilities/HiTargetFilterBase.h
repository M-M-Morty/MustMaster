// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiAbilities/HiGASLibrary.h"

#include "HiTargetFilterBase.generated.h"

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable)
class HIGAME_API UHiTargetFilterBase: public UObject
{
	GENERATED_BODY()

public:
	/** Actor we're comparing against. */
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	AActor* SelfActor = nullptr;

	/** Subclass actors must be to pass the filter. */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (ExposeOnSpawn = true), Category = HiFilter)
	TSubclassOf<AActor> RequiredActorClass;

	/** Reverses the meaning of the filter, so it will exclude all actors that pass. */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (ExposeOnSpawn = true), Category = HiFilter)
	bool bReverseFilter = false;
	
	UHiTargetFilterBase();

	UFUNCTION(BlueprintNativeEvent)
	bool FilterActor(const AActor* ActorToBeFiltered);
};
