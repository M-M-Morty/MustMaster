// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiNotifyStateRootMotionScale.h"

#include "AnimNodes/AnimNode_RandomPlayer.h"
#include "Characters/HiLocomotionCharacter.h"
#include "Characters/Animation/HiLocomotionAnimInstance.h"


void UHiNotifyStateRootMotionScale::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                                float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
	
	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	UHiLocomotionAnimInstance* LocomotionAnimInstance = Cast<UHiLocomotionAnimInstance>(MeshComp->GetLinkedAnimGraphInstanceByTag(TEXT("Locomotion")));
	if (BaseCharacter && LocomotionAnimInstance)
	{
		if(LocomotionAnimInstance->bAllowAutoJump)
		{
			BaseCharacter->SetAnimRootMotionTranslationScale(BaseCharacter->LandedAutoJumpBeginRootMotionScale);
			BaseCharacter->AutoJumpRateScale = BaseCharacter->LandedAutoJumpBeginPlayRate;
		}
	}
}

void UHiNotifyStateRootMotionScale::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);
	
	AHiLocomotionCharacter* BaseCharacter = Cast<AHiLocomotionCharacter>(MeshComp->GetOwner());
	UHiLocomotionAnimInstance* LocomotionAnimInstance = Cast<UHiLocomotionAnimInstance>(MeshComp->GetLinkedAnimGraphInstanceByTag(TEXT("Locomotion")));
	if (BaseCharacter && LocomotionAnimInstance)
	{
			BaseCharacter->SetAnimRootMotionTranslationScale(1.0f);
			BaseCharacter->AutoJumpRateScale = 1.0f;
			BaseCharacter->LandedAutoJumpBeginRootMotionScale = 1.0f;
			BaseCharacter->LandedAutoJumpBeginPlayRate = 1.0f;
			LocomotionAnimInstance->bAllowAutoJump = false;
	}
}

void UHiNotifyStateRootMotionScale::NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float FrameDeltaTime, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference);
}

FString UHiNotifyStateRootMotionScale::GetNotifyName_Implementation() const
{
	FString Name = FString::Printf(TEXT("Change RootMotionScale"));
	return Name;
}
