// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemComponent.h"
#include "LevelSequence.h"
#include "MovieSceneSequencePlayer.h"
#include "Gameplay/DDSAbilitySystemComponent.h"
#include "HiAbilities/Tasks/HiAbilityTask_PlaySequence.h"
#include "HiAbilitySystemComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHiOnGameplayEffectRemoved, const FActiveGameplayEffect&, Effect);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FHiOnGameplayEffectTagCountChanged, const FGameplayTag, Tag, int32, NewCount);

/**
 * 
 */
class UHiAttributeSet;

UCLASS(Blueprintable)
class UHiAbilitySystemComponent : public UDDSAbilitySystemComponent
{
	GENERATED_UCLASS_BODY()
public:
	UFUNCTION(BlueprintCallable, Category = "Abilities")
	bool TryActivateAbilityByClassParam(TSubclassOf<UGameplayAbility> InAbilityToActivate, UAnimMontage* InMontageToPlay, bool bAllowRemoteActivation = true);

	UFUNCTION(BlueprintCallable, Category = "Abilities", DisplayName = "TryActivateAbilityFromGameplayEvent")
	bool TryActivateAbilityFromGameplayEvent(TSubclassOf<UGameplayAbility> InAbilityToActivate, FGameplayTag EventTag, struct FGameplayEventData Payload);

	UFUNCTION(BlueprintCallable, Category = "Abilities", DisplayName = "CancelAbilityHandle")
	void BP_CancelAbilityHandle(const FGameplayAbilitySpecHandle& AbilityHandle);

	UFUNCTION(BlueprintCallable, Category="Abilities", DisplayName = "TryActivateAbilityByHandle")
	bool BP_TryActivateAbilityByHandle(FGameplayAbilitySpecHandle AbilityToActivate, bool bAllowRemoteActivation = true);

	UFUNCTION(BlueprintCallable, Category="Abilities", DisplayName = "FindAbilitySpecHandleFromInputID")
	FGameplayAbilitySpecHandle FindAbilitySpecHandleFromInputID(int32 InputID);

	UFUNCTION(BlueprintCallable, Category="Abilities", DisplayName = "FindAbilitySpecHandleFromClass")
	FGameplayAbilitySpecHandle FindAbilitySpecHandleFromClass(TSubclassOf<UGameplayAbility> InAbilityClass);

	UFUNCTION(BlueprintCallable, Category="Abilities", DisplayName = "CancelAbilities")
	void BP_CancelAbilities(UGameplayAbility* Ignore=nullptr);

	UFUNCTION(BlueprintCallable)
	bool CanApplyGE(const UGameplayEffect *GameplayEffect, float Level, const FGameplayEffectContextHandle& EffectContext);

	static UHiAbilitySystemComponent* GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent);

	virtual FTimerManager& GetTimerManager() const;
	
	UFUNCTION(BlueprintCallable, Category="Abilities")
	bool SetGameplayEffectDurationHandle(FActiveGameplayEffectHandle Handle, float NewDuration);
	
	UFUNCTION(BlueprintCallable, Category="Abilities")
	bool RestartActiveGameplayEffectDuration(FActiveGameplayEffectHandle Handle);

	UFUNCTION(BlueprintCallable, Category="Effects")
	void GetActiveGameplayEffectRemainingAndDuration(FActiveGameplayEffectHandle Handle, float& Remaining, float &Duration) const;

	UFUNCTION(BlueprintCallable, Category="Abilities")
	bool HasGameplayTag(FGameplayTag Tag) const;	
	
	UFUNCTION(BlueprintCallable, Category="Abilities")
	void SetGameplayTag(FGameplayTag Tag, int32 Count);

	virtual void OnRep_ActivateAbilities() override;

	//run on server , when give new ability
	virtual void OnGiveAbility(FGameplayAbilitySpec& AbilitySpec) override;
	
	UFUNCTION(BlueprintImplementableEvent)
	void BP_OnGiveAbility(const FGameplayAbilitySpecHandle& Handle);
	
	//run on server, when remove ability
	virtual void OnRemoveAbility(FGameplayAbilitySpec& AbilitySpec) override;

	UFUNCTION(BlueprintImplementableEvent)
	void BP_OnRemoveAbility(const FGameplayAbilitySpecHandle& Handle);

	UFUNCTION(BlueprintCallable, Category= "Ability")
	virtual void InitAbilityActorInfo(AActor* InOwnerActor, AActor* InAvatarActor);

	void OnImmunityBlockGameplayEffect(const FGameplayEffectSpec& Spec, const FActiveGameplayEffect* ImmunityGE) override;

	UFUNCTION(BlueprintImplementableEvent)
	void BP_OnImmunityBlockGameplayEffect(const FGameplayEffectSpec& Spec, const FActiveGameplayEffect& ImmunityGE);

	UFUNCTION(BlueprintCallable, Category="Ability")
	FGameplayAbilityActorInfo GetAbilityActorInfo();

	UFUNCTION(BlueprintCallable, Category= "Ability")
	void BP_RefreshAbilityActorInfo();

	UFUNCTION(BlueprintCallable, Category="Ability")
	virtual void SetReplicationMode(EGameplayEffectReplicationMode NewReplicationMode);

	UFUNCTION(BlueprintCallable, Category="Ability")
	bool CanClientPredict() const;

	UFUNCTION(BlueprintCallable, Category="Ability")
	float GetCurrentMontagePosition() const;
	
	UFUNCTION(BlueprintCallable, Category="Ability")
	const UAnimSequenceBase* GetCurrentAnimSequence() const;

	UFUNCTION(BlueprintCallable, Category="Ability")
	void GetCurrentAnimSequenceStartAndEndTime(float& OutStartTime, float& OutEndTime) const;

	UFUNCTION(BlueprintPure, Category="Ability")
	UAnimMontage* BP_GetCurrentMontage() const;

	UFUNCTION(BlueprintCallable, Category="Ability")
	bool HasActivateAbilities() const;

	UFUNCTION(BlueprintCallable, Category="Ability")
	bool HasActivateAbilityByClass(TSubclassOf<UGameplayAbility> InAbilityClass);
	
	
	
	/** Set attribute base value. */
	UFUNCTION(BlueprintCallable, Category="Attribute")
	void SetAttributeBaseValue(const FGameplayAttribute &Attribute, float NewBaseValue);

	/** Get attribute base value. */
	UFUNCTION(BlueprintCallable, Category="Attribute")
	float GetAttributeBaseValue(const FGameplayAttribute &Attribute);

	UFUNCTION(BlueprintCallable, Category="Attribute")
	void SetAttributeCurrentValue(const FGameplayAttribute& Attribute, float NewValue);

	/** Get attribute Current value. */
	UFUNCTION(BlueprintCallable, Category="Attribute")
	float GetAttributeCurrentValue(const FGameplayAttribute &Attribute);

	UFUNCTION(BlueprintPure, Category="Attribute")
	FGameplayAttribute FindAttributeByName(FName Name);

	/** Play sequence on simulated client */
	UFUNCTION(NetMulticast, Reliable)
	void MulticastOther_PlaySequence(ULevelSequence* SequenceToPlay, const FMovieSceneSequencePlaybackSettings& Settings, const TArray<FAbilityTaskSequenceBindings>& Bindings);

	/** Stop sequence on simulated client */
	UFUNCTION(NetMulticast, Reliable, BlueprintCallable)
	void MulticastOther_StopSequence(ULevelSequence* SequenceToPlay);

	UFUNCTION(BlueprintCallable)
	void StopSequence();

	UFUNCTION()
	void OnStopSequence();

	UFUNCTION()
	void OnFinishedSequence();

	/** Add attribute set to ASC spawned attribute sets. */
	UFUNCTION(BlueprintCallable, Category="Attribute")
	void AddAttributeSet(UAttributeSet* AttrSet);

	/** Remove attribute set from ASC spawned attribute sets. */
	UFUNCTION(BlueprintCallable, Category="Attribute")
	void RemoveAttributeSet(UAttributeSet* AttrSet);
	
	// run on client when replicated
	//UFUNCTION()
	//virtual void OnRep_ActivateAbilities();

	virtual void OnRegister() override;
	virtual void OnUnregister() override;

	virtual void OnComponentDestroyed(bool bDestroyingHierarchy) override;

private:
	void ClearSequenceSpawnedActors();

	FDelegateHandle GameplayEffectRemovedHandle;
	FDelegateHandle GameplayEffectTagCountChangedHandle;

	void OnAnyGameplayEffectRemoved(const FActiveGameplayEffect& Effect) const;

	void OnGameplayEffectTagCountChangedCallback(const FGameplayTag Tag, int32 NewCount);
	
public:
	UPROPERTY(BlueprintReadWrite)
	ALevelSequenceActor* LevelSequenceActor;

	UPROPERTY(BlueprintReadWrite)
	ULevelSequencePlayer* LevelSequencePlayer;

	UPROPERTY(BlueprintReadOnly)
	ULevelSequence* CurrentSequenceInPlay;

	UPROPERTY(BlueprintReadWrite)
	TArray<AActor*> ActorsSpawnedInSequence;
	//UPROPERTY(ReplicatedUsing=OnRep_ActivateAbilities, BlueprintReadOnly, Category = "Abilities")
	//FGameplayAbilitySpecContainer ActivatableAbilities;

	UPROPERTY(BlueprintAssignable)
	FHiOnGameplayEffectRemoved OnGameplayEffectRemoved;

	UPROPERTY(BlueprintAssignable)
	FHiOnGameplayEffectTagCountChanged OnGameplayEffectTagCountChanged;
};
