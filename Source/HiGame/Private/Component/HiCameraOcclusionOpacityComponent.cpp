// Fill out your copyright notice in the Description page of Project Settings.

#include "Component/HiCameraOcclusionOpacityComponent.h"
#include "Components/MeshComponent.h"
#include "GeometryCollection/GeometryCollectionComponent.h"
#include "Materials/MaterialInstanceDynamic.h"

// Default Parameters
const float DefaultStartEffectFactor = 1.0f;
const float DefaultEndEffectFactor = 0.0f;


UHiCameraOcclusionOpacityComponent::UHiCameraOcclusionOpacityComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bCanEverTick = false;
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bAllowTickOnDedicatedServer = false;
}

void UHiCameraOcclusionOpacityComponent::StartEffect_Implementation(const int EffectType)
{
	check(EffectType >= 0 && EffectType < 16);
	const int EffectFlag = 1 << EffectType;
	const int OldEffectFlag = CurrentEffectFlag;
	CurrentEffectFlag = OldEffectFlag | EffectFlag;
	if (OldEffectFlag || !CurrentEffectFlag)
	{
		return;
	}
	
	EffectMeshComponents.Empty();

	TArray<UActorComponent*> ActorComponents = GetOwner()->K2_GetComponentsByClass(UMeshComponent::StaticClass());
	for (UActorComponent* ActorComponent : ActorComponents)
	{
		// Only effective on these types of components
		if (!Cast<const UStaticMeshComponent>(ActorComponent) && !Cast<const USkeletalMeshComponent>(ActorComponent) && !Cast<const UGeometryCollectionComponent>(ActorComponent))
		{
			continue;
		}
		UMeshComponent* EffectMeshComponent = Cast<UMeshComponent>(ActorComponent);
		check(IsValid(EffectMeshComponent));
		//OverlapMultiByChannel check max response of all components so here check again
		if (EffectMeshComponent->GetCollisionResponseToChannel(ECC_Visibility) == ECR_Ignore)
		{
			continue;
		}
		EffectMeshComponents.Add(EffectMeshComponent);
	}
	
	// Create dynamic material instances
	if (OverrideMaterialSettings.IsEmpty())
	{
		auto GetDefaultStaticMeshFunc = [](UMeshComponent* InComponent) -> UStaticMesh*
		{
			UStaticMeshComponent* StaticMeshComponent = Cast<UStaticMeshComponent>(InComponent);
			if (!StaticMeshComponent)
			{
				return nullptr;
			}
			return StaticMeshComponent->GetStaticMesh();
		};
		
		// Override materials
		TArray<TObjectPtr<class UMaterialInterface>> ReplacedMaterials;
		for(int32 MeshComponentIndex = 0; MeshComponentIndex < EffectMeshComponents.Num(); MeshComponentIndex++)
		{
			UMeshComponent* EffectMeshComponent = EffectMeshComponents[MeshComponentIndex];
			check(EffectMeshComponent);
			ReplacedMaterials = EffectMeshComponent->DynamicReplacedMaterials;
			if (EffectMeshComponent->GetNumMaterials() != EffectMeshComponent->DynamicReplacedMaterials.Num())
			{
				if (UStaticMesh* DefaultMeshAsset = GetDefaultStaticMeshFunc(EffectMeshComponent))
				{
					ReplacedMaterials.Empty();
					ReplacedMaterials = DefaultMeshAsset->DynamicReplacedMaterials;
					if (EffectMeshComponent->GetNumMaterials() != ReplacedMaterials.Num() && ReplacedMaterials.Num())
					{
						UE_LOG(LogTemp, Error, TEXT("StaticMesh: %s has invalid Materials than DynamicReplacedMaterials."), *DefaultMeshAsset->GetFName().ToString());
						continue;
					}
				}
				else if(EffectMeshComponent->DynamicReplacedMaterials.Num())
				{
					UE_LOG(LogTemp, Error, TEXT("Actor %s: Component  %s has invalid Materials than DynamicReplacedMaterials."), *GetOwner()->GetFName().ToString(),*EffectMeshComponent->GetFName().ToString());
					continue;
				}
			}
			for(int32 MaterialIndex = 0; MaterialIndex < ReplacedMaterials.Num(); MaterialIndex++)
			{
				TObjectPtr<class UMaterialInterface> OverrideMaterial = ReplacedMaterials[MaterialIndex];
				if (!IsValid(OverrideMaterial))
				{
					continue;
				}
				// Create and set the dynamic material instance.
				FOverrideMaterialSetting OverrideSetting;
				OverrideSetting.MeshComponent = EffectMeshComponent;
				OverrideSetting.MaterialIndex = MaterialIndex;
				OverrideSetting.DynamicMaterial = UMaterialInstanceDynamic::Create(OverrideMaterial, this);
				OverrideMaterialSettings.Add(OverrideSetting);
			}
		}
	}

	// Do replace
	for (FOverrideMaterialSetting& OverrideMaterialSetting : OverrideMaterialSettings)
	{
		OverrideMaterialSetting.OriginalOverrideMaterial = OverrideMaterialSetting.MeshComponent->UMeshComponent::GetMaterial(OverrideMaterialSetting.MaterialIndex);
		OverrideMaterialSetting.MeshComponent->SetMaterial(OverrideMaterialSetting.MaterialIndex, OverrideMaterialSetting.DynamicMaterial);
	}

	// Start Effect
	HiddenEffect(DefaultStartEffectFactor);
}

void UHiCameraOcclusionOpacityComponent::ApplyEffect_Implementation()
{

}

void UHiCameraOcclusionOpacityComponent::HiddenEffect_Implementation(const float HiddenFactor)
{
	float EffectHiddenFactor = FMath::Clamp(HiddenFactor, DefaultEndEffectFactor, DefaultStartEffectFactor);
	for (int32 ElementIndex = 0; ElementIndex < OverrideMaterialSettings.Num(); ++ElementIndex)
	{
		// Effect on current material
		TObjectPtr <class UMaterialInstanceDynamic> DynamicMaterial = OverrideMaterialSettings[ElementIndex].DynamicMaterial;
		if (DynamicMaterial)
		{
			DynamicMaterial->SetScalarParameterValue(FadeParameterName, EffectHiddenFactor);
		}
	}
}

void UHiCameraOcclusionOpacityComponent::StopEffect_Implementation(const int EffectType/* = 1*/)
{
	check(EffectType >= 0 && EffectType < 16);
	const int EffectFlag = 1 << EffectType;
	const int OldEffectFlag = CurrentEffectFlag;
	CurrentEffectFlag = OldEffectFlag & (~EffectFlag);
	if (CurrentEffectFlag || !OldEffectFlag)
	{
		return;
	}

	// End Effect
	HiddenEffect(DefaultEndEffectFactor);

	// Reset materials to original materials
	for (FOverrideMaterialSetting &OverrideMaterialSetting : OverrideMaterialSettings)
	{
		OverrideMaterialSetting.MeshComponent->SetMaterial(OverrideMaterialSetting.MaterialIndex, OverrideMaterialSetting.OriginalOverrideMaterial);
		OverrideMaterialSetting.OriginalOverrideMaterial = nullptr;
	}
}
