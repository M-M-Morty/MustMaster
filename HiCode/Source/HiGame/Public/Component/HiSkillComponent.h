// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiPawnComponent.h"
#include "GameplayAbilitySpec.h"
#include "GameplayEffect.h"
#include "HiSkillComponent.generated.h"

/**
 * 
 */


class UHiAbilitySystemComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FHiDynamicMulticastDelegate);

UCLASS()
class HIGAME_API UHiSkillComponent : public UHiPawnComponent
{
	GENERATED_BODY()
	
public:
	UHiSkillComponent(const FObjectInitializer& ObjectInitializer);

	//Returns the skill component  if one exists on the specified actor.
	UFUNCTION(BlueprintCallable, Category = "Gameplay/Pawn")
	static UHiSkillComponent* FindSkillComponent(const AActor* Actor) { return (Actor ? Actor->FindComponentByClass<UHiSkillComponent>() : nullptr); }

	UFUNCTION(BlueprintCallable, Category="Gameplay/Pawn")
	UHiAbilitySystemComponent* GetHiAbilitySystemComponent() const { return AbilitySystemComponent; }

	// Should be called by the owning pawn to become the avatar of the ability system.
	UFUNCTION(BlueprintCallable, Category="Gameplay/Pawn")
	void InitializeAbilitySystem(UHiAbilitySystemComponent* InASC, AActor* InOwnerActor);
	
	// Should be called by the owning pawn to remove itself as the
	UFUNCTION(BlueprintCallable, Category="Gameplay/Pawn")
	void UninitializeAbilitySystem();

	//Should be called by the owning pawn when the pawn`s controller change
	void HandleControllerChanged();

	//Should be called by the owning pawn when the player state has been replicated.
	void HandlePlayerStateReplicated();

	//Should be called by the owning pawn when the input component is setup.
	void SetupPlayerInputComponent();

	//Call this anytime the pawn needs to check if it's ready to be initialized (pawn data assigned, possessed, etc..). 
	bool CheckPawnReadyToInitialize();

	// Returns true if the pawn is ready to be initialized.
	UFUNCTION(BlueprintCallable, BlueprintPure = false, Category = "Gameplay|Pawn", Meta = (ExpandBoolAsExecs = "ReturnValue"))
	bool IsPawnReadyToInitialize() const { return bPawnReadyToInitialize; }

	// Register with the OnPawnReadyToInitialize delegate and broadcast if condition is already met.
	void OnPawnReadyToInitialize_RegisterAndCall(FSimpleMulticastDelegate::FDelegate Delegate);

	UFUNCTION(BlueprintCallable)
	FGameplayAbilitySpecHandle GiveAbility(TSubclassOf<UGameplayAbility> AbilityType, int32 InputID, UGameplayAbilityUserData* UserData = nullptr, int32 SkillLevel = 1);

	UFUNCTION(BlueprintCallable)
	void SetAbilityLevel(TSubclassOf<UGameplayAbility> AbilityType, int32 NewLevel);
	
	UFUNCTION(BlueprintCallable)
	void SetRemoveAbilityOnEnd(FGameplayAbilitySpecHandle AbilitySpecHandle);

	UFUNCTION(BlueprintImplementableEvent, Category = "Gameplay|Ability")
	void ClientOnRep_ActivateAbilities();
	
	UFUNCTION(BlueprintCallable)
	void RegisterASCCallback();

	UFUNCTION(BlueprintCallable)
	void UnRegisterASCCallback();

	virtual void ImmunityCallback(const FGameplayEffectSpec& BlockedSpec, const FActiveGameplayEffect* ImmunityGE);

	UFUNCTION(BlueprintImplementableEvent)
	void OnImmunityBlockGameplayEffect(const FGameplayEffectSpec& BlockedSpec, const FActiveGameplayEffect& ImmunityGE); 
	
protected:
	virtual void OnRegister() override;

	//Delegate fired when pawn has everything needed for initialization.
	FSimpleMulticastDelegate OnPawnReadyToInitialize;

	UPROPERTY(BlueprintAssignable, Meta = (DisplayName = "On Pawn Ready To Initialize"))
	FHiDynamicMulticastDelegate BP_OnPawnReadyToInitialize;

	//Delegate fired when ability system initialized.
	UPROPERTY(BlueprintAssignable, Meta = (DisplayName = "On Ability System Initialized"))
	FHiDynamicMulticastDelegate OnAbilitySystemInitialized;

	//Delegate fired when ability system uninitialized.
	UPROPERTY(BlueprintAssignable, Meta = (DisplayName = "On Ability System UnInitialized"))
	FHiDynamicMulticastDelegate OnAbilitySystemUninitialized;

protected:
	UPROPERTY()	
	UHiAbilitySystemComponent* AbilitySystemComponent;

	//True when the pawn has everything needed for initialization.
	int32 bPawnReadyToInitialize : 1;
	
private:
	FDelegateHandle ImmunityCallbackHandle;
};
