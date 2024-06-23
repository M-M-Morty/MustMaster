// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiTargetActorBase.h"
#include "HiAbilityTypes.generated.h"

/**
 * 
 */
class UHiAbilitySystemComponent;
class UGameplayEffect;
class URPGTargetType;


/**
 * Struct defining a list of gameplay effects, and targeting info
 * These containers are defined statically in blueprints or assets and then turn into Specs at runtime
 */
USTRUCT(BlueprintType)
struct HIGAME_API FHiGameplayEffectContainer
{
	GENERATED_BODY()

	FHiGameplayEffectContainer() {}

	/** Sets the way that targeting happens */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
	TSubclassOf<AHiTargetActorBase> TargetType;

	/** Sets the target actor confirmation type */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
	TEnumAsByte<EGameplayTargetingConfirmation::Type> ConfirmationType;

	/** Sets the wait target data task instance name */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
	FName TaskInstanceName;
	
	/** List of gameplay effects to apply to the targets */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
	TArray<TSubclassOf<UGameplayEffect>> TargetGameplayEffectClasses;

	/** List of gameplay effects to apply to self after hit valid targets */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
	TArray<TSubclassOf<UGameplayEffect>> SelfGameplayEffectClasses;
};
