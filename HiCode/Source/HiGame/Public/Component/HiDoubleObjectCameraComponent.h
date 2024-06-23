// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Characters/VisionerCustomView/HiViewConfig_DoubleObject.h"

#include "HiDoubleObjectCameraComponent.generated.h"


class AHiPlayerCameraManager;

/**
  * UHiDoubleObjectCameraComponent
  *
  *	An actor component class used to preset different parameters on the character
 */

UCLASS(BlueprintType, Blueprintable, meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiDoubleObjectCameraComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UHiDoubleObjectCameraComponent();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void OnEnter(AHiPlayerCameraManager* PlayerCameraManager);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void OnLeave(AHiPlayerCameraManager* PlayerCameraManager);
	
public:
	
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = Attribute)
	bool bEnableCameraScheme = true;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = Attribute)
	TEnumAsByte<ECollisionChannel> ReplacedCameraCollision = ECollisionChannel::ECC_Visibility;

	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = Attribute, meta = (ShowInnerProperties))
	FHiViewConfig_DoubleObject CameraSchemeConfig;
};
