// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiVehicleLocomotionComponent.h"

#include "Component/HiVehicleMovementComponent.h"

void UHiVehicleLocomotionComponent::InitializeComponent()
{
	Super::InitializeComponent();
	VehicleMovementComponent = Cast<UHiVehicleMovementComponent>(CharacterOwner->GetMovementComponent());
}

void UHiVehicleLocomotionComponent::TickComponent(float DeltaTime, ELevelTick TickType,
                                                  FActorComponentTickFunction* ThisTickFunction)
{
	bHasMovementInput = VehicleMovementComponent ? VehicleMovementComponent->IsAccelerating() : false;
}
