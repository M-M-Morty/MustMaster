// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimData/BoneMaskFilter.h"
#include "Animation/AnimTypes.h"
#include "Components/SkeletalMeshComponent.h"
#include "HiCombineMeshComponent.generated.h"

class UHiCombineAnimInstance;
/**
 * 
 */
UCLASS(Blueprintable, ClassGroup=(Rendering, Common), hidecategories=(Object, "Mesh|SkeletalAsset"), config=Engine, editinlinenew, meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiCombineMeshComponent : public USkeletalMeshComponent
{
	friend class UHiCombineAnimInstance;
	GENERATED_BODY()
	
public:
	UHiCombineMeshComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	virtual void OnRegister() override;
	virtual void OnUnregister() override;

	virtual void InitAnim(bool bForceReinit) override;
	
	UFUNCTION(BlueprintPure)
	bool IsSubMesh() const { return bIsSubMesh;}
	virtual void OnChildAttached(USceneComponent* ChildComponent) override;
	virtual void OnChildDetached(USceneComponent* ChildComponent) override;
	virtual void OnAttachmentChanged() override;

	void InitializeMesh();
	void CleanCombineMesh();

	virtual void InitializeComponent() override;
	void InitializeMergeAnimScriptInstance();
	void MergeSubMeshes();
	
	UFUNCTION(BlueprintCallable, Category="Hi Combine Mesh")
	static USkeleton* MergeSkeletons(const TArray<USkeleton*>& SkeletonsToMerge);

	UFUNCTION(BlueprintCallable, Category="Hi Combine Mesh")
	static USkeletalMesh* MergeSkeletalMeshes(const TArray<USkeletalMesh*>& SkeletalMeshes);

	UPROPERTY(EditDefaultsOnly, Category="Mesh")
	bool bNeedMerge = false;

	UPROPERTY(EditDefaultsOnly, Category="Mesh")
	bool bBaseMesh = false;

private:
	bool bIsSubMesh = false;
	bool bIsCombineMesh = false;

public:
	UPROPERTY()
	TArray<TWeakObjectPtr<UHiCombineMeshComponent>> SubMeshComponents;

	UPROPERTY(EditAnywhere)
	float BlendWeight=1.0;

	UPROPERTY(EditAnywhere)
	TObjectPtr<UBlendProfile> BlendProfile=nullptr;

	UPROPERTY(EditAnywhere)
	FInputBlendPose LayerSetup;
	
};
