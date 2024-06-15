// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "RootMotionModifier.h"
#include "HiRootMotionModifier.generated.h"

/**
 * 
 */
UCLASS(meta = (DisplayName = "Rotate Translation"))
class HIGAME_API URootMotionModifier_RotateTranslation : public URootMotionModifier_Warp
{
	GENERATED_BODY()
public:
	URootMotionModifier_RotateTranslation(const FObjectInitializer& ObjectInitializer);

	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;
};

UCLASS(meta = (DisplayName = "Clear Rotation"))
class HIGAME_API URootMotionModifier_ClearRotation : public URootMotionModifier
{
	GENERATED_BODY()
public:
	URootMotionModifier_ClearRotation(const FObjectInitializer& ObjectInitializer);

	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	bool bClearPitch = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	bool bClearYaw = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	bool bClearRoll = false;
};

UCLASS(meta = (DisplayName = "Warp Rotation"))
class HIGAME_API URootMotionModifier_WarpRotation : public URootMotionModifier_Warp
{
	GENERATED_BODY()
public:
	URootMotionModifier_WarpRotation(const FObjectInitializer& ObjectInitializer);

	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	FQuat ProcessRotation(const FTransform& RootMotionDelta, float DeltaSeconds);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	TObjectPtr<UCurveFloat> AngularVelocityCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	float AngularVelocity = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	FVector Scale = FVector(1.f);

	float TotalTime = 0.0f;

	//UFUNCTION(BlueprintCallable, Category = "Defaults")
	virtual void OnWarpBegin();

	//UFUNCTION(BlueprintCallable, Category = "Defaults")
	virtual void OnWarpEnd();
};

UCLASS(meta = (DisplayName = "Simple Rotate Translation"))
class HIGAME_API URootMotionModifier_SimpleRotateTranslation : public URootMotionModifier
{
	GENERATED_BODY()
public:
	URootMotionModifier_SimpleRotateTranslation(const FObjectInitializer& ObjectInitializer);

	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	FRotator Rotation{0, 0, 0};

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	FVector Scale = FVector(1.f);
};

UCLASS(meta = (DisplayName = "Hi SimpleWarp"))
class HIGAME_API URootMotionModifier_HiSimpleWarp : public URootMotionModifier_Warp
{
	GENERATED_BODY()

public:

	URootMotionModifier_HiSimpleWarp(const FObjectInitializer& ObjectInitializer);
	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config", meta = (EditCondition = "bWarpTranslation"))
	bool bIgnoreHorizontal = false;

	FBoneContainer RequiredBones;

	FAnimSequenceTrackContainer Result;
};

UCLASS(meta = (DisplayName = "Hi SimpleWarp AdjustmentBlendWarp"))
class HIGAME_API URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp : public URootMotionModifier_HiSimpleWarp
{
	GENERATED_BODY()

public:

	URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp(const FObjectInitializer& ObjectInitializer);
	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	void InitRequiredBones();

	void WrapRelatedBone();

	UFUNCTION(BlueprintPure, Category = "Motion Warping")
	static void GetAdjustmentBoneTransformAndAlpha(ACharacter* Character, const FName &BoneName, FTransform& OutTransform, float& OutAlpha);

	virtual void OnWarpBegin();
	
	void GetAdjustBoneTransform(const FName &BoneName, FTransform& OutTransform, float& OutAlpha);

	UPROPERTY(EditAnywhere, Category=SkeletalControl)
	FBoneReference BoneToModify;
	
	FBoneContainer RequiredBones;

	FTransform AdjustBoneTransform;

	FTransform LastAdjustBoneTransform;
	
	FTransform MeshInitTransform;

	float HorizontalTranslationScale = 1.0f;
	float VerticalTranslationScale = 1.0f;

	bool bRestart = false;
};


UCLASS(meta = (DisplayName = "Hi ScaleRotation"))
class HIGAME_API URootMotionModifier_HiScaleRotation : public URootMotionModifier_Warp
{
	GENERATED_BODY()

public:

	URootMotionModifier_HiScaleRotation(const FObjectInitializer& ObjectInitializer);
	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	virtual void OnWarpBegin();

	virtual void OnTargetTransformChanged();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	FVector Scale = FVector(1.f);
	
protected:
};

UCLASS(meta = (DisplayName = "Hi ScaleTranslation"))
class HIGAME_API URootMotionModifier_HiScaleTranslation : public URootMotionModifier_Warp
{
	GENERATED_BODY()

public:

	URootMotionModifier_HiScaleTranslation(const FObjectInitializer& ObjectInitializer);
	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	virtual void OnWarpBegin();

	virtual void OnTargetTransformChanged();

	FORCEINLINE FVector GetTargetScale() const { return CachedTargetTransform.GetScale3D(); }

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config")
	FVector Scale = FVector(1.f);

	FVector AccDelta;
	
protected:
};

UCLASS(meta = (DisplayName = "Hi ScaleToTargetLength"))
class HIGAME_API URootMotionModifier_HiScaleToTargetLength : public URootMotionModifier_Warp
{
	GENERATED_BODY()

public:

	URootMotionModifier_HiScaleToTargetLength(const FObjectInitializer& ObjectInitializer);
	virtual FTransform ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds) override;

	virtual void OnWarpBegin();

	virtual void OnTargetTransformChanged();

	FORCEINLINE FVector GetTargetLength() const { return CachedTargetTransform.GetScale3D(); }
	
protected:
	FVector Scale = FVector(1.f);
};