// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "OfficeSubsystem.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType, Abstract)
class HIGAME_API UOfficeSubsystem : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	virtual bool ShouldCreateSubsystem(UObject* Outer) const override;

	UFUNCTION(BlueprintImplementableEvent)
	bool ScriptShouldCreateSubsystem(UObject* Outer) const;
	
	UFUNCTION(BlueprintImplementableEvent)
	void PostInitializeScript();

	virtual void PostInitialize() override;

	void Initialize(FSubsystemCollectionBase& Collection) override;
	
protected:
	virtual bool DoesSupportWorldType(const EWorldType::Type WorldType) const override;

	UPROPERTY(BlueprintReadWrite, EditDefaultsOnly)
	int64 OfficeMapID;
};
