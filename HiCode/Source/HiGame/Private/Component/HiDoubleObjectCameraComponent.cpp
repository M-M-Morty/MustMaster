// Fill out your copyright notice in the Description page of Project Settings.

#include "Component/HiDoubleObjectCameraComponent.h"
#include "Characters/HiPlayerCameraManager.h"


UHiDoubleObjectCameraComponent::UHiDoubleObjectCameraComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
	PrimaryComponentTick.bStartWithTickEnabled = false;
}

void UHiDoubleObjectCameraComponent::OnEnter_Implementation(AHiPlayerCameraManager* PlayerCameraManager)
{
	//check(PlayerCameraManager && PlayerCameraManager->DoubleObjectScheme && PlayerCameraManager->CollisionNode);
	//PlayerCameraManager->DoubleObjectScheme->SetCameraSchemeConfig(CameraSchemeConfig);
	//PlayerCameraManager->CollisionNode->SetTemporaryCollisionChannel(ReplacedCameraCollision);
}

void UHiDoubleObjectCameraComponent::OnLeave_Implementation(AHiPlayerCameraManager* PlayerCameraManager)
{
	//check(PlayerCameraManager && PlayerCameraManager->CollisionNode);
	//PlayerCameraManager->CollisionNode->RestoreCollisionChannel();
}
