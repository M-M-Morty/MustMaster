// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyFootstep.h"
#include "Engine/DataTable.h"
#include "Kismet/KismetSystemLibrary.h"
#include "PhysicalMaterials/PhysicalMaterial.h"
#include "NiagaraSystem.h"
#include "NiagaraFunctionLibrary.h"
#include "AkAudioEvent.h"
#include "AkGameplayStatics.h"
#include "HiSoundPrimaryDataAsset.h"


const FName NAME_Mask_FootstepSound(TEXT("Mask_FootstepSound"));

FName UHiAnimNotifyFootstep::NAME_FootstepType(TEXT("FootstepType"));
FName UHiAnimNotifyFootstep::NAME_Foot_R(TEXT("Foot_R"));


void UHiAnimNotifyFootstep::Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference)
{
	Super::Notify(MeshComp, Animation, EventReference);
	
	if (!MeshComp)
	{
		return;
	}
	
	AActor* MeshOwner = MeshComp->GetOwner();
	if (!MeshOwner)
	{
		return;
	}

	if (HitDataTable)
	{
		UWorld* World = MeshComp->GetWorld();
		check(World);

		const FVector FootLocation = MeshComp->GetSocketLocation(FootSocketName);
		const FRotator FootRotation = MeshComp->GetSocketRotation(FootSocketName);
		const FVector TraceEnd = FootLocation - MeshOwner->GetActorUpVector() * TraceLength;

		FHitResult Hit;

		if (UKismetSystemLibrary::LineTraceSingle(MeshOwner /*used by bIgnoreSelf*/, FootLocation, TraceEnd, TraceChannel, true /*bTraceComplex*/, MeshOwner->Children,
		                                          DrawDebugType, Hit, true /*bIgnoreSelf*/))
		{
			
			{
				Received_Notify_WwiseDataAsset(MeshOwner, Hit);	
			}			
			
			if (!Hit.PhysMaterial.Get())
			{
				return;
			}
			
			const EPhysicalSurface SurfaceType = Hit.PhysMaterial.Get()->SurfaceType;

			check(IsInGameThread());
			checkNoRecursion();
			static TArray<FHiFootstepFX*> HitFXRows;
			HitFXRows.Reset();

			HitDataTable->GetAllRows<FHiFootstepFX>(FString(), HitFXRows);

			FHiFootstepFX* FootstepFX = nullptr;
			if (auto FoundResult = HitFXRows.FindByPredicate([&](const FHiFootstepFX* Value)
			{
				return SurfaceType == Value->SurfaceType;
			}))
			{
				FootstepFX = *FoundResult;
			}
			else if (auto DefaultResult = HitFXRows.FindByPredicate([&](const FHiFootstepFX* Value)
			{
				return EPhysicalSurface::SurfaceType_Default == Value->SurfaceType;
			}))
			{
				FootstepFX = *DefaultResult;
			}
			else
			{
				return;
			}
			if (bSpawnNiagara && FootstepFX->NiagaraSystem.LoadSynchronous())
			{
				Received_Notify_Niagara_Implementation(MeshComp, Hit, *FootstepFX);
			}

			if (bSpawnDecal && FootstepFX->DecalMaterial.LoadSynchronous())
			{
				Received_Notify_Decal_Implementation(MeshComp, Hit, *FootstepFX);
			}

			Received_Notify_Custom(MeshComp, Hit, *FootstepFX);
		}
		else
		{
			//UE_LOG(LogTemp, Warning, TEXT("LineTraceSingle -------->Fail :"));
		}
	}
}

FString UHiAnimNotifyFootstep::GetNotifyName_Implementation() const
{
	FString Name(TEXT("Footstep Type: "));
	Name.Append(GetEnumerationValueString(EHiFootstepType::Step));
	return Name;
}


bool UHiAnimNotifyFootstep::Received_Notify_WwiseDataAsset_Implementation(AActor* MeshOwner, FHitResult const& BlockingHit) const
{	
#if WITH_EDITOR
	if ( !PreviewDA.IsNull())
	{
		TObjectPtr<UHiFootstepSoundPrimaryDataAsset> SoundDataAsset = *PreviewDA->MovementDataMap.Find(MovementTag);
		if (!SoundDataAsset.IsNull())
		{
			TObjectPtr<UAkSwitchValue> AkSwitchValue = *SoundDataAsset->SurfaceAudios.Find(BlockingHit.PhysMaterial->SurfaceType);
			if (AkSwitchValue)
			{
				UAkGameplayStatics::SetSwitch(AkSwitchValue, MeshOwner, "None", "None");
			}
			TObjectPtr<UAkAudioEvent> AkEvent = SoundDataAsset->AudioEvent;
			if (AkEvent)
			{
				UAkGameplayStatics::PostEvent(AkEvent, MeshOwner, 0, FOnAkPostEventCallback());
			}
		}
		return true;
	}
	return false;
#else
	return true;
#endif
}


bool UHiAnimNotifyFootstep::Received_Notify_Decal_Implementation(USkeletalMeshComponent* MeshComp, FHitResult const& Hit, const FHiFootstepFX& FootstepFX) const
{
	AActor* MeshOwner = MeshComp->GetOwner();

	const FVector Location = Hit.Location + MeshOwner->GetTransform().TransformVector(
					FootstepFX.DecalLocationOffset);

	const FVector DecalSize = FVector(bMirrorDecalX ? -FootstepFX.DecalSize.X : FootstepFX.DecalSize.X,
									  bMirrorDecalY ? -FootstepFX.DecalSize.Y : FootstepFX.DecalSize.Y,
									  bMirrorDecalZ ? -FootstepFX.DecalSize.Z : FootstepFX.DecalSize.Z);

	UDecalComponent* SpawnedDecal = nullptr;
	const FRotator FootRotation = MeshComp->GetSocketRotation(FootSocketName);
	switch (FootstepFX.DecalSpawnType)
	{
	case EHiSpawnType::Location:
		{
			UWorld* World = MeshComp->GetWorld();		
			SpawnedDecal = UGameplayStatics::SpawnDecalAtLocation(
				World, FootstepFX.DecalMaterial.Get(), DecalSize, Location,
				FootRotation + FootstepFX.DecalRotationOffset, FootstepFX.DecalLifeSpan);
		}
		break;
	case EHiSpawnType::Attached:
		{
			SpawnedDecal = UGameplayStatics::SpawnDecalAttached(FootstepFX.DecalMaterial.Get(), DecalSize,
																Hit.Component.Get(), NAME_None, Location,
																FootRotation + FootstepFX.DecalRotationOffset,
																FootstepFX.DecalAttachmentType,
															FootstepFX.DecalLifeSpan);
		}
		break;
	}
	return true;
}

bool UHiAnimNotifyFootstep::Received_Notify_Niagara_Implementation(USkeletalMeshComponent* MeshComp, FHitResult const& Hit,  const FHiFootstepFX& FootstepFX) const
{
	UNiagaraComponent* SpawnedParticle = nullptr;
	AActor* MeshOwner = MeshComp->GetOwner();		
	const FVector Location = Hit.Location + MeshOwner->GetTransform().TransformVector(FootstepFX.DecalLocationOffset);
	
	switch (FootstepFX.NiagaraSpawnType)
	{
	case EHiSpawnType::Location:
		{
			UWorld* World = MeshComp->GetWorld();
			const FRotator FootRotation = MeshComp->GetSocketRotation(FootSocketName);
			SpawnedParticle = UNiagaraFunctionLibrary::SpawnSystemAtLocation(
				World, FootstepFX.NiagaraSystem.Get(), Location, FootRotation + FootstepFX.NiagaraRotationOffset);
		}
		break;

	case EHiSpawnType::Attached:
		{
			SpawnedParticle = UNiagaraFunctionLibrary::SpawnSystemAttached(
				FootstepFX.NiagaraSystem.Get(), MeshComp, FootSocketName, FootstepFX.NiagaraLocationOffset,
				FootstepFX.NiagaraRotationOffset, FootstepFX.NiagaraAttachmentType, true);
		}
		break;
	}
	return true;
}


#if WITH_EDITOR
void UHiAnimNotifyFootstep::SetFootSocketName(FName InFootSocketName)
{
	FootSocketName = InFootSocketName;
}

void UHiAnimNotifyFootstep::SetMovementTag(FGameplayTag InTag)
{
	MovementTag = InTag;
}


void UHiAnimNotifyFootstep::OnAnimNotifyCreatedInEditor(FAnimNotifyEvent& ContainingAnimNotifyEvent)
{
	Super::OnAnimNotifyCreatedInEditor(ContainingAnimNotifyEvent);
	UE_LOG(LogTemp, Warning, TEXT("OnAnimNotifyCreatedInEditor -------->OnAnimNotifyCreatedInEditor :"));
}
#endif