// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/ObjectMacros.h"
#include "UObject/Interface.h"
#include "CameraPostProcessorBase.generated.h"


class AHiPlayerCameraManager;


/** Evaluation context passed around during graph evaluation */
USTRUCT(BlueprintType)
struct HIGAME_API FPostProcessEvaluateContext
{
	GENERATED_BODY()

	// Camera Pose
	UPROPERTY(EditAnywhere, Category = "Visioner Evaluate Context")
	FMinimalViewInfo POV;
	// CameraManager
	UPROPERTY(EditAnywhere, Category = "Visioner Evaluate Context")
	TObjectPtr<APlayerCameraManager> PlayerCameraManager = nullptr;
	// Character
	UPROPERTY(EditAnywhere, Category = "Visioner Evaluate Context")
	TObjectPtr<AActor> ViewTarget = nullptr;
};


UCLASS(NotBlueprintType, Category = "Camera|Post Processor")
class HIGAME_API UCameraPostProcessorBase : public UObject
{
	GENERATED_BODY()

public:

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void Initialize(AHiPlayerCameraManager* PlayerCameraManager);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void Process(const float DeltaTime, const FPostProcessEvaluateContext& ViewContext);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Camera|Post Process")
	void OnTargetChanged(AActor* NewTarget);

	UFUNCTION(BlueprintCallable, Category = "Camera|Post Process")
	virtual FName GetIdentityName();
};