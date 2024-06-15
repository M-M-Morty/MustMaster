// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "InteractSystem.h"
#include "InteractItemComponent.h"
#include "GameplayTagContainer.h"
#include "InteractCharacterComponent.generated.h"

class UCustomInteractExecutor;
class UGameplayAbility;
class UInteractWidget;
class USphereComponent;
class AOasisCharacterBase;
class UInteractManagerComponent;

UCLASS(ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class HIGAME_API UInteractCharacterComponent : public UInteractItemComponent
{
	friend class UInteractManagerComponent;
	friend struct FObserveComponentInfo;
	friend struct FFocusCandidateInfo;

	GENERATED_BODY()

	//DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnInteractStateChanged, EInteractItemState, OldState, EInteractItemState, NewState);

public:	
	// Sets default values for this component's properties
	UInteractCharacterComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;
	virtual void PassivelyTick(float DeltaTime) override;

public:
	virtual float GetFocusRange() const override;
	virtual bool CanBeInteracted() const override;

	//UFUNCTION()
	//float GetPriority() const override;

protected:
	//virtual bool TryInteractInternal(const FInteractQueryParam& QueryParam) const override;
	void UpdateFocusRange();

	class AHiCharacter* OCharacterRef;

	UPROPERTY(Transient)
	float CurFocusRange;

	UPROPERTY(Transient)
	float LastUpdateTime;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	float MinFocusRangeUpdateFreq;
};
