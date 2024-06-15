// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Characters/Camera/CameraPostProcessorBase.h"
#include "GeometryCollection/GeometryCollectionComponent.h"
#include "GameFramework/Character.h"
#include "HiCameraOcclusionPostProcessor.generated.h"


class UHierarchicalInstancedStaticMeshComponent;

class UMaterialInterface;

USTRUCT()
struct FActorOverrideMaterialSetting
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

USTRUCT()
struct FActorOverrideMaterialSettingArray
{
	GENERATED_BODY()

	UPROPERTY()
	TArray<FActorOverrideMaterialSetting> OverrideMaterialSettings;
};

USTRUCT(BlueprintType)
struct FMaskedMaterialsEffectRecord
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float IneffectDuration = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float FadeFactor = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	int32 ItemIndex = INDEX_NONE;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	TObjectPtr<UHierarchicalInstancedStaticMeshComponent> OriginalInstancedComponent = nullptr;
};

USTRUCT(BlueprintType)
struct FOcclusionDetectContext
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	bool bVisiblityHit = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float TraceLength = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	TArray<AActor*> PendingProcessActors;
};

USTRUCT(BlueprintType)
struct FMaskedMaterialsEffectContext
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	UMeshComponent* EffectMeshComponent = nullptr;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float DeltaTime = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float DistanceOfHitToCamera = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	float DistanceOfCharacterToCamera = 0.0f;
};


UCLASS(BlueprintType, Blueprintable, EditInlineNew, Category = "Camera|Post Processor")
class HIGAME_API UHiCameraOcclusionPostProcessor : public UCameraPostProcessorBase
{
	GENERATED_BODY()

public:

	UHiCameraOcclusionPostProcessor(class FObjectInitializer const&);

	// UCameraPostProcessorBase interface
	virtual void Initialize_Implementation(AHiPlayerCameraManager* PlayerCameraManager) override;
	virtual void Process_Implementation(const float DeltaTime, const FVisionerEvaluateContext& ViewContext) override;
	virtual void OnTargetChanged_Implementation(AActor* NewTarget) override;
	virtual FName GetIdentityName() override;
	// UCameraPostProcessorBase interface end

public:

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void StopPerspective(UMeshComponent* EffectMeshComponent, FMaskedMaterialsEffectRecord& EffectRecord);
	virtual void StopPerspective_Implementation(UMeshComponent* EffectMeshComponent, FMaskedMaterialsEffectRecord& EffectRecord);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	bool StartPerspective(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord);
	virtual bool StartPerspective_Implementation(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void ApplyPerspective(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord);
	virtual void ApplyPerspective_Implementation(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void FadePerspective(const UMeshComponent* EffectMeshComponent, const float HiddenFactor);
	virtual void FadePerspective_Implementation(const UMeshComponent* EffectMeshComponent, const float HiddenFactor);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void OnCameraSequenceOverrideChanged(bool bIsOverride);
	virtual void OnCameraSequenceOverrideChanged_Implementation(bool bIsOverride);

private:
	void PreStartPerspective_InstancedStaticMesh(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord);

private:
	void ProcessPerspectiveEffect(const float DeltaTime, const FVisionerEvaluateContext& ViewContext, const FOcclusionDetectContext& DetectContext);

	void ProcessOutlineEffect(const float DeltaTime, const FVisionerEvaluateContext& ViewContext, const FOcclusionDetectContext& DetectContext);

public:
	/* Occlusion Detection Settings */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Detection")
	FName CameraSocketName = TEXT("Camera_TraceCollision");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Detection")
	float SweepCapsuleRadius = 15.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Detection")
	float SweepCapsuleHalfHeight = 20.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Detection")
	TEnumAsByte<ECollisionChannel> VisibilityChannel = ECollisionChannel::ECC_Visibility;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Detection")
	bool bDebugCollisionTrace = false;

public:
	/* Occlusion Perspective Settings */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	bool bEnableOcclusionPerspective = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	bool bEnableHiddenOcclusionActor = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "0.0", ClampMax = "10.0", ForceUnits = s))
	float PendingIneffectiveDuration = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	float FadeBlendDuration = 0.3f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	float HideBlendDuration = 0.15f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	FName FadeParameterName = TEXT("Fade Intensity");

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective")
	TArray<UClass*> EffectiveMeshClasses;

	/*
	 * For replace material in UInstancedStaticMeshComponent
	 *	   When the number of InstancedMesh greater then this value, copy a new component (only contains select instance) and replace material
	 *	   Conversely, directly replace the material of the current component
	*/
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Perspective", meta = (ClampMin = "1"))
	int32 InstancedBatchReplacedCount = 2;

private:
	/* Occlusion Perspective Variables */
	UPROPERTY()
	TMap<TObjectPtr<UMeshComponent>, FMaskedMaterialsEffectRecord> MeshEffectRecords;

	UPROPERTY()
	TMap<TObjectPtr<AActor>, float> EffectiveOcclusions;

public:
	/* Occlusion Outline Settings */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Outline", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	bool bEnableOcclusionOutline = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Outline", meta = (ClampMin = "0.01", ClampMax = "1.0", ForceUnits = s))
	float DelayOutlineDuration = 0.5f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Outline")
	int32 CustomDepthStencilValue = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Camera Occlusion|Outline")
	TSet<TObjectPtr<UMaterialInstance>> OcclusionPostProcessMaterials;

private:
	/* Occlusion Outline Variables */
	UPROPERTY()
	bool bIsOutlineInEffect = false;

	UPROPERTY()
	float IneffectOutlineDuration = 0.0f;

public:
	/* Meshself Occlusion Opacity */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void StartEffect(AActor* HitActor);
	virtual void StartEffect_Implementation(AActor* HitActor);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void ApplyEffect(AActor* HitActor);
	virtual void ApplyEffect_Implementation(AActor* HitActor);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void HiddenEffect(AActor* HitActor, const float HiddenFactor);
	virtual void HiddenEffect_Implementation(AActor* HitActor, const float HiddenFactor);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Gameplay|RenderEffect")
	void StopEffect(AActor* HitActor);
	virtual void StopEffect_Implementation(AActor* HitActor);

	UPROPERTY()
	TMap<AActor*, FActorOverrideMaterialSettingArray> ActorMapOverrideMaterialSettings;
};