// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HiAppearanceMod.generated.h"


UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiAppearanceMod : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UHiAppearanceMod();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

	/**
	 * Ends gameplay for this component.
	 * Called from AActor::EndPlay only if bHasBegunPlay is true
	 */
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason);
public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|InsertMod")
	class TSubclassOf<UAnimInstance>  InsertModBlueprint;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|InsertMod")
	float BlendInTime;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|InsertMod")
	float BlendOutTime;

	UAnimInstance* AnimIns;



		
};
