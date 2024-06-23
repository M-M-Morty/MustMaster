// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/AssetManager.h"
#include "Engine/AssetManagerSettings.h"
#include "HiAssetManager.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiAssetManager : public UAssetManager
{
	GENERATED_BODY()

public:
	// Constructor and overrides
	UHiAssetManager() {}
	virtual void FinishInitialLoading() override;
	
	virtual void PostInitialAssetScan() override;

	virtual void ScanPrimaryAssetTypesFromConfig() override;

	/** Returns the current AssetManager object */
	static UHiAssetManager& Get();

private:
	const TArray<FString> PreloadAssetsType =
	{
		"LevelSequence",
		"GameplayAbility",
	};
};
