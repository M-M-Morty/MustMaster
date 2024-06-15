// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "HiPushOverlapActorComponet.generated.h"


class UHiCharacterMovementComponent;
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UHiPushOverlapActorComponet : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UHiPushOverlapActorComponet();

	UFUNCTION(BlueprintCallable, Category = "Hi|PushOverlapActor")
	virtual void AddOverlapActor(UHiCharacterMovementComponent* Actor);

	UFUNCTION(BlueprintCallable, Category = "Hi|PushOverlapActor")
	virtual void DelOverlapActor(UHiCharacterMovementComponent* Actor);

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
public:
	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|PushOverlapActor")
	bool IsStandOn;

	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|PushOverlapActor",meta=(ToolTip ="push player Speed scale"))
	float SpeedScale=1;

	TArray<UHiCharacterMovementComponent*> ActorArray;

	FVector LastPos;

		
};
