// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Component/HiLocomotionComponent.h"
#include "HiVehicleLocomotionComponent.generated.h"

class UHiVehicleMovementComponent;
/**
 * 
 */
UCLASS()
class HIGAME_API UHiVehicleLocomotionComponent : public UHiLocomotionComponent
{
	GENERATED_BODY()

public:
	
	virtual void InitializeComponent() override;
	
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

protected:
	/* Custom movement component*/
	UPROPERTY(Transient)
	TObjectPtr<UHiVehicleMovementComponent> VehicleMovementComponent = nullptr;
};
