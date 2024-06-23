// Fill out your copyright notice in the Description page of Project Settings.


#include "HiGameState.h"

AHiGameState::AHiGameState(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, TimerManager(new FTimerManager())
{
	OnWorldPreActorTickHandle = FWorldDelegates::OnWorldPreActorTick.AddUObject(this, &AHiGameState::OnWorldPreActorTick);
}

void AHiGameState::FinishDestroy()
{
	FWorldDelegates::OnWorldPreActorTick.Remove(OnWorldPreActorTickHandle);
	if (TimerManager)
	{
		delete TimerManager;
		TimerManager = nullptr;
	}

	Super::FinishDestroy();
}

void AHiGameState::PostNetInit()
{
	Super::PostNetInit();
	if (IsNetMode(NM_Client))
	{
		UWorld* World = GetWorld();
		AGameStateBase* GameStateBase = World->GetGameState();
		if (!GameStateBase || GameStateBase != this)
		{
			GetWorld()->SetGameState(this);
		}
	}
}

void AHiGameState::PostNetReceive()
{
	Super::PostNetReceive();
	if (IsNetMode(NM_Client))
	{
		UWorld* World = GetWorld();
		AGameStateBase* GameStateBase = World->GetGameState();
		if (!GameStateBase || GameStateBase != this)
		{
			GetWorld()->SetGameState(this);
		}
	}
}

void AHiGameState::BeginPlay()
{
	Super::BeginPlay();
	BeginPlayDelegate.Broadcast(this);
}

void AHiGameState::OnWorldPreActorTick(UWorld* InWorld, ELevelTick InLevelTick, float InDeltaSeconds)
{
	const FGameTime &GameTime = InWorld->GetTime();
	DeltaRealTimeSeconds = GameTime.GetDeltaRealTimeSeconds();

	if (TimerManager)
	{
		TimerManager->Tick(DeltaRealTimeSeconds);
	}
}

void AHiGameState::ClearTimerHandle(const UObject* WorldContextObject, FTimerHandle Handle)
{
	if (Handle.IsValid())
	{
		if (TimerManager)
		{
			TimerManager->ClearTimer(Handle);
		}
	}
}

void AHiGameState::ClearAndInvalidateTimerHandle(const UObject* WorldContextObject, FTimerHandle& Handle)
{
	if (Handle.IsValid())
	{
		if (TimerManager)
		{
			TimerManager->ClearTimer(Handle);
		}
	}
}

FTimerHandle AHiGameState::SetTimerDelegate(FTimerDynamicDelegate Delegate, float Time, bool bLooping, float InitialStartDelay, float InitialStartDelayVariance)
{
	FTimerHandle Handle;
	if (Delegate.IsBound())
	{
		if(TimerManager)
		{
			InitialStartDelay += FMath::RandRange(-InitialStartDelayVariance, InitialStartDelayVariance);
			if (Time <= 0.f || (Time + InitialStartDelay) < 0.f)
			{
				FString ObjectName = GetNameSafe(Delegate.GetUObject());
				FString FunctionName = Delegate.GetFunctionName().ToString(); 
				FFrame::KismetExecutionMessage(*FString::Printf(TEXT("%s %s SetTimer passed a negative or zero time. The associated timer may fail to be created/fire! If using InitialStartDelayVariance, be sure it is smaller than (Time + InitialStartDelay)."), *ObjectName, *FunctionName), ELogVerbosity::Warning);
			}

			Handle = TimerManager->K2_FindDynamicTimerHandle(Delegate);
			TimerManager->SetTimer(Handle, Delegate, Time, bLooping, (Time + InitialStartDelay));
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning, 
			TEXT("SetTimer passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}

	return Handle;
}

FTimerHandle AHiGameState::SetTimerForNextTickDelegate(FTimerDynamicDelegate Delegate)
{
	FTimerHandle Handle;
	if (Delegate.IsBound())
	{
		if (TimerManager)
		{
			Handle = TimerManager->SetTimerForNextTick(Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("SetTimerForNextTick passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}

	return Handle;
}
