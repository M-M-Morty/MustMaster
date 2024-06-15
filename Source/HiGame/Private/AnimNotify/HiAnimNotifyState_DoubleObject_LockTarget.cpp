// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyState_DoubleObject_LockTarget.h"
#include "Runtime/Engine/Classes/Kismet/GameplayStatics.h"
#include "Characters/HiPlayerCameraManager.h"
#include "VisionerInstance.h"
#include "Characters/VisionerCustomView/HiVisionerView_DoubleObject.h"


void UHiAnimNotifyState_DoubleObject_LockTarget::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);

	APlayerCameraManager* PlayerCameraManager = UGameplayStatics::GetPlayerCameraManager(MeshComp->GetWorld(), 0);
	AHiPlayerCameraManager* HiPlayerCameraManager = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (!HiPlayerCameraManager)
	{
		return;
	}

	if (UVisionerInstance* VisionerInstance = HiPlayerCameraManager->GetVisionerBP())
	{
		if (UHiVisionerView_DoubleObject* DoubleObjectView = Cast<UHiVisionerView_DoubleObject>(VisionerInstance->GetVisionerCustomViewByTag("DoubleObject")))
		{
			if (LockPlayerControlPitch)
			{
				DoubleObjectView->LockControlPitch(true, LockTargetViewPitchPercent * 0.01);	// Percent to decimal
			}
			if (LockPlayerControlYaw)
			{
				DoubleObjectView->LockControlYaw(true);
			}
		}
	}
}

void UHiAnimNotifyState_DoubleObject_LockTarget::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyEnd(MeshComp, Animation, EventReference);

	APlayerCameraManager* PlayerCameraManager = UGameplayStatics::GetPlayerCameraManager(MeshComp->GetWorld(), 0);
	AHiPlayerCameraManager* HiPlayerCameraManager = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (!HiPlayerCameraManager)
	{
		return;
	}

	if (UVisionerInstance* VisionerInstance = HiPlayerCameraManager->GetVisionerBP())
	{
		if (UHiVisionerView_DoubleObject* DoubleObjectView = Cast<UHiVisionerView_DoubleObject>(VisionerInstance->GetVisionerCustomViewByTag("DoubleObject")))
		{
			if (LockPlayerControlPitch)
			{
				DoubleObjectView->LockControlPitch(false);
			}
			if (LockPlayerControlYaw)
			{
				DoubleObjectView->LockControlYaw(false);
			}
		}
	}
}
