// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/EngineTypes.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "HiAnimNotifyState_DoubleObject_LockTarget.generated.h"

/**
 *
 */

UCLASS()
class UHiAnimNotifyState_DoubleObject_LockTarget : public UAnimNotifyState
{
	GENERATED_BODY()
	virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration,
							const FAnimNotifyEventReference& EventReference) override;

	virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
							const FAnimNotifyEventReference& EventReference) override;

public:

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify)
	bool LockPlayerControlPitch = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify, meta = (ForceUnits = "Percent", ClampMin = "-50", ClampMax = "50"))
	float LockTargetViewPitchPercent = 30.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify)
	bool LockPlayerControlYaw = false;
};
