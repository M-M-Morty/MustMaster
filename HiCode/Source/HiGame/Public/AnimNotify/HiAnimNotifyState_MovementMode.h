// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/EngineTypes.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "HiAnimNotifyState_MovementMode.generated.h"

/**
 *
 */

UCLASS()
class UHiAnimNotifyState_MovementMode : public UAnimNotifyState
{
	GENERATED_BODY()
	virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration,
							const FAnimNotifyEventReference& EventReference) override;

	virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
							const FAnimNotifyEventReference& EventReference) override;

	virtual FString GetNotifyName_Implementation() const override;

public:

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify)
	TEnumAsByte<enum EMovementMode> EnterMovementMode = EMovementMode::MOVE_Flying;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AnimNotify)
	TEnumAsByte<enum EMovementMode> LeaveMovementMode = EMovementMode::MOVE_Falling;
};
