// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "Components/PostProcessComponent.h"
#include "LevelSequence.h"
#include "HiAnimNotifyState_PostProcess.generated.h"

/**
 * 
 */


UCLASS()
class UHiAnimNotifyState_PostProcess : public UAnimNotifyState
{
	GENERATED_BODY()
	
	virtual void NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference) override;
	virtual void NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, float FrameDeltaTime, const FAnimNotifyEventReference& EventReference) override;
	virtual void NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;


public:
	UFUNCTION(BlueprintCallable, Category="Gameplay")
	UPostProcessComponent* TryGetPostProcessComponent(AActor* InActor);

protected:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Gameplay")
	FWeightedBlendables PostProcessMaterials;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Gameplay")
	TObjectPtr<ULevelSequence> LevelSequence;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Gameplay")
	bool PlayerOnly = true;
};
