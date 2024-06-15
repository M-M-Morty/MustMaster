// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "InteractWidgetUpdater.generated.h"

class UInteractWidget;

/*
* A singleton actor for updating all interacting widgets.
*/
UCLASS()
class HIGAME_API AInteractWidgetUpdater : public AActor
{
	GENERATED_BODY()
	
public:	
	static AInteractWidgetUpdater* Get(const UObject* WorldContextObject);

	// Sets default values for this actor's properties
	AInteractWidgetUpdater();

	virtual void PostInitializeComponents() override;

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;



public:
	void RegisterNewInteractWidget(UInteractWidget* NewWidget);
	void UnregisterInteractWidget(UInteractWidget* InWidget);

protected:
	UPROPERTY()
	TArray<UInteractWidget*> InteractWidgets;
};
