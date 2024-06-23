// Fill out your copyright notice in the Description page of Project Settings.


#include "UI/UILogicSubSystem.h"

void UUILogicSubSystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	InitializeScript();
}


void UUILogicSubSystem::PostInitialize()
{
	UE_LOG(LogTemp, Log, TEXT("UUILogicSubSystem::PostInitialize %s"), *GetName());
	Super::PostInitialize();
	UWorld* World = GetWorld();
	check(World);
	World->OnWorldBeginPlay.AddUObject(this, &UUILogicSubSystem::OnWorldBeginPlayDelegate);
	PostInitializeScript();
}

void UUILogicSubSystem::Deinitialize()
{
	UE_LOG(LogTemp, Log, TEXT("UUILogicSubSystem::Deinitialize %s"), *GetName());
	DeinitializeScript();
}


void UUILogicSubSystem::OnWorldBeginPlayDelegate()
{
	UE_LOG(LogTemp, Log, TEXT("UUILogicSubSystem::OnWorldBeginPlay %s"), *GetName());
	OnWorldBeginPlayScript();
}