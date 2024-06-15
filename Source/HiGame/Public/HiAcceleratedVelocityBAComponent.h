// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HiAcceleratedVelocityBAComponent.generated.h"


class UHiCharacterMovementComponent;
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UHiAcceleratedVelocityBAComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UHiAcceleratedVelocityBAComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category = "Hi|LevelBuffer")
	virtual void AddVelocityBufferActor(UHiCharacterMovementComponent* Actor);

	UFUNCTION(BlueprintCallable, Category = "Hi|LevelBuffer")
	virtual void DelVelocityBufferActor(UHiCharacterMovementComponent* Actor);
public:
   UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|LevelBuffer")
	float MaxBufferAcceleratedSpeed;

   UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Hi|LevelBuffer")
	FVector MaxAreaAcceleratedVelocity;

	 UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Hi|LevelBuffer")
	FVector CurAreaAcceleratedVelocity;

	double BoxMinZ;
	double BoxLen;

	FVector BoxCenter;

	TArray<UHiCharacterMovementComponent*> ActorArray;
		
};
