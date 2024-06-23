// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "UILogicSubSystem.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType, Abstract)
class HIGAME_API UUILogicSubSystem : public UWorldSubsystem
{
	GENERATED_BODY()
public:
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void PostInitialize() override;
	virtual void Deinitialize() override;

	void OnWorldBeginPlayDelegate();

	UFUNCTION(BlueprintImplementableEvent)
	void OnWorldBeginPlayScript();


	UFUNCTION(BlueprintImplementableEvent)
	void InitializeScript();

	UFUNCTION(BlueprintImplementableEvent)
	void DeinitializeScript();
	

	UFUNCTION(BlueprintImplementableEvent)
	void PostInitializeScript();
};
