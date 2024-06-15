// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotify.h"
#include "Characters/HiCharacterStructLibrary.h"

#include "HiAnimNotifyGroundedEntryState.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiAnimNotifyGroundedEntryState : public UAnimNotify
{
	GENERATED_BODY()

	virtual void Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;

	virtual FString GetNotifyName_Implementation() const override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AnimNotify)
	EHiGroundedEntryState GroundedEntryState = EHiGroundedEntryState::None;
};
