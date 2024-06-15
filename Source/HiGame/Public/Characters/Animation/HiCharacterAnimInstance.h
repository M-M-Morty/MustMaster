// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Characters/Animation/HiAnimInstance.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "Characters/AnimationUpdater/HiAnimationUpdater.h"
#include "HiCharacterAnimInstance.generated.h"

class UHiAnimationUpdater;
/**
 * 
 */
UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiCharacterAnimInstance : public UHiAnimInstance
{
	GENERATED_BODY()
	
public:
	virtual void NativeBeginPlay() override;

	virtual void NativeUninitializeAnimation() override;
	
	virtual void NativeUpdateAnimation(float DeltaSeconds) override;

	virtual void NativePostEvaluateAnimation() override;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void WalkStop();
private:
	EHiMovementDirection CalculateMovementDirection(float& NewRootYawOffset);

public:
	/** Configuration */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	FHiAnimGroundedConfig GroundedConfig;
	
	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementDirection MovementDirection = EHiMovementDirection::Forward;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	float RootYawOffset = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Character Information")
	float RootYawOffsetInterpSpeed = 7.0f;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, Category = "Evaluation Data")
	FHiAnimGraphGrounded Grounded;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Configuration|Turn In Place", Meta = (
		ShowOnlyInnerProperties))
	FHiAnimTurnInPlace TurnInPlaceValues;
	
	/** Foot IK - Values */
	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiFootAnimValues FootAnimValues;

	/** Foot IK - Configuration */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	FHiFootAnimConfig FootAnimConfig;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementState MovementState = EHiMovementState::None;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, Category = "Read Only Data|Character Information", Meta = (
		ShowOnlyInnerProperties))
	FHiAnimCharacterInformation CharacterInformation;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiGait LogicGait = EHiGait::Idle;				// Idle / Walking / Running / Sprinting

	UFUNCTION(BlueprintCallable, Category = "Animation") 
	UHiAnimationUpdater* GetAnimationUpdater(FName Tag);

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	TArray<TSubclassOf<UHiAnimationUpdater>> AnimationUpdaterClasses;

	UPROPERTY(Transient, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	TArray<TObjectPtr<UHiAnimationUpdater>> AnimationUpdaters;
};
