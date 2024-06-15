// Copyright Epic Games, Inc. All Rights Reserved.

#include "AsyncAction_CreateAssetAsync.h"
#include "Engine/AssetManager.h"
#include "Engine/StreamableManager.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Engine/Engine.h"
#include "Engine/GameInstance.h"
#include "Engine/LocalPlayer.h"


UAsyncAction_CreateAssetAsync::UAsyncAction_CreateAssetAsync(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

UAsyncAction_CreateAssetAsync* UAsyncAction_CreateAssetAsync::CreateAssetAsync(UObject* WorldContextObject, TSoftObjectPtr<UObject> Asset)
{
	if (Asset.IsNull())
	{
		FFrame::KismetExecutionMessage(TEXT("CreateWidgetAsync was passed a null UserWidgetSoftClass"), ELogVerbosity::Error);
		return nullptr;
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);

	UAsyncAction_CreateAssetAsync* Action = NewObject<UAsyncAction_CreateAssetAsync>();
	Action->SoftObjectPath = Asset.ToSoftObjectPath();
	Action->World = World;
	Action->RegisterWithGameInstance(World);

	return Action;
}

UAsyncAction_CreateAssetAsync* UAsyncAction_CreateAssetAsync::CreateAssetAsyncUsePath(UWorld* World, const FString& AssetPath)
{
	FAssetRegistryModule& AssetRegistryModule = FModuleManager::GetModuleChecked<FAssetRegistryModule>("AssetRegistry");
	IAssetRegistry& AssetRegistry = AssetRegistryModule.Get();
	FAssetData AssetData = AssetRegistry.GetAssetByObjectPath(FSoftObjectPath(*AssetPath));
	UAsyncAction_CreateAssetAsync* Action = NewObject<UAsyncAction_CreateAssetAsync>();
	Action->SoftObjectPath = AssetData.ToSoftObjectPath();
	Action->World = World;
	Action->RegisterWithGameInstance(World);
	return Action;
}

UAsyncAction_CreateAssetAsync* UAsyncAction_CreateAssetAsync::CreateAssetAsyncUseSoftPath(UWorld* World, const FSoftObjectPath& SoftObjectPath)
{
	UAsyncAction_CreateAssetAsync* Action = NewObject<UAsyncAction_CreateAssetAsync>();
	Action->SoftObjectPath = SoftObjectPath;
	Action->World = World;
	Action->RegisterWithGameInstance(World);
	return Action;
}

void UAsyncAction_CreateAssetAsync::Activate()
{
	TWeakObjectPtr<UAsyncAction_CreateAssetAsync> LocalWeakThis(this);
	StreamingHandle = UAssetManager::Get().GetStreamableManager().RequestAsyncLoad(
		SoftObjectPath,
		FStreamableDelegate::CreateUObject(this, &ThisClass::OnAssetLoaded),
		FStreamableManager::AsyncLoadHighPriority
	);
}

void UAsyncAction_CreateAssetAsync::Cancel()
{
	Super::Cancel();

	if (StreamingHandle.IsValid())
	{
		StreamingHandle->CancelHandle();
		StreamingHandle.Reset();
	}
}

void UAsyncAction_CreateAssetAsync::OnAssetLoaded()
{
	UObject* Asset = StreamingHandle->GetLoadedAsset();

	OnComplete.Broadcast(Asset);
	
	if (OnComplete2.IsBound())
	{
		OnComplete2.Execute(Asset);
	}
	
	
	StreamingHandle.Reset();
	SetReadyToDestroy();
}
