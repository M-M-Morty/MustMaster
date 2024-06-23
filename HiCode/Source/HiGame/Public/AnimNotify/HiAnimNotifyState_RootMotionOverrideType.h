// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "Characters/HiCharacterEnumLibrary.h"

#include "HiAnimNotifyState_RootMotionOverrideType.generated.h"


/**
 * Change Root Motion Override Type
 * - Return to EHiRootMotionOverrideType::All when NotifyEnd
 */

UCLASS()
class UHiAnimNotifyState_RootMotionOverrideType : public UAnimNotifyState
{
	GENERATED_BODY()
	
	virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference) override;
	virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;

	virtual FString GetNotifyName_Implementation() const override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AnimNotify)
	EHiRootMotionOverrideType RootMotionOverrideType = EHiRootMotionOverrideType::Default;
};
