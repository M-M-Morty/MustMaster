// Fill out your copyright notice in the Description page of Project Settings.

#include "Sequence/HiLevelSequencePlayer.h"
#include "Sequence/HiLevelSequenceActor.h"
#include "GameFramework/CharacterMovementComponent.h"


/* UHiLevelSequencePlayer structors
 *****************************************************************************/

UHiLevelSequencePlayer::UHiLevelSequencePlayer(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	this->OnStop.AddDynamic(this, &UHiLevelSequencePlayer::OnStopCallback);
}

void UHiLevelSequencePlayer::IgnoreNetCorrection(UCharacterMovementComponent* MovementComponent)
{
	MovementComponent->bIgnoreClientMovementErrorChecksAndCorrection = 1;
	CachedMovementComponents.Add(MovementComponent);
}

void UHiLevelSequencePlayer::OnStopCallback()
{
	for (TWeakObjectPtr<UCharacterMovementComponent> MovementComponent : CachedMovementComponents)
	{
		if (MovementComponent.Get())
		{
			MovementComponent->bIgnoreClientMovementErrorChecksAndCorrection = 0;
		}
	}
	CachedMovementComponents.Reset();
}

ULevelSequencePlayer* UHiLevelSequencePlayer::CreateHiLevelSequencePlayer(UObject* WorldContextObject, ULevelSequence* InLevelSequence, FMovieSceneSequencePlaybackSettings Settings, ALevelSequenceActor*& OutActor)
{
	if (InLevelSequence == nullptr)
	{
		return nullptr;
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World == nullptr || World->bIsTearingDown)
	{
		return nullptr;
	}

	FActorSpawnParameters SpawnParams;
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	SpawnParams.ObjectFlags |= RF_Transient;
	SpawnParams.bAllowDuringConstructionScript = true;

	// Defer construction for autoplay so that BeginPlay() is called
	SpawnParams.bDeferConstruction = true;

	AHiLevelSequenceActor* Actor = World->SpawnActor<AHiLevelSequenceActor>(SpawnParams);

	Actor->PlaybackSettings = Settings;
	Actor->SequencePlayer->SetPlaybackSettings(Settings);

	Actor->SetSequence(InLevelSequence);

	Actor->InitializePlayer();
	OutActor = Cast<ALevelSequenceActor>(Actor);

	FTransform DefaultTransform;
	Actor->FinishSpawning(DefaultTransform);

	return Actor->SequencePlayer;
}
