// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/BoxComponent.h"
#include "GameFramework/Actor.h"
#include "WeatherChangeActor.generated.h"

UCLASS(Blueprintable)
class HIGAME_API AWeatherChangeActor : public AActor
{
	GENERATED_BODY()
	
public:	
	
	UFUNCTION(BlueprintImplementableEvent, CallInEditor)
	int GetPriority();
	
	UFUNCTION(BlueprintImplementableEvent, CallInEditor)
	bool IsEnable();

	UFUNCTION(BlueprintImplementableEvent, CallInEditor)
	void GetTriggerInfo(int&Priority, FSoftObjectPath& SequencePath, UBoxComponent*& Comp, float& LastTime);

	UFUNCTION(BlueprintImplementableEvent, CallInEditor)
	float GetGlobalStartTimeOfDay();
	

};
