// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AttributeSet.h"
#include "AbilitySystemComponent.h"
#include "Component/HiAbilitySystemComponent.h"
#include "HiAttributeSet.generated.h"

class UHiAttributeComponent;
struct FGameplayEffectSpec;

/**
 * This macro defines a set of helper functions for accessing and initializing attributes.
 *
 * The following example of the macro:
 *		ATTRIBUTE_ACCESSORS(UHiHealthSet, Health)
 * will create the following functions:
 *		static FGameplayAttribute GetHealthAttribute();
 *		float GetHealth() const;
 *		void SetHealth(float NewVal);
 *		void InitHealth(float NewVal);
 */
#define ATTRIBUTE_ACCESSORS(ClassName, PropertyName) \
	UFUNCTION(BlueprintCallable, Category="Gameplay/Attribute") \
	GAMEPLAYATTRIBUTE_PROPERTY_GETTER(ClassName, PropertyName) \
	UFUNCTION(BlueprintCallable, Category="Gameplay/Attribute") \
	GAMEPLAYATTRIBUTE_VALUE_GETTER(PropertyName) \
	UFUNCTION(BlueprintCallable, Category="Gameplay/Attribute") \
	GAMEPLAYATTRIBUTE_VALUE_SETTER(PropertyName) \
	UFUNCTION(BlueprintCallable, Category="Gameplay/Attribute") \
	GAMEPLAYATTRIBUTE_VALUE_INITTER(PropertyName)


// Delegate used to broadcast attribute events.
DECLARE_MULTICAST_DELEGATE_FourParams(FHiAttributeEvent, AActor* /*EffectInstigator*/, AActor* /*EffectCauser*/, const FGameplayEffectSpec& /*EffectSpec*/, float /*EffectMagnitude*/);


/**
* UHiAttributeSet
 *
 *	Base attribute set class for the project.
 */
UCLASS(Blueprintable)
class HIGAME_API UHiAttributeSet : public UAttributeSet
{
	GENERATED_BODY()
public:

	UHiAttributeSet();

	UWorld* GetWorld() const override;

	UFUNCTION(BlueprintCallable)
	UHiAbilitySystemComponent* GetHiAbilitySystemComponent() const;

	UFUNCTION(BlueprintPure)
	AActor* BP_GetOwningActor() const;

	UFUNCTION(BlueprintCallable)
	void BP_SetOwningActor(AActor* OwnerActor);

	/** Find attribute by name. */
	UFUNCTION(BlueprintCallable)
	FGameplayAttribute FindAttribute(FName Name);

	virtual void PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue) override;

	UFUNCTION(BlueprintNativeEvent)
	void OnPreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue);

	virtual void PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data) override;

	UFUNCTION(BlueprintNativeEvent)
	void OnPostGameplayEffectExecute(const FGameplayEffectSpec& EffectSpec, FGameplayModifierEvaluatedData& EvaluatedData, UAbilitySystemComponent *Target);

	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	virtual void BeginDestroy();

	/** Whether is common attribute **/
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	bool bCommonAttribute;
};
