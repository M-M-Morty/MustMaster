// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GameplayEffect.h"
#include "Component/HiCharacterDebugComponent.h"
#include "HiProjectileActorBase.generated.h"

UCLASS()class HIGAME_API AHiProjectileActorBase : public AActor
{
	GENERATED_BODY()


public:	
	AHiProjectileActorBase();

	/** GameplayEffects to apply to TargetData */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Calculation)
	TArray<FGameplayEffectSpecHandle> GameplayEffectsHandle;

	/** GameplayEffects to apply to self when hit target. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Calculation)
	TArray<FGameplayEffectSpecHandle> SelfGameplayEffectsHandle;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Calculation)
	const UObject* KnockInfo;

	UPROPERTY(BlueprintReadWrite, EditAnywhere, Replicated, Category = Targeting)
	bool bDebug;

	/** Debug trace type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	TEnumAsByte<EDrawDebugTrace::Type> DebugType;
};
