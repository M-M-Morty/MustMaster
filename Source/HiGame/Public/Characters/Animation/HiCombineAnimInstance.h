// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "HiCombineAnimInstance.generated.h"

struct FInputBlendPose;
/**
 * 
 */
UCLASS(Blueprintable)
class HIGAME_API UHiCombineAnimInstance : public UHiAnimInstance
{
	GENERATED_BODY()

public:
	int32 AddLinkedMeshComponent(USkeletalMeshComponent* Mesh);
	void SetBasePoseLinkedMeshComponent(USkeletalMeshComponent* Mesh);
	void SetLayeredBlendProfile(int32, TObjectPtr<UBlendProfile> BlendProfile);
	void SetLayeredBoneMaskFilter(int32, const FInputBlendPose&);
	void SetLayeredBoneBlendWeight(int32, float);
protected:
	virtual FAnimInstanceProxy* CreateAnimInstanceProxy() override;
	
};
