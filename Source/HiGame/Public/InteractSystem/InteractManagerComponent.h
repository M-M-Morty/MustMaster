// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "InteractSystem.h"
#include "InteractItemComponent.h"
#include "InteractManagerComponent.generated.h"

class AOasisCharacterBase;
class UInteractCharacterComponent;
class UInteractWidget;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnInteractActionDelayTime, float, CurActionDelay , float , TotalDurationTime);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnInteractActionDelaySuccess, UInteractItemComponent*, InteractComp);

USTRUCT(BlueprintType)
struct FObserveComponentInfo
{
	GENERATED_BODY()

	UPROPERTY(Transient)
	UInteractItemComponent* InteractItemComponent = nullptr;

	UPROPERTY()
	bool bOutOfObserveRange = false;

	FObserveComponentInfo() { InteractItemComponent = 0; bOutOfObserveRange = false; }
	FObserveComponentInfo(UInteractItemComponent* Component);

	void InternalSetInteractState(EInteractItemState NewState);
	float GetFocusRange() const;
	float GetPromptRange() const;
	float GetCustomScore() const;
	int32 GetGroup() const;
	FVector GetLocation() const;
	FORCEINLINE UInteractItemComponent* GetInteractItem() const
	{
		return InteractItemComponent;
	}

	bool operator==(const FObserveComponentInfo& rhs) const { return InteractItemComponent == rhs.InteractItemComponent; }
};

/*
	A component attached to PlayerController for interactive logics. This component maintains a interact item component list that player is interacting with.
	All interactive item (such as pickup, bonfire, tinder, rope, trap...) is an actor which should contains a UInteractItemComponent or subclass!
*/
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UInteractManagerComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UInteractManagerComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;



protected:
	UPROPERTY()
	UInputComponent* InputComponent = 0;



	/*
	* Prompt and Focus
	*/
public:
	UFUNCTION(BlueprintPure, Category = "InteractManager")
	AActor* GetFocusingActor() { return FocusingComponent->GetOwner(); }

	UFUNCTION(BlueprintPure, Category = "InteractManager")
	UInteractItemComponent* GetFocusingComponent() { return FocusingComponent; }


	UFUNCTION(BlueprintPure, Category = "InteractManager")
		TArray<FObserveComponentInfo> GetObserveComponents() {	return ObserveComponents;}

protected:
	void ForceRefreshObserveComponents();

	UFUNCTION()
	void OnPossessEvent(APawn* ThePawn, bool bPossess);

	UFUNCTION()
	void OnPawnBeginOverlapWithInteractItem(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult & SweepResult);

	UFUNCTION()
	void OnPawnEndOverlapWithInteractItem(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex);

	//TLOU style focusing, not necessary to watch for focus. A big angle diff is also acceptable, as long as the item is in screen.
	void UpdateObserveComponentsState();

	//We are initially ticking each observe components from here, not in each component's native tick.
	void TickObserveComponents(float DeltaTime);

	bool IsLocationInScreenMargin(FVector TestLocation, float ScreenMarginBias);

	void SetNewFocusingComponent(UInteractItemComponent* NewFocusingComponent);

	//all Components that are in the interact range.
	UPROPERTY()
	TArray<FObserveComponentInfo> ObserveComponents;

	//IInteractiveInterface actor which I'm focusing
	UPROPERTY()
	UInteractItemComponent* FocusingComponent = 0;



	/*
	* Interact
	*/
public:
	UFUNCTION(BlueprintCallable, Category = "InteractManager", meta = (WorldContext = "WorldContextObject"))
	static AActor* GetMainPawnCurrentInteractingActor(const UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, Category = "InteractManager", meta = (WorldContext = "WorldContextObject"))
	static UInteractItemComponent* GetMainPawnCurrentInteractingComponent(const UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, Category = "InteractManager")
	void ForceSetCurrentInteractingItem(UInteractItemComponent* NewInteractingComponent);

	UFUNCTION(BlueprintPure, Category = "InteractManager")
	AActor* GetCurrentInteractingActor();

	UFUNCTION(BlueprintPure, Category = "InteractManager")
	UInteractItemComponent* GetCurrentInteractingComponent();
	UFUNCTION()
	void OnInteractAction();
	void DoRealAction(UInteractItemComponent* InteractItemComponent);

	UFUNCTION(BlueprintCallable, Category = "InteractManager")
	void QuitInteract();

protected:
	UPROPERTY()
	UInteractItemComponent* CurrentInteractingComponent = 0;



	/*
	* JoeyTan add. For InteractCharacterComponent.
	*/
public:
	UFUNCTION()
	AHiCharacter* GetOwnerCharacter();

	UFUNCTION()
	FVector GetOwnerPos();

	UFUNCTION()
	FVector GetOwnerMoveDir();

protected:
	void UpdateOwnerPos();

private:
	FVector OwnerMoveDir;
	FVector OwnerPos;

	UPROPERTY()
	AHiCharacter* OwnerCharacterRef = 0;



	//Junejliu add. For delayed interaction.
public:
	void OnReleaseAction();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "InteractManagerComponent"/*, meta = (editcondition = "InteractActionType == EInteractActionType::EIAT_Delay", EditConditionHides)*/)
	float InteractDelayDuration = 0.4f;

	float InteractDelayTick = 0;

	UPROPERTY(BlueprintAssignable, BlueprintCallable)
	FOnInteractActionDelayTime OnInteractActionDelayTime;

	UPROPERTY(BlueprintAssignable, BlueprintCallable)
	FOnInteractActionDelaySuccess OnInteractActionDelaySuccess;

	UPROPERTY()
	UInteractItemComponent* NewInteractItem = 0;
};
