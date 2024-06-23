// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "LevelSequencePlayer.h"
#include "HiLevelSequencePlayer.generated.h"

class UCharacterMovementComponent;

/**
 * 
 */
UCLASS(BlueprintType)
class HIGAME_API UHiLevelSequencePlayer : public ULevelSequencePlayer
{
public:
	UHiLevelSequencePlayer(const FObjectInitializer&);

	GENERATED_BODY()

	/**
	 * Create a new level sequence player.
	 *
	 * @param WorldContextObject Context object from which to retrieve a UWorld.
	 * @param LevelSequence The level sequence to play.
	 * @param Settings The desired playback settings
	 * @param OutActor The level sequence actor created to play this sequence.
	 */
	UFUNCTION(BlueprintCallable, Category = "Sequencer|Player", meta = (WorldContext = "WorldContextObject", DynamicOutputParam = "OutActor"))
	static ULevelSequencePlayer* CreateHiLevelSequencePlayer(UObject* WorldContextObject, ULevelSequence* LevelSequence, FMovieSceneSequencePlaybackSettings Settings, ALevelSequenceActor*& OutActor);

	void IgnoreNetCorrection(UCharacterMovementComponent* MovementComponent);

private:
	UFUNCTION()
	void OnStopCallback();

private:
	TArray<TWeakObjectPtr<UCharacterMovementComponent>> CachedMovementComponents;
};