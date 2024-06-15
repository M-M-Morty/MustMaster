// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "ObjectRegistryWorldSubsystem.generated.h"

/**
 * 
 */
UCLASS(BlueprintType)
class HIGAME_API UObjectRegistryWorldSubsystem : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category=HiGamePlay)
	void RegisterObject(const FString& Key, UObject* Obj)
	{
		BlackBoard.FindOrAdd(Key, Obj);
	}
	
	UFUNCTION(BlueprintCallable, Category=HiGamePlay)
	void UnregisterObject(const FString& Key)
	{
		if(BlackBoard.Contains(Key))
		{
			BlackBoard.Remove(Key);
		}
	}
	
	UFUNCTION(BlueprintCallable, Category=HiGamePlay)
	UObject* FindObject(const FString& Key)
	{
		if(BlackBoard.Contains(Key))
		{
			return BlackBoard[Key];
		}
		return nullptr;
	}
	
private:
	TMap<const FString, UObject*> BlackBoard;
};
