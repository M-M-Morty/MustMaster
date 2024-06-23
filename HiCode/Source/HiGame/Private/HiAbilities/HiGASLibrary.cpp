// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiGASLibrary.h"
#include "Characters/HiCharacter.h"
#include "Component/HiAbilitySystemComponent.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "HiAbilities/HiCollisionLibrary.h"


FGameplayEffectContextHandle UHiGASLibrary::GetGameplayEffectContextHandle(const FGameplayEffectSpec& Spec)
{
	return Spec.GetContext();
}

FGameplayEffectSpec UHiGASLibrary::GetGameplayEffectSpecByHandle(const FGameplayEffectSpecHandle& Handle)
{
	if (!Handle.IsValid())
	{
		return FGameplayEffectSpec();
	}
	
	return *Handle.Data.Get();
}

bool UHiGASLibrary::IsGameplayEffectSpecHandleValid(const FGameplayEffectSpecHandle& Handle)
{
	return Handle.IsValid();
}

FString UHiGASLibrary::GetGameplayEffectNameByHandle(const FGameplayEffectSpecHandle& Handle)
{
	return Handle.Data.Get()->Def->GetName();
}

const UGameplayAbility* UHiGASLibrary::GetAbilityInstanceNotReplicated(const FGameplayEffectSpec& Spec)
{
	return Spec.GetContext().GetAbilityInstance_NotReplicated();
}

const UGameplayAbility* UHiGASLibrary::GetAbilityCDO(const FGameplayEffectSpec& Spec)
{
	return Spec.GetContext().GetAbility();
}

const FGameplayTagContainer& UHiGASLibrary::GetDynamicAssetTags(const FGameplayEffectSpec& Spec)
{
	return Spec.GetDynamicAssetTags();
}

float UHiGASLibrary::GetValueAtLevel(const FScalableFloat ScalableVar, float Level)
{
	return ScalableVar.GetValueAtLevel(Level);
}

FGameplayTag UHiGASLibrary::RequestGameplayTag(FName TagName)
{
	return FGameplayTag::RequestGameplayTag(TagName, true);
}

bool UHiGASLibrary::IsDefendFrontDamage(AActor* SourceActor, AActor* TargetActor)
{
	if (!IsValid(SourceActor) || !IsValid(TargetActor)) 
		return false;

	auto const HiASC = Cast<UHiAbilitySystemComponent>(UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(TargetActor));
	if (!HiASC)
		return false;

	auto const Tag = FGameplayTag::RequestGameplayTag("Ability.Skill.Defend.ImmuneFront", true);
	if (!HiASC->HasGameplayTag(Tag))
		return false;
	
	if (UHiCollisionLibrary::CheckInSection(SourceActor->GetActorLocation(), TargetActor->GetActorLocation(), TargetActor->GetActorForwardVector(), PI))
		return true;

	return false;
}

bool UHiGASLibrary::IsDefendBackDamage(AActor* SourceActor, AActor* TargetActor)
{
	if (!IsValid(SourceActor) || !IsValid(TargetActor)) 
		return false;

	auto const HiASC = Cast<UHiAbilitySystemComponent>(UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(TargetActor));
	if (!HiASC)
		return false;

	auto const Tag = FGameplayTag::RequestGameplayTag("Ability.Skill.Defend.ImmuneBack", true);
	if (!HiASC->HasGameplayTag(Tag))
		return false;
	
	if (!UHiCollisionLibrary::CheckInSection(SourceActor->GetActorLocation(), TargetActor->GetActorLocation(), TargetActor->GetActorForwardVector(), PI))
		return true;

	return false;
}

bool UHiGASLibrary::IsWithStand(AActor* SourceActor, AActor* TargetActor, float StartAngle, float EndAngle)
{
	if (!IsValid(SourceActor) || !IsValid(TargetActor)) 
		return false;

	auto const HiASC = Cast<UHiAbilitySystemComponent>(UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(TargetActor));
	if (!HiASC)
		return false;

	auto const Tag = FGameplayTag::RequestGameplayTag("Ability.Skill.Defend.WithStand", true);
	if (!HiASC->HasGameplayTag(Tag))
		return false;
	
	if (UHiCollisionLibrary::CheckInDirectionBySection(SourceActor->GetActorLocation(), TargetActor->GetActorLocation(), TargetActor->GetActorForwardVector(), (int)StartAngle, (int)EndAngle))
		return true;

	return false;
}

AActor* UHiGASLibrary::GetGrantedAbilityGECauser(const UGameplayAbility* Ability)
{
	const FGameplayAbilitySpec* AbilitySpec = Ability->GetCurrentAbilitySpec();
	AActor* AbilityOwner = Ability->GetActorInfo().OwnerActor.Get();
	if (!IsValid(AbilityOwner))
	{
		return nullptr;
	}

	const UAbilitySystemComponent* ASC = UAbilitySystemBlueprintLibrary::GetAbilitySystemComponent(AbilityOwner);
	if (!IsValid(ASC))
	{
		return nullptr;
	}
	
	const FActiveGameplayEffect* ActiveGE = ASC->GetActiveGameplayEffect(AbilitySpec->GameplayEffectHandle);
	if (nullptr == ActiveGE)
	{
		return nullptr;
	}

	return ActiveGE->Spec.GetContext().GetEffectCauser();
}

const UGameplayAbility* UHiGASLibrary::GetAbilitySpawnThisGE(FGameplayEffectSpecHandle GESpecHandle)
{
	const FGameplayEffectSpec* GESpec = GESpecHandle.Data.Get();
	if (nullptr == GESpec)
	{
		return nullptr;
	}

	return GESpec->GetContext().GetAbility();
}

bool UHiGASLibrary::IsAbilityActive(const FGameplayAbilitySpec& Spec)
{
	return Spec.IsActive();
}

UClass* UHiGASLibrary::GetAttributeSetClass(const FGameplayAttribute& Attribute)
{
	return Attribute.GetAttributeSetClass();
}

FGameplayAttributeData UHiGASLibrary::GetAttributeData(UAttributeSet* AttrSet, FGameplayAttribute Attr)
{
	auto Data = Attr.GetGameplayAttributeData(AttrSet);
	if (Data) return *Data;
	
	return FGameplayAttributeData();
}

FString UHiGASLibrary::GetActiveGameplayEffectDebugString(FActiveGameplayEffect ActiveGE)
{
	return UAbilitySystemBlueprintLibrary::GetActiveGameplayEffectDebugString(ActiveGE.Handle);
}

const UGameplayAbility* UHiGASLibrary::EffectContextGetAbility(FGameplayEffectContextHandle EffectContext)
{
	return EffectContext.GetAbility();
}
