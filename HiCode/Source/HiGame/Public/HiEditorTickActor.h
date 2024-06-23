// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "HiEditorTickActor.generated.h"

UCLASS()
class HIGAME_API AHiEditorTickActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AHiEditorTickActor(const FObjectInitializer& ObjectInitializer);
	virtual bool ShouldTickIfViewportsOnly() const override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;
#if WITH_EDITOR
	virtual void EditorTick(float DeltaTime);
#endif

public:
#if WITH_EDITORONLY_DATA
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Transient)
	bool bUseEditorTick = true;
#endif
};
