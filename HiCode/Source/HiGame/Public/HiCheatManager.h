// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/CheatManager.h"
#include "HiCheatManager.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, Within=PlayerController)
class HIGAME_API UHiCheatManager : public UCheatManager
{
	GENERATED_UCLASS_BODY()

	UFUNCTION(exec)
	bool ServerTravel(const FString& InURL);
};
