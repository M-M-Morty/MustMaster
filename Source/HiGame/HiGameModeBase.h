// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/PartialWorldGameModeBase.h"
#include "HiGameModeBase.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API AHiGameModeBase : public APartialWorldGameModeBase
{
	GENERATED_BODY()
public:
	AHiGameModeBase();
	virtual FString InitNewPlayer(APlayerController* NewPlayerController, const FUniqueNetIdRepl& UniqueId, const FString& Options, const FString& Portal = TEXT("")) override;
	virtual APlayerController* Login(UPlayer* NewPlayer, ENetRole InRemoteRole, const FString& Portal, const FString& Options, const FUniqueNetIdRepl& UniqueId, FString& ErrorMessage) override;
	virtual void PostLogin(APlayerController* NewPlayer) override;
	virtual void ReplicateStreamingStatus(APlayerController* PC) override;

	virtual APlayerController* SpawnPlayerController(ENetRole InRemoteRole, const FString& Options) override;
	virtual APlayerController* SpawnPlayerControllerCommon(ENetRole InRemoteRole, FVector const& SpawnLocation, FRotator const& SpawnRotation, TSubclassOf<APlayerController> InPlayerControllerClass) override;

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category=Game)
	bool EnableCheats(APlayerController* P);

	virtual bool AllowCheats(APlayerController* P);

public:
	class FLoginProgressScope
	{
	public:
		explicit FLoginProgressScope(AHiGameModeBase* InGameModeBase, const FString& InOptions)
			: GameModeBase(InGameModeBase)
		{
			CachedOptions = GameModeBase->LoginProgressOptions;
			GameModeBase->LoginProgressOptions = InOptions;
			GameModeBase->bInLoginProgressScope++;
		}
		virtual ~FLoginProgressScope()
		{
			GameModeBase->LoginProgressOptions = CachedOptions;
			GameModeBase->bInLoginProgressScope--;
		}
	private:
		AHiGameModeBase* GameModeBase;
		FString CachedOptions;
	};
protected:
	int32 bInLoginProgressScope = 0;
	FString LoginProgressOptions;
};
