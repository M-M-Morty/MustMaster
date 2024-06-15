// Fill out your copyright notice in the Description page of Project Settings.


#include "HiEditorTickActor.h"

// Sets default values
AHiEditorTickActor::AHiEditorTickActor(const FObjectInitializer& ObjectInitializer):
				Super(ObjectInitializer)
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
#if WITH_EDITOR
	PrimaryActorTick.bCanEverTick = true;
#endif
}

bool AHiEditorTickActor::ShouldTickIfViewportsOnly() const
{
#if WITH_EDITOR
	if (GetWorld() != nullptr && bUseEditorTick)
	{
		return true;
	}
	else
	{
		return false;
	}
#else
	return Super::ShouldTickIfViewportsOnly();
#endif
}

// Called every frame
void AHiEditorTickActor::Tick(float DeltaTime)
{

#if WITH_EDITOR
	if (GetWorld() != nullptr  && bUseEditorTick)
	{
		EditorTick(DeltaTime);
	}
	else
#endif
	{
		Super::Tick(DeltaTime);	
	}
}
#if WITH_EDITOR
void AHiEditorTickActor::EditorTick(float DeltaTime)
{
}
#endif