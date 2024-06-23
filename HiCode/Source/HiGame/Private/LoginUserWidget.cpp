// Fill out your copyright notice in the Description page of Project Settings.


#include "LoginUserWidget.h"
#include "Engine/NetConnection.h"

#include "Kismet/GameplayStatics.h"
#include "Components/Button.h"
#include "Components/EditableTextBox.h"
#include "GameFramework/GameModeBase.h"
#include "UObject/UObjectGlobals.h"
#include "GameMapsSettings.h"

#include "Logging/LogMacros.h"

DEFINE_LOG_CATEGORY(LogLoginUserWidget);

ULoginUserWidget::ULoginUserWidget(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
	TxtServerIP = NULL;
	TxtServerPort = NULL;
	BtnLogin = NULL;
}

void ULoginUserWidget::HandleNetworkFailure(UWorld* World, UNetDriver* InNetDriver, ENetworkFailure::Type FailureType, const FString& ErrorString)
{
	bIsServerConnected = false;
	SetServerState(bIsServerConnected);
	UnregisterTickEvents(GetWorld());
	if (APlayerController* PC = GetWorld()->GetFirstPlayerController())
	{
		PC->OnNetCleanup(InNetDriver->ServerConnection);
	}
	UE_LOG(LogLoginUserWidget, Warning, TEXT("HandleNetworkFailure: FailureType(%i) NetMode(%i)"), FailureType, World->GetNetMode());
}

void ULoginUserWidget::NativeConstruct()
{
	Super::NativeConstruct();

	if (UEditableTextBox *textbox = Cast<UEditableTextBox>(GetWidgetFromName("TextBoxServerIP")))
	{
		TxtServerIP = textbox;
	}

	if (UEditableTextBox *textbox = Cast<UEditableTextBox>(GetWidgetFromName("TextBoxServerPort")))
	{
		TxtServerPort = textbox;
	}

	if (UButton *btn = Cast<UButton>(GetWidgetFromName("BtnLogin")))
	{
		BtnLogin = btn;

		FScriptDelegate Del;
		Del.BindUFunction(this, "OnBtnLoginClick");
		btn->OnClicked.Add(Del);
	}
	if (UButton* btn_server = Cast<UButton>(GetWidgetFromName("Button_ServerState")))
	{
		BtnServerState = btn_server;
	}
	if (UTextBlock* txt_server = Cast<UTextBlock>(GetWidgetFromName("Txt_ServerState")))
	{
		TxtServerState = txt_server;
	}
	SetServerState(bIsServerConnected);
	RegisterTickEvents(GetWorld());
	//HandleNetworkFailureDelegateHandle = GEngine->OnNetworkFailure().AddUObject(this, &ULoginUserWidget::HandleNetworkFailure);
}

bool ULoginUserWidget::ServerTravel(const FString& InURL, bool bAbsolute, bool bShouldSkipGameNotify)
{
	if (UWorld* wd = GetWorld())
	{
		return wd->ServerTravel(InURL, bAbsolute, bShouldSkipGameNotify);
	}
	return false;
}

void ULoginUserWidget::SetServerState(bool isConnection)
{
	if (isConnection)
	{
		BtnServerState->SetBackgroundColor(FLinearColor(FColor(0.0, 255.0, 0.0)));
		TxtServerState->SetText(FText::FromString(TEXT("Connected")));
	}
	else
	{
		BtnServerState->SetBackgroundColor(FLinearColor(FColor(0.0, 0.0, 0.0)));
		TxtServerState->SetText(FText::FromString(TEXT("Disconnected")));
	}
}

void ULoginUserWidget::ConnectServer(const FString& IP, const FString& Port)
{
	if (APlayerController *PC = GetWorld()->GetFirstPlayerController())
	{
		FString URL = FString::Printf(TEXT("%s:%s"), *IP, *Port);
		PC->ClientTravel(*URL, TRAVEL_Absolute);
		SetVisibility(ESlateVisibility::Hidden);
		//RemoveFromViewport();
		// 最好有知道连接上的途径
		bIsServerConnected = true;
		SetServerState(bIsServerConnected);
	}
}

void ULoginUserWidget::RegisterTickEvents(class UWorld* InWorld)
{
	if (InWorld)
	{
		TickDispatchDelegateHandle  = InWorld->OnTickDispatch ().AddUObject(this, &ULoginUserWidget::TickDispatch);
	}
}

void ULoginUserWidget::TickDispatch(float DeltaTime)
{
	/*if (UWorld* wd = GetWorld())
	{
		UNetDriver* const NetDriver = wd->GetNetDriver();
		if (NetDriver)
		{
			UE_LOG(LogLoginUserWidget, Warning, TEXT("TickDispatch: Num(%d)"), NetDriver->ClientConnections.Num());
		}
	}*/
	// 目前 ClientTravel 之后，就不再是 Standalone 模式了
	// OnNetworkFailure 之后 IsStandalone 和 IsServer 都是 false
	//if (!bIsServerConnected && !UKismetSystemLibrary::IsStandalone(GetWorld()) && !UKismetSystemLibrary::IsServer(GetWorld()))
	//{
	//	bIsServerConnected = true;
	//	SetServerState(bIsServerConnected);
	//}
}

void ULoginUserWidget::UnregisterTickEvents(class UWorld* InWorld)
{
	if (InWorld)
	{
		InWorld->OnTickDispatch ().Remove(TickDispatchDelegateHandle);
	}
}

bool ULoginUserWidget::IsEditor()
{
#if WITH_EDITOR
	return true;
#else
	return false;
#endif
}

FString ULoginUserWidget::GetGameDefaultMap()
{
	
	return GetDefault<UGameMapsSettings>()->GetGameDefaultMap();
}

void ULoginUserWidget::DisconnectServer()
{
}

void ULoginUserWidget::OnBtnLoginClick()
{
	ConnectServer(TxtServerIP->GetText().ToString(), TxtServerPort->GetText().ToString());
}
