// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/GameFrameworkComponent.h"
#include "GameplayEffectTypes.h"
#include "HiAttributeComponent.generated.h"

/**
  * UHiAttributeComponent
  *
  *	An actor component base class used to handle anything related to attribute set.
 */

class UGameplayAbility;
class UHiAttributeSet;
class UHiAbilitySystemComponent;

//DECLARE_DYNAMIC_MULTICAST_DELEGATE_FourParams(FHi_AttributeChanged, UHiAttributeComponent*, AttributeComponent, float, OldValue, float, NewValue, AActor*, Instigator);

UCLASS(Blueprintable, Meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiAttributeComponent : public UGameFrameworkComponent
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = Attribute)
	TArray<FGameplayAttribute> AttributesToListenFor;
	
public:
	UHiAttributeComponent(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintCallable, Category="Gameplay|AttributeSet")
	static UHiAttributeComponent* FindHiAttributeComponent(const AActor* Actor) { return (Actor ? Actor->FindComponentByClass<UHiAttributeComponent>() : nullptr);}

	// Initialize the component using an ability system component.
    UFUNCTION(BlueprintCallable, Category = "Gameplay|AttributeSet")
    void InitializeWithAbilitySystem(UHiAbilitySystemComponent* InASC);

	// Uninitialize the component, clearing any references to the ability system.
	UFUNCTION(BlueprintCallable, Category = "Gameplay|AttributeSet")
	void UninitializeFromAbilitySystem();
	
	UFUNCTION(BlueprintCallable, Category="Ability")
	void InitAttributeListener();
	UFUNCTION(BlueprintCallable, Category="Ability")
	void RemoveAttributeListener();

	void HandleAttributeChange(const FOnAttributeChangeData& Data);
	void HandleAbilityFailed(const UGameplayAbility* Ability, const FGameplayTagContainer& FailureReason);
	
	
protected:
	virtual  void OnUnregister() override;

	void ClearGameplayTags();

protected:
	// Ability system used by this component.
	UPROPERTY()
	UHiAbilitySystemComponent* AbilitySystemComponent;

};
