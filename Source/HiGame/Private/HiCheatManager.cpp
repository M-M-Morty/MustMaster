// Fill out your copyright notice in the Description page of Project Settings.


#include "HiCheatManager.h"

UHiCheatManager::UHiCheatManager(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	
}

bool UHiCheatManager::ServerTravel(const FString& InURL)
{
	if (UWorld* wd = GetWorld())
	{
		return wd->ServerTravel(InURL, false, false);
	}
	return false;	
}
