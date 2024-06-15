// Fill out your copyright notice in the Description page of Project Settings.


#include "Attributies/HiAttributeSet.h"

#include "GameplayEffectExtension.h"
#include "Component/HiAbilitySystemComponent.h"
#include "Component/HiAttributeComponent.h"
#include "UObject/PropertyAccessUtil.h"


UHiAttributeSet::UHiAttributeSet()
{
}

UWorld* UHiAttributeSet::GetWorld() const
{
	const UObject* Outer = GetOuter();
	check(Outer);
	return Outer->GetWorld();
}

UHiAbilitySystemComponent* UHiAttributeSet::GetHiAbilitySystemComponent() const
{
	return Cast<UHiAbilitySystemComponent>(GetOwningAbilitySystemComponent());
}

AActor* UHiAttributeSet::BP_GetOwningActor() const
{
	return this->GetOwningActor();
}

void UHiAttributeSet::BP_SetOwningActor(AActor* OwnerActor)
{
	if (!IsValid(OwnerActor))
	{
		return;
	}
	
	this->Rename(nullptr, OwnerActor);
}

FGameplayAttribute UHiAttributeSet::FindAttribute(FName Name)
{
	return GetClass()->FindPropertyByName(Name);
}

void UHiAttributeSet::PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue)
{
	OnPreAttributeChange(Attribute, NewValue);
}

void UHiAttributeSet::OnPreAttributeChange_Implementation(const FGameplayAttribute& Attribute, float& NewValue)
{
}

void UHiAttributeSet::PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data)
{
	OnPostGameplayEffectExecute(Data.EffectSpec, Data.EvaluatedData, &Data.Target);
}

void UHiAttributeSet::OnPostGameplayEffectExecute_Implementation(const FGameplayEffectSpec& EffectSpec, FGameplayModifierEvaluatedData& EvaluatedData, UAbilitySystemComponent* Target)
{
}

void UHiAttributeSet::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	// Enable replicate of fields in blueprint subclass.
	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(GetClass());
	if (BPClass)
	{
		BPClass->GetLifetimeBlueprintReplicationList(OutLifetimeProps);
	}
}

void UHiAttributeSet::BeginDestroy() {
	Super::BeginDestroy();
}
