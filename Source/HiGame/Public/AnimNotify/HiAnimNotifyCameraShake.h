// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Camera/CameraShakeBase.h"
#include "Animation/AnimNotifies/AnimNotify.h"
#include "HiAnimNotifyCameraShake.generated.h"

class UCameraShakeBase;

/**
 * Generic camera shake animation notify for pawns with controller enabled
 */
UCLASS()
class HIGAME_API UHiAnimNotifyCameraShake : public UAnimNotify
{
	GENERATED_BODY()

	virtual void Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AnimNotify)
	TSubclassOf<UCameraShakeBase> ShakeClass;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AnimNotify)
	float Scale = 1.0f;
};
