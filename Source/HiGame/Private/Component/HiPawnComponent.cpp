// Copyright Epic Games, Inc. All Rights Reserved.

#include "Component/HiPawnComponent.h"
#include "Characters/HiCharacter.h"


UHiPawnComponent::UHiPawnComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bCanEverTick = false;
}

void UHiPawnComponent::InitializeComponent()
{
	Super::InitializeComponent();
	if (AHiCharacter * Character = Cast<AHiCharacter>(GetOwner()))
	{
		Character->RegisterPossessCallback(this);
	}
}

void UHiPawnComponent::OnPossessedBy_Implementation(AController* NewController)
{
	
}

void UHiPawnComponent::OnUnPossessedBy_Implementation(AController* NewController)
{
	
}