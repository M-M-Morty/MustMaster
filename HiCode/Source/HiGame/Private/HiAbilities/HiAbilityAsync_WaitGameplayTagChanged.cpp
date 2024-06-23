// Copyright Epic Games, Inc. All Rights Reserved.

#include "HiAbilities/HiAbilityAsync_WaitGameplayTagChanged.h"
#include "AbilitySystemComponent.h"
#include "AbilitySystemLog.h"

UAbilityAsync_WaitGameplayTagChanged* UAbilityAsync_WaitGameplayTagChanged::WaitGameplayTagChangedToActor(AActor* TargetActor, const FGameplayTag Tag, const EGameplayTagEventType::Type EventType, const bool TriggerOnce)
{
	UAbilityAsync_WaitGameplayTagChanged* MyObj = NewObject<UAbilityAsync_WaitGameplayTagChanged>();
	MyObj->SetAbilityActor(TargetActor);
	MyObj->Tag = Tag;
	MyObj->EventType = EventType;
	MyObj->TriggerOnce = TriggerOnce;
	return MyObj;
}

void UAbilityAsync_WaitGameplayTagChanged::Activate()
{
	Super::Activate();

	if (UAbilitySystemComponent* ASC = GetAbilitySystemComponent())
	{
		OnApplyGameplayTagCallbackDelegateHandle = ASC->RegisterGameplayTagEvent(Tag, EventType).AddUObject(this, &UAbilityAsync_WaitGameplayTagChanged::OnGameplayTagChanged);
	}
	else
	{
		EndAction();
	}
}

void UAbilityAsync_WaitGameplayTagChanged::OnGameplayTagChanged(const FGameplayTag ChangedTag, const int32 NewCount)
{
	if (bLocked)
	{
		ABILITY_LOG(Error, TEXT("WaitGameplayTagChanged recursion detected. Action: %s. TagName: %s. This could cause an infinite loop! Ignoring"), *GetPathName(), *(Tag.ToString()));
		return;
	}

	if (ShouldBroadcastDelegates())
	{
		TGuardValue<bool> GuardValue(bLocked, true);
		OnChanged.Broadcast(ChangedTag, NewCount);

		if (TriggerOnce)
		{
			EndAction();
		}
	}
	else
	{
		EndAction();
	}
}

void UAbilityAsync_WaitGameplayTagChanged::EndAction()
{
	if (UAbilitySystemComponent* ASC = GetAbilitySystemComponent())
	{
		ASC->UnregisterGameplayTagEvent(OnApplyGameplayTagCallbackDelegateHandle, Tag, EventType);
	}
	Super::EndAction();
}
