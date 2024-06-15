// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiProjectileMovementComponent.h"

FVector UHiProjectileMovementComponent::ComputeAcceleration(const FVector& InVelocity, float DeltaTime) const
{
	FVector Acceleration(FVector::ZeroVector);

	Acceleration.Z += GetGravityZ();

	Acceleration += PendingForceThisUpdate;

	if (bIsHomingProjectile && (HomingTargetComponent.IsValid() || bUseHomingTargetLocation))
	{
		Acceleration += ComputeHomingAcceleration(InVelocity, DeltaTime);
	}

	return Acceleration;
}

FVector UHiProjectileMovementComponent::ComputeHomingAcceleration(const FVector& InVelocity, float DeltaTime) const
{
	FVector TargetLocation = HomingTargetLocation;
	if (HomingTargetComponent.IsValid())
	{
		TargetLocation = HomingTargetComponent->GetComponentLocation();
	}
	
	FVector HomingAcceleration = ((TargetLocation - UpdatedComponent->GetComponentLocation()).GetSafeNormal() * HomingAccelerationMagnitude);
	return HomingAcceleration;
}
