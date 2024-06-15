// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "UObject/Interface.h"
#include "Nodes/VisionerNode_Base.h"
#include "CameraPostProcessorBase.generated.h"


class AHiPlayerCameraManager;


UCLASS(NotBlueprintType, Category = "Camera|Post Processor")
class HIGAME_API UCameraPostProcessorBase : public UObject
{
	GENERATED_BODY()

public:

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void Initialize(AHiPlayerCameraManager* PlayerCameraManager);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void Process(const float DeltaTime, const FVisionerEvaluateContext& ViewContext);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void OnTargetChanged(AActor* NewTarget);

	UFUNCTION(BlueprintCallable, Category = "Camera|Post Process")
	virtual FName GetIdentityName();
};