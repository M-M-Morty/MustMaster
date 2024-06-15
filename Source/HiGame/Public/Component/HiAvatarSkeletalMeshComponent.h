// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Component/HiSkeletalMeshComponent.h"
#include "HiAvatarSkeletalMeshComponent.generated.h"

/**
 * 
 */
UCLASS(Blueprintable, ClassGroup=(Rendering, Common), hidecategories=(Object, "Mesh|SkeletalAsset"), config=Engine, editinlinenew, meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiAvatarSkeletalMeshComponent : public UHiSkeletalMeshComponent
{
	GENERATED_BODY()
public:
	virtual void InitializeBaseSkeletonAnimSequence() override;
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void GetSkeletonAnimationByTargetAnimation(UAnimSequenceBase * Anim) override;

	virtual bool NeedFillTargetSkeletonPose() override;
	UAnimSequence * GetBaseSkeletonAnimation(const FString& AnimName);
	UAnimSequence* LoadBaseSkeletonAnimation(const FString& AnimName, const FString& AnimPath);

	virtual void SyncAnimSequence(UAnimSequenceBase* AnimationSequence) override;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Animation|DataTable")
	TObjectPtr<UDataTable> VehicleAnimationMappingDataTable;
	
private:
	UFUNCTION()
	void OnReceiveControllerChanged(APawn* InPawn, AController* OldController, AController* NewController);
	
	TMap<FString, FString> BaseAnimSequencePathMap;

	UPROPERTY(SkipSerialization, Transient)
	TMap<FString, TObjectPtr<UAnimSequence>> BaseSkeletonAnimations;
};
