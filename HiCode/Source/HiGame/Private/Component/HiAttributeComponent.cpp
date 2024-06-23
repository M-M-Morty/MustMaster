// Fill out your copyright notice in the Description page of Project Settings.

#include "Component/HiAttributeComponent.h"

#include "Component/HiAbilitySystemComponent.h"
#include "HiLogChannels.h"
#include "Characters/HiCharacter.h"
#include "HiAbilities/HiGameplayAbility.h"
#include "HiAbilities/HiMountActor.h"
#include "GameplayEffectTypes.h"
#include "GameplayEffectExtension.h"

UHiAttributeComponent::UHiAttributeComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bCanEverTick = false;

	SetIsReplicatedByDefault(true);

	AbilitySystemComponent = nullptr;	
}

void UHiAttributeComponent::InitializeWithAbilitySystem(UHiAbilitySystemComponent* InASC)
{
	AActor* Owner = GetOwner();
	check(Owner);

	if (AbilitySystemComponent)
	{
		UE_LOG(LogHiGame, Error, TEXT("UHiAttributeComponent: Attribute component for owner [%s] has already been initialized with an ability system."), *GetNameSafe(Owner));
		return;
	}

	AbilitySystemComponent = InASC;
	if (!AbilitySystemComponent)
	{
		UE_LOG(LogHiGame, Error, TEXT("UHiAttributeComponent: Cannot initialize health component for owner [%s] with NULL ability system."), *GetNameSafe(Owner));
		return;
	}
	
	/*
	AttributeSet = AbilitySystemComponent->GetSet<ULyraHealthSet>();
	if (!AttributeSet)
	{
		UE_LOG(LogHiGame, Error, TEXT("UHiAttributeComponent: Cannot initialize health component for owner [%s] with NULL health set on the ability system."), *GetNameSafe(Owner));
		return;
	}
	
	/ Register to listen for attribute changes.
	AbilitySystemComponent->GetGameplayAttributeValueChangeDelegate(ULyraHealthSet::GetHealthAttribute()).AddUObject(this, &ThisClass::HandleHealthChanged);
	AbilitySystemComponent->GetGameplayAttributeValueChangeDelegate(ULyraHealthSet::GetMaxHealthAttribute()).AddUObject(this, &ThisClass::HandleMaxHealthChanged);
	HealthSet->OnOutOfHealth.AddUObject(this, &ThisClass::HandleOutOfHealth);

	// TEMP: Reset attributes to default values.  Eventually this will be driven by a spread sheet.
	AbilitySystemComponent->SetNumericAttributeBase(ULyraHealthSet::GetHealthAttribute(), HealthSet->GetMaxHealth());

	ClearGameplayTags();

	OnHealthChanged.Broadcast(this, HealthSet->GetHealth(), HealthSet->GetHealth(), nullptr);
	OnMaxHealthChanged.Broadcast(this, HealthSet->GetHealth(), HealthSet->GetHealth(), nullptr);
	*/
}

void UHiAttributeComponent::UninitializeFromAbilitySystem()
{
	ClearGameplayTags();
	AbilitySystemComponent = nullptr;
}

void UHiAttributeComponent::InitAttributeListener()
{
	UHiAbilitySystemComponent* HiAbilitySystemComponent = Cast<UHiAbilitySystemComponent>(AbilitySystemComponent);
	if (IsValid(HiAbilitySystemComponent))
	{
		for (FGameplayAttribute Attribute : AttributesToListenFor)
		{
			HiAbilitySystemComponent->GetGameplayAttributeValueChangeDelegate(Attribute).AddUObject(this, &UHiAttributeComponent::HandleAttributeChange);
		}
		HiAbilitySystemComponent->AbilityFailedCallbacks.AddUObject(this, &UHiAttributeComponent::HandleAbilityFailed);
	}
}

void UHiAttributeComponent::RemoveAttributeListener()
{
	UHiAbilitySystemComponent* HiAbilitySystemComponent = Cast<UHiAbilitySystemComponent>(AbilitySystemComponent);
	if (IsValid(HiAbilitySystemComponent))
	{
		for (FGameplayAttribute Attribute : AttributesToListenFor)
		{
			HiAbilitySystemComponent->GetGameplayAttributeValueChangeDelegate(Attribute).RemoveAll(this);
		}

		HiAbilitySystemComponent->AbilityFailedCallbacks.RemoveAll(this);
	}
}

void UHiAttributeComponent::HandleAttributeChange(const FOnAttributeChangeData& Data)
{
	AActor* Owner = GetOwner();
	check(Owner);
	
	AHiCharacter* CharacterAbility = Cast<AHiCharacter>(Owner);
	if (IsValid(CharacterAbility))
	{
		if (Data.GEModData != nullptr) {
			CharacterAbility->Multicast_OnAttributeChanged(Data.Attribute, Data.NewValue, Data.OldValue, Data.GEModData->EffectSpec);
		}
		else {
			CharacterAbility->Multicast_OnAttributeChanged(Data.Attribute, Data.NewValue, Data.OldValue, FGameplayEffectSpec());
		}
	}	
	
	AHiMountActor* MountActor = Cast<AHiMountActor>(Owner);
	if (IsValid(MountActor))
	{
		if (Data.GEModData != nullptr) {
			MountActor->Multicast_OnAttributeChanged(Data.Attribute, Data.NewValue, Data.OldValue, Data.GEModData->EffectSpec);
		}
		else {
			MountActor->Multicast_OnAttributeChanged(Data.Attribute, Data.NewValue, Data.OldValue, FGameplayEffectSpec());
		}
	}
}

void UHiAttributeComponent::HandleAbilityFailed(const UGameplayAbility* Ability, const FGameplayTagContainer& FailureReason)
{
	if (IsValid(Ability))
	{
		const UHiGameplayAbility* HiAbility = Cast<UHiGameplayAbility>(Ability);
		if (HiAbility)
		{
			HiAbility->OnAbilityFailed(FailureReason);
		}
	}
}


void UHiAttributeComponent::OnUnregister()
{
	UninitializeFromAbilitySystem();
	Super::OnUnregister();
}

void UHiAttributeComponent::ClearGameplayTags()
{
}
