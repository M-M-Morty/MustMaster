// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiVehicleMovementComponent.h"
#include "Component/HiMantleComponent.h"
#include "HiVehicleMantleComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiVehicleMantleComponent : public UHiMantleComponent
{
	GENERATED_BODY()
public:
	
	UHiVehicleMantleComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	
	virtual void InitializeComponent() override;
	FORCEINLINE virtual UCharacterMovementComponent* GetCharacterMovementComponent()  const override { return VehicleMovementComponent.Get();}

	virtual void PhysMantle_Implementation(float DeltaTime) override;
protected:
	virtual void CheckClimbType(float DeltaTime) override;

	// Called when the game starts
	virtual void BeginPlay() override;

	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

protected:
	UPROPERTY(Transient)
	TObjectPtr<UHiVehicleMovementComponent> VehicleMovementComponent = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<AHiCharacter> OwnerVehicle= nullptr;
	
};
