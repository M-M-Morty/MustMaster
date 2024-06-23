// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyGroundedEntryState.h"

#include "Characters/HiLocomotionCharacter.h"
#include "Component/HiLocomotionComponent.h"


void UHiAnimNotifyGroundedEntryState::Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference)
{
	Super::Notify(MeshComp, Animation, EventReference);
	
	AActor* Character = MeshComp->GetOwner();
	if (!Character)
	{
		return;
	}
	UHiLocomotionComponent* LocomotionComponent = Cast<UHiLocomotionComponent>(Character->GetComponentByClass(UHiLocomotionComponent::StaticClass()));
	if (!LocomotionComponent)
	{
		return;
	}
	LocomotionComponent->SetGroundedEntryState(GroundedEntryState);
}

FString UHiAnimNotifyGroundedEntryState::GetNotifyName_Implementation() const
{
	FString Name(TEXT("Grounded Entry State: "));
	Name.Append(GetEnumerationValueString(GroundedEntryState));
	return Name;
}
