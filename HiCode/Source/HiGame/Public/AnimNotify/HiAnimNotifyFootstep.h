// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotify.h"
#include "Engine/DataTable.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Kismet/GameplayStatics.h"
#include "GameplayTagContainer.h"
#include "HiAnimNotifyFootstep.generated.h"

class UNiagaraSystem;


USTRUCT(BlueprintType)
struct FHiFootstepFX : public FTableRowBase
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Surface")
	TEnumAsByte<enum EPhysicalSurface> SurfaceType = EPhysicalSurface::SurfaceType_Default;

	UPROPERTY(EditAnywhere, Category = "Wwise")
	TSoftObjectPtr<class UAkSwitchValue> AkSwitchValue;

	UPROPERTY(EditAnywhere, Category = "Wwise")
	FString AttachName;

	UPROPERTY(EditAnywhere, Category = "Wwise")
	bool bFollow = true;

	UPROPERTY(EditAnywhere, Category = "Wwise")
	FString EventName;

	UPROPERTY(EditAnywhere, Category = "Wwise")
	EHiSpawnType SoundSpawnType = EHiSpawnType::Location;

	UPROPERTY(EditAnywhere, Category = "Wwise", meta = (EditCondition = "SoundSpawnType == EHiSpawnType::Attached"))
	TEnumAsByte<enum EAttachLocation::Type> SoundAttachmentType = EAttachLocation::Type::KeepRelativeOffset;

	UPROPERTY(EditAnywhere, Category = "Decal")
	TSoftObjectPtr<UMaterialInterface> DecalMaterial;

	UPROPERTY(EditAnywhere, Category = "Decal")
	EHiSpawnType DecalSpawnType = EHiSpawnType::Location;

	UPROPERTY(EditAnywhere, Category = "Decal", meta = (EditCondition = "DecalSpawnType == EHiSpawnType::Attached"))
	TEnumAsByte<enum EAttachLocation::Type> DecalAttachmentType;

	UPROPERTY(EditAnywhere, Category = "Decal")
	float DecalLifeSpan = 10.0f;

	UPROPERTY(EditAnywhere, Category = "Decal")
	FVector DecalSize = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Decal")
	FVector DecalLocationOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Decal")
	FRotator DecalRotationOffset = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere, Category = "Niagara")
	TSoftObjectPtr<UNiagaraSystem> NiagaraSystem;

	UPROPERTY(EditAnywhere, Category = "Niagara")
	EHiSpawnType NiagaraSpawnType = EHiSpawnType::Location;

	UPROPERTY(EditAnywhere, Category = "Niagara", meta = (EditCondition = "NiagaraSpawnType == EHiSpawnType::Attached"))
	TEnumAsByte<enum EAttachLocation::Type> NiagaraAttachmentType;

	UPROPERTY(EditAnywhere, Category = "Niagara")
	FVector NiagaraLocationOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Niagara")
	FRotator NiagaraRotationOffset = FRotator::ZeroRotator;
};



/**
 * HiGame Character footstep anim notify
 */
UCLASS(BlueprintType)
class HIGAME_API UHiAnimNotifyFootstep : public UAnimNotify
{
	GENERATED_BODY()

	virtual void Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation, const FAnimNotifyEventReference& EventReference) override;

	virtual FString GetNotifyName_Implementation() const override;

public:
	/** 
	* Implementable event to spawn decal
	*/
	UFUNCTION(BlueprintNativeEvent)
	bool Received_Notify_Decal(USkeletalMeshComponent* MeshComp, FHitResult const& BlockingHit, const FHiFootstepFX& HitFX) const;

	/** 
	* Implementable event to spawn wwise from data asset
	*/
	UFUNCTION(BlueprintNativeEvent)
	bool Received_Notify_WwiseDataAsset(AActor* MeshOwner, FHitResult const& BlockingHit) const;

	/** 
	* Implementable event to spawn niagara
	*/
	UFUNCTION(BlueprintNativeEvent)
	bool Received_Notify_Niagara(USkeletalMeshComponent* MeshComp, FHitResult const& BlockingHit, const FHiFootstepFX& HitFX) const;

	UFUNCTION(BlueprintImplementableEvent)
	bool Received_Notify_Custom(USkeletalMeshComponent* MeshComp, FHitResult const& BlockingHit, const FHiFootstepFX& HitFX) const;


	//UFUNCTION(BlueprintGetter, Category = "Socket")
	//FName GetFootSocketName() const { return FootSocketName; }
#if WITH_EDITOR
	UFUNCTION(BlueprintCallable, Category = "Socket")
	void SetFootSocketName(FName InFootSocketName);

	UFUNCTION(BlueprintCallable, Category="Settings")
	void SetMovementTag(FGameplayTag InTag);
	
	virtual void OnAnimNotifyCreatedInEditor(FAnimNotifyEvent& ContainingAnimNotifyEvent) override;
#endif
	
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings")
	TObjectPtr<UDataTable> HitDataTable;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Settings", meta=(AllowPrivateAccess="true"))
	FGameplayTag MovementTag;

	static FName NAME_Foot_R;
	UPROPERTY(EditAnywhere, BlueprintReadWrite, BlueprintSetter=SetFootSocketName, Category = "Socket")
	FName FootSocketName = NAME_Foot_R;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	TEnumAsByte<ETraceTypeQuery> TraceChannel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	TEnumAsByte<EDrawDebugTrace::Type> DrawDebugType;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Trace")
	float TraceLength = 50.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	bool bSpawnDecal = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	bool bMirrorDecalX = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	bool bMirrorDecalY = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	bool bMirrorDecalZ = false;

	static FName NAME_FootstepType;	

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Niagara")
	bool bSpawnNiagara = false;
	
	#if WITH_EDITORONLY_DATA
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Preview")
	TObjectPtr<class UHiCharacterMovementPrimaryDataAsset> PreviewDA;
	#endif
};
