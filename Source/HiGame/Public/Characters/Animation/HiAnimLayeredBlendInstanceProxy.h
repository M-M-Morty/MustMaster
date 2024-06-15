// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstanceProxy.h"
#include "AnimNodes/HiAnimNode_LayeredBoneBlend.h"
#include "HiAnimLayeredBlendInstanceProxy.generated.h"


/**
 * 
 */
USTRUCT()
struct FHiAnimLayeredBlendInstanceProxy : public FAnimInstanceProxy
{
	friend struct FHiAnimNode_LayeredBoneBlend;

	GENERATED_BODY()
public:
	FHiAnimLayeredBlendInstanceProxy(){}
	FHiAnimLayeredBlendInstanceProxy(UAnimInstance* InAnimInstance)
		:FAnimInstanceProxy(InAnimInstance)
	{
		BlendNode.Proxy = this;
	}
	virtual ~FHiAnimLayeredBlendInstanceProxy(){}

	virtual void Initialize(UAnimInstance* InAnimInstance) override;
	virtual bool Evaluate(FPoseContext& Output) override;
	virtual void UpdateAnimationNode(const FAnimationUpdateContext& InContext) override;
	virtual void UpdateAnimationNode_WithRoot(const FAnimationUpdateContext& InContext, FAnimNode_Base* InRootNode, FName InLayerName) override;
	virtual void PostUpdate(UAnimInstance* InAnimInstance) const override;
	virtual void PreUpdate(UAnimInstance* InAnimInstance, float DeltaSeconds) override;
	virtual void InitializeObjects(UAnimInstance* InAnimInstance) override;
	virtual void ClearObjects() override;

	void AddLinkedAnimGraph(UAnimInstance* LinkedAnimInstance, int32 PoseIndex=INDEX_NONE);
	void SetBasePoseLinkedAnimGraph(UAnimInstance* LinkedAnimInstance);

	int32 AddLinkedComponent(USkeletalMeshComponent* SourceMeshComponent, int32 PoseIndex=INDEX_NONE);
	void SetBasePoseLinkedComponent(USkeletalMeshComponent* SourceMeshComponent);

	void SetLayeredBlendProfile(int32, TObjectPtr<UBlendProfile> BlendProfile);
	void SetLayeredBoneMaskFilter(int32, const FInputBlendPose&);
	void SetLayeredBoneBlendWeight(int32, float);
protected:
	FHiAnimNode_LayeredBoneBlend BlendNode;
};
