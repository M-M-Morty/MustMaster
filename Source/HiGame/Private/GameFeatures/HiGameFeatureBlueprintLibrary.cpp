// Fill out your copyright notice in the Description page of Project Settings.


#include "GameFeatures/HiGameFeatureBlueprintLibrary.h"
#include "GameFeaturesSubsystem.h"
#include "Interfaces/IPluginManager.h"
#include "Kismet/GameplayStatics.h"
#include "HiLogChannels.h"
#include "GameFeaturePluginOperationResult.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wdangling"
#endif

UGameFeaturesSubsystem* UHiGameFeatureBlueprintLibrary::GetGameFeaturesSubsystem()
{
	return &UGameFeaturesSubsystem::Get();
}

bool UHiGameFeatureBlueprintLibrary::AddToPluginsList(const FString& PluginFileName)
{
	return IPluginManager::Get().AddToPluginsList(PluginFileName);
}

bool UHiGameFeatureBlueprintLibrary::GetPluginURLForBuiltInPluginByName(UGameFeaturesSubsystem* Subsystem,	const FString& PluginName, FString& OutPluginURL)
{
	return Subsystem->GetPluginURLForBuiltInPluginByName(PluginName, OutPluginURL);
}

void UHiGameFeatureBlueprintLibrary::LoadGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName)
{
	FString PluginURL;
	UHiGameFeatureBlueprintLibrary::GetPluginURLForBuiltInPluginByName(Subsystem, InFeatureName, PluginURL);
	if (!PluginURL.IsEmpty())
	{
		Subsystem->LoadGameFeaturePlugin(PluginURL, FGameFeaturePluginDeactivateComplete::CreateStatic(&UHiGameFeatureBlueprintLibrary::OnStatus));
	}
}

void UHiGameFeatureBlueprintLibrary::ActivateGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName)
{
	FString PluginURL;
	UHiGameFeatureBlueprintLibrary::GetPluginURLForBuiltInPluginByName(Subsystem, InFeatureName, PluginURL);
	if (!PluginURL.IsEmpty())
	{
		Subsystem->LoadAndActivateGameFeaturePlugin(PluginURL,FGameFeaturePluginDeactivateComplete::CreateStatic(&UHiGameFeatureBlueprintLibrary::OnStatus));
	}
}

void UHiGameFeatureBlueprintLibrary::LoadBuiltInGameFeaturePlugin(UGameFeaturesSubsystem* Subsystem, const FString& InPluginName)
{	
	TSharedPtr<IPlugin> FoundModule = IPluginManager::Get().FindPlugin(InPluginName);
	if (FoundModule.IsValid())
	{
		UGameFeaturesSubsystem::FBuiltInPluginAdditionalFilters Filters = [](const FString& PluginFilename, const FGameFeaturePluginDetails& Details, FBuiltInGameFeaturePluginBehaviorOptions& OutOptions)->bool
		{
			UE_LOG(LogHiGame, Log, TEXT("Load Game Feature Plugin %s"),*PluginFilename);
			return true;
		};
		Subsystem->LoadBuiltInGameFeaturePlugin(FoundModule.ToSharedRef(),Filters);
	}
}

void UHiGameFeatureBlueprintLibrary::LoadBuiltInGameFeaturePlugins(UGameFeaturesSubsystem* Subsystem)
{
	UGameFeaturesSubsystem::FBuiltInPluginAdditionalFilters Filters = [](const FString& PluginFilename, const FGameFeaturePluginDetails& Details, FBuiltInGameFeaturePluginBehaviorOptions& OutOptions)->bool
	{
		UE_LOG(LogHiGame, Log, TEXT("Load Game Feature Plugin %s"),*PluginFilename);
		return true;
	};
	Subsystem->LoadBuiltInGameFeaturePlugins(Filters);
}

void UHiGameFeatureBlueprintLibrary::UnloadGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName,	bool bKeepRegistered)
{
	FString PluginURL;
	if(UHiGameFeatureBlueprintLibrary::GetPluginURLForBuiltInPluginByName(Subsystem,InFeatureName,PluginURL))
	{
		Subsystem->UnloadGameFeaturePlugin(PluginURL,bKeepRegistered);
	}
}

void UHiGameFeatureBlueprintLibrary::DeactivateGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName)
{
	FString PluginURL;
	UHiGameFeatureBlueprintLibrary::GetPluginURLForBuiltInPluginByName(Subsystem,InFeatureName,PluginURL);
	if(!PluginURL.IsEmpty())
	{
		Subsystem->DeactivateGameFeaturePlugin(PluginURL);
	}
}

void UHiGameFeatureBlueprintLibrary::OnStatus(const UE::GameFeatures::FResult& InStatus)
{
	if(InStatus.HasError())
	{
		UE_LOG(LogHiGame,Log,TEXT("Load Status %s"),*InStatus.GetError());
	}	
}

void UHiGameFeatureBlueprintLibrary::SetGameFeatureState(FString GameFeatureName, EGameFeatureState State)
{
	FString PluginURL;
	GetPluginURLForBuiltInPluginByName(&UGameFeaturesSubsystem::Get(),GameFeatureName,PluginURL);

	if (State == EGameFeatureState::Deactivated)
	{
		UGameFeaturesSubsystem::Get().DeactivateGameFeaturePlugin(PluginURL);
	}

	if (State == EGameFeatureState::Activated)
	{
		UGameFeaturesSubsystem::Get().LoadAndActivateGameFeaturePlugin(PluginURL, FGameFeaturePluginLoadComplete());
	}

	if (State == EGameFeatureState::Unloaded)
	{
		UGameFeaturesSubsystem::Get().UnloadGameFeaturePlugin(PluginURL);
	}

	if (State == EGameFeatureState::Loaded)
	{
		UGameFeaturesSubsystem::Get().LoadGameFeaturePlugin(PluginURL, FGameFeaturePluginLoadComplete());
	}
}

UGameFrameworkComponentManager* UHiGameFeatureBlueprintLibrary::GetGameFrameworkComponentManager(UObject* WorldContextObject)
{
	UGameFrameworkComponentManager* GFCM = nullptr;
	UGameInstance* GameInstance = UGameplayStatics::GetGameInstance(WorldContextObject);
	if(IsValid(GameInstance))
	{
		GFCM = UGameInstance::GetSubsystem<UGameFrameworkComponentManager>(GameInstance);
	}
	return GFCM;
}

#include "Components/GameFrameworkComponentManager.h"

void UHiGameFeatureBlueprintLibrary::AddReceiver(UObject* WorldContextObject, AActor* Owner)
{
	UGameFrameworkComponentManager* GFCM = UHiGameFeatureBlueprintLibrary::GetGameFrameworkComponentManager(WorldContextObject);
	if(GFCM)
	{
		GFCM->AddReceiver(Owner);
	}
}

void UHiGameFeatureBlueprintLibrary::RemoveReceiver(UObject* WorldContextObject, AActor* Owner)
{
	UGameFrameworkComponentManager* GFCM = UHiGameFeatureBlueprintLibrary::GetGameFrameworkComponentManager(WorldContextObject);
	if(GFCM)
	{
		GFCM->RemoveReceiver(Owner);
	}
}
