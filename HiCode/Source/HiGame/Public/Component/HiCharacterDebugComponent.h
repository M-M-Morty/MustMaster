﻿// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "Kismet/KismetSystemLibrary.h"
#include "Components/ActorComponent.h"
#include "HiCharacterDebugComponent.generated.h"

class AHiCharacter;
class USkeletalMesh;

UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiCharacterDebugComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UHiCharacterDebugComponent();
	
	void BeginPlay() override;

	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, Category = "Hi|Debug")
	void OnPlayerControllerInitialized(APlayerController* Controller);

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
	                           FActorComponentTickFunction* ThisTickFunction) override;

	virtual void OnComponentDestroyed(bool bDestroyingHierarchy) override;

	/** Implemented on BP to update layering colors */
	UFUNCTION(BlueprintImplementableEvent, Category = "Hi|Debug")
	void UpdateColoringSystem();

	/** Implement on BP to draw debug spheres */
	UFUNCTION(BlueprintImplementableEvent, Category = "Hi|Debug")
	void DrawDebugSpheres();

	/** Implemented on BP to set/reset layering colors */
	UFUNCTION(BlueprintImplementableEvent, Category = "Hi|Debug")
	void SetResetColors();

	/** Implemented on BP to set dynamic color materials for debugging */
	UFUNCTION(BlueprintImplementableEvent, Category = "Hi|Debug")
	void SetDynamicMaterials();

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleGlobalTimeDilationLocal(float TimeDilation);

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleSlomo();

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleHud() { bShowHud = !bShowHud; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleDebugView();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Debug")
	void OpenOverlayMenu(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Debug")
	void OverlayMenuCycle(bool bValue);

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleDebugMesh();

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleTraces() { bShowTraces = !bShowTraces; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleDebugShapes() { bShowDebugShapes = !bShowDebugShapes; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleLayerColors() { bShowLayerColors = !bShowLayerColors; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleCharacterInfo() { bShowCharacterInfo = !bShowCharacterInfo; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void ToggleFootLock() { bShowFootLock = !bShowFootLock; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	bool GetDebugView() { return bDebugView; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	bool GetShowTraces() { return bShowTraces; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	bool GetShowDebugShapes() { return bShowDebugShapes; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	bool GetShowLayerColors() { return bShowLayerColors; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	bool GetShowFootLock() { return bShowFootLock; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Debug")
	void FocusedDebugCharacterCycle(bool bValue);

	// utility functions to draw trace debug shapes,
	// which are derived from Engine/Private/KismetTraceUtils.h.
	// Sadly the functions are private, which was the reason
	// why there reimplemented here.
	static void DrawDebugLineTraceSingle(const UWorld* World,
	                                     const FVector& Start,
	                                     const FVector& End,
	                                     EDrawDebugTrace::Type DrawDebugType,
	                                     bool bHit,
	                                     const FHitResult& OutHit,
	                                     FLinearColor TraceColor,
	                                     FLinearColor TraceHitColor,
	                                     float DrawTime);

	static void DrawDebugCapsuleTraceSingle(const UWorld* World,
	                                        const FVector& Start,
	                                        const FVector& End,
	                                        const FCollisionShape& CollisionShape,
	                                        EDrawDebugTrace::Type DrawDebugType,
	                                        bool bHit,
	                                        const FHitResult& OutHit,
	                                        FLinearColor TraceColor,
	                                        FLinearColor TraceHitColor,
	                                        float DrawTime,
	                                        const FQuat &Rotation = FQuat::Identity);

	static void DrawDebugSphereTraceSingle(const UWorld* World,
	                                       const FVector& Start,
	                                       const FVector& End,
	                                       const FCollisionShape& CollisionShape,
	                                       EDrawDebugTrace::Type DrawDebugType,
	                                       bool bHit,
	                                       const FHitResult& OutHit,
	                                       FLinearColor TraceColor,
	                                       FLinearColor TraceHitColor,
	                                       float DrawTime);

	static void DrawDebugBoxTraceSingle(const UWorld* World,
										   const FVector& Start,
										   const FVector& End,
										   const FCollisionShape& CollisionShape,
										   EDrawDebugTrace::Type DrawDebugType,
										   bool bHit,
										   const FHitResult& OutHit,
										   FLinearColor TraceColor,
										   FLinearColor TraceHitColor,
										   float DrawTime);

protected:
	void DetectDebuggableCharactersInWorld();

public:
	UPROPERTY(BlueprintReadOnly, Category = "Hi|Debug")
	TObjectPtr<AHiCharacter> OwnerCharacter;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Debug")
	bool bSlomo = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Debug")
	bool bShowHud = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Debug")
	bool bShowCharacterInfo = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Debug")
	bool bShowFootLock = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Debug")
	TObjectPtr<USkeletalMesh> DebugSkeletalMesh = nullptr;
	
	UPROPERTY(BlueprintReadOnly, Category = "Hi|Debug")
	TArray<TObjectPtr<AHiCharacter>> AvailableDebugCharacters;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Debug")
	TObjectPtr<AHiCharacter> DebugFocusCharacter = nullptr;
private:
	static bool bDebugView;

	static bool bShowTraces;

	static bool bShowDebugShapes;

	static bool bShowLayerColors;

	bool bNeedsColorReset = false;

	bool bDebugMeshVisible = false;

	UPROPERTY()
	TObjectPtr<USkeletalMesh> DefaultSkeletalMesh = nullptr;
	
	/// Stores the index, which is used to select the next focused debug ALSBaseCharacter.
	/// If no characters where found during BeginPlay the value should be set to INDEX_NONE.
	int32 FocusedDebugCharacterIndex = INDEX_NONE;
};

