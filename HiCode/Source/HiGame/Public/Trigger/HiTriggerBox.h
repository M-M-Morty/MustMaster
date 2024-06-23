// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/TriggerBox.h"
#include "HiTriggerBox.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API AHiTriggerBox : public ATriggerBox
{
	GENERATED_BODY()
public:
	AHiTriggerBox(const FObjectInitializer& ObjectInitializer);

	UPROPERTY(EditAnywhere, NoClear, BlueprintReadOnly, Category = "Trigger")
	TArray<TObjectPtr<const AActor>> ReferenceActors;
};
