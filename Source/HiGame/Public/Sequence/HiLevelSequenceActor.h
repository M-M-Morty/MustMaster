// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "LevelSequenceActor.h"
#include "HiLevelSequenceActor.generated.h"

/**
 * 
 */
UCLASS(BlueprintType)
class HIGAME_API AHiLevelSequenceActor : public ALevelSequenceActor
{

public:
	GENERATED_BODY()

	/** Create and initialize a new instance. */
	AHiLevelSequenceActor(const FObjectInitializer& Init);

protected:

	//~ Begin IMovieScenePlaybackClient interface
	virtual bool RetrieveBindingOverrides(const FGuid& InBindingId, FMovieSceneSequenceID InSequenceID, TArray<UObject*, TInlineAllocator<1>>& OutObjects) const override;
	//~ End IMovieScenePlaybackClient interface
};