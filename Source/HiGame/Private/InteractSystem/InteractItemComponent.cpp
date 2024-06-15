// Fill out your copyright notice in the Description page of Project Settings.


#include "InteractSystem/InteractItemComponent.h"
#include "InteractSystem/InteractRangeComponent.h"
#include "InteractSystem/InteractSystem.h"
#include "InteractSystem/CustomInteractExecutor.h"
#include "InteractSystem/InteractWidget.h"
#include "Abilities/GameplayAbilityTypes.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "InteractSystem/UInteractExecutorInterface.h"
#include "Characters/HiPlayerController.h"
#include "Component/HiPawnComponent.h"
#include "InteractSystem/InteractManagerComponent.h"


// Sets default values for this component's properties
UInteractItemComponent::UInteractItemComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = false;

	//Mobility = EComponentMobility::Movable;
	bWantsInitializeComponent = true;
}

FString UInteractItemComponent::GetDebugName() const
{
	check(GetOwner());
	return FString::Printf(TEXT("%s.%s"), *GetOwner()->GetName(), *GetName());
}

void UInteractItemComponent::InitializeComponent()
{
	Super::InitializeComponent();

	InitializeRangeCollision();
}

// Called when the game starts
void UInteractItemComponent::BeginPlay()
{
	Super::BeginPlay();
	
	UpdateOverlaps();

	if (InteractWidgetClass)
	{
		if (!GetWorld()) return;
		InteractWidget = CreateWidget<UInteractWidget>(GetWorld()->GetFirstPlayerController(), InteractWidgetClass);
		if(InteractWidget)
		{
			InteractWidget->SetupAttachment(this);
			InteractWidget->SetHideMeWhenOutOfScreen(false /* UInteractManagerComponent does the show/hide logic!!! */);
			InteractWidget->AddToViewport();
		}
	}
}

// Called every frame
void UInteractItemComponent::PassivelyTick(float DeltaTime)
{
}

bool UInteractItemComponent::CanBeInteracted() const
{
	if (InteractAction == EInteractAction::IA_InterfaceImplement)
	{
		auto OwnerClass = GetOwner()->GetClass();

		if (OwnerClass->ImplementsInterface(UInteractExecutorInterface::StaticClass()))
		{
			return IInteractExecutorInterface::Execute_CanBeInteracted(GetOwner());
		}

		return false;
	}
	else
	{
		return true;
	}
}

bool UInteractItemComponent::CanBeFocused() const
{
	if (InteractAction == EInteractAction::IA_InterfaceImplement)
	{
		auto OwnerClass = GetOwner()->GetClass();

		if (OwnerClass->ImplementsInterface(UInteractExecutorInterface::StaticClass()))
		{
			return IInteractExecutorInterface::Execute_CanBeFocused(GetOwner());
		}

		return false;
	}
	else
	{
		return true;
	}
}

void UInteractItemComponent::InitializeRangeCollision()
{
	auto SphereCollision = NewObject<UInteractSphereRangeComponent>(this, "RangeCollision");
	if (!Cast<IInteractRangeInterface>(SphereCollision)) return;
	Cast<IInteractRangeInterface>(SphereCollision)->SetInteractItemComponent(this);
	SphereCollision->SetSphereRadius(FMath::Max(PromptRange, FocusRange));
	SphereCollision->SetCollisionProfileName("InteractRange");
	SphereCollision->RegisterComponent();
	SphereCollision->AttachToComponent(this, FAttachmentTransformRules::SnapToTargetIncludingScale);
	RangeCollision = SphereCollision;
}

void UInteractItemComponent::InternalSetInteractState(EInteractItemState NewState)
{
	auto OldState = InteractState;
	if (OldState != NewState)
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) interact state change: %s -> %s"), *GetDebugName(),
		       *UEnum::GetValueAsString(OldState), *UEnum::GetValueAsString(NewState));


		if (NewState == EInteractItemState::IIS_Interacting)
		{
			UE_LOG(LogInteractSystem, Log, TEXT("Interact ItemName:%s, Class:%s, Location:%s, Time:%lld"), *GetDebugName(),
			       *(StaticClass()->GetName()), *GetComponentLocation().ToCompactString(),
			       FDateTime::UtcNow().ToUnixTimestamp());
		}
		// Update State
		InteractState = NewState;

		OnInteractStateChanged.Broadcast(OldState, NewState);
		if (InteractWidget)
		{
			InteractWidget->OnInteractStateChanged(OldState, NewState);
		}
		
		if (OldState == EInteractItemState::IIS_Interacting && NewState == EInteractItemState::IIS_None)
		{
			if (InteractAction == EInteractAction::IA_InterfaceImplement)
			{
				check(IsInGameThread())
                auto MyClass = GetOwner()->GetClass();
				static UClass* InterfaceClass = UInteractExecutorInterface::StaticClass();
				if (MyClass->ImplementsInterface(InterfaceClass))                             // static binding
				{
					IInteractExecutorInterface::Execute_QuitInteract(GetOwner(), GetOwner(), this);
				}
			}
		}
	}
}

void UInteractItemComponent::QuitInteract()
{
	if (!GetWorld()) return;
	auto PC = Cast<AHiPlayerController>(GetWorld()->GetFirstPlayerController());
	if (!PC)
		return;

	if (PC->InteractManager->GetCurrentInteractingActor() == GetOwner())
		PC->InteractManager->QuitInteract();
}

bool UInteractItemComponent::TryInteract(FInteractQueryParam QueryParam)
{
	if (InteractState != EInteractItemState::IIS_Focus)
	{
		UE_LOG(LogInteractSystem, Error, TEXT("%s is not being focused (Current InteractState = %s), calling TryInteractWithMe() failed"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractState));
		return false;
	}

	switch (InteractAction)
	{
	case EInteractAction::IA_None:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction));
		return false;
	}

	case EInteractAction::IA_SendGameplayEventWithPayload:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s, GameplayEventTag = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction), *GameplayEventToSend.ToString());

		FGameplayEventData Payload;
		Payload.EventTag = GameplayEventToSend;
		Payload.OptionalObject = GetOwner();
		Payload.OptionalObject2 = this;
		UAbilitySystemBlueprintLibrary::SendGameplayEventToActor(QueryParam.InitiatePawn, GameplayEventToSend, Payload); //todo, also need to verify the ability was successfully activated! use ASC->TriggerAbilityFromGameplayEvent() instead???
		return true;
	}

	case EInteractAction::IA_CustomExecutor:
	{
		if (!CustomInteractExecutorClass)
		{
			UE_LOG(LogInteractSystem, Error, TEXT("%s's CustomInteractExecutorClass is not configured, calling TryInteractWithMe() failed"), *GetOwner()->GetName());
			return false;
		}

		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s, CustomExecutor = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction), *CustomInteractExecutorClass->GetName());

		return CustomInteractExecutorClass->GetDefaultObject<UCustomInteractExecutor>()->TryInteract(QueryParam, GetOwner(), this);
	}
	case EInteractAction::IA_InterfaceImplement:
	{
		check(IsInGameThread())
			auto MyClass = GetOwner()->GetClass();
		static UClass* InterfaceClass = UInteractExecutorInterface::StaticClass();
		if (MyClass->ImplementsInterface(InterfaceClass))                             // static binding
		{
			return IInteractExecutorInterface::Execute_TryInteract(GetOwner(), QueryParam, GetOwner(), this);
		}
		return false;
	}

	}

	return false;
}

void UInteractItemComponent::SetObserver(UInteractManagerComponent* Manager)
{
	Observer = Manager;
	if(InteractWidget)
	{
		auto WidgetTemp = Cast<UInteractWidget>(InteractWidget);
		if(!WidgetTemp) return;
		if(!Manager->OnInteractActionDelayTime.IsBound() || !WidgetTemp->IsBoundActionDelayTimeDelegate)
		{
			Manager->OnInteractActionDelayTime.AddDynamic(InteractWidget,&UInteractWidget::GetInteractTimeTickEvent);
			WidgetTemp->IsBoundActionDelayTimeDelegate = true;
		}
	}
}
