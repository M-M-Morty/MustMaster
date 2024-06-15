// Fill out your copyright notice in the Description page of Project Settings.


#include "InteractSystem/InteractManagerComponent.h"
#include "InteractSystem/InteractSystem.h"
#include "InteractSystem/InteractItemComponent.h"
#include "InteractSystem/InteractWidget.h"
#include "InteractSystem/InteractItemComponent.h"
#include "InteractSystem/InteractRangeComponent.h"
#include "InteractSystem/InteractCharacterComponent.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "DrawDebugHelpers.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "EnhancedInputSubsystems.h"
#include "Characters/HiPlayerController.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/InputSettings.h"
#include "GameFramework/PawnMovementComponent.h"

FObserveComponentInfo::FObserveComponentInfo(UInteractItemComponent* Component)
{
	InteractItemComponent = Component;
	bOutOfObserveRange = false;
}

void FObserveComponentInfo::InternalSetInteractState(EInteractItemState NewState)
{
	InteractItemComponent->InternalSetInteractState(NewState);
}

float FObserveComponentInfo::GetFocusRange() const
{
	if (InteractItemComponent)
	{
		return InteractItemComponent->GetFocusRange();
	}

	return 0.0f;
}

float FObserveComponentInfo::GetPromptRange() const
{
	if (InteractItemComponent)
	{
		return InteractItemComponent->GetPromptRange();
	}

	return 0.0f;
}

int32 FObserveComponentInfo::GetGroup() const
{
	/*if (InteractItemComponent)
	{
		return InteractItemComponent->GetGroup();
	}*/

	return 0;
}

FVector FObserveComponentInfo::GetLocation() const
{
	if (InteractItemComponent)
	{
		return InteractItemComponent->GetComponentLocation();
	}

	return FVector::ZeroVector;
}


struct FFocusCandidateInfo
{
	UInteractItemComponent* InteractItemComponent = 0;
	float Distance = 0.f;

	FFocusCandidateInfo(const FObserveComponentInfo& InObserveComponentInfo, const float InDistance)
	{
		InteractItemComponent = InObserveComponentInfo.InteractItemComponent;
		Distance = InDistance;
	}

	FVector GetInteractLocation()
	{
		if (InteractItemComponent)
		{
			return InteractItemComponent->GetComponentLocation();
		}

		return FVector::ZeroVector;
	}

	void InternalSetInteractState(EInteractItemState NewState)
	{
		if (InteractItemComponent)
		{
			InteractItemComponent->InternalSetInteractState(NewState);
		}
	}

	float GetFocusRange()
	{
		if (InteractItemComponent)
		{
			return InteractItemComponent->GetFocusRange();
		}

		return 0.0f;
	}

	float GetPromptRange()
	{
		if (InteractItemComponent)
		{
			return InteractItemComponent->GetPromptRange();
		}

		return 0.0f;
	}
};

// Sets default values for this component's properties
UInteractManagerComponent::UInteractManagerComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UInteractManagerComponent::BeginPlay()
{
	Super::BeginPlay();

	auto OwnerController = Cast<AHiPlayerController>(GetOwner());
	check(OwnerController);

	if (OwnerController->IsLocalController())
	{
		//create my own InputComponent
		{
			InputComponent = NewObject<UInputComponent>(this, UInputSettings::GetDefaultInputComponentClass(), "InteractManagerInputComponent", RF_Transient);
			InputComponent->bBlockInput = false;
			InputComponent->Priority = 100;
			InputComponent->RegisterComponent();
			OwnerController->PushInputComponent(InputComponent);
		}

		OwnerController->OnPossessEvent.AddDynamic(this, &UInteractManagerComponent::OnPossessEvent);		
		
		auto OwnerPawn = OwnerController->GetPawn();
		if (OwnerPawn)
		{
			OnPossessEvent(OwnerPawn, true);

			//OwnerPawn->InputComponent->BindAction("Interact", IE_Pressed, this, &UInteractManagerComponent::OnInteractAction);			
			//OwnerPawn->InputComponent->BindAction("Interact", IE_Released, this, &UInteractManagerComponent::OnReleaseAction);

			OwnerCharacterRef = Cast<AHiCharacter>(OwnerPawn);
		}
	}
}

// Called every frame
void UInteractManagerComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	UpdateOwnerPos();

	//if (!CurrentInteractingComponent) //only when not interacting, should we do update
	{
		UpdateObserveComponentsState();
		TickObserveComponents(DeltaTime);
	}

	if (InteractDelayTick > 0)
	{
		InteractDelayTick -= DeltaTime;
		OnInteractActionDelayTime.Broadcast(InteractDelayDuration - InteractDelayTick, InteractDelayDuration);
		UE_LOG(LogInteractSystem, Warning, TEXT("Time is %f"),InteractDelayDuration - InteractDelayTick);
		if (InteractDelayTick <= 0 && FocusingComponent)
		{
			DoRealAction(NewInteractItem);
		}
	}
}

void UInteractManagerComponent::UpdateObserveComponentsState()
{
	auto OwnerController = Cast<APlayerController>(GetOwner());
	check(OwnerController);

	auto OwnerCharacter = Cast<AHiCharacter>(OwnerController->GetPawn());
	if (!OwnerCharacter) //consider [Simulate]
		return;

	FVector PawnLocation = OwnerCharacter->GetActorLocation();

	//Step 1, let's filter certain IIS_None & IIS_Prompt.
	TArray<FFocusCandidateInfo> FocusCandidates;

	for (int i = ObserveComponents.Num() - 1; i >= 0; i--)
	{
		if (!ObserveComponents[i].InteractItemComponent)
		{
			continue;
		}

		if (ObserveComponents[i].bOutOfObserveRange)
		{
			FString TheName = ObserveComponents[i].InteractItemComponent->GetDebugName();
			ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_None);
			ObserveComponents.RemoveAt(i);
			UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) has been removed from observe list due to out of range."), *TheName);
			continue;
		}

		FVector InteractLocation = ObserveComponents[i].GetLocation();
		float Distance = FVector::Distance(PawnLocation, InteractLocation);

		if (ObserveComponents[i].InteractItemComponent->CanBeInteracted())
		{
			if (ObserveComponents[i].InteractItemComponent->CanBeFocused() && Distance <= ObserveComponents[i].GetFocusRange())
			{
				if (IsLocationInScreenMargin(InteractLocation, ObserveComponents[i].InteractItemComponent->ScreenMarginBias))
				{
					FocusCandidates.Add(FFocusCandidateInfo(ObserveComponents[i], Distance));
				}
				else
				{
					ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_None);
				}
			}
			else if (Distance <= ObserveComponents[i].GetPromptRange())
			{
				if (IsLocationInScreenMargin(InteractLocation, ObserveComponents[i].InteractItemComponent->ScreenMarginBias))
				{
					ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_Prompt);
				}
				else
				{
					ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_None);
				}
			}
			else
			{
				ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_None);
			}
		}
		else
		{
			ObserveComponents[i].InternalSetInteractState(EInteractItemState::IIS_None);
		}
	}

	//Step 2, let's filter FocusCandidates
	int CandidateNum = FocusCandidates.Num();

	UInteractItemComponent* NewFocusingComponent = nullptr;

	if (CandidateNum > 1)
	{
		int BestFocusingItemIndex = -1;

		FVector CamLoc;
		FRotator CamRot;
		
		if(GetWorld() && GetWorld()->GetFirstPlayerController())
		{
			GetWorld()->GetFirstPlayerController()->GetPlayerViewPoint(CamLoc, CamRot);
		}

		float BestFocusingCos = -1.f;

		for (int i = 0; i < FocusCandidates.Num(); i++)
		{
			FVector InteractLocation = FocusCandidates[i].GetInteractLocation();

			FVector CamVec = CamRot.Vector();
			FVector ItemVec = (InteractLocation - PawnLocation /*CamLoc*/).GetSafeNormal();

			float ThisAngleCos = CamVec | ItemVec;
			if (
				(BestFocusingItemIndex >= 0 && ThisAngleCos > BestFocusingCos) ||
				BestFocusingItemIndex < 0
				)
			{
				BestFocusingItemIndex = i;
				BestFocusingCos = ThisAngleCos;
			}
		}

		NewFocusingComponent = FocusCandidates[BestFocusingItemIndex].InteractItemComponent;
	}
	else if (CandidateNum == 1)
	{
		NewFocusingComponent = FocusCandidates[0].InteractItemComponent;
	}

	//Step 3, 
	for (int i = 0; i < CandidateNum; i++)
	{
		if (FocusCandidates[i].InteractItemComponent == NewFocusingComponent)
		{
			FocusCandidates[i].InternalSetInteractState(EInteractItemState::IIS_Focus);
		}
		else
		{
			if (FocusCandidates[i].Distance <= FocusCandidates[i].GetPromptRange())
			{
				FocusCandidates[i].InternalSetInteractState(EInteractItemState::IIS_Prompt);
			}
			else
			{
				FocusCandidates[i].InternalSetInteractState(EInteractItemState::IIS_None);
			}
		}
	}

	//Step 4, update FocusingComponent
	SetNewFocusingComponent(NewFocusingComponent);
}

void UInteractManagerComponent::TickObserveComponents(float DeltaTime)
{
	for (auto& Component : ObserveComponents)
	{
		if (Component.InteractItemComponent)
			Component.InteractItemComponent->PassivelyTick(DeltaTime);
	}
}

bool UInteractManagerComponent::IsLocationInScreenMargin(FVector TestLocation, float ScreenMarginBias)
{
	auto PC = Cast<APlayerController>(GetOwner());
	check(PC);

	FVector2D ScreenLocation;
	if (!PC->ProjectWorldLocationToScreen(TestLocation, ScreenLocation))
		return false;

	auto ViewportSize = UWidgetLayoutLibrary::GetViewportSize(GetWorld());

	return (
		(ScreenLocation.X >= -ScreenMarginBias && ScreenLocation.X <= ViewportSize.X + ScreenMarginBias) &&
		(ScreenLocation.Y >= -ScreenMarginBias && ScreenLocation.Y <= ViewportSize.Y + ScreenMarginBias)
		);
}

void UInteractManagerComponent::SetNewFocusingComponent(UInteractItemComponent* NewFocusingComponent)
{
	if (NewFocusingComponent != FocusingComponent)
	{
		if (!(FocusingComponent && NewFocusingComponent && FocusingComponent->InputActionName == NewFocusingComponent->InputActionName))
		{
			if (FocusingComponent)
			{
				InputComponent->RemoveActionBinding(FocusingComponent->InputActionName, EInputEvent::IE_Pressed);
				UE_LOG(LogInteractSystem, Verbose, TEXT("Removed action binding (%s)"), *FocusingComponent->InputActionName.ToString());
			}

			if (NewFocusingComponent)
			{
				InputComponent->BindAction(NewFocusingComponent->InputActionName, EInputEvent::IE_Pressed, this, &UInteractManagerComponent::OnInteractAction);
				UE_LOG(LogInteractSystem, Verbose, TEXT("Add action binding (%s)"), *NewFocusingComponent->InputActionName.ToString());
			}
		}

		UE_LOG(LogInteractSystem, Verbose, TEXT("Focusing component changed: (%s -> %s)"), (FocusingComponent ? *FocusingComponent->GetDebugName() : TEXT("Null")), (NewFocusingComponent ? *NewFocusingComponent->GetDebugName() : TEXT("Null")));
		FocusingComponent = NewFocusingComponent;
	}
}

void UInteractManagerComponent::ForceRefreshObserveComponents()
{
	UE_LOG(LogInteractSystem, Verbose, TEXT("ForceRefreshObserveComponents() begin..."));

	if (!Cast<APlayerController>(GetOwner())) return;
	auto Character = Cast<ACharacter>(Cast<APlayerController>(GetOwner())->GetPawn());
	if (Character)
	{
		//clear the array
		ObserveComponents.Reset();

		//rebuild the observe actors
		TArray<UPrimitiveComponent*> OverlappingComponents;
		Character->GetCapsuleComponent()->GetOverlappingComponents(OverlappingComponents);
		for (auto& Component : OverlappingComponents)
		{
			if (Component && Component->GetClass()->ImplementsInterface(UInteractRangeInterface::StaticClass()))
			{
				if (!Cast<IInteractRangeInterface>(Component)) return;
				UInteractItemComponent* InteractItemComponent = Cast<IInteractRangeInterface>(Component)->GetInteractItemComponent();
				UE_LOG(LogInteractSystem, Verbose, TEXT("Pawn initially overlap with an interactive actor (%s), add it into observe list!"), *InteractItemComponent->GetDebugName());
				ObserveComponents.AddUnique(FObserveComponentInfo(InteractItemComponent));
				InteractItemComponent->SetObserver(this);
			}
		}
	}

	UE_LOG(LogInteractSystem, Verbose, TEXT("ForceRefreshObserveComponents() done!!!"));
}

void UInteractManagerComponent::OnPossessEvent(APawn* ThePawn, bool bPossess)
{
	if (bPossess)
	{
		ForceRefreshObserveComponents();

		auto Character = Cast<AHiCharacter>(ThePawn);
		check(Character);
		Character->GetCapsuleComponent()->OnComponentBeginOverlap.AddUniqueDynamic(this, &UInteractManagerComponent::OnPawnBeginOverlapWithInteractItem);
		Character->GetCapsuleComponent()->OnComponentEndOverlap.AddUniqueDynamic(this, &UInteractManagerComponent::OnPawnEndOverlapWithInteractItem);
	}
}

void UInteractManagerComponent::OnPawnBeginOverlapWithInteractItem(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult & SweepResult)
{
	if (OtherComp && OtherComp->GetClass()->ImplementsInterface(UInteractRangeInterface::StaticClass()))
	{
		if (!Cast<IInteractRangeInterface>(OtherComp)) return;
		UInteractItemComponent* InteractItemComponent = Cast<IInteractRangeInterface>(OtherComp)->GetInteractItemComponent();

		UE_LOG(LogInteractSystem, Verbose, TEXT("Pawn begin overlap with an interactive actor (%s)!"), *InteractItemComponent->GetDebugName());

		int FindIndex;
		if (ObserveComponents.Find(FObserveComponentInfo(InteractItemComponent), FindIndex))
		{
			ObserveComponents[FindIndex].bOutOfObserveRange = false;
			UE_LOG(LogInteractSystem, Verbose, TEXT("Element already exist in observe list, only mark bOutOfObserveRange = false!"));
		}
		else
		{
			ObserveComponents.Add(FObserveComponentInfo(InteractItemComponent));
			UE_LOG(LogInteractSystem, Verbose, TEXT("Add to observe list!"));
		}

		InteractItemComponent->SetObserver(this);
	}
}

void UInteractManagerComponent::OnPawnEndOverlapWithInteractItem(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex)
{
	if (OtherComp && OtherComp->GetClass()->ImplementsInterface(UInteractRangeInterface::StaticClass()))
	{
		if (!Cast<IInteractRangeInterface>(OtherComp)) return;
		UInteractItemComponent* InteractItemComponent = Cast<IInteractRangeInterface>(OtherComp)->GetInteractItemComponent();

		UE_LOG(LogInteractSystem, Verbose, TEXT("Pawn end overlap with an interactive actor (%s)!"), *InteractItemComponent->GetDebugName());

		int FindIndex;
		if (ObserveComponents.Find(FObserveComponentInfo(InteractItemComponent), FindIndex))
		{
			ObserveComponents[FindIndex].bOutOfObserveRange = true;
			UE_LOG(LogInteractSystem, Verbose, TEXT("Mark bOutOfObserveRange = true, will be removed in next cycle!"));
		}
		else
		{
			UE_LOG(LogInteractSystem, Error, TEXT("Not in ObserveComponents, this is abnormal!"));
		}
	}
}

AActor* UInteractManagerComponent::GetMainPawnCurrentInteractingActor(const UObject* WorldContextObject)
{
	check(WorldContextObject);
	UWorld* World = WorldContextObject->GetWorld();
	check(World);

	auto OwnerController = Cast<AHiPlayerController>(World->GetFirstPlayerController());
	check(OwnerController && OwnerController->InteractManager);

	return OwnerController->InteractManager->GetCurrentInteractingActor();
}

UInteractItemComponent* UInteractManagerComponent::GetMainPawnCurrentInteractingComponent(const UObject* WorldContextObject)
{
	check(WorldContextObject);
	UWorld* World = WorldContextObject->GetWorld();
	check(World);

	auto OwnerController = Cast<AHiPlayerController>(World->GetFirstPlayerController());
	check(OwnerController && OwnerController->InteractManager);

	return OwnerController->InteractManager->GetCurrentInteractingComponent();
}

void UInteractManagerComponent::ForceSetCurrentInteractingItem(UInteractItemComponent* NewInteractingComponent)
{
	check(NewInteractingComponent);
	UE_LOG(LogInteractSystem, Verbose, TEXT("ForceSetCurrentInteractingItem() with %s"), *NewInteractingComponent->GetDebugName());

	if (CurrentInteractingComponent)
	{
		if (CurrentInteractingComponent == NewInteractingComponent)
		{
			UE_LOG(LogInteractSystem, Error, TEXT("Already interacting with %s"), *NewInteractingComponent->GetDebugName());
			return;
		}
		else
		{
			CurrentInteractingComponent->InternalSetInteractState(EInteractItemState::IIS_None);
		}
	}

	SetNewFocusingComponent(0);

	CurrentInteractingComponent = NewInteractingComponent;
	CurrentInteractingComponent->InternalSetInteractState(EInteractItemState::IIS_Interacting);

	UE_LOG(LogInteractSystem, Verbose, TEXT("Calling ForceRefreshObserveComponents()..."));
	ForceRefreshObserveComponents();
}

AActor* UInteractManagerComponent::GetCurrentInteractingActor()
{
	if (CurrentInteractingComponent)
	{
		return CurrentInteractingComponent->GetOwner();
	}
	else
	{
		return 0;
	}
}

UInteractItemComponent* UInteractManagerComponent::GetCurrentInteractingComponent()
{
	return CurrentInteractingComponent;
}

void UInteractManagerComponent::QuitInteract()
{
	UE_LOG(LogInteractSystem, Verbose, TEXT("QuitInteract() was called"));

	if (!CurrentInteractingComponent)
	{
		UE_LOG(LogInteractSystem, Error, TEXT("Not interacting with anything!"));
		return;
	}
		
	CurrentInteractingComponent->InternalSetInteractState(EInteractItemState::IIS_None);
	CurrentInteractingComponent = 0;

	UE_LOG(LogInteractSystem, Verbose, TEXT("Calling ForceRefreshObserveComponents()..."));
	ForceRefreshObserveComponents();
}

void UInteractManagerComponent::OnInteractAction()
{
	/*if (CurrentInteractingComponent)
	{
		UE_LOG(LogInteractSystem, Warning, TEXT("I'm now interacting with %s, cannot perform interact"), *CurrentInteractingComponent->GetDebugName());
		return;
	}*/

	if (!FocusingComponent)
	{
		UE_LOG(LogInteractSystem, Warning, TEXT("Not focusing on any actor, cannot perform interact"));
		return;
	}

	NewInteractItem = FocusingComponent;
	check(NewInteractItem);

	if (NewInteractItem->InteractActionType == EInteractActionType::EIAT_Delay)
	{
		if(InteractDelayTick <= 0)
		{
			InteractDelayTick = InteractDelayDuration;
		}
	}
	else if(NewInteractItem->InteractActionType == EInteractActionType::EIAT_Immediate)
	{
		DoRealAction(NewInteractItem);
	}
	
}

void UInteractManagerComponent::DoRealAction(UInteractItemComponent* InteractItemComponent)
{
	auto OwnerController = Cast<AHiPlayerController>(GetOwner());
	check(OwnerController);

	auto OwnerPawn = Cast<AHiCharacter>(OwnerController->GetPawn());
	check(OwnerPawn);
	
	FInteractQueryParam QueryParam;
	QueryParam.InitiatePawn = OwnerPawn;

	//we put it before success, because during interact, we may need a valid CurrentInteractingItem. If Try failed, we revert CurrentInteractingItem to null.
	CurrentInteractingComponent = FocusingComponent;

	if (InteractItemComponent->TryInteract(QueryParam))
	{
		SetNewFocusingComponent(0);

		for (auto& InRangeItem : ObserveComponents)
		{
				if (InRangeItem.InteractItemComponent  && InRangeItem.InteractItemComponent != CurrentInteractingComponent)
				{
					InRangeItem.InteractItemComponent->InternalSetInteractState(EInteractItemState::IIS_None);
				}
		}

		if (!InteractItemComponent) return;
		InteractItemComponent->InternalSetInteractState(EInteractItemState::IIS_Interacting);

		OnInteractActionDelaySuccess.Broadcast(InteractItemComponent);

		if (CurrentInteractingComponent)
		{
			UE_LOG(LogInteractSystem, Log, TEXT("Interacting with %s now!"), *CurrentInteractingComponent->GetDebugName());
		}
		else
		{
			UE_LOG(LogInteractSystem, Log, TEXT("Interacting item released!"));
		}
	}
	else
	{
		CurrentInteractingComponent = 0;
		if (!FocusingComponent) return;
		UE_LOG(LogInteractSystem, Log, TEXT("Try interacting with %s but failed!"), *FocusingComponent->GetDebugName());
	}
}

AHiCharacter* UInteractManagerComponent::GetOwnerCharacter()
{
	return OwnerCharacterRef;
}

FVector UInteractManagerComponent::GetOwnerPos()
{
	return OwnerPos;
}

FVector UInteractManagerComponent::GetOwnerMoveDir()
{
	return OwnerMoveDir;
}

void UInteractManagerComponent::UpdateOwnerPos()
{
	auto OwnerController = Cast<AHiPlayerController>(GetOwner());
	check(OwnerController);
	AHiCharacter* OasisCharacter = nullptr;
	OwnerPos = OwnerMoveDir = FVector::ZeroVector;
	if (OwnerController->GetPawn() && Cast<AHiCharacter>(OwnerController->GetPawn()))
		OasisCharacter = Cast<AHiCharacter>(OwnerController->GetPawn());
	if (OasisCharacter)
	{
		OwnerPos = OasisCharacter->GetActorLocation();
		UPawnMovementComponent* CharacterMovement = OasisCharacter->GetMovementComponent();
		if (auto Cmp = Cast<UCharacterMovementComponent>(CharacterMovement))
		{
			OwnerMoveDir = Cmp->GetLastUpdateVelocity();
		}
	}
}

void UInteractManagerComponent::OnReleaseAction()
{
	//Revert to the state it was in before the interaction key was pressed
	InteractDelayTick = 0;
	if (OnInteractActionDelayTime.IsBound())
	{
		OnInteractActionDelayTime.Broadcast(InteractDelayTick, InteractDelayDuration);
	}
}

