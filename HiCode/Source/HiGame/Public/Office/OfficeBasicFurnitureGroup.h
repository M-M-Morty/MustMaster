// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "OfficeBasicFurnitureGroup.generated.h"

UCLASS()
class HIGAME_API AOfficeBasicFurnitureGroup : public AActor
{
	GENERATED_BODY()

public:
	// Sets default values for this actor's properties
	AOfficeBasicFurnitureGroup();
	virtual void PreInitializeComponents() override;

	UFUNCTION(BlueprintImplementableEvent)
	void K2_PreInitializeComponents();
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;
};
