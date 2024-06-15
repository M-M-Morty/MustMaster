// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Camera/HiCameraOcclusionPostProcessor.h"
#include "Component/HiCameraOcclusionOpacityComponent.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Components/HierarchicalInstancedStaticMeshComponent.h"
#include "Engine/PostProcessVolume.h"
#include "Characters/HiCharacter.h"
#include "Components/ShapeComponent.h"
#include "Characters/HiPlayerCameraManager.h"


const float DefaultFadeFactor_Start = 1.0f;
const float DefaultFadeFactor_Close = 0.0f;


UHiCameraOcclusionPostProcessor::UHiCameraOcclusionPostProcessor(class FObjectInitializer const& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FName UHiCameraOcclusionPostProcessor::GetIdentityName()
{
	return FName(TEXT("CameraOcclusion"));
}

void UHiCameraOcclusionPostProcessor::Initialize_Implementation(AHiPlayerCameraManager* PlayerCameraManager)
{
	PlayerCameraManager->OnCameraSequenceOverrideDelegate.AddUniqueDynamic(this, &UHiCameraOcclusionPostProcessor::OnCameraSequenceOverrideChanged);
	ActorMapOverrideMaterialSettings.Empty();
}

void UHiCameraOcclusionPostProcessor::OnCameraSequenceOverrideChanged_Implementation(bool bIsOverride)
{
	bEnableOcclusionOutline = !bIsOverride; 
	bEnableOcclusionPerspective = !bIsOverride;
}

void UHiCameraOcclusionPostProcessor::OnTargetChanged_Implementation(AActor* NewTarget)
{
	if (bIsOutlineInEffect)
	{
		if (AHiCharacter* Character = Cast<AHiCharacter>(NewTarget))
		{
			Character->GetMesh()->SetCustomDepthStencilValue(CustomDepthStencilValue);
			Character->GetMesh()->SetRenderCustomDepth(true);
		}
	}
}

void UHiCameraOcclusionPostProcessor::Process_Implementation(const float DeltaTime, const FVisionerEvaluateContext& ViewContext)
{
	if (!ViewContext.ViewTarget)
	{
		return;
	}

	UWorld* World = ViewContext.ViewTarget->GetWorld();
	check(World);

	// 1. sweep multi
	FOcclusionDetectContext DetectContext;
	FVector TargetCameraLocation = ViewContext.POV.Location;
	FVector PivotLocation = ViewContext.ViewTarget->GetActorLocation();
	if (ACharacter* ViewCharacter = Cast<ACharacter>(ViewContext.ViewTarget))
	{
		PivotLocation = ViewCharacter->GetMesh()->GetSocketLocation(CameraSocketName);
	}
	FVector TraceDir = PivotLocation - TargetCameraLocation;
	const float OriginalTraceLength = TraceDir.Length();
	const FVector TraceNormal = TraceDir.GetSafeNormal();

	FCollisionShape CollisionShape;
	CollisionShape.SetCapsule(FVector3f(SweepCapsuleRadius, SweepCapsuleHalfHeight, 0.0f));
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(ViewContext.ViewTarget);

	if (OriginalTraceLength < SweepCapsuleRadius)
	{
		/* Ignore Check */
	}
	else if (OriginalTraceLength < SweepCapsuleRadius * 2.0)
	{
		/* Do Overlap Check */
		DetectContext.TraceLength = 0.0f;
		TargetCameraLocation += TraceNormal * SweepCapsuleRadius;

		// Overlap
		TArray<FOverlapResult> OverlapResults;
		World->OverlapMultiByChannel(OverlapResults, TargetCameraLocation, FQuat::Identity
			, VisibilityChannel, CollisionShape, Params);
		for (const FOverlapResult& VisiblityHitResult : OverlapResults)
		{
			DetectContext.PendingProcessActors.Add(VisiblityHitResult.GetActor());
		}
	}
	else
	{
		/* Do Sweep Check */
		DetectContext.TraceLength = TraceDir.Length() - SweepCapsuleRadius * 2.0f;
		TargetCameraLocation += TraceNormal * SweepCapsuleRadius;
		PivotLocation -= TraceNormal * SweepCapsuleRadius;

		// Sweep
		TArray<FHitResult> HitResults;
		World->SweepMultiByChannel(HitResults, PivotLocation, TargetCameraLocation, FQuat::Identity
			, VisibilityChannel, CollisionShape, Params);
		for (const FHitResult& VisiblityHitResult : HitResults)
		{
			DetectContext.PendingProcessActors.Add(VisiblityHitResult.GetActor());
		}
		DetectContext.bVisiblityHit = !DetectContext.PendingProcessActors.IsEmpty();
	}

	DetectContext.bVisiblityHit = !DetectContext.PendingProcessActors.IsEmpty();

	// 2. Process sweep hit actors
#if WITH_EDITOR
	if (bDebugCollisionTrace)
	{
		::DrawDebugCapsule(World, PivotLocation, SweepCapsuleHalfHeight, SweepCapsuleRadius, FQuat::Identity, FColor::Green, true, 1, 1, 1);
		::DrawDebugCapsule(World, TargetCameraLocation, SweepCapsuleHalfHeight, SweepCapsuleRadius, FQuat::Identity, FColor::Red, true, 1, 1, 1);
	}
#endif

	ProcessPerspectiveEffect(DeltaTime, ViewContext, DetectContext);

	ProcessOutlineEffect(DeltaTime, ViewContext, DetectContext);
}

void UHiCameraOcclusionPostProcessor::ProcessPerspectiveEffect(const float DeltaTime, const FVisionerEvaluateContext& ViewContext, const FOcclusionDetectContext& DetectContext)
{
	const int ReserveSize = 8;

	//TMap<TObjectPtr<UMeshComponent>, FMaskedMaterialsEffectRecord> OldMeshEffectRecords = MeshEffectRecords;
	//// Always maintain a certain amount of memory to reduce the overhead of repeated deletions and additions
	//MeshEffectRecords.Empty(ReserveSize);

	TMap<TObjectPtr<AActor>, float> OldEffectiveOcclusions = EffectiveOcclusions;
	EffectiveOcclusions.Empty(ReserveSize);


	if (DetectContext.bVisiblityHit && bEnableOcclusionPerspective)
	{
		TSet<UPrimitiveComponent*> CheckComponentSet;								// Prevent duplicate processing
		TArray<AActor*> PendingProcessActors = DetectContext.PendingProcessActors;	// Cache actors processing 

		// Scan Queue Actors
		const int32 HeadIndex = 0;
		TArray<AActor*> AssociatedActors;
		while (!PendingProcessActors.IsEmpty())
		{
			// Get Head Actor
			AActor* HitActor = PendingProcessActors[HeadIndex];
			PendingProcessActors.RemoveAtSwap(HeadIndex);

			// Append Associated Actors
			AssociatedActors.Reset();
			HitActor->GetAttachedActors(AssociatedActors, /*bResetArray = */false, /*bRecursivelyIncludeAttachedActors = */false);
			PendingProcessActors.Append(AssociatedActors);
			AssociatedActors.Reset();
			HitActor->GetAllChildActors(AssociatedActors, /*bIncludeDescendants = */false);
			PendingProcessActors.Append(AssociatedActors);

			// Process Actor
			EffectiveOcclusions.Emplace(HitActor, 0.0f);
			UHiCameraOcclusionOpacityComponent* OcclusionOpacityComponent = Cast<UHiCameraOcclusionOpacityComponent>(HitActor->GetComponentByClass(UHiCameraOcclusionOpacityComponent::StaticClass()));
			if (OcclusionOpacityComponent && OcclusionOpacityComponent->bIsEffectAllowed)
			{
				if (OldEffectiveOcclusions.Contains(HitActor))
				{
					// Continue effect material
					if (OldEffectiveOcclusions[HitActor] > 0.0f)
					{
						// Remove from hidden array
						OcclusionOpacityComponent->HiddenEffect(DefaultFadeFactor_Start);
					}
					OcclusionOpacityComponent->ApplyEffect();
					OldEffectiveOcclusions.Remove(HitActor);
				}
				else
				{
					// Start new effect material
					OcclusionOpacityComponent->StartEffect();
				}
			}
			else if (bEnableHiddenOcclusionActor)
			{
				if (OldEffectiveOcclusions.Contains(HitActor))
				{
					OldEffectiveOcclusions.Remove(HitActor);
				}
				HitActor->SetActorHiddenInGame(true);
			}
			else
			{
				if (OldEffectiveOcclusions.Contains(HitActor))
				{
					// Continue effect material
					if (OldEffectiveOcclusions[HitActor] > 0.0f)
					{
						// Remove from hidden array
						HiddenEffect(HitActor, DefaultFadeFactor_Start);
					}
					ApplyEffect(HitActor);
					OldEffectiveOcclusions.Remove(HitActor);
				}
				else
				{
					// Start new effect material
					StartEffect(HitActor);
				}
			}

			//// Effective once testing
			//UPrimitiveComponent* HitComponent = VisiblityHitResult.GetComponent();
			//if (!HitComponent || CheckComponentSet.Contains(HitComponent))
			//{
			//	continue;
			//}
			//CheckComponentSet.Add(HitComponent);

			//if (HitComponent->IsA(UShapeComponent::StaticClass()) && VisiblityHitResult.GetActor())
			//{
			//	HitComponent = VisiblityHitResult.GetActor()->FindComponentByClass<UMeshComponent>();
			//}

			//// Component type detection
			//UMeshComponent* EffectMeshComponent = nullptr;
			//for (UClass* EffectiveMeshClass : EffectiveMeshClasses)
			//{
			//	if (HitComponent->IsA(EffectiveMeshClass))
			//	{
			//		EffectMeshComponent = Cast<UMeshComponent>(HitComponent);
			//	}
			//}
			//if (!EffectMeshComponent)
			//{
			//	continue;
			//}

			//FMaskedMaterialsEffectContext EffectContext;
			//EffectContext.EffectMeshComponent = EffectMeshComponent;
			//EffectContext.DeltaTime = DeltaTime;
			//EffectContext.DistanceOfCharacterToCamera = VisiblityHitResult.Distance - ViewContext.POV.OrthoNearClipPlane;
			//EffectContext.DistanceOfHitToCamera = DetectContext.TraceLength;

			//if (!OldMeshEffectRecords.Contains(EffectMeshComponent))
			//{
			//	// Start effect & Add new record
			//	FMaskedMaterialsEffectRecord NewActorEffectRecord;
			//	NewActorEffectRecord.ItemIndex = VisiblityHitResult.Item;

			//	if (StartPerspective(EffectContext, NewActorEffectRecord))
			//	{
			//		// EffectMeshComponent maybe replaced by StartEffect
			//		if (EffectMeshComponent != EffectContext.EffectMeshComponent)
			//		{
			//			// InstancedComponent can hit multitimes
			//			CheckComponentSet.Remove(HitComponent);
			//		}
			//		MeshEffectRecords.Emplace(EffectContext.EffectMeshComponent, NewActorEffectRecord);
			//	}
			//}
			//else
			//{
			//	// Maintain effect & Maintain record
			//	FMaskedMaterialsEffectRecord& ExsitEffectRecord = OldMeshEffectRecords[EffectMeshComponent];
			//	ApplyPerspective(EffectContext, ExsitEffectRecord);
			//	// Adjust array
			//	MeshEffectRecords.Emplace(EffectMeshComponent, ExsitEffectRecord);
			//	OldMeshEffectRecords.Remove(EffectMeshComponent);
			//}
		}
	}

	for (TPair<TObjectPtr<AActor>, float>& OldEffectiveOcclusionPair : OldEffectiveOcclusions)
	{
		TObjectPtr<AActor> HitActor = OldEffectiveOcclusionPair.Key;
		if (IsValid(HitActor))
		{
			UHiCameraOcclusionOpacityComponent* OcclusionOpacityComponent = Cast<UHiCameraOcclusionOpacityComponent>(HitActor->GetComponentByClass(UHiCameraOcclusionOpacityComponent::StaticClass()));

			if (OcclusionOpacityComponent)
			{
				float HiddenEffectionDuration = OldEffectiveOcclusionPair.Value + DeltaTime;
				if (HiddenEffectionDuration >= PendingIneffectiveDuration)
				{
					check(OcclusionOpacityComponent);
					OcclusionOpacityComponent->StopEffect();
				}
				else
				{
					EffectiveOcclusions.Emplace(HitActor, HiddenEffectionDuration);
					const float LeftDuration = PendingIneffectiveDuration - HiddenEffectionDuration;
					if (LeftDuration < FadeBlendDuration)
					{
						// InputRange is [0.0, 1.0], OutputRange is [DefaultFadeFactor_Start, DefaultFadeFactor_Close]
						float HiddenFactor = FMath::GetMappedRangeValueClamped<float, float>({ 1.0f, 0.0f }, { DefaultFadeFactor_Start, DefaultFadeFactor_Close }, LeftDuration / FadeBlendDuration);
						OcclusionOpacityComponent->HiddenEffect(HiddenFactor);
					}
				}
			}
			else if (bEnableHiddenOcclusionActor)
			{
				float HiddenEffectionDuration = OldEffectiveOcclusionPair.Value + DeltaTime;
				if (HiddenEffectionDuration > HideBlendDuration)
				{
					HitActor->SetActorHiddenInGame(false);
				}
				else
				{
					EffectiveOcclusions.Emplace(HitActor, HiddenEffectionDuration);
				}
			}
			else
			{
				float HiddenEffectionDuration = OldEffectiveOcclusionPair.Value + DeltaTime;
				if (HiddenEffectionDuration >= PendingIneffectiveDuration)
				{
					StopEffect(HitActor);
				}
				else
				{
					EffectiveOcclusions.Emplace(HitActor, HiddenEffectionDuration);
					const float LeftDuration = PendingIneffectiveDuration - HiddenEffectionDuration;
					if (LeftDuration < FadeBlendDuration)
					{
						// InputRange is [0.0, 1.0], OutputRange is [DefaultFadeFactor_Start, DefaultFadeFactor_Close]
						float HiddenFactor = FMath::GetMappedRangeValueClamped<float, float>({ 1.0f, 0.0f }, { DefaultFadeFactor_Start, DefaultFadeFactor_Close }, LeftDuration / FadeBlendDuration);
						HiddenEffect(HitActor, HiddenFactor);
					}
				}
			}
		}
	}

	// 3. Process sweep missing actors
	/*for (TPair<TObjectPtr<UMeshComponent>, FMaskedMaterialsEffectRecord>& OldEffectiveOcclusionPair : OldMeshEffectRecords)
	{
		TObjectPtr<UMeshComponent> EffectMeshComponent = OldEffectiveOcclusionPair.Key;
		if (!IsValid(EffectMeshComponent))
		{
			continue;
		}

		FMaskedMaterialsEffectRecord& ExsitEffectRecord = OldEffectiveOcclusionPair.Value;
		ExsitEffectRecord.IneffectDuration += DeltaTime;
		if (ExsitEffectRecord.IneffectDuration > PendingIneffectiveDuration)
		{
			StopPerspective(EffectMeshComponent, ExsitEffectRecord);
		}
		else
		{
			MeshEffectRecords.Emplace(EffectMeshComponent, ExsitEffectRecord);
			const float LeftDuration = PendingIneffectiveDuration - ExsitEffectRecord.IneffectDuration;
			if (LeftDuration < FadeBlendDuration)
			{
				const float HiddenFactor = FMath::GetMappedRangeValueClamped<float, float>({ 1.0f, 0.0f }, { DefaultFadeFactor_Start, DefaultFadeFactor_Close }, LeftDuration / FadeBlendDuration);
				FadePerspective(EffectMeshComponent, HiddenFactor);
			}
		}
	}*/
}

void UHiCameraOcclusionPostProcessor::ProcessOutlineEffect(const float DeltaTime, const FVisionerEvaluateContext& ViewContext, const FOcclusionDetectContext& DetectContext)
{
	UWorld* World = GetWorld();
	check(World);

	bool bIsOutlineInEffectNew = bEnableOcclusionOutline && DetectContext.bVisiblityHit;

	if (bIsOutlineInEffectNew != bIsOutlineInEffect)
	{
		if (!bIsOutlineInEffectNew && IneffectOutlineDuration < DelayOutlineDuration)
		{
			// Maintain Outline Effect
			IneffectOutlineDuration += DeltaTime;
			bIsOutlineInEffectNew = true;
		}
		else
		{
			// Process Occlusion Post Process
			APostProcessVolume* PostVolumeActor = nullptr;
			for (IInterface_PostProcessVolume* VolumeItem : World->PostProcessVolumes)
			{
				if (APostProcessVolume* VolumeActor = Cast<APostProcessVolume>(VolumeItem))
				{
					if (!VolumeActor->bUnbound)
					{
						continue;
					}
					PostVolumeActor = VolumeActor;
					break;
				}
			}
			if (PostVolumeActor)
			{
				for (TObjectPtr<UMaterialInstance> PostMaterial : OcclusionPostProcessMaterials)
				{
					if (bIsOutlineInEffectNew)
					{
						PostVolumeActor->Settings.AddBlendable(PostMaterial, 1.0f);
					}
					else
					{
						PostVolumeActor->Settings.RemoveBlendable(PostMaterial);
					}
				}
			}

			if (AHiCharacter* Character = Cast<AHiCharacter>(ViewContext.ViewTarget))
			{
				if (bIsOutlineInEffectNew)
				{
					Character->GetMesh()->SetCustomDepthStencilValue(CustomDepthStencilValue);
				}
				Character->GetMesh()->SetRenderCustomDepth(bIsOutlineInEffectNew);
			}
			IneffectOutlineDuration = 0.0f;
			bIsOutlineInEffect = bIsOutlineInEffectNew;
		}
	}
}

void UHiCameraOcclusionPostProcessor::StartEffect_Implementation(AActor* HitActor)
{
	TArray<TObjectPtr<class UMeshComponent>> EffectMeshComponents;
	EffectMeshComponents.Empty();

	TArray<UActorComponent*> ActorComponents = HitActor->K2_GetComponentsByClass(UMeshComponent::StaticClass());
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
		if (EffectMeshComponent->GetCollisionResponseToChannel(VisibilityChannel) == ECR_Ignore)
		{
			continue;
		}
		EffectMeshComponents.Add(EffectMeshComponent);
	}
	
	// Create dynamic material instances
	ActorMapOverrideMaterialSettings.FindOrAdd(HitActor);
	if (ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings.IsEmpty())
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
			if (EffectMeshComponent->GetNumMaterials() != ReplacedMaterials.Num())
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
					UE_LOG(LogTemp, Error, TEXT("Actor %s: Component  %s has invalid Materials than DynamicReplacedMaterials."), *HitActor->GetFName().ToString(),*EffectMeshComponent->GetFName().ToString());
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
				FActorOverrideMaterialSetting OverrideSetting;
				OverrideSetting.MeshComponent = EffectMeshComponent;
				OverrideSetting.MaterialIndex = MaterialIndex;
				OverrideSetting.DynamicMaterial = UMaterialInstanceDynamic::Create(OverrideMaterial, this);
				ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings.Add(OverrideSetting);
			}
		}
	}

	// Do replace
	for (FActorOverrideMaterialSetting& OverrideMaterialSetting : ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings)
	{
		OverrideMaterialSetting.OriginalOverrideMaterial = OverrideMaterialSetting.MeshComponent->UMeshComponent::GetMaterial(OverrideMaterialSetting.MaterialIndex);
		OverrideMaterialSetting.MeshComponent->SetMaterial(OverrideMaterialSetting.MaterialIndex, OverrideMaterialSetting.DynamicMaterial);
	}

	// Start Effect
	HiddenEffect(HitActor, DefaultFadeFactor_Start);
}

void UHiCameraOcclusionPostProcessor::ApplyEffect_Implementation(AActor* HitActor)
{
	
}

void UHiCameraOcclusionPostProcessor::HiddenEffect_Implementation(AActor* HitActor, const float HiddenFactor)
{
	if(ActorMapOverrideMaterialSettings.Contains(HitActor))
	{
		float EffectHiddenFactor = FMath::Clamp(HiddenFactor, DefaultFadeFactor_Close, DefaultFadeFactor_Start);
		for (int32 ElementIndex = 0; ElementIndex < ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings.Num(); ++ElementIndex)
		{
			// Effect on current material
			TObjectPtr <class UMaterialInstanceDynamic> DynamicMaterial = ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings[ElementIndex].DynamicMaterial;
			if (DynamicMaterial)
			{
				DynamicMaterial->SetScalarParameterValue(FadeParameterName, EffectHiddenFactor);
			}
		}
	}
}

void UHiCameraOcclusionPostProcessor::StopEffect_Implementation(AActor* HitActor)
{
	// End Effect
	HiddenEffect(HitActor, DefaultFadeFactor_Close);

	// Reset materials to original materials
	for (FActorOverrideMaterialSetting &OverrideMaterialSetting : ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings)
	{
		OverrideMaterialSetting.MeshComponent->SetMaterial(OverrideMaterialSetting.MaterialIndex, OverrideMaterialSetting.OriginalOverrideMaterial);
		OverrideMaterialSetting.OriginalOverrideMaterial = nullptr;
	}
	ActorMapOverrideMaterialSettings[HitActor].OverrideMaterialSettings.Empty();
	ActorMapOverrideMaterialSettings.Remove(HitActor);
}

void UHiCameraOcclusionPostProcessor::PreStartPerspective_InstancedStaticMesh(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord)
{
	UHierarchicalInstancedStaticMeshComponent* InstancedStaticMeshComponent = Cast<UHierarchicalInstancedStaticMeshComponent>(EffectContext.EffectMeshComponent);
	if (!InstancedStaticMeshComponent)
	{
		return;
	}

	if (InstancedStaticMeshComponent->PerInstanceSMData.Num() <= InstancedBatchReplacedCount)
	{
		return;
	}

	AActor* Owner = InstancedStaticMeshComponent->GetOwner();
	check(Owner);

	UHierarchicalInstancedStaticMeshComponent* DuplicateInstancedMeshComponent = DuplicateObject(InstancedStaticMeshComponent, Owner);
	check(DuplicateInstancedMeshComponent);
	DuplicateInstancedMeshComponent->ClearInstances();
	//UHierarchicalInstancedStaticMeshComponent* DuplicateInstancedMeshComponent = Cast<UHierarchicalInstancedStaticMeshComponent>(Owner->AddComponentByClass(InstancedStaticMeshComponent->GetClass(), false, InstancedStaticMeshComponent->GetRelativeTransform(), true));
	//DuplicateInstancedMeshComponent->SetStaticMesh(InstancedStaticMeshComponent->GetStaticMesh());
	DuplicateInstancedMeshComponent->AddInstance(FTransform(InstancedStaticMeshComponent->PerInstanceSMData[EffectRecord.ItemIndex].Transform));
	Owner->FinishAddComponent(DuplicateInstancedMeshComponent, false, FTransform::Identity);
	EffectContext.EffectMeshComponent = DuplicateInstancedMeshComponent;

	{
		// Maybe hide is a better choice
		InstancedStaticMeshComponent->RemoveInstance(EffectRecord.ItemIndex);
	}
	
	EffectRecord.OriginalInstancedComponent = InstancedStaticMeshComponent;
}

bool UHiCameraOcclusionPostProcessor::StartPerspective_Implementation(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord)
{
	PreStartPerspective_InstancedStaticMesh(EffectContext, EffectRecord);

	if (!EffectContext.EffectMeshComponent->ApplyDynamicReplacedMaterial())
	{
		return false;
	}
	EffectRecord.FadeFactor = DefaultFadeFactor_Close;
	FadePerspective(EffectContext.EffectMeshComponent, EffectRecord.FadeFactor);
	return true;
}

void UHiCameraOcclusionPostProcessor::StopPerspective_Implementation(UMeshComponent* EffectMeshComponent, FMaskedMaterialsEffectRecord& EffectRecord)
{
	check(IsValid(EffectMeshComponent));
	EffectMeshComponent->RevertDynamicReplacedMaterial();
	if (EffectRecord.OriginalInstancedComponent)
	{
		UHierarchicalInstancedStaticMeshComponent* ReplacedMaterialComponent = Cast<UHierarchicalInstancedStaticMeshComponent>(EffectMeshComponent);
		check(ReplacedMaterialComponent);
		EffectRecord.OriginalInstancedComponent->AddInstance(FTransform(ReplacedMaterialComponent->PerInstanceSMData[0].Transform));
		ReplacedMaterialComponent->DestroyComponent();
	}
}

void UHiCameraOcclusionPostProcessor::ApplyPerspective_Implementation(FMaskedMaterialsEffectContext& EffectContext, FMaskedMaterialsEffectRecord& EffectRecord)
{
	if (!FMath::IsNearlyEqual(EffectRecord.FadeFactor, DefaultFadeFactor_Start, UE_KINDA_SMALL_NUMBER))
	{
		EffectRecord.FadeFactor = FMath::Min(DefaultFadeFactor_Start, EffectRecord.FadeFactor + EffectContext.DeltaTime / FadeBlendDuration);
		FadePerspective(EffectContext.EffectMeshComponent, EffectRecord.FadeFactor);
	}
	EffectRecord.IneffectDuration = 0.0f;
}

void UHiCameraOcclusionPostProcessor::FadePerspective_Implementation(const UMeshComponent* EffectMeshComponent, const float HiddenFactor)
{
	check(IsValid(EffectMeshComponent));
	for (int32 ElementIndex = 0; ElementIndex < EffectMeshComponent->GetNumOverrideMaterials(); ++ElementIndex)
	{
		// Effect on current material
		UMaterialInstanceDynamic* DynamicMaterial = Cast<UMaterialInstanceDynamic>(EffectMeshComponent->OverrideMaterials[ElementIndex]);
		if (DynamicMaterial)
		{
			DynamicMaterial->SetScalarParameterValue(FadeParameterName, HiddenFactor);
		}
	}
}
