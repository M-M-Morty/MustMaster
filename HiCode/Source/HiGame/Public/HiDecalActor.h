// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DecalActor.h"
#include "HiDecalActor.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, BlueprintType, config=Game)
class HIGAME_API AHiDecalActor : public ADecalActor
{
	GENERATED_BODY()
public:	
	AHiDecalActor(const FObjectInitializer& ObjectInitializer);

#if WITH_EDITOR
protected:
	virtual void Tick(float DeltaTime) override;
	void UpdateBoxBounds();
#endif
	
public:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly)
	TObjectPtr<UBoxComponent> BoxComponent;
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	bool bAutoUpdateBounds = true;
};
