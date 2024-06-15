// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiLocomotionComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include "HiNpcLocomotionAppearance.generated.h"

/**
 * 
 */
UCLASS(BlueprintType)
class HIGAME_API UHiNpcLocomotionAppearance : public UHiLocomotionComponent
{
	GENERATED_BODY()
	
public:
	UHiNpcLocomotionAppearance(const FObjectInitializer& ObjectInitializer);

	virtual void InitializeComponent() override;

	virtual void TickLocomotion(float DeltaTime) override;

	virtual void BeginPlay() override;

	virtual void RagdollStart() override;

	virtual void RagdollEnd() override;

	virtual EHiGait GetActualGait(EHiGait AllowedGait) const;
	
protected:
	TObjectPtr<UHiCharacterMovementComponent> MyCharacterMovementComponent;
	
	/** Movement System */

	virtual void OnRotationModeChanged(EHiRotationMode PreviousRotationMode);

	virtual void OnSpeedScaleChanged(float PrevSpeedScale);

	void UpdateCharacterMovement();
	
	virtual void UpdateCharacterRotation(float DeltaTime) override;

public:

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Input")
	bool bEnableCustomizedRotationWithRootMotion = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Input")
	float DefaultActorRotationSpeed = 3.0f;

private:
	bool bNeedsColorReset = false;
};
