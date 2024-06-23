// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "PoseSearch/PoseSearchFeatureChannel.h"
#include "HiPoseSearchFeatureChannels.generated.h"


struct SampleValueBounds
{
	float MinBoundValue = 1e8f;
	float MinBoundIndex = 0.0f;
	float MaxBoundValue = -1e8f;
	float MaxBoundIndex = 0.0f;
};

struct SampleCachedPose
{
	TArray<FTransform> LocalPose;
	TArray<FTransform> ComponentPose;
	FTransform RootRotation;
};


UCLASS(BlueprintType, EditInlineNew)
class HIGAME_API UHiPoseSearchFeatureChannel_LinearPosition : public UPoseSearchFeatureChannel
{
	GENERATED_BODY()

public:
	UPROPERTY(EditAnywhere, Category = "Settings")
	FBoneReference LeftBone;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FBoneReference RightBone;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FBoneReference ReferenceBone;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float Weight = 1.f;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SampleTimeOffset = 0.f;

	UPROPERTY()
	int16 SchemaLeftBoneIdx;

	UPROPERTY()
	int16 SchemaRightBoneIdx;

	UPROPERTY()
	int16 SchemaReferenceBoneIdx;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int32 ColorPresetIndex = 0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	EInputQueryPose InputQueryPose = EInputQueryPose::UseContinuingPose;

	// UPoseSearchFeatureChannel interface
	// virtual void InitializeSchema(UE::PoseSearch::FSchemaInitializer& Initializer) override;
	// virtual void FillWeights(TArray<float>& Weights) const override;
	// virtual void IndexAsset(UE::PoseSearch::FAssetIndexer& Indexer, UE::PoseSearch::FAssetIndexingOutput& IndexingOutput) const override;
	virtual void BuildQuery(UE::PoseSearch::FSearchContext& SearchContext, UE::PoseSearch::FFeatureVectorBuilder& InOutQuery) const override;

#if ENABLE_DRAW_DEBUG
	virtual void DebugDraw(const UE::PoseSearch::FDebugDrawParams& DrawParams, TArrayView<const float> PoseVector) const override;
#endif

	void BuildPoseTransform(UE::PoseSearch::FSearchContext& SearchContext, const UPoseSearchSchema* SearchSchema
		, const float InSampleTimeOffset, SampleCachedPose& OutPose, bool& OutAnyError) const;
	FTransform BuildSingleBoneTransform(const FReferenceSkeleton& RefSkeleton, const FBoneReference& BoneRef
		, SampleCachedPose& OutPose, bool& OutAnyError) const;
	void UpdateSampleBounds(const FTransform& InSampleTransform, const int32 InSampleIdx, SampleValueBounds& OutValueBounds) const;
};
