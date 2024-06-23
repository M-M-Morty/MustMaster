// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Engine/AssetUserData.h"
#include "Interfaces/Interface_AssetUserData.h"
#include "Containers/Map.h"

#include "HiCameraOcclusionOpacityComponent.generated.h"


class UMaterialInterface;

USTRUCT()
struct FOverrideMaterialSetting
{
	GENERATED_BODY()

	UPROPERTY()
	TObjectPtr<class UMeshComponent> MeshComponent = nullptr;
	
	UPROPERTY()
	int32 MaterialIndex = 0;

	UPROPERTY()
	TObjectPtr<class UMaterialInstanceDynamic> DynamicMaterial = nullptr;
	
	UPROPERTY()
	TObjectPtr<class UMaterialInterface> OriginalOverrideMaterial = nullptr;
};


/**
 *
 */

UCLASS(Blueprintable, ClassGroup = (Custom), meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiCameraOcclusionOpacityComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UHiCameraOcclusionOpacityComponent(const FObjectInitializer& ObjectInitializer);

public:

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void StartEffect(const int EffectType = 0);
	virtual void StartEffect_Implementation(const int EffectType = 0);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void ApplyEffect();
	virtual void ApplyEffect_Implementation();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void HiddenEffect(const float HiddenFactor);
	virtual void HiddenEffect_Implementation(const float HiddenFactor);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void StopEffect(const int EffectType = 0);
	virtual void StopEffect_Implementation(const int EffectType = 0);

public:

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Interp, Category = "Gameplay|RenderEffect")
	bool bIsEffectAllowed = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Gameplay|RenderEffect")
	TArray<TObjectPtr<class UMaterialInterface>> EffectMaterials;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Gameplay|RenderEffect")
	TArray<FName> EffectMeshList;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	FName FadeParameterName = TEXT("Fade Intensity");

	UPROPERTY()
	TArray<FOverrideMaterialSetting> OverrideMaterialSettings;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Gameplay|RenderEffect")
	int CurrentEffectFlag = 0;

private:

	UPROPERTY()
	TArray<TObjectPtr<class UMeshComponent>> EffectMeshComponents;
};
