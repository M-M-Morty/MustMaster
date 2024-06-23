// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "HiAnimNotifyState_TimedChangeMID.generated.h"

class UMaterialInterface;
/**
 * 
 */
UCLASS()
class HIGAME_API UHiAnimNotifyState_TimedChangeMID : public UAnimNotifyState
{
	GENERATED_BODY()
	
	virtual void NotifyBegin(USkeletalMeshComponent * MeshComp, UAnimSequenceBase * Animation, float TotalDuration, const FAnimNotifyEventReference& EventReference) override;
	virtual void NotifyTick(USkeletalMeshComponent * MeshComp, UAnimSequenceBase * Animation, float FrameDeltaTime, const FAnimNotifyEventReference& EventReference) override;
	virtual void NotifyEnd(USkeletalMeshComponent * MeshComp, UAnimSequenceBase * Animation, const FAnimNotifyEventReference& EventReference) override;

public:
	UFUNCTION(BlueprintCallable)
	TArray<USceneComponent*> GetMeshComponentChildren(USkeletalMeshComponent* MeshComp);
	
protected:	
	TArray<UMaterialInterface*> Materials;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Parameters)
	TObjectPtr<UMaterialInterface> DynamicMaterial;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Parameters)
	TObjectPtr<UStruct> UserData;
};

