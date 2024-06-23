// Fill out your copyright notice in the Description page of Project Settings.


#include "Attributies/HiHealthAttributeSet.h"
#include "GameplayEffectExtension.h"
#include "Component/HiAttributeComponent.h"
#include "Characters/HiCharacter.h"
#include "HiAbilities/HiMountActor.h"


UHiHealthAttributeSet::UHiHealthAttributeSet()
{
	
}

 void UHiHealthAttributeSet::OnRep_Health_Implementation(const FGameplayAttributeData& OldHealth)
 {
 	GAMEPLAYATTRIBUTE_REPNOTIFY(UHiHealthAttributeSet, Health, OldHealth);
 }

 void UHiHealthAttributeSet::OnRep_MaxHealth_Implementation(const FGameplayAttributeData& OldMaxHealth)
 {
 	GAMEPLAYATTRIBUTE_REPNOTIFY(UHiHealthAttributeSet, MaxHealth, OldMaxHealth);
 }

 void UHiHealthAttributeSet::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
 {
 	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME(UHiHealthAttributeSet, Health);
 	DOREPLIFETIME(UHiHealthAttributeSet, MaxHealth);
 }

void UHiHealthAttributeSet::OnPreAttributeChange_Implementation(const FGameplayAttribute& Attribute, float& NewValue)
{
	if (Attribute == this->GetHealthAttribute())
	{
		NewValue = FMath::Clamp(NewValue, 0, this->GetMaxHealth());
	}
	else if (Attribute == this->GetMaxHealthAttribute())
	{
		this->AdjustAttributeForMaxChange(Health, MaxHealth, NewValue, this->GetHealthAttribute());	
	}
}

void UHiHealthAttributeSet::AdjustAttributeForMaxChange(FGameplayAttributeData& AffectedAttribute, const FGameplayAttributeData& MaxAttribute, float NewMaxValue, const FGameplayAttribute& AffectedAttributeProperty)
{
	UAbilitySystemComponent* AbilityComp = GetOwningAbilitySystemComponent();
	const float CurrentMaxValue = MaxAttribute.GetCurrentValue();
	if (!FMath::IsNearlyEqual(CurrentMaxValue, NewMaxValue) && AbilityComp)
	{
		// Change current value to maintain the current Val / Max percent
		const float CurrentValue = AffectedAttribute.GetCurrentValue();
		float NewDelta = (CurrentMaxValue > 0.f) ? (CurrentValue * NewMaxValue / CurrentMaxValue) - CurrentValue : NewMaxValue;

		AbilityComp->ApplyModToAttributeUnsafe(AffectedAttributeProperty, EGameplayModOp::Additive, NewDelta);
	}
}