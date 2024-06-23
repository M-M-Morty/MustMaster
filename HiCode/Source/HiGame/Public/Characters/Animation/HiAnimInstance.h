// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstance.h"
#include "Engine/DataTable.h"
#include "HiAnimInstance.generated.h"

class UHiGlideComponent;
class UHiLocomotionComponent;
class UHiSkeletalMeshComponent;
class UHiJumpComponent;
class AHiCharacter;


USTRUCT(Blueprintable)
struct FHiAnimSequencePath : public FTableRowBase
{
	GENERATED_BODY()
public:
	FHiAnimSequencePath(){}
	FHiAnimSequencePath(const FString animName, const FString animPath):
	AnimName(animName),AnimPath(animPath){}
	UPROPERTY(EditAnywhere)
	FString AnimName;
	UPROPERTY(EditAnywhere)
	FString AnimPath;
};
/**
 * Animation blueprint sub instance.
 * Specially designed for walking, running and jumping.
 */
UCLASS(Blueprintable)
class HIGAME_API UHiAnimInstance : public UAnimInstance
{
	GENERATED_BODY()

public:
	virtual void NativeInitializeAnimation() override;

	virtual void NativeUninitializeAnimation() override;

	/** Plays an animation montage. Returns the length of the animation montage in seconds. Returns 0.f if failed to play. */
	UFUNCTION(BlueprintNativeEvent)
	float Montage_Play_With_PoseSearch(UAnimMontage* MontageToPlay, float InPlayRate = 1.f, EMontagePlayReturnType ReturnValueType = EMontagePlayReturnType::MontageLength, float InTimeToStartMontageAt=0.f, bool bStopAllMontages = true);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	float GetMontageStartPosition(UAnimMontage* MontageToPlay);
public:
	UFUNCTION(BlueprintCallable, Category = "Event")
	virtual void OnUpdateComponent();

	virtual void PreUpdateAnimation(float DeltaSeconds) override;
	
	UFUNCTION()
	void OnMontageStartToPlay(UAnimMontage* Montage);

	UFUNCTION()
	void OnMontageEnd(UAnimMontage* Montage, bool bInterrupted);
	
	static FString GetSkeletonName(const USkeleton* Skeleton, const FString& ParentName);

#if WITH_EDITOR
	UFUNCTION(BlueprintCallable, Category = "Animation") 
	static UDataTable* GenerateSkeletonAnimationsTable(USkeleton* Skeleton, FString PackagePath, bool IncludeSubClass=false);
	
	UFUNCTION(BlueprintCallable, Category = "Animation|Montage") 
	static UDataTable*  GenerateActorAnimMontageTable(USkeleton* Skeleton, FString ActorName, FString PackagePath);

	UFUNCTION(BlueprintCallable, Category = "Animation|Montage") 
	static UDataTable*  GenerateActorAnimMontageTableByMesh(USkeletalMeshComponent* MeshComponent, FString ActorName, FString PackagePath);
#endif
	
	void UpdateAnimNodeAnimSequence();
	
	void OnAnimNodeInitialize(UAnimSequenceBase* Anim);

	UFUNCTION(BlueprintCallable, Category = "DataTable") 
	static UDataTable* LoadDataTable(FString Path);

	UFUNCTION(BlueprintCallable, Category = "DataTable") 
	static FString LoadAnimPathFromDataTable(UDataTable* DataTable, FString AnimName);
	
	
	/** Override point for derived classes to create their own proxy objects (allows custom allocation) */
	virtual FAnimInstanceProxy* CreateAnimInstanceProxy() override;

	UFUNCTION(BlueprintCallable, Category = "Animation|Montage") 
	static UAnimMontage* LoadMontage_Play(UAnimInstance* Instance, FString MontageName,  float InPlayRate = 1.f, EMontagePlayReturnType ReturnValueType = EMontagePlayReturnType::MontageLength, float InTimeToStartMontageAt=0.f, bool bStopAllMontages = true);

	UFUNCTION(BlueprintCallable, Category = "Animation|Montage") 
	static UAnimMontage* LoadSlotAnimAsDynamicMontage(FString AnimName, FName SlotNodeName, float BlendInTime = 0.25f, float BlendOutTime = 0.25f, float InPlayRate = 1.f, int32 LoopCount = 1, float BlendOutTriggerTime = -1.f, float InTimeToStartMontageAt = 0.f);

	UFUNCTION(BlueprintCallable, Category = "Animation|Montage") 
	static UAnimMontage* LoadMontageSlotAnimAsDynamicMontage(UAnimMontage * Montage);


	
	UFUNCTION(BlueprintCallable, Category = "Animation|InsertMod") 
	void OpenInsert(float BlendInTime);

	UFUNCTION(BlueprintCallable, Category = "Animation|InsertMod") 
	void CloseInsert(float BlendOutTime);
	
private:

	void UpdateFaceMeshComponent();

public:
	
	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data| Face Animation")
	float FaceAnimBlendWeight = 0.0f;

	/** References */
	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data|CharacterLocomotion Information")
	TObjectPtr<UHiLocomotionComponent> LocomotionComponent = nullptr;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data|CharacterLocomotion Information")
	TObjectPtr<UHiJumpComponent> JumpComponent = nullptr;
	
	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data|CharacterLocomotion Information")
	TObjectPtr<UHiGlideComponent> GlideComponent = nullptr;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data|CharacterLocomotion Information")
	TObjectPtr<UHiSkeletalMeshComponent> FaceMeshComponent = nullptr;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data|Character Information")
	TObjectPtr<AHiCharacter> Character = nullptr;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data| InsertMod")
	float BlendInInsertTime = 0.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data| InsertMod")
	float BlendOutInsertTime = 0.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Read Only Data| InsertMod")
	bool IsinsertActive = false;
};
