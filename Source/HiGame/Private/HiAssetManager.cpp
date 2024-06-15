// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAssetManager.h"
#include "AbilitySystemGlobals.h"

UHiAssetManager& UHiAssetManager::Get()
{
	UHiAssetManager* This = Cast<UHiAssetManager>(GEngine->AssetManager);

	if (This)
	{
		return *This;
	}
	else
	{
		UE_LOG(LogTemp, Fatal, TEXT("Invalid AssetManager in DefaultEngine.ini, must be UHiAssetManager!"));
		return *NewObject<UHiAssetManager>(); // never calls this
	}
}

void UHiAssetManager::FinishInitialLoading()
{
	Super::FinishInitialLoading();
	
	FCoreDelegates::OnAllModuleLoadingPhasesComplete.AddLambda([&]()
	{
		/*UE_LOG(LogTemp, Display, TEXT("Init global data"));*/
        UAbilitySystemGlobals::Get().InitGlobalData();
        
        for (int i = 0; i < PreloadAssetsType.Num(); i++) {
        	const FString& CurType = PreloadAssetsType[i];
        	const FPrimaryAssetType TypeToLoad(*CurType);
        	LoadPrimaryAssetsWithType(TypeToLoad);
        }
	});
}

void UHiAssetManager::PostInitialAssetScan() {
	Super::PostInitialAssetScan();
}

void UHiAssetManager::ScanPrimaryAssetTypesFromConfig()
{
	SCOPED_BOOT_TIMING("UAssetManager::ScanPrimaryAssetTypesFromConfig");
	IAssetRegistry& AssetRegistry = GetAssetRegistry();
	const UAssetManagerSettings& Settings = GetSettings();

	PushBulkScanning();

	double LastPumpTime = FPlatformTime::Seconds();
	for (FPrimaryAssetTypeInfo TypeInfo : Settings.PrimaryAssetTypesToScan)
	{
		// This function also fills out runtime data on the copy
		if (!ShouldScanPrimaryAssetType(TypeInfo))
		{
			continue;
		}

		ScanPathsForPrimaryAssets(TypeInfo.PrimaryAssetType, TypeInfo.AssetScanPaths, TypeInfo.AssetBaseClassLoaded, TypeInfo.bHasBlueprintClasses, TypeInfo.bIsEditorOnly, true);
		SetPrimaryAssetTypeRules(TypeInfo.PrimaryAssetType, TypeInfo.Rules);
	}

	PopBulkScanning();
}
