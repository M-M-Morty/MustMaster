// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiCharacter.h"
#include "InputActionValue.h"
#include "GameFramework/PartialWorldPlayerController.h"
#include "GameFramework/PlayerController.h"
#include "GEOQuadTreeTypes.h"
#include "GameFramework/GameModeBase.h"
#include "HiPlayerController.generated.h"

class UInputMappingContext;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FOnPossessEvent, APawn*, ThePawn, bool, bPossess);

/**
 * Player controller class
 */
UCLASS(Blueprintable, BlueprintType)
class HIGAME_API AHiPlayerController : public APartialWorldPlayerController
{
	GENERATED_BODY()

public:
	AHiPlayerController();

	virtual void BeginPlay() override;

	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	virtual void Destroyed() override;
	
	virtual void OnPossess(APawn* NewPawn) override;

	virtual void OnUnPossess() override;

	virtual void OnRep_Pawn() override;

	virtual void SetupInputComponent() override;

	virtual void BindActions(UInputMappingContext* Context);

	virtual void Tick(float DeltaSeconds) override;
	
	UFUNCTION(BlueprintCallable)
	virtual FString LuaConsoleCommand(const FString& Cmd, bool bWriteToLog);

	UFUNCTION(Client, Reliable)
	void ClientSetGeoSpaceInfo(const FGeoWorldConfig& WorldConfig, const TArray<FGeoRegionInfo>& RegionInfoList);

	/**
	 * Convert a World Space 3D position into a 2D Screen Space position with in front of screen or behind screen.
	 * @return true if the world coordinate was successfully projected to the screen.
	 */
	UFUNCTION(BlueprintCallable, Category="Game|Player", meta = (DisplayName = "Convert World Location To Screen Location With Direction", Keywords = "project"))
	bool ProjectWorldLocationToScreenPositionWithDirection(FVector WorldLocation, bool bPlayerViewportRelative, FVector2D& ScreenPosition, bool& bFront);

	UFUNCTION(BlueprintCallable, Category="Render")
	void SetRenderPrimitiveComponents(bool bEnabled);

	UFUNCTION(BlueprintPure, Category="Render")
	bool IsRenderPrimitiveComponents();

	UFUNCTION(BlueprintCallable, Category="Render")
	void SetRenderShowOnlyPrimitiveComponents(bool bEnabled);

	UFUNCTION(BlueprintPure, Category = "Render")
	bool IsRenderShowOnlyPrimitiveComponents();

	UFUNCTION(BlueprintCallable, Category="Render")
	void SetShowOnlyActors(TArray<AActor*> Actors);

	UFUNCTION(BlueprintCallable, Category="Render")
	void AddShowOnlyActor(AActor* Actor);
	
	UFUNCTION(BlueprintNativeEvent)
	void DoLuaString(const FString& LuaStr);

	//////////////////// DS reconnection start
	virtual void PawnLeavingGame() override;
	virtual void InitPlayerState() override;
	virtual void InitPlayerStateFromGameMode(const AGameModeBase* GameMode);
	//////////////////// DS reconnection end

protected:

	virtual bool GetStreamingSourcesInternal(TArray<FWorldPartitionStreamingSource>& OutStreamingSources) const;
	void SetupInputs();
	
	void SetupCamera();

	void UnbindCamera();

	UFUNCTION(BlueprintNativeEvent)
	void ForwardMovementAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void RightMovementAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void CameraUpAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void CameraRightAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void CameraScaleAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void JumpAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void SprintAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void AimAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void AttackAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void StanceAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void WalkAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void RagdollAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void VelocityDirectionAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void LookingDirectionAction(const FInputActionValue& Value);

	// Debug actions
	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleHudAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleDebugViewAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleTracesAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleShapesAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleLayerColorsAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleCharacterInfoAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleSlomoAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugFocusedCharacterCycleAction(const FInputActionValue& Value);
	
	UFUNCTION(BlueprintNativeEvent)
	void DebugToggleMeshAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugOpenOverlayMenuAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void DebugOverlayMenuCycleAction(const FInputActionValue& Value);

	UFUNCTION(BlueprintNativeEvent)
	void GetInVehicleAction(const FInputActionValue& Value);


public:
	/** Main character reference */
	UPROPERTY(BlueprintReadOnly, Category = "Hi")
	TObjectPtr<AHiCharacter> PossessedCharacter = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Input")
	TObjectPtr<UInputMappingContext> DefaultInputMappingContext = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Input")
	TObjectPtr<UInputMappingContext> DebugInputMappingContext = nullptr;

	//Interact manager, deals everything with INTERACT.
	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	class UInteractManagerComponent* InteractManager;

	UPROPERTY(VisibleInstanceOnly, BlueprintReadOnly, Category = "Hi")
	bool bIsPossessPawnCalled = false;

	UPROPERTY(BlueprintAssignable)
	FOnPossessEvent OnPossessEvent;
	
	void PlayerReplicateStreamingStatus();

	void OnPossessPawnReady();

	// TODO. AugustusDu. 后续是否支持Add和Remove时进行更新，减少同步消耗
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated, Category="Hi")
	TArray<TObjectPtr<AHiCharacter>> SwitchPlayers;

	UFUNCTION(BlueprintCallable)
	void AddSwitchPlayer(AHiCharacter* InHiCharacter);

	UFUNCTION(BlueprintCallable)
	void RemoveSwitchPlayer(AHiCharacter* InHiCharacter);

private:
	void InternalPlayerReplicateStreamingStatus();
	int32 SentStreamingStatusIdx = 0;

public:
	void InitPlayerProxyID(uint64 InPlayerProxyID) { PlayerProxyID = InPlayerProxyID; }
	void InitPlayerGuid(uint64 InPlayerGuid) { PlayerGuid = InPlayerGuid; }
	void InitPlayerRoleId(uint64 InPlayerRoleId) { PlayerRoleId = InPlayerRoleId; }

	UFUNCTION(BlueprintCallable, Category="Game|Player")
	int64 GetPlayerProxyID() const { return static_cast<int64>(PlayerProxyID); }

	UFUNCTION(BlueprintCallable, Category="Game|Player")
	int64 GetPlayerGuid() const { return static_cast<int64>(PlayerGuid); }

	UFUNCTION(BlueprintCallable, Category="Game|Player")
	FString GetPlayerGuidAsString() const { return FString(std::to_string(PlayerGuid).c_str()); }

	UFUNCTION(BlueprintCallable, Category="Game|Player")
	int64 GetPlayerRoleId() const { return static_cast<int64>(PlayerRoleId); }
	
	UFUNCTION(BlueprintCallable, Category="Game|Player")
	FString GetPlayerRoleIdAsString() const { return FString(std::to_string(PlayerRoleId).c_str()); }
	
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

protected:
	UPROPERTY(Replicated)
	uint64 PlayerProxyID;

	// G6 生成的账号唯一ID
	UPROPERTY(Replicated)
	uint64 PlayerGuid;	

	// 账号创建时，Lobby服务生成的全服唯一角色ID， 后续约定业务上使用此ID
	UPROPERTY(Replicated)
	uint64 PlayerRoleId;

	UPROPERTY(Replicated, BlueprintReadOnly)
	bool bIsReconnected;
};
