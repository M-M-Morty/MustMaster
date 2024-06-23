// Fill out your copyright notice in the Description page of Project Settings.


#include "InteractSystem/InteractWidgetUpdater.h"
#include "InteractSystem/InteractSystem.h"
#include "InteractSystem/InteractWidget.h"

AInteractWidgetUpdater* AInteractWidgetUpdater::Get(const UObject* WorldContextObject)
{
	check(WorldContextObject);

	auto World = WorldContextObject->GetWorld();

	if(!World)
		return 0;

	if (!World->IsGameWorld())
		return 0;

	AInteractWidgetUpdater* SingletonActor = 0;
	if (!World->PerModuleDataObjects.FindItemByClass<AInteractWidgetUpdater>(&SingletonActor))
	{
		UE_LOG(LogInteractSystem, Warning, TEXT("Cannot find existing AInteractWidgetUpdater in current world, will create a new AInteractWidgetUpdater in this world."));

		FActorSpawnParameters SpawnParam;
		SpawnParam.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		SpawnParam.Name = TEXT("InteractWidgetUpdater");
		SingletonActor = World->SpawnActor<AInteractWidgetUpdater>(StaticClass(), SpawnParam);
	}

	check(SingletonActor);
	return SingletonActor;
}

// Sets default values
AInteractWidgetUpdater::AInteractWidgetUpdater()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;
}

void AInteractWidgetUpdater::PostInitializeComponents()
{
	Super::PostInitializeComponents();

	/**
	 * elegant register to world, avoid ugly GetAllActorsFromClass(), independent from any global manager.
	 */
	{
		if (!GetWorld()) return;
		GetWorld()->PerModuleDataObjects.RemoveAll(
			[](UObject* Object)
		{
			return Object != nullptr && Object->IsA(AInteractWidgetUpdater::StaticClass());
		}
		);

		GetWorld()->PerModuleDataObjects.Add(this);
	}
}

// Called when the game starts or when spawned
void AInteractWidgetUpdater::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void AInteractWidgetUpdater::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	for (int i = 0; i < InteractWidgets.Num(); i++)
	{
		InteractWidgets[i]->RefreshLocation();
	}
}

void AInteractWidgetUpdater::RegisterNewInteractWidget(UInteractWidget* NewWidget)
{
	InteractWidgets.Add(NewWidget);
}

void AInteractWidgetUpdater::UnregisterInteractWidget(UInteractWidget* InWidget)
{
	InteractWidgets.Remove(InWidget);
}
