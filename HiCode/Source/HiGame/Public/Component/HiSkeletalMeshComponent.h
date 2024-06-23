// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "SkeletalMergingLibrary.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Components/SkeletalMeshComponent.h"
#include "HiSkeletalMeshComponent.generated.h"


/**
* Delegate for when Montage is started
*/
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FHiOnMontageStartedDelegate, UHiAnimInstance*, AnimInstance, UAnimMontage*, Montage);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FHiOnMontageEndedMCDelegate, UHiAnimInstance*, AnimInstance, UAnimMontage*, Montage, bool, bInterrupted);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnMergedMeshDelegate);
DECLARE_DYNAMIC_MULTICAST_SPARSE_DELEGATE_TwoParams(FHiChildAttachmentDelegate, UHiSkeletalMeshComponent, OnChildAttachment, USceneComponent*, InSceneComponent, bool, bIsAttached);

class UGFurComponent;
/**
 * 
 */
UCLASS(Blueprintable, ClassGroup=(Rendering, Common), hidecategories=(Object, "Mesh|SkeletalAsset"), config=Engine, editinlinenew, meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiSkeletalMeshComponent : public USkeletalMeshComponent
{
	GENERATED_BODY()

public:

	
	UHiSkeletalMeshComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	virtual ~UHiSkeletalMeshComponent() override;

	UPROPERTY(EditAnywhere, Category=Animation)
	bool bFillTargetSkeletonPose = false;

	static TMap<FString, FString> SkeletonAnimPrefixTags;

	virtual void InitializeBaseSkeletonAnimSequence();
	
	virtual bool NeedFillTargetSkeletonPose();
	
	virtual UAnimSequence * GetSkeletonAnimation(const FString& AnimName);

	virtual void GetSkeletonAnimationByTargetAnimation(UAnimSequenceBase * Anim);
	
	FString GetMatchingAnimationName(const UAnimSequenceBase * Anim);
	static FString GetNoPrefixAnimationName(const UAnimSequenceBase * Anim);
	
	virtual UAnimSequence* LoadSkeletonAnimation(const FString& AnimName, const FString& AnimPath);
	
	UFUNCTION(BlueprintCallable, Category=Animation)
	void AddSyncedMeshComponents(UHiSkeletalMeshComponent* Mesh, EMergeSkeletonFlag EMergeSkeletonFlag=EMergeSkeletonFlag::Override, FString Prefix="" ,bool HiddenInGame=true);
	
	UFUNCTION(BlueprintCallable, Category=Animation)
	void RemoveSyncedMeshComponents(UHiSkeletalMeshComponent* Mesh);

	UFUNCTION(BlueprintCallable, Category=Animation)
	void UpdateAnimNodeSyncedAnimSequence();
	
	UFUNCTION()
	void OnMontageStartToPlay(UHiAnimInstance* AnimInstance , UAnimMontage* Montage);
	
	UFUNCTION()
	void OnMontageEnd( UHiAnimInstance* AnimInstance, UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION(BlueprintCallable, Category="Hi Merge Mesh")
	static USkeleton* MergeSkeletons(const TArray<USkeleton*>& SkeletonsToMerge, FName SkeletonName = NAME_None,
		bool CheckCompatibility=true, bool GenerateMergedAsset = false);

	UFUNCTION(BlueprintCallable, Category="Hi Merge Mesh")
	static USkeletalMesh* MergeSkeletalMeshes(const TArray<USkeletalMesh*>& SkeletalMeshes);

	virtual void SetSkeletalMesh(class USkeletalMesh* NewMesh, bool bReinitPose = true) override;

	UFUNCTION(BlueprintCallable, Category="Hi Merge Mesh")
	static void FixSkeletonRemappingByBoneNameMapping( USkeleton * Skeleton, USkeleton* TargetSkeleton, FString Prefix);


	static void UpdateTranslationRetargetingMode(USkeleton * Skeleton, const USkeleton* SourceSkeleton, const FString& BoneNamePrefix = "");
	
	USkeleton* GetSkeleton() const;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Animation|DataTable")
	TObjectPtr<UDataTable> AnimSequencePathDataTable;

	/** If false, Attach To Parent. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Mesh|Merge Configure")
	bool AutoMatchingParentSkeleton = true;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Mesh|Merge Configure")
	FName AttachToParentBone = NAME_None;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Mesh|Merge Configure")
	FString AdditionBoneNamePrefixForAttach;

	/** Called when a montage has started */
	UPROPERTY(BlueprintAssignable)
	FHiOnMontageStartedDelegate OnMontageStarted;

	UPROPERTY(BlueprintAssignable)
	FHiOnMontageEndedMCDelegate OnMontageEnded;
	
	virtual void SyncAnimSequence(UAnimSequenceBase* AnimationSequence);

	UPROPERTY(BlueprintAssignable)
	FOnMergedMeshDelegate OnMergedMeshFinished;
	
	UPROPERTY(EditAnywhere, Category="Animation|DataTable")
	FString AnimNamePrefixTag;

	UPROPERTY(BlueprintAssignable)
	FHiChildAttachmentDelegate OnChildAttachment;
	
	TMap<FString, FString> AnimSequencePathMap;

	UPROPERTY(SkipSerialization, Transient)
	TMap<FString, TObjectPtr<UAnimSequence>> SkeletonAnimations;

	virtual void OnChildAttached(USceneComponent* ChildComponent) override;
	virtual void OnChildDetached(USceneComponent* ChildComponent) override;
	
protected:
	virtual void OnRegister() override;
private:
	
	void UpdateSkeletonForSyncAnimations();
	
	UPROPERTY(Transient)
	TObjectPtr<USkeletalMesh> OrigMesh = nullptr;
	
	TArray<FSkeletalMergeFlag> SyncedMeshMergeFlags;
	
	TArray<TWeakObjectPtr<UHiSkeletalMeshComponent>> SyncedMeshComponents;
	
	TMap<UHiSkeletalMeshComponent*, UGFurComponent*> gFurs;
};
