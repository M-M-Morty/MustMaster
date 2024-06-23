// Fill out your copyright notice in the Description page of Project Settings.


#include "GameFeatures/HiGameFeaturePolicy.h"
#include "GameFeaturesSubsystem.h"

UHiGameFeaturePolicy& UHiGameFeaturePolicy::Get()
{
	return UGameFeaturesSubsystem::Get().GetPolicy<UHiGameFeaturePolicy>();
}

UHiGameFeaturePolicy::UHiGameFeaturePolicy(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
}

void UHiGameFeaturePolicy::InitGameFeatureManager()
{
	Super::InitGameFeatureManager();
	/* add filter here, decide which plugin should be loaded;
	 * ex. check version
	 * we should externd the if to lua or blueprint
	UE_LOG(LogGameFeatures, Log, TEXT("Scanning for built-in game feature plugins"));
	auto AdditionalFilter = [&](const FString& PluginFilename, const FGameFeaturePluginDetails& PluginDetails, FBuiltInGameFeaturePluginBehaviorOptions& OutOptions) -> bool
	{
		if (const FString* myGameVersion = PluginDetails.AdditionalMetadata.Find(TEXT("MyGameVersion")))
		{
			float version = FCString::Atof(**myGameVersion);
			if (version > 2.0)
			{
				return true;
			}
		}
		return false;
	};
	UGameFeaturesSubsystem::Get().LoadBuiltInGameFeaturePlugins(AdditionalFilter);
	*/
}

void UHiGameFeaturePolicy::ShutdownGameFeatureManager()
{
	Super::ShutdownGameFeatureManager();
}

TArray<FPrimaryAssetId> UHiGameFeaturePolicy::GetPreloadAssetListForGameFeature(
	const UGameFeatureData* GameFeatureToLoad, bool bIncludeLoadedAssets/* = false*/) const
{
	return Super::GetPreloadAssetListForGameFeature(GameFeatureToLoad, bIncludeLoadedAssets);
}

bool UHiGameFeaturePolicy::IsPluginAllowed(const FString& PluginURL) const
{
	return Super::IsPluginAllowed(PluginURL);
}

const TArray<FName> UHiGameFeaturePolicy::GetPreloadBundleStateForGameFeature() const
{
	return Super::GetPreloadBundleStateForGameFeature();
}

void UHiGameFeaturePolicy::GetGameFeatureLoadingMode(bool& bLoadClientData, bool& bLoadServerData) const
{
	Super::GetGameFeatureLoadingMode(bLoadClientData, bLoadServerData);
}

void UHiGameFeature_HotfixManager::OnGameFeatureLoading(const UGameFeatureData* GameFeatureData, const FString& PluginURL)
{
	IGameFeatureStateChangeObserver::OnGameFeatureLoading(GameFeatureData, PluginURL);
}

void UHiGameFeature_AddGameplayCuePaths::OnGameFeatureRegistering(const UGameFeatureData* GameFeatureData,
	const FString& PluginName, const FString& PluginURL)
{
	IGameFeatureStateChangeObserver::OnGameFeatureRegistering(GameFeatureData, PluginName, PluginURL);
}

void UHiGameFeature_AddGameplayCuePaths::OnGameFeatureUnregistering(const UGameFeatureData* GameFeatureData,
	const FString& PluginName, const FString& PluginURL)
{
	IGameFeatureStateChangeObserver::OnGameFeatureUnregistering(GameFeatureData, PluginName, PluginURL);
}
