// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Characters/HiCharacter.h"
#include "Components/ActorComponent.h"
#include "HiTriggerAutoJumpComponent.generated.h"


UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UHiTriggerAutoJumpComponent : public UActorComponent
{
	GENERATED_BODY()

public:	
	// Sets default values for this component's properties
	UHiTriggerAutoJumpComponent();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintCallable, Category = "Hi|AutoJump")
	void AddInTriggerCharacter(AHiCharacter* Character);

	UFUNCTION(BlueprintCallable, Category = "Hi|AutoJump")
	void DelInTriggerCharacter(AHiCharacter* Character);

	UFUNCTION(BlueprintCallable, Category = "Hi|AutoJump")
	void TriggerCharactersArrayAutoJump(UActorComponent* Component, bool bReset);

	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|AutoJump")
	float RootMotionScale = 1.0f;

	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|AutoJump")
	float PlayRate = 1.0f;

	UPROPERTY(EditAnywhere,BlueprintReadWrite, Category = "Hi|AutoJump")
	bool bWalkInAutoJump = false;

	TArray<AHiCharacter*> CharactersArray;	
};
