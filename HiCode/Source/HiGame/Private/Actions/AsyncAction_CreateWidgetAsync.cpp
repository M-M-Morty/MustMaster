// Copyright Epic Games, Inc. All Rights Reserved.

#include "AsyncAction_CreateWidgetAsync.h"

#include <mutex>

#include "Engine/AssetManager.h"
#include "Engine/StreamableManager.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Engine/Engine.h"
#include "Engine/GameInstance.h"
#include "Engine/LocalPlayer.h"
#include "Blueprint/WidgetBlueprintGeneratedClass.h"

UAsyncAction_CreateWidgetAsync::UAsyncAction_CreateWidgetAsync(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

UAsyncAction_CreateWidgetAsync* UAsyncAction_CreateWidgetAsync::CreateWidgetAsync(UObject* WorldContextObject, TSoftClassPtr<UUserWidget> InUserWidgetSoftClass)
{
	if (InUserWidgetSoftClass.IsNull())
	{
		FFrame::KismetExecutionMessage(TEXT("CreateWidgetAsync was passed a null UserWidgetSoftClass"), ELogVerbosity::Error);
		return nullptr;
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);

	UAsyncAction_CreateWidgetAsync* Action = NewObject<UAsyncAction_CreateWidgetAsync>();
	Action->SoftObjectPath = InUserWidgetSoftClass.ToSoftObjectPath();
	Action->World = World;
	Action->RegisterWithGameInstance(World);

	return Action;
}

UAsyncAction_CreateWidgetAsync* UAsyncAction_CreateWidgetAsync::CreateWidgetAsyncInLua(UWorld* World, const FString& WidgetPath)
{
	if (WidgetPath.IsEmpty())
	{
		return nullptr;
	}
	const FAssetRegistryModule& AssetRegistryModule = FModuleManager::GetModuleChecked<FAssetRegistryModule>("AssetRegistry");
	const IAssetRegistry& AssetRegistry = AssetRegistryModule.Get();
	const FAssetData AssetData = AssetRegistry.GetAssetByObjectPath(FSoftObjectPath(*WidgetPath));
	if (!AssetData.IsValid())
	{
		return nullptr;
	}
	
	UAsyncAction_CreateWidgetAsync* Action = NewObject<UAsyncAction_CreateWidgetAsync>();
	Action->SoftObjectPath = FSoftObjectPath(WidgetPath + TEXT("_C"));
	//TSoftClassPtr<UUserWidget> UserWidgetClassPtr = AssetData:GetClass();
	Action->World = World;
	Action->RegisterWithGameInstance(World);
	return Action;
}

void UAsyncAction_CreateWidgetAsync::Activate()
{
	if (SoftObjectPath.IsNull())
	{
		OnComplete.Broadcast(nullptr);
		SetReadyToDestroy();
		return;
	}
	TWeakObjectPtr<UAsyncAction_CreateWidgetAsync> LocalWeakThis(this);
	StreamingHandle = UAssetManager::Get().GetStreamableManager().RequestAsyncLoad(
		SoftObjectPath,
		FStreamableDelegate::CreateUObject(this, &ThisClass::OnWidgetLoaded),
		FStreamableManager::AsyncLoadHighPriority
	);
}

void UAsyncAction_CreateWidgetAsync::Cancel()
{
	Super::Cancel();

	if (StreamingHandle.IsValid())
	{
		StreamingHandle->CancelHandle();
		StreamingHandle.Reset();
	}
}

void UAsyncAction_CreateWidgetAsync::OnWidgetLoaded()
{
	// If the load as successful, create it, otherwise call failed.

	UObject* Asset = StreamingHandle->GetLoadedAsset();
	if (UWidgetBlueprintGeneratedClass* WidgetBlueprintGenerateClass =  Cast<UWidgetBlueprintGeneratedClass>(StreamingHandle->GetLoadedAsset()))
	{
		UUserWidget* UserWidget = UWidgetBlueprintLibrary::Create(World.Get(), WidgetBlueprintGenerateClass, World->GetFirstPlayerController());
		OnComplete.Broadcast(UserWidget);
	}
	else
	{
		OnComplete.Broadcast(nullptr);
	}
	
	StreamingHandle.Reset();

	SetReadyToDestroy();
}
