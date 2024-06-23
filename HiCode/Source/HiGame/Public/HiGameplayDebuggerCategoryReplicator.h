// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "GameplayDebuggerCategoryReplicator.h"
#include "HiGameplayDebuggerCategoryReplicator.generated.h"

/**
 * 
 */
UCLASS(Blueprintable)
class HIGAME_API AHiGameplayDebuggerCategoryReplicator : public AGameplayDebuggerCategoryReplicator
{
	GENERATED_BODY()
	
public:
	AHiGameplayDebuggerCategoryReplicator();
	
	UFUNCTION(BlueprintCallable)
	void SetReplicatorOwner(APlayerController* InOwnerPC);
};
