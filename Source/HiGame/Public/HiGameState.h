// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameFramework/GameStateBase.h"
#include "GameFramework/PartialWorldGameStateBase.h"
#include "HiGameState.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API AHiGameState : public APartialWorldGameStateBase
{
	GENERATED_BODY()

public:
	AHiGameState(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual void FinishDestroy() override;

	virtual void PostNetInit() override;
	virtual void PostNetReceive() override;

	UFUNCTION(BlueprintCallable, Category="Gameplay|GameState|Timer")
	void ClearTimerHandle(const UObject* WorldContextObject, FTimerHandle Handle);

	UFUNCTION(BlueprintCallable, Category="Gameplay|GameState|Timer")
	void ClearAndInvalidateTimerHandle(const UObject* WorldContextObject, FTimerHandle& Handle);

	UFUNCTION(BlueprintCallable, Category="Gameplay|GameState|Timer")
	FTimerHandle SetTimerDelegate(UPARAM(DisplayName="Event") FTimerDynamicDelegate Delegate, float Time, bool bLooping, float InitialStartDelay = 0.f, float InitialStartDelayVariance = 0.f);

	UFUNCTION(BlueprintCallable, Category="Gameplay|GameState|Timer")
	FTimerHandle SetTimerForNextTickDelegate(UPARAM(DisplayName = "Event") FTimerDynamicDelegate Delegate);

	UFUNCTION(BlueprintCallable, Category="Gameplay|GameState|Timer")
	float GetDeltaRealTimeSeconds() const { return DeltaRealTimeSeconds; }

	inline FTimerManager& GetTimerManager() const
	{
		return *TimerManager;
	}
	
protected:
	void OnWorldPreActorTick(UWorld* InWorld, ELevelTick InLevelTick, float InDeltaSeconds);
	
	FDelegateHandle OnWorldPreActorTickHandle;
	FTimerManager* TimerManager;
	float DeltaRealTimeSeconds;
	
};
