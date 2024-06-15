// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "Interfaces/IHttpRequest.h"
#include "Kismet/BlueprintAsyncActionBase.h"
#include "Blueprint/UserWidget.h"
#include "Engine/StreamableManager.h"
#include "GameFramework/PlayerController.h"
#include "Engine/CancellableAsyncAction.h"
#include "Engine/StaticMeshActor.h"

#include "AsyncAction_CreateActorAsync.generated.h"

class UGameInstance;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FCreateActorAsyncDelegate, AActor*, Actor);
DECLARE_DELEGATE_OneParam(FCreateActorAsyncDelegate2, AActor*)
/**
 * Load the widget class asynchronously, the instance the widget after the loading completes, and return it on OnComplete.
 */
UCLASS(BlueprintType)
class HIGAME_API UAsyncAction_CreateActorAsync : public UCancellableAsyncAction
{
	GENERATED_UCLASS_BODY()

public:
	virtual void Cancel() override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_CreateActorAsync* CreateActorAsync(UObject* WorldContextObject, TSoftObjectPtr<UObject> Asset);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_CreateActorAsync* CreateActorAsyncInLua(UWorld* World, const FString& AssetPath);

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_CreateActorAsync* CreateActorWithObjectPathAsync(UWorld* World, const FSoftObjectPath& SoftObjectPath);

	virtual void Activate() override;

public:

	UPROPERTY(BlueprintAssignable)
	FCreateActorAsyncDelegate OnComplete;
	
	FCreateActorAsyncDelegate2 OnComplete2;

private:
	
	void OnAssetLoaded();

	FSoftObjectPath SoftObjectPath;
	TWeakObjectPtr<UWorld> World;
	TSharedPtr<FStreamableHandle> StreamingHandle;
};
