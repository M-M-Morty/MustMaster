#pragma once

#include "CoreMinimal.h"
#include "HiAbilities/HiAbilityTypes.h"
#include "Abilities/GameplayAbility.h"
#include "Abilities/Tasks/AbilityTask_WaitTargetData.h"
#include "CameraAnimationSequence.h"
#include "LevelSequence.h"
#include "HiGameplayAbility.generated.h"

class UAbilityTask_PlayMontageAndWait;
UCLASS()
class UHiGameplayAbility : public UGameplayAbility
{
	GENERATED_UCLASS_BODY()

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	UAnimMontage* MontageToPlay;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	ULevelSequence* SequenceToPlay;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	UCameraAnimationSequence* CameraSequenceToPlay;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category=Ability)
	bool ActivateOnGranted;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Cooldowns")
	FScalableFloat CooldownDuration;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Cooldowns")
	FGameplayTagContainer CooldownTags;

	// Temp container that we will return the pointer to in GetCooldownTags().
	// This will be a union of our CooldownTags and the Cooldown GE's cooldown tags.
	UPROPERTY(Transient)
	FGameplayTagContainer TempCooldownTags;

	FActiveGameplayEffectHandle CooldownEffectHandle;

public:
	/** The function before the object starts to degrade before the migration */
	virtual void PreTransfer();
	virtual void SerializeTransferPrivateData(FArchive& Ar, UPackageMap* PackageMap);
	/** The function after the object starts to upgrade after the migration */
	virtual void PostTransfer();
	UFUNCTION(BlueprintImplementableEvent)
	void K2_PostTransfer();
	
	UFUNCTION(BlueprintImplementableEvent)
	void OnGive();

	UFUNCTION(BlueprintImplementableEvent)
	void OnRemove();

	UFUNCTION()
	virtual void OnCompleted();

	UFUNCTION()
	virtual void OnBlendOut();

	UFUNCTION()
	virtual void OnInterrupted();

	UFUNCTION()
	virtual void OnCancelled();

	virtual void OnAvatarSet(const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilitySpec& Spec) override;

	virtual const FGameplayTagContainer* GetCooldownTags() const override;
	virtual void ApplyCooldown(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo) const override;
	
public:
	// todo param not only montage, depend on designer
	UFUNCTION(BlueprintImplementableEvent, Category=Ability, DisplayName = "ActivateAbilityParams", meta=(ScriptName = "ActivateAbilityParams"))
	void K2_ActivateAbilityParams(UAnimMontage* InMontageToPlay);
	
	UFUNCTION(BlueprintImplementableEvent, Category=Ability, DisplayName="OnCompleted", meta=(ScriptName="OnCompleted"))
	void K2_OnCompleted();
	
	UFUNCTION(BlueprintImplementableEvent, Category=Ability, DisplayName="OnBlendOut", meta=(ScriptName="OnBlendOut"))
	void K2_OnBlendOut();
	
	UFUNCTION(BlueprintImplementableEvent, Category=Ability, DisplayName="OnInterrupted", meta=(ScriptName="OnInterrupted"))
	void K2_OnInterrupted();
	
	UFUNCTION(BlueprintImplementableEvent, Category=Ability, DisplayName="OnCancelled", meta=(ScriptName="OnCancelled"))
	void K2_OnCancelled();

	UFUNCTION(BlueprintImplementableEvent, Category=Ability)
	void OnAbilityFailed(const FGameplayTagContainer& FailureReason) const;

	UFUNCTION(BlueprintCallable, Category=HiAbility)
	void ResetAbilityCD();

	virtual UGameplayEffect* GetCostGameplayEffect() const;

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category=HiAbility)
	UGameplayEffect* K2_GetCostGameplayEffect() const;

	UFUNCTION(BlueprintCallable, Category=HiAbility)
	bool CanActivateAbilityWithHandle(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo ActorInfo, FGameplayTagContainer& OptionalRelevantTags) const;

	UFUNCTION(BlueprintCallable, Category=HiAbility)
	void GetCooldownRemainingAndDuration(FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo ActorInfo, float& TimeRemaining, float& CD) const;

	virtual bool ShouldActivateAbility(ENetRole Role) const override;

	UFUNCTION(BlueprintPure)
	FGameplayAbilitySpecHandle GetCurrentSpecHandle() const;
	
public:
	UFUNCTION(BlueprintCallable, Category="HiGameplayAbility|Tasks", meta=(DisplayName="PlayMontageAndWait"))
	UAbilityTask_PlayMontageAndWait* CreatePlayMontageAndWaitProxy(
		FName TaskInstanceName,
		UAnimMontage* InMontageToPlay,
		float Rate = 1.0f,
		FName StartSection = NAME_None,
		bool bStopWhenAbilityEnds = true,
		float AnimRootMotionTranslationScale = 1.0f,
		float StartTimeSeconds = 0.0f);

	UFUNCTION(BlueprintCallable, Category="HiGameplayAbility|Tasks")
	UAbilityTask_PlayMontageAndWait *PlayMontage(FName StartSection = NAME_None);

public:
	int32 GetCompositeSectionsNumber() const;
	
	bool bHasBlueprintActivateParams;

	/** Map of gameplay tags to target actor and gameplay effect containers */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = GameplayEffects)
	TMap<FGameplayTag, FHiGameplayEffectContainer> EffectContainerMap;

	/** Get gameplay effect container by tag and make GameplayEffectSpec, return whether success */
	UFUNCTION(BlueprintCallable, Category = Ability, meta = (AutoCreateRefTerm = "EventData"))
	virtual bool MakeEffectContainerSpecByTag(FGameplayTag ContainerTag, int32 Level, FHiGameplayEffectContainer& EffectContainer, TArray<FGameplayEffectSpecHandle>& Specs);
	
	/** Get gameplay effect container by tag and make GameplayEffectSpec for apply to self GEs, return whether success */
	UFUNCTION(BlueprintCallable, Category = Ability, meta = (AutoCreateRefTerm = "EventData"))
	virtual bool MakeEffectContainerSpecByTagOfSelf(FGameplayTag ContainerTag, int32 Level, FHiGameplayEffectContainer& EffectContainer, TArray<FGameplayEffectSpecHandle>& Specs);

	/** Apply gameplay effect container spec to TargetData */
	UFUNCTION(BlueprintCallable, Category = Ability, meta = (AutoCreateRefTerm = "EventData"))
	virtual TArray<FActiveGameplayEffectHandle> ApplyEffectContainerSpec(const TArray<FGameplayEffectSpecHandle>& Specs, const FGameplayAbilityTargetDataHandle& TargetData);

	virtual void GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const override;

protected:
	virtual void ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData);
};
