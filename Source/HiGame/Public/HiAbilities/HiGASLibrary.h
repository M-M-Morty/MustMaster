// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffect.h"
#include "GameplayAbilities/Public/Abilities/GameplayAbility.h"
#include "HiGASLibrary.generated.h"


// /**
//  * Character Identity
//  */
// UENUM(BlueprintType)
// enum class ECharIdentity : uint8
// {
// 	Player,
// 	Monster,
// 	NPC,
// 	SummonedActor,
//
// 	None
// };

/**
 *  A static library for expose GAS functions to blueprint.
 */
UCLASS()
class HIGAME_API UHiGASLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
public:
	/** Get context handle of GameplayEffectSpec */
	UFUNCTION(BlueprintPure, Category="Ability")
	static FGameplayEffectContextHandle GetGameplayEffectContextHandle(const FGameplayEffectSpec& Spec);

	/** Get GameplayEffectSpec not replicated ability instance  */
	UFUNCTION(BlueprintCallable, Category="Ability")
	static const UGameplayAbility* GetAbilityInstanceNotReplicated(const FGameplayEffectSpec& Spec);

	/** Get ability CDO in effect context. */
	UFUNCTION(BlueprintCallable, Category="Ability")
	static const UGameplayAbility* GetAbilityCDO(const FGameplayEffectSpec& Spec);

	/** Get GameplayEffectSpec dynamic asset tags. */
	UFUNCTION(BlueprintCallable, Category="Ability")
	static const FGameplayTagContainer& GetDynamicAssetTags(const FGameplayEffectSpec& Spec);

	UFUNCTION(BlueprintPure, Category="Ability")
	static float GetValueAtLevel(const FScalableFloat ScalableVar, float Level);
	
	UFUNCTION(BlueprintCallable, Category="Ability")
    static FGameplayTag RequestGameplayTag(FName TagName);

    UFUNCTION(BlueprintCallable, Category = "Ability")
	static bool IsDefendFrontDamage(AActor* SourceActor, AActor* TargetActor);

	UFUNCTION(BlueprintCallable, Category = "Ability")
	static bool IsDefendBackDamage(AActor* SourceActor, AActor* TargetActor);

	UFUNCTION(BlueprintCallable, Category = "Ability")
	static bool IsWithStand(AActor* SourceActor, AActor* TargetActor, float StartAngle, float EndAngle);

	/** Get the GE that grant this GA and then get the GE causer */
	UFUNCTION(BlueprintPure, Category="Ability")
	static AActor* GetGrantedAbilityGECauser(const UGameplayAbility* Ability);

	/** Get the ability that was used to spawn this GE*/
	UFUNCTION(BlueprintPure, Category="Ability")
	static const UGameplayAbility* GetAbilitySpawnThisGE(FGameplayEffectSpecHandle GESpecHandle);

	UFUNCTION(BlueprintPure, Category="Ability")
	static FGameplayEffectSpec GetGameplayEffectSpecByHandle(const FGameplayEffectSpecHandle& Handle);

	/** Check GameplayEffectSpecHandle valid */
	UFUNCTION(BlueprintPure, Category="Ability")
	static bool IsGameplayEffectSpecHandleValid(const FGameplayEffectSpecHandle& Handle);

	UFUNCTION(BlueprintPure, Category="Ability")
	static FString GetGameplayEffectNameByHandle(const FGameplayEffectSpecHandle& Handle);

	/** Whether ability is active. */
	UFUNCTION(BlueprintCallable, Category="Ability")
	static bool IsAbilityActive(const FGameplayAbilitySpec& Spec);

	UFUNCTION(BlueprintCallable, Category="Attribute")
	static UClass* GetAttributeSetClass(const FGameplayAttribute& Attribute);

	UFUNCTION(BlueprintPure, Category="Attribute")
	static FGameplayAttributeData GetAttributeData(UAttributeSet* AttrSet, FGameplayAttribute Attr);
	
	UFUNCTION(BlueprintPure, Category = "Ability|GameplayEffect")
	static FString GetActiveGameplayEffectDebugString(FActiveGameplayEffect ActiveGE);

	UFUNCTION(BlueprintPure, Category = "Ability|EffectContext", Meta = (DisplayName = "GetAbility"))
	static const UGameplayAbility* EffectContextGetAbility(FGameplayEffectContextHandle EffectContext);
};
