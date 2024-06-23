// Fill out your copyright notice in the Description page of Project Settings.

#include "Sequence/HiLevelSequenceActor.h"
#include "Sequence/HiLevelSequencePlayer.h"
#include "GameFramework/Character.h"


AHiLevelSequenceActor::AHiLevelSequenceActor(const FObjectInitializer& Init)
	: Super(Init.SetDefaultSubobjectClass<UHiLevelSequencePlayer>("AnimationPlayer"))
{
}

bool AHiLevelSequenceActor::RetrieveBindingOverrides(const FGuid& InBindingId, FMovieSceneSequenceID InSequenceID, TArray<UObject*, TInlineAllocator<1>>& OutObjects) const
{
	bool bRet = Super::RetrieveBindingOverrides(InBindingId, InSequenceID, OutObjects);
	
	for (UObject* Object : OutObjects)
	{
		if (ACharacter* BindingCharacter = Cast<ACharacter>(Object))
		{
			if (BindingCharacter->HasAuthority() && BindingCharacter->GetMovementComponent())
			{
				UCharacterMovementComponent* MovementComponent = Cast<UCharacterMovementComponent>(BindingCharacter->GetMovementComponent());
				if (MovementComponent)
				{
					UHiLevelSequencePlayer* HiSequencePlayer = Cast<UHiLevelSequencePlayer>(SequencePlayer);
					check(HiSequencePlayer);
					HiSequencePlayer->IgnoreNetCorrection(MovementComponent);
				}
			}
		}
	}
	return bRet;
}
