// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiTriggerAutoJumpComponent.h"

#include "GameFramework/CharacterMovementComponent.h"

// Sets default values for this component's properties
UHiTriggerAutoJumpComponent::UHiTriggerAutoJumpComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = false;

	CharactersArray.Reset();
	// ...
}


// Called when the game starts
void UHiTriggerAutoJumpComponent::BeginPlay()
{
	Super::BeginPlay();

	OnComponentActivated.AddUniqueDynamic(this, &UHiTriggerAutoJumpComponent::TriggerCharactersArrayAutoJump);
	// ...
	
}


// Called every frame
void UHiTriggerAutoJumpComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

void UHiTriggerAutoJumpComponent::AddInTriggerCharacter(AHiCharacter* Character)
{
	if (Character && Character->IsLocallyControlled() && CharactersArray.Find(Character) == -1)
	{
		CharactersArray.Add(Character);
		if (IsActive())
		{
			if (UCharacterMovementComponent* MoveComp = Character->GetCharacterMovement())
			{
				bool Trigger = MoveComp->MovementMode == MOVE_Falling || bWalkInAutoJump;
				Character->TriggerLandedAutoJump(Trigger, RootMotionScale, PlayRate);
			}
		}
	}
}

void UHiTriggerAutoJumpComponent::DelInTriggerCharacter(AHiCharacter* Character)
{
	if (Character && Character->IsLocallyControlled() && CharactersArray.Find(Character) != -1)
	{
		CharactersArray.Remove(Character);
	}
}

void UHiTriggerAutoJumpComponent::TriggerCharactersArrayAutoJump(UActorComponent* Component, bool bReset)
{
	for (AHiCharacter* Character : CharactersArray)
	{
		if (Character && Character->IsLocallyControlled())
		{
			if (UCharacterMovementComponent* MoveComp = Character->GetCharacterMovement())
			{
				bool Trigger = MoveComp->MovementMode == MOVE_Falling || bWalkInAutoJump;
				Character->TriggerLandedAutoJump(Trigger, RootMotionScale, PlayRate);
			}
		}
	}
}


