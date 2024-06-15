// Fill out your copyright notice in the Description page of Project Settings.


#include "InteractSystem/InteractCharacterComponent.h"
#include "Components/SphereComponent.h"
#include "InteractSystem/InteractSystem.h"
#include "InteractSystem/CustomInteractExecutor.h"
#include "InteractSystem/InteractWidget.h"
#include "Abilities/GameplayAbilityTypes.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "InteractSystem/UInteractExecutorInterface.h"
#include "Components/SphereComponent.h"
#include "Characters/HiCharacter.h"
#include "InteractSystem/InteractManagerComponent.h"


// Sets default values for this component's properties
UInteractCharacterComponent::UInteractCharacterComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	//Mobility = EComponentMobility::Movable;
}

// Called when the game starts
void UInteractCharacterComponent::BeginPlay()
{
	Super::BeginPlay();

	if (GetOwner()->IsA(AHiCharacter::StaticClass()))
	{
		OCharacterRef = Cast<AHiCharacter>(GetOwner());
	}
}

// Called every frame
void UInteractCharacterComponent::PassivelyTick(float DeltaTime)
{
	Super::PassivelyTick(DeltaTime);

	UpdateFocusRange();
}

float UInteractCharacterComponent::GetFocusRange() const
{
	return CurFocusRange;
}

void UInteractCharacterComponent::UpdateFocusRange()
{
	if (!GetWorld()) return;
	float CurTime = GetWorld()->GetTimeSeconds();
	if (CurTime != LastUpdateTime && CurTime - LastUpdateTime > MinFocusRangeUpdateFreq)
	{
		if (Observer)
		{
			auto OwnerController = Cast<APlayerController>(Observer->GetOwner());
			if (OwnerController)
			{
				auto OwnerCharacter = Cast<AHiCharacter>(OwnerController->GetPawn());
				if (OwnerCharacter)
				{
					FInteractInfo Info;
					/*
					if (OwnerCharacter->FindInteractInfo(OCharacterRef, Info))
					{
						CurFocusRange = Info.Range;
						LastUpdateTime = GetWorld()->GetTimeSeconds();
					}
					else
					{
						CurFocusRange = 0.0f;
						LastUpdateTime = GetWorld()->GetTimeSeconds();
					}
					*/
				}
			}
		}
	}
}

bool UInteractCharacterComponent::CanBeInteracted() const
{
	return GetFocusRange() > 0.0f;
}

/*float UInteractCharacterComponent::GetPriority() const
{
	const float DistancePriorityWeight = 0.2;
	const float MoveDirPriorityWeight = 0.3f;
	const float HealthPriorityWeight = 0.1f;
	const float DangerousPriorityWeight = 0.15f;
	const float ViewPriorityWeight = 0.25f;
	auto Character = Cast<AOasisCharacterBase>(GetOwner());
	auto CS = ACameraSystem::Get(this);

	const float MaxDistance = PromptRange;
	if (Observer)
	{
		FVector ObserverPos = Observer->GetOwnerPos();
		FVector OwnerPos = GetOwner()->GetActorLocation();
		FVector OwnerMoveDir = Observer->GetOwnerMoveDir();

		FVector V = GetOwner()->GetActorLocation() - ObserverPos;

		float DistancePriority = (MaxDistance - V.Size2D()) / MaxDistance * DistancePriorityWeight;

		float MoveDirPriority = 0.0f;
		if (!OwnerMoveDir.IsNearlyZero())
		{
			float Radians = FMath::Acos(OwnerMoveDir.GetSafeNormal2D() | V.GetSafeNormal2D());
			float Degrees = FMath::RadiansToDegrees(Radians);
			MoveDirPriority = (PI - Radians) / PI * MoveDirPriorityWeight; //(180.0f - Degrees) * MoveDirDotPriorityWeight;
		}

		float CurHP = Character->GetCharacterAttribute(ENMAttribution::HP);
		float HealthPriority = CurHP / 100.0f * HealthPriorityWeight;

		float ViewPriority = 0.0f;

		if (CS)
		{
			FVector CamLoc;
			FRotator CamRot;
			CS->GetCurrentPOV(CamLoc, CamRot);

			FVector CamVec = CamRot.Vector();
			FVector ItemVec = (ObserverPos - OwnerPos).GetSafeNormal();

			float ThisAngleCos = CamVec | ItemVec;
			float Radians = FMath::Acos(ThisAngleCos);

			ViewPriority = Radians / PI * ViewPriorityWeight;
		}

		return DistancePriority + MoveDirPriority + HealthPriority + ViewPriority;
	}

	return 0.0f;
}*/

/*int32 UInteractCharacterComponent::GetGroup() const
{
	if (Observer)
	{
		AOasisCharacterBase* InteractPawn = Observer->GetOwnerCharacter();
		FInteractInfo Info;
		if (InteractPawn->FindInteractInfo(OCharacterRef, Info))
		{
			return 1 << Info.Type;
		}
	}

	return 0;
}*/

/*
bool UInteractCharacterComponent::TryInteractInternal(const FInteractQueryParam& QueryParam) const
{
	if (InteractState != EInteractItemState::IIS_Focus)
	{
		UE_LOG(LogInteractSystem, Error, TEXT("%s is not being focused (Current InteractState = %s), calling TryInteractWithMe() failed"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractState));
		return false;
	}

	auto Character = Cast<AOasisCharacterBase>(QueryParam.InitiatePawn);

	switch (InteractAction)
	{
	case EInteractAction::IA_None:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction));

		return Character->TryInteract(QueryParam);
	}

	case EInteractAction::IA_SetLocoState:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s, LocoState = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction), *LocoStateToSet.ToString());

		//auto Character = Cast<AOasisCharacterBase>(QueryParam.InitiatePawn);
		//check(Character);

		return Character->TrySetLocomotionStateByTag(LocoStateToSet);
	}

	case EInteractAction::IA_ActivateAbility:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s, AbilityClass = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction), *AbilityClassToActivate->GetName());

		//auto Character = Cast<AOasisCharacterBase>(QueryParam.InitiatePawn);
		//check(Character);

		auto ASC = Character->GetAbilitySystemComponent();
		check(ASC);

		return ASC->TryActivateAbilityByClass(AbilityClassToActivate);
	}

	case EInteractAction::IA_SendGameplayEventWithPayload:
	{
		UE_LOG(LogInteractSystem, Verbose, TEXT("(%s) InteractAction = %s, GameplayEventTag = %s"), *GetOwner()->GetName(), *UEnum::GetValueAsString(InteractAction), *GameplayEventToSend.ToString());

		FGameplayEventData Payload;
		Payload.EventTag = GameplayEventToSend;
		Payload.OptionalObject = GetOwner();
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

		//return CustomInteractExecutorClass->GetDefaultObject<UCustomInteractExecutor>()->TryInteract(QueryParam, GetOwner()->GetRootComponent(), this);
	}
	case EInteractAction::IA_InterfaceImplement:
	{
		check(IsInGameThread())
			auto MyClass = GetOwner()->GetClass();
		static UClass* InterfaceClass = UInteractExecutorInterface::StaticClass();

		return false;
	}
	}

	return false;
}

*/