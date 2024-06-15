// Copyright Tencent Games, Inc. All Rights Reserved.
#pragma once

#include "CoreMinimal.h"
#include "GameplayAbilities/Public/Abilities/Async/AbilityAsync.h"
#include "Delegates/IDelegateInstance.h"
#include "HiAbilityAsync_WaitGameplayTagChanged.generated.h"


UCLASS()
class HIGAME_API UAbilityAsync_WaitGameplayTagChanged : public UAbilityAsync
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Ability|Async", meta = (DefaultToSelf = "TargetActor", BlueprintInternalUseOnly = "TRUE"))
	static UAbilityAsync_WaitGameplayTagChanged* WaitGameplayTagChangedToActor(AActor* TargetActor, const FGameplayTag Tag, const EGameplayTagEventType::Type EventType, const bool TriggerOnce = false);

	DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnGameplayTagChangedDelegate, FGameplayTag, Tag, int32, NewCount);
	UPROPERTY(BlueprintAssignable)
	FOnGameplayTagChangedDelegate OnChanged;

protected:
	virtual void Activate() override;
	virtual void EndAction() override;

	void OnGameplayTagChanged(const FGameplayTag Tag, const int32 NewCount);

	FGameplayTag Tag;
	EGameplayTagEventType::Type EventType;
	bool TriggerOnce = false;

	FDelegateHandle OnApplyGameplayTagCallbackDelegateHandle;
	bool bLocked = false;
};
