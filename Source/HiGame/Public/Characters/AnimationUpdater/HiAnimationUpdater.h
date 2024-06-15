// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "Engine/DataAsset.h"
#include "HiAnimationUpdater.generated.h"

class UHiCharacterAnimInstance;
/**
 * 
 */
UCLASS(BlueprintType, Blueprintable, Category = "Animation|Animation Updater")
class HIGAME_API UHiAnimationUpdater : public UObject
{
	GENERATED_BODY()

public:
	virtual void Initialize(UHiCharacterAnimInstance *AnimInstance);

	void UnInitialize(UHiCharacterAnimInstance *AnimInstance);

	virtual void NativeUpdateAnimation(float DeltaSeconds);

	virtual void NativePostEvaluateAnimation();

protected:
	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, transient, Category = "AnimInstance Owner")
	TObjectPtr<UHiCharacterAnimInstance> AnimInstanceOwner;

public:
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, transient, Category = "AnimInstance Owner")
	FName Tag;
};


