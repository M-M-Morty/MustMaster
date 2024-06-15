// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/Animation/HiCombineAnimInstance.h"
#include "Characters/Animation/HiAnimLayeredBlendInstanceProxy.h"

int32 UHiCombineAnimInstance::AddLinkedMeshComponent(USkeletalMeshComponent* Mesh)
{
	return GetProxyOnGameThread<FHiAnimLayeredBlendInstanceProxy>().AddLinkedComponent(Mesh); 
}

void UHiCombineAnimInstance::SetBasePoseLinkedMeshComponent(USkeletalMeshComponent* Mesh)
{
	GetProxyOnGameThread<FHiAnimLayeredBlendInstanceProxy>().SetBasePoseLinkedComponent(Mesh);
}

void UHiCombineAnimInstance::SetLayeredBlendProfile(int32 PoseIndex, TObjectPtr<UBlendProfile> BlendProfile)
{
	GetProxyOnGameThread<FHiAnimLayeredBlendInstanceProxy>().SetLayeredBlendProfile(PoseIndex, BlendProfile);
}

void UHiCombineAnimInstance::SetLayeredBoneMaskFilter(int32 PoseIndex, const FInputBlendPose& Filter)
{
	GetProxyOnGameThread<FHiAnimLayeredBlendInstanceProxy>().SetLayeredBoneMaskFilter(PoseIndex, Filter);
}

void UHiCombineAnimInstance::SetLayeredBoneBlendWeight(int32 PoseIndex, float BlendWeight)
{
	GetProxyOnGameThread<FHiAnimLayeredBlendInstanceProxy>().SetLayeredBoneBlendWeight(PoseIndex, BlendWeight);
}

FAnimInstanceProxy* UHiCombineAnimInstance::CreateAnimInstanceProxy()
{
	return new FHiAnimLayeredBlendInstanceProxy(this);
}
