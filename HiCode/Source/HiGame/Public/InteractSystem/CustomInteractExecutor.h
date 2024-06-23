// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/NoExportTypes.h"
#include "InteractSystem.h"
#include "CustomInteractExecutor.generated.h"

/**
 * 
 */
UCLASS(Blueprintable)
class HIGAME_API UCustomInteractExecutor : public UObject
{
	GENERATED_BODY()
	
public:


	UFUNCTION(BlueprintNativeEvent)
	bool TryInteract(FInteractQueryParam QueryParam, AActor* InteractItem, UInteractItemComponent* InteractItemComponent);

	virtual bool TryInteract_Implementation(FInteractQueryParam QueryParam, AActor* InteractItem, UInteractItemComponent* InteractItemComponent) { return false; }
};
