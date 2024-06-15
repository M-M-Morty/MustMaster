// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "Components/TextBlock.h"
#include "LoginUserWidget.generated.h"

class UEditableTextBox;
class UButton;

/**
 *
 */
UCLASS()
class HIGAME_API ULoginUserWidget : public UUserWidget, public FNetworkNotify 
{
	GENERATED_BODY()
public:
	ULoginUserWidget(const FObjectInitializer &ObjectInitializer);
	virtual void NativeConstruct() override;

	UFUNCTION()
	void OnBtnLoginClick();

	UFUNCTION(BlueprintCallable)
	bool ServerTravel(const FString& InURL, bool bAbsolute, bool bShouldSkipGameNotify);

	UFUNCTION(BlueprintCallable)
	void ConnectServer(const FString& IP, const FString& Port);

	UFUNCTION(BlueprintCallable)
	void DisconnectServer();

	UFUNCTION(BlueprintCallable)
	bool IsEditor();

	UFUNCTION(BlueprintCallable)
	FString GetGameDefaultMap();

private:
	inline static bool bIsServerConnected = false;
	UEditableTextBox *TxtServerIP;
	UEditableTextBox *TxtServerPort;
	UButton *BtnLogin;
	UButton *BtnServerState;
	UTextBlock *TxtServerState;

	/** Handle to the registered HandleNetworkFailure delegate */
	FDelegateHandle HandleNetworkFailureDelegateHandle;
	/**
	 * Notification of network error messages, allows a beacon to handle the failure
	 *
	 * @param	World associated with failure
	 * @param	NetDriver associated with failure
	 * @param	FailureType	the type of error
	 * @param	ErrorString	additional string detailing the error
	 */
	virtual void HandleNetworkFailure(UWorld* World, UNetDriver *NetDriver, ENetworkFailure::Type FailureType, const FString& ErrorString);

	void SetServerState(bool isConnection);

	/** handle time update: read and process packets */
	virtual void TickDispatch( float DeltaTime );
	/** Handles to various registered delegates */
	FDelegateHandle TickDispatchDelegateHandle;
	/** Register all TickDispatch, TickFlush, PostTickFlush to tick in World */
	void RegisterTickEvents(class UWorld* InWorld);
	/** Unregister all TickDispatch, TickFlush, PostTickFlush to tick in World */
	void UnregisterTickEvents(class UWorld* InWorld);
};

HIGAME_API DECLARE_LOG_CATEGORY_EXTERN(LogLoginUserWidget, Log, All);
