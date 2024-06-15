// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiAttributeSet.h"
#include "AbilitySystemComponent.h"
#include "HiHealthAttributeSet.generated.h"


/**
 *  UHiHealthAttributeSet
 *  
*	Class that defines attributes that are necessary for taking damage.
 *	Attribute examples include: health, shields, and resistances.
 */

UCLASS(BlueprintType)
class HIGAME_API UHiHealthAttributeSet : public UHiAttributeSet
{
	GENERATED_BODY()
public:

	UHiHealthAttributeSet();
	
	UPROPERTY(BlueprintReadOnly, Category = Health, ReplicatedUsing = OnRep_Health)
		FGameplayAttributeData Health {100.0f};
	ATTRIBUTE_ACCESSORS(UHiHealthAttributeSet, Health)

	UPROPERTY(BlueprintReadOnly, Category = Health, ReplicatedUsing = OnRep_MaxHealth)
		FGameplayAttributeData MaxHealth {100.0f};
	ATTRIBUTE_ACCESSORS(UHiHealthAttributeSet, MaxHealth)

	UPROPERTY(BlueprintReadOnly)
		FGameplayAttributeData Damage;
	ATTRIBUTE_ACCESSORS(UHiHealthAttributeSet, Damage);

	UPROPERTY(BlueprintReadOnly)
	FGameplayAttributeData WithStandDamageScale {1.0f};
	ATTRIBUTE_ACCESSORS(UHiHealthAttributeSet, WithStandDamageScale);

	// Delegate to broadcast when the health attribute reaches zero.
	mutable FHiAttributeEvent OnOutOfHealth;
	
public:
	virtual void OnPreAttributeChange_Implementation(const FGameplayAttribute& Attribute, float& NewValue) override;
	
	UFUNCTION(BlueprintNativeEvent)
	void OnRep_Health(const FGameplayAttributeData& OldHealth);

	UFUNCTION(BlueprintNativeEvent)
	void OnRep_MaxHealth(const FGameplayAttributeData& OldMaxHealth);

protected:
	void AdjustAttributeForMaxChange(FGameplayAttributeData& AffectedAttribute, const FGameplayAttributeData& MaxAttribute, float NewMaxValue, const FGameplayAttribute& AffectedAttributeProperty);	
};
