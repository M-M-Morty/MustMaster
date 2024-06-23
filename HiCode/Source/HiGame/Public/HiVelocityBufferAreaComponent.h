// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HiVelocityBufferAreaComponent.generated.h"

class UHiCharacterMovementComponent;
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UHiVelocityBufferAreaComponent : public UActorComponent
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this component's properties
	UHiVelocityBufferAreaComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category = "Hi|LevelBuffer")
	void AddVelocityBufferActor(UHiCharacterMovementComponent* Actor);

	UFUNCTION(BlueprintCallable, Category = "Hi|LevelBuffer")
	void DelVelocityBufferActor(UHiCharacterMovementComponent* Actor);

public:
	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|LevelBuffer")
	float BufferSpeed;

	UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Hi|LevelBuffer")
	FVector AreaVelocity;

	TArray<UHiCharacterMovementComponent*> ActorArray;
};


