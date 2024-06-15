// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/ProjectileMovementComponent.h"
#include "HiProjectileMovementComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, Meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiProjectileMovementComponent : public UProjectileMovementComponent
{
	GENERATED_BODY()

public:
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Category=Homing)
	bool bUseHomingTargetLocation;
	
	/**
	 * @brief Homing target location if no HomingTargetComponent configured.
	 */
	UPROPERTY(VisibleInstanceOnly, BlueprintReadWrite, Category=Homing)
	FVector HomingTargetLocation;

	virtual FVector ComputeAcceleration(const FVector& InVelocity, float DeltaTime) const override;
	virtual FVector ComputeHomingAcceleration(const FVector& InVelocity, float DeltaTime) const override;
};
