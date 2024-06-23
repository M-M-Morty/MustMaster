// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiAIComponent.h"
#include "Engine/EngineTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Component/HiAbilitySystemComponent.h"
#include "GameplayTagsManager.h"
#include "Characters/HiCharacter.h"

// PRAGMA_DISABLE_OPTIMIZATION

UHiAIComponent::UHiAIComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bCanEverTick = false;
	SetIsReplicatedByDefault(true);
}

void UHiAIComponent::OnRegister()
{
	Super::OnRegister();

	const APawn* Pawn = GetPawn<APawn>();
	ensureAlwaysMsgf((Pawn != nullptr), TEXT("HiAIComponent on [%s] can only be added to Pawn Actors."), *GetNameSafe(GetOwner()));

	TArray<UActorComponent*> AIComponents;
	Pawn->GetComponents(UHiAIComponent::StaticClass(), AIComponents);
	// LevelSequence convert to spawnable will created another trash component
	ensureAlwaysMsgf(
		AIComponents.Num() == 1 ||
		(AIComponents.Num() == 2 && AIComponents[0]->GetName().Find(TEXT("TRASH_")) != INDEX_NONE),
		TEXT("Only one UHiAIComponent should exist on [%s]."), *GetNameSafe(GetOwner())
	);
}

void UHiAIComponent::CreateMountActor(TSubclassOf<AHiMountActor> MountClass, FName AttachSocketName)
{
	APawn* Pawn = GetPawn<APawn>();
	if (!IsValid(Pawn))
		return;
	
	auto const SourceActor = Cast<AActor>(Pawn);
	if (!IsValid(SourceActor))
		return;
	
	auto const World = SourceActor->GetWorld(); 
	auto const Location = SourceActor->GetActorLocation();
	auto const Rotation = SourceActor->GetActorRotation();
		
	AHiMountActor* MountActor = Cast<AHiMountActor>(World->SpawnActor(*MountClass, &Location, &Rotation));
	if (!IsValid(MountActor))
	{
		return;
	}

	auto const Character = Cast<AHiCharacter>(Pawn);
		
	// MountActor->Identity = Character->Identity;
	MountActor->SourceActor = SourceActor;
		
	auto const SnapToTarget = EAttachmentRule::SnapToTarget;
	MountActor->K2_AttachToComponent(Character->GetMesh(), AttachSocketName, SnapToTarget, SnapToTarget, SnapToTarget, true);

	MountActors.Add(MountActor);
}

void UHiAIComponent::AddMountActor(AActor* Actor)
{
	AHiMountActor* MountActor = Cast<AHiMountActor>(Actor);
	if (!IsValid(MountActor))
	{
		return;
	}

	MountActors.Add(MountActor);
}

void UHiAIComponent::DestroyAllMountActor()
{
	int8_t MaxLoop = 127;
	while (MountActors.Num() > 0 && MaxLoop > 0)
	{
		MountActors[0]->Destroy();
		--MaxLoop;
	}
}

void UHiAIComponent::OnMountActorDestroyed(AHiMountActor* MountActor)
{
	BP_OnMountActorDestroyed(MountActor);
	MountActors.Remove(MountActor);
}
