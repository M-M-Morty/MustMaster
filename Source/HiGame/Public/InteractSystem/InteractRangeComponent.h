// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/SphereComponent.h"
#include "Components/BoxComponent.h"
#include "InteractRangeInterface.h"
#include "InteractRangeComponent.generated.h"

class UInteractItemComponent;

/**
 * 
 */
UCLASS()
class HIGAME_API UInteractSphereRangeComponent : public USphereComponent, public IInteractRangeInterface
{
	GENERATED_BODY()

public:
	virtual void SetInteractItemComponent(UInteractItemComponent* NewInteractItemComponent) override
	{
		InteractItemComponent = NewInteractItemComponent;
	}

	virtual UInteractItemComponent* GetInteractItemComponent() const override { return InteractItemComponent; }

protected:
	UPROPERTY()
	UInteractItemComponent* InteractItemComponent = 0;
};

/**
 *
 */
UCLASS()
class HIGAME_API UInteractBoxRangeComponent : public UBoxComponent, public IInteractRangeInterface
{
	GENERATED_BODY()

public:
	virtual void SetInteractItemComponent(UInteractItemComponent* NewInteractItemComponent) override
	{
		InteractItemComponent = NewInteractItemComponent;
	}

	virtual UInteractItemComponent* GetInteractItemComponent() const override { return InteractItemComponent; }

protected:
	UPROPERTY()
	UInteractItemComponent* InteractItemComponent = 0;
};
