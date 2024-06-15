// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiEditorTickActor.h"
#include "HiAkEditorableActor.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType, config=Game)
class HIGAME_API AHiAkEditorableActor : public AHiEditorTickActor
{
	GENERATED_BODY()
public:	
	AHiAkEditorableActor(const FObjectInitializer& ObjectInitializer);

#if WITH_EDITOR
	void OnToggleSelectWireSwitch(const FString& ClassName, bool bToggle);
	virtual void EditorTick(float DeltaTime) override;
	void DebugDrawSourcePoints();
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
	virtual FBox GetStreamingBounds() const override;
#endif
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void Tick(float DeltaTime) override;
	
	UFUNCTION(BlueprintNativeEvent)
	void DoDistanceCulling();

	UFUNCTION(BlueprintImplementableEvent)
	void RecieveInsideCullingRange();
	UFUNCTION(BlueprintImplementableEvent)
	void RecieveOutsideCullingRange();
	
public:
#if WITH_EDITORONLY_DATA
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)	
	bool bDebugDraw = false;
#endif

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere)
	TObjectPtr<class UAkComponent> AkComponent;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	TArray<FTransform> SourcePositions;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float CullingDistance = 1000.0f;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	FVector CenterLocation;

	UPROPERTY(BlueprintReadWrite, Transient)
	bool bPlaying = false;

#if WITH_EDITORONLY_DATA
protected:
	FDelegateHandle OnToggleSelectDelegateHandle;
#endif
};
