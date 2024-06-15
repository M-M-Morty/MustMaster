// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "InteractSystem.h"
#include "GameplayTagContainer.h"
#include "InteractItemComponent.generated.h"

class UInputAction;
class UCustomInteractExecutor;
class UGameplayAbility;
class UInteractWidget;
class UInteractManagerComponent;

UENUM(BlueprintType)
enum class EInteractActionType : uint8
{
	EIAT_Immediate = 0,
	EIAT_Delay = 1,
};

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnInteractStateChanged, EInteractItemState, OldState, EInteractItemState, NewState);


UCLASS(Blueprintable, ClassGroup=(Custom), meta=(BlueprintSpawnableComponent), AutoExpandCategories=(Range, UI, InteractAction) )
class HIGAME_API UInteractItemComponent : public USceneComponent
{
	friend class UInteractManagerComponent;
	friend struct FObserveComponentInfo;
	friend struct FFocusCandidateInfo;

	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UInteractItemComponent();

	FString GetDebugName() const;

protected:
	virtual void InitializeComponent() override;

	// Called when the game starts
	virtual void BeginPlay() override;

	// Called every frame only from UInteractManagerComponent!
	virtual void PassivelyTick(float DeltaTime);

	

public:
	UFUNCTION()
	virtual bool TryInteract(FInteractQueryParam QueryParam);

	UPROPERTY(BlueprintAssignable,Transient)
	FOnInteractStateChanged OnInteractStateChanged;
	EInteractItemState GetInteractState() { return InteractState; }
	virtual AActor* GetActor() const
	{
		return GetOwner();
	}

	void SetObserver(UInteractManagerComponent* Manager);

	UPROPERTY(BlueprintReadOnly,Transient)
		UInteractWidget* InteractWidget = 0;

protected:
	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|Range")
	float ScreenMarginBias = 0.f;

	virtual bool CanBeInteracted() const;
	virtual bool CanBeFocused() const;

	virtual float GetPromptRange() const { return PromptRange; }

	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|Range")
	float PromptRange = 500.f;

	virtual float GetFocusRange() const  { return FocusRange; }

	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|Range")
	float FocusRange = 200.f;

	UPROPERTY()
	UPrimitiveComponent* RangeCollision = 0;

	virtual void InitializeRangeCollision();

	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|Input")
	FName InputActionName = "InteractAction1";


	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|UI")
	TSubclassOf<UInteractWidget> InteractWidgetClass;

	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|InteractAction")
	EInteractAction InteractAction = EInteractAction::IA_None;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "InteractAction == EInteractAction::IA_SetLocoState"), Category = "InteractItemComponent|InteractAction")
	FGameplayTag LocoStateToSet;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "InteractAction == EInteractAction::IA_ActivateAbility"), Category = "InteractItemComponent|InteractAction")
	TSubclassOf<UGameplayAbility> AbilityClassToActivate;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "InteractAction == EInteractAction::IA_SendGameplayEventWithPayload"), Category = "InteractItemComponent|InteractAction")
	FGameplayTag GameplayEventToSend;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "InteractAction == EInteractAction::IA_CustomExecutor"), Category = "InteractItemComponent|InteractAction")
	TSubclassOf<UCustomInteractExecutor> CustomInteractExecutorClass;

	UPROPERTY(VisibleInstanceOnly)
	EInteractItemState InteractState = EInteractItemState::IIS_None;

	virtual void InternalSetInteractState(EInteractItemState NewState);

	virtual void QuitInteract();

public:
	UPROPERTY(EditAnywhere, Category = "InteractItemComponent|InteractActionType")
	EInteractActionType InteractActionType = EInteractActionType::EIAT_Immediate;

	UPROPERTY(BlueprintReadOnly)
	UInteractManagerComponent* Observer;
};
