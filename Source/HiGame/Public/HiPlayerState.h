// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerState.h"
#include "AbilitySystemInterface.h"
#include "PartialWorldPlayerState.h"
#include "Attributies/HiAttributeSet.h"
#include "HiPlayerState.generated.h"

/**
 * 
 */

class AActor;
 
UCLASS()
class HIGAME_API AHiPlayerState : public APartialWorldPlayerState
{
	GENERATED_BODY()

public:
	AHiPlayerState();

	virtual void PreInitializeComponents() override;

	UFUNCTION(BlueprintImplementableEvent)
	void K2_PreInitializeComponents();

	virtual void BeginPlay() override;
	
	/** Add AttributeSet common to all roles of player **/
	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	void AddAttributeSet(UHiAttributeSet* InAttributeSet);

	/** AttributeSets for all roles of player **/
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated, ReplicatedUsing = OnRep_AttributeSets, Category="HiPlayerState", meta = (AllowPrivateAccess = "true"))
	TArray<TObjectPtr<UHiAttributeSet>> AttributeSets;

	UFUNCTION(BlueprintImplementableEvent)
	void OnPawnSetCallback(APlayerState* Player, APawn* NewPawn, APawn* OldPawn);

	UFUNCTION(BlueprintImplementableEvent)
	void OnRep_AttributeSets();

	UFUNCTION(BlueprintCallable)
	FString GenerateActorID();
	
	UFUNCTION(Client, Reliable)
	void OnTransferToSpace(int32 InSpaceID);

	UFUNCTION(BlueprintImplementableEvent)
	void K2_OnTransferToSpace(int32 InSpaceID);

	virtual void PostTransfer() override;
};
