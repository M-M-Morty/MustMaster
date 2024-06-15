// Fill out your copyright notice in the Description page of Project Settings.


#include "Office/OfficeSubsystem.h"

#include "GameplayEntitySubsystem.h"
#include "Kismet/KismetSystemLibrary.h"

bool UOfficeSubsystem::ShouldCreateSubsystem(UObject* Outer) const
{
	
	return Super::ShouldCreateSubsystem(Outer);
}

void UOfficeSubsystem::PostInitialize()
{
	Super::PostInitialize();
	PostInitializeScript();
}

void UOfficeSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Collection.InitializeDependency(UGameplayEntitySubsystem::StaticClass());
	Super::Initialize(Collection);
}

bool UOfficeSubsystem::DoesSupportWorldType(const EWorldType::Type WorldType) const
{
	return WorldType == EWorldType::Game || WorldType == EWorldType::PIE;
}
