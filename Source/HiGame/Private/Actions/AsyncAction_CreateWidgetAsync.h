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

#include "AsyncAction_CreateWidgetAsync.generated.h"

class UGameInstance;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FCreateWidgetAsyncDelegate, UUserWidget*, UserWidget);

/**
 * Load the widget class asynchronously, the instance the widget after the loading completes, and return it on OnComplete.
 */
UCLASS(BlueprintType)
class HIGAME_API UAsyncAction_CreateWidgetAsync : public UCancellableAsyncAction
{
	GENERATED_UCLASS_BODY()

public:
	virtual void Cancel() override;

	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_CreateWidgetAsync* CreateWidgetAsync(UObject* WorldContextObject, TSoftClassPtr<UUserWidget> UserWidgetSoftClass);
	
	UFUNCTION(BlueprintCallable, BlueprintCosmetic, meta=(WorldContext = "WorldContextObject", BlueprintInternalUseOnly="true"))
	static UAsyncAction_CreateWidgetAsync* CreateWidgetAsyncInLua(UWorld* World, const FString& WidgetPath);
	virtual void Activate() override;

public:

	UPROPERTY(BlueprintAssignable)
	FCreateWidgetAsyncDelegate OnComplete;

private:
	
	void OnWidgetLoaded();
	
	FSoftObjectPath SoftObjectPath;
	TWeakObjectPtr<UWorld> World;
	TSoftClassPtr<UUserWidget> UserWidgetSoftClass;
	TSharedPtr<FStreamableHandle> StreamingHandle;
};
