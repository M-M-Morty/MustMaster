// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"

#include "HiNotifyStateMoveActionInterruption.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiNotifyStateMoveActionInterruption : public UAnimNotifyState
{
	GENERATED_BODY()

	virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration,
	                         const FAnimNotifyEventReference& EventReference) override;

	virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	                       const FAnimNotifyEventReference& EventReference) override;

	virtual FString GetNotifyName_Implementation() const override;


public:
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify, meta = (ClampMin = "0.0", ClampMax = "180.0", UIMin = "0.0", UIMax = "180.0", ForceUnits = "degrees"))
	float MinimumInterruptionAngle = 10.0f;
};
