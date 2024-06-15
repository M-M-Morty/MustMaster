// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "GameFeaturesSubsystem.h"
#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "HiGameFeatureBlueprintLibrary.generated.h"

class UGameFeaturesSubsystem;
class UGameFrameworkComponentManager;

UENUM()
enum class EGameFeatureState : uint8
{
	Unloaded,
	Loaded,
	Deactivated,
	Activated,

	EGameFeatureState_Max UMETA(Hidden)
};

/**
 * 
 */
UCLASS()
class HIGAME_API UHiGameFeatureBlueprintLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
public:
    UFUNCTION(BlueprintCallable)
    static UGameFeaturesSubsystem* GetGameFeaturesSubsystem();
    UFUNCTION(BlueprintCallable)
    static bool AddToPluginsList(const FString& PluginFileName);
    
    static bool GetPluginURLForBuiltInPluginByName(UGameFeaturesSubsystem* Subsystem, const FString& PluginName, FString& OutPluginURL);

	UFUNCTION(BlueprintCallable)
	static void  LoadGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName);
	
	UFUNCTION(BlueprintCallable)
	static void ActivateGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName);

	UFUNCTION(BlueprintCallable)
	static void LoadBuiltInGameFeaturePlugin(UGameFeaturesSubsystem* Subsystem, const FString& InPluginName);

	UFUNCTION(BlueprintCallable)
	static void LoadBuiltInGameFeaturePlugins(UGameFeaturesSubsystem* Subsystem);

	UFUNCTION(BlueprintCallable)
	static void UnloadGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeature, bool bKeepRegistered = false);

	UFUNCTION(BlueprintCallable)
	static void DeactivateGameFeature(UGameFeaturesSubsystem* Subsystem, const FString& InFeatureName);

	static void OnStatus(const UE::GameFeatures::FResult& InStatus);


	UFUNCTION(BlueprintCallable, Category="Game Feature Function Library|Modifier")
	static void SetGameFeatureState(FString GameFeatureName, EGameFeatureState State);
	
	UFUNCTION(BlueprintCallable, BlueprintPure, meta = (WorldContext="WorldContextObject"))
	static UGameFrameworkComponentManager* GetGameFrameworkComponentManager(UObject* WorldContextObject);
	UFUNCTION(BlueprintCallable,meta=(WorldContext="WorldContextObject",DefaultToSelf="Owner"))
	static void AddReceiver(UObject* WorldContextObject,AActor* Owner);
	UFUNCTION(BlueprintCallable,meta=(WorldContext="WorldContextObject",DefaultToSelf="Owner"))
	static void RemoveReceiver(UObject* WorldContextObject,AActor* Owner);	
};
