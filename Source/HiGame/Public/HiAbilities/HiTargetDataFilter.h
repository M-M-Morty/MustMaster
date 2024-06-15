// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiTargetActorSpec.h"
#include "Abilities/GameplayAbilityTargetDataFilter.h"
#include "HiAbilities/HiGASLibrary.h"

#include "HiTargetDataFilter.generated.h"

/**
 * 
 */
USTRUCT(BlueprintType)
struct HIGAME_API FHiTargetDataFilter: public FGameplayTargetDataFilter
{
	GENERATED_BODY()
	
	/** Calculation filter type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Filter)
	TEnumAsByte<ECalcFilterType> FilterType = NoSelf;

	FHiTargetDataFilter();
	FHiTargetDataFilter(ECalcFilterType FilterType);

	virtual bool FilterPassesForActor(const AActor* ActorToBeFiltered) const override;
	
	// virtual bool IsEnemy(const AActor* ActorToBeFiltered) const;
	// virtual ECharIdentity GetActorIdentity(const AActor* Actor) const;
	
	~FHiTargetDataFilter();
};
