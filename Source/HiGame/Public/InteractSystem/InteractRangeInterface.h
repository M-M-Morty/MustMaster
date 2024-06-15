// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "InteractRangeInterface.generated.h"

class UInteractItemComponent;

// This class does not need to be modified.
UINTERFACE(MinimalAPI)
class UInteractRangeInterface : public UInterface
{
	GENERATED_BODY()
};

/**
 * 
 */
class HIGAME_API IInteractRangeInterface
{
	GENERATED_BODY()

	// Add interface functions to this class. This is the class that will be inherited to implement this interface.
public:
	virtual void SetInteractItemComponent(UInteractItemComponent* NewInteractItemComponent) {}
	virtual UInteractItemComponent* GetInteractItemComponent() const { return 0; }
};
