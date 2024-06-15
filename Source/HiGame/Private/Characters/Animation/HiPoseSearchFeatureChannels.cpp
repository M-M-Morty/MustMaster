// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiPoseSearchFeatureChannels.h"

//////////////////////////////////////////////////////////////////////////
// Constants

constexpr float HiDrawDebugSphereSize = 2.0f;
constexpr int32 HiDrawDebugSphereSegments = 8;
constexpr int EncodeLinearSpeedCardinality = 1;

struct CachedTransform
{
	FTransform Current;
	FTransform Previous;
	int16 SchemaBoneIdx;
};

//////////////////////////////////////////////////////////////////////////
// UHiPoseSearchFeatureChannel_LinearPosition

// void UHiPoseSearchFeatureChannel_LinearPosition::InitializeSchema(UE::PoseSearch::FSchemaInitializer& Initializer)
// {
// 	using namespace UE::PoseSearch;
//
// 	Super::InitializeSchema(Initializer);
// 	ChannelCardinality = (FFeatureVectorHelper::EncodeVectorCardinality + EncodeLinearSpeedCardinality) * 2;
// 	Initializer.SetCurrentChannelDataOffset(ChannelDataOffset + ChannelCardinality);
// 	SchemaLeftBoneIdx = Initializer.AddBoneReference(LeftBone);
// 	SchemaRightBoneIdx = Initializer.AddBoneReference(RightBone);
// 	SchemaReferenceBoneIdx = Initializer.AddBoneReference(ReferenceBone);
// }

// void UHiPoseSearchFeatureChannel_LinearPosition::FillWeights(TArray<float>& Weights) const
// {
// 	using namespace UE::PoseSearch;
//
// 	for (int32 i = 0; i != ChannelCardinality; ++i)
// 	{
// 		Weights[ChannelDataOffset + i] = Weight;
// 	}
// }

// void UHiPoseSearchFeatureChannel_LinearPosition::IndexAsset(UE::PoseSearch::IAssetIndexer& Indexer, UE::PoseSearch::FAssetIndexingOutput& IndexingOutput) const
// {
// 	using namespace UE::PoseSearch;
//
// 	const FAssetIndexingContext& IndexingContext = Indexer.GetIndexingContext();
// 	const FAssetSamplingContext* SamplingContext = IndexingContext.SamplingContext;
//
// 	TArray<float>& SampleBounds = IndexingContext.MetaData->SearchIndex.SampleBounds;
// 	SampleBounds.Reset(0);
// 	SampleBounds.SetNumZeroed(sizeof(SampleValueBounds) / sizeof(float) * 2);
// 	SampleValueBounds* LeftBoneBound = reinterpret_cast<SampleValueBounds*>(SampleBounds.GetData());
// 	SampleValueBounds* RightBoneBound = reinterpret_cast<SampleValueBounds*>(SampleBounds.GetData()) + 1;
//
// 	for (int32 SampleIdx = IndexingContext.BeginSampleIdx; SampleIdx != IndexingContext.EndSampleIdx; ++SampleIdx)
// 	{
// 		int32 VectorIdx = SampleIdx - IndexingContext.BeginSampleIdx;
// 		FPoseSearchFeatureVectorBuilder& FeatureVector = IndexingOutput.PoseVectors[VectorIdx];
//
// 		const float OriginSampleTime = FMath::Min(SampleIdx * IndexingContext.Schema->GetSamplingInterval(), IndexingContext.MainSampler->GetPlayLength());
// 		const float SubsampleTime = OriginSampleTime + SampleTimeOffset;
//
// 		bool ClampedPresent, ClampedPast, ClampedFuture;
// 		int32 DataOffset = ChannelDataOffset;
//
// 		FVector ReferenceTranslation(0, 0, 0);
// 		if (SchemaReferenceBoneIdx >= 0)
// 		{
// 			ReferenceTranslation = Indexer.GetTransformAndCacheResults(SubsampleTime, SubsampleTime, SchemaReferenceBoneIdx, ClampedPresent).GetTranslation();
// 		}
//
// 		// Left Forward Location
// 		const FTransform LeftBoneTransformsPresent = Indexer.GetTransformAndCacheResults(SubsampleTime, SubsampleTime, SchemaLeftBoneIdx, ClampedPresent);
// 		UpdateSampleBounds(LeftBoneTransformsPresent, SampleIdx, *LeftBoneBound);
// 		FFeatureVectorHelper::EncodeVector(FeatureVector.EditValues(), DataOffset, LeftBoneTransformsPresent.GetTranslation() - ReferenceTranslation);
//
// 		// Left Velocity
// 		const FTransform LeftBoneTransformsPast = Indexer.GetTransformAndCacheResults(SubsampleTime - SamplingContext->FiniteDelta, SubsampleTime - SamplingContext->FiniteDelta, SchemaLeftBoneIdx, ClampedPast);
// 		const FTransform LeftBoneTransformsFuture = Indexer.GetTransformAndCacheResults(SubsampleTime + SamplingContext->FiniteDelta, SubsampleTime + SamplingContext->FiniteDelta, SchemaLeftBoneIdx, ClampedFuture);
// 		const FVector LeftForwardVelocity = (LeftBoneTransformsFuture.GetTranslation() - LeftBoneTransformsPast.GetTranslation()) / (SamplingContext->FiniteDelta * 2.0f);
// 		FeatureVector.EditValues()[DataOffset++] = LeftForwardVelocity.Y;
//
// 		// Right Location
// 		const FTransform RightBoneTransformsPresent = Indexer.GetTransformAndCacheResults(SubsampleTime, SubsampleTime, SchemaRightBoneIdx, ClampedPresent);
// 		UpdateSampleBounds(RightBoneTransformsPresent, SampleIdx, *RightBoneBound);
// 		FFeatureVectorHelper::EncodeVector(FeatureVector.EditValues(), DataOffset, RightBoneTransformsPresent.GetTranslation() - ReferenceTranslation);
//
// 		// Right Forward Velocity
// 		const FTransform RightBoneTransformsPast = Indexer.GetTransformAndCacheResults(SubsampleTime - SamplingContext->FiniteDelta, SubsampleTime - SamplingContext->FiniteDelta, SchemaRightBoneIdx, ClampedPast);
// 		const FTransform RightBoneTransformsFuture = Indexer.GetTransformAndCacheResults(SubsampleTime + SamplingContext->FiniteDelta, SubsampleTime + SamplingContext->FiniteDelta, SchemaRightBoneIdx, ClampedFuture);
// 		const FVector RightForwardVelocity = (RightBoneTransformsFuture.GetTranslation() - RightBoneTransformsPast.GetTranslation()) / (SamplingContext->FiniteDelta * 2.0f);
// 		FeatureVector.EditValues()[DataOffset++] = RightForwardVelocity.Y;
//
// 		// {
// 		// 	UE_LOG(LogTemp, Warning, L"[ZLA] Index Asset Sample Index: %d   Left: loc %s  v %.2f    Right: loc %s  v %.2f"
// 		// 		, SampleIdx
// 		// 		, *(LeftBoneTransformsPresent.GetTranslation() - ReferenceTranslation).ToString(), LeftForwardVelocity.Y
// 		// 		, *(RightBoneTransformsPresent.GetTranslation() - ReferenceTranslation).ToString(), RightForwardVelocity.Y
// 		// 	);
// 		// }
// 	}
// }

void UHiPoseSearchFeatureChannel_LinearPosition::UpdateSampleBounds(const FTransform& InSampleTransform, const int32 InSampleIdx, SampleValueBounds& OutValueBounds) const
{
	float ForwardLocation = InSampleTransform.GetTranslation().Y;
	if (OutValueBounds.MinBoundValue > ForwardLocation)
	{
		OutValueBounds.MinBoundValue = ForwardLocation;
		OutValueBounds.MinBoundIndex = InSampleIdx;
	}
	if (OutValueBounds.MaxBoundValue < ForwardLocation)
	{
		OutValueBounds.MaxBoundValue = ForwardLocation;
		OutValueBounds.MaxBoundIndex = InSampleIdx;
	}
}

void UHiPoseSearchFeatureChannel_LinearPosition::BuildQuery(UE::PoseSearch::FSearchContext& SearchContext, UE::PoseSearch::FFeatureVectorBuilder& InOutQuery) const
{
	// using namespace UE::PoseSearch;
	//
	// const bool bIsCurrentResultValid = SearchContext.CurrentResult.IsValid();
	// const bool bSkip = InputQueryPose != EInputQueryPose::UseCharacterPose && bIsCurrentResultValid && SearchContext.CurrentResult.Database->Schema == InOutQuery.GetSchema();
	// if (bSkip || !SearchContext.History)
	// {
	// 	if (bIsCurrentResultValid)
	// 	{
	// 		const float LerpValue = InputQueryPose == EInputQueryPose::UseInterpolatedContinuingPose ? SearchContext.CurrentResult.LerpValue : 0.f;
	// 		int32 DataOffset = ChannelDataOffset;
	// 		FFeatureVectorHelper::EncodeVector(InOutQuery.EditValues(), DataOffset, SearchContext.GetCurrentResultPrevPoseVector(), SearchContext.GetCurrentResultPoseVector(), SearchContext.GetCurrentResultNextPoseVector(), LerpValue);
	// 	}
	// 	return bSkip;
	// }
	//
	// bool AnyError = false;
	//
	// const float HistorySamplelInterval = SearchContext.History->GetSampleTimeInterval();
	// const UPoseSearchSchema* SearchSchema = InOutQuery.GetSchema();
	// check(SearchContext.History && SearchSchema);
	//
	// CachedTransform LeftBoneTransform, RightBoneTransform;
	// SampleCachedPose CachedPose;
	// float CalculateSampleTimeOffset = SampleTimeOffset;
	// const FReferenceSkeleton& RefSkeleton = SearchContext.BoneContainer->GetReferenceSkeleton();
	// BuildPoseTransform(SearchContext, SearchSchema, CalculateSampleTimeOffset, CachedPose, AnyError);
	// if (AnyError)
	// {
	// 	return false;
	// }
	// LeftBoneTransform.Current = BuildSingleBoneTransform(RefSkeleton, LeftBone, CachedPose, AnyError);
	// RightBoneTransform.Current = BuildSingleBoneTransform(RefSkeleton, RightBone, CachedPose, AnyError);
	// CalculateSampleTimeOffset -= HistorySamplelInterval;
	// BuildPoseTransform(SearchContext, SearchSchema, CalculateSampleTimeOffset, CachedPose, AnyError);
	// if (AnyError)
	// {
	// 	return false;
	// }
	// LeftBoneTransform.Previous = BuildSingleBoneTransform(RefSkeleton, LeftBone, CachedPose, AnyError);
	// RightBoneTransform.Previous = BuildSingleBoneTransform(RefSkeleton, RightBone, CachedPose, AnyError);
	//
	// int32 DataOffset = ChannelDataOffset;
	// FFeatureVectorHelper::EncodeVector(InOutQuery.EditValues(), DataOffset, LeftBoneTransform.Current.GetTranslation());
	// const FVector LeftForwardVelocity = (LeftBoneTransform.Current.GetTranslation() - LeftBoneTransform.Previous.GetTranslation()) / HistorySamplelInterval;
	// InOutQuery.EditValues()[DataOffset++] = LeftForwardVelocity.Y;
	// FFeatureVectorHelper::EncodeVector(InOutQuery.EditValues(), DataOffset, RightBoneTransform.Current.GetTranslation());
	// const FVector RightForwardVelocity = (RightBoneTransform.Current.GetTranslation() - RightBoneTransform.Previous.GetTranslation()) / HistorySamplelInterval;
	// InOutQuery.EditValues()[DataOffset++] = RightForwardVelocity.Y;
	//
	// // {
	// // 	UE_LOG(LogTemp, Warning, L"[ZLA] BuildQuery   Left: loc %s  v %.2f    Right: loc %s  v %.2f"
	// // 		, *LeftBoneTransform.Current.GetTranslation().ToString(), LeftForwardVelocity.Y
	// // 		, *RightBoneTransform.Current.GetTranslation().ToString(), RightForwardVelocity.Y
	// // 	);
	// // }
	//
	// check(DataOffset == ChannelDataOffset + ChannelCardinality);
	// return !AnyError;
}

FTransform UHiPoseSearchFeatureChannel_LinearPosition::BuildSingleBoneTransform(const FReferenceSkeleton& RefSkeleton
	, const FBoneReference& BoneRef, SampleCachedPose& OutPose, bool& OutAnyError) const
{
	using namespace UE::PoseSearch;
	static constexpr FBoneIndexType RootBoneIdx = 0xFFFF;

	const FBoneIndexType BoneIndexType = RefSkeleton.FindBoneIndex(BoneRef.BoneName);
	if (INDEX_NONE == BoneIndexType)
	{
		OutAnyError = true;
		return FTransform::Identity;
	}
	FTransform BoneTransform = OutPose.ComponentPose[BoneIndexType];

	const FBoneIndexType ReferenceBoneIndexType = RefSkeleton.FindBoneIndex(ReferenceBone.BoneName);
	if (INDEX_NONE != ReferenceBoneIndexType)
	{
		FVector ReferenceTranslation = OutPose.ComponentPose[ReferenceBoneIndexType].GetTranslation();
		BoneTransform.SetTranslation(BoneTransform.GetTranslation() - ReferenceTranslation);
	}
	
	BoneTransform *= OutPose.RootRotation;
	return BoneTransform;
}

void UHiPoseSearchFeatureChannel_LinearPosition::BuildPoseTransform(UE::PoseSearch::FSearchContext& SearchContext, const UPoseSearchSchema* SearchSchema
	, const float InSampleTimeOffset, SampleCachedPose& OutPose, bool& OutAnyError) const
{
	// if (SearchContext.History->TrySampleLocalPose(-InSampleTimeOffset, &SearchSchema->BoneIndicesWithParents, &OutPose.LocalPose, &OutPose.RootRotation))
	// {
	// 	FAnimationRuntime::FillUpComponentSpaceTransforms(SearchContext.BoneContainer->GetSkeletonAsset()->GetReferenceSkeleton(), OutPose.LocalPose, OutPose.ComponentPose);
	// 	OutAnyError = false;
	//
	// 	OutPose.RootRotation *= SearchContext.OwningComponent->GetComponentTransform().Inverse();
	// 	OutPose.RootRotation.SetTranslation(FVector(0, 0, 0));
	// 	return;
	// }
	// OutAnyError = true;
	// return;
}

#if ENABLE_DRAW_DEBUG
void UHiPoseSearchFeatureChannel_LinearPosition::DebugDraw(const UE::PoseSearch::FDebugDrawParams& DrawParams, TArrayView<const float> PoseVector) const
{
	// using namespace UE::PoseSearch;
	//
	// const UPoseSearchSchema* Schema = DrawParams.GetSchema();
	// check(Schema && Schema->IsValid());
	//
	// const float LifeTime = DrawParams.DefaultLifeTime;
	// const uint8 DepthPriority = ESceneDepthPriorityGroup::SDPG_Foreground + 2;
	// const bool bPersistent = EnumHasAnyFlags(DrawParams.Flags, EDebugDrawFlags::Persistent);
	//
	// int32 DataOffset = ChannelDataOffset;
	// const FVector BonePos = DrawParams.RootTransform.TransformPosition(FFeatureVectorHelper::DecodeVector(PoseVector, DataOffset));
	//
	// const FColor Color = DrawParams.GetColor(ColorPresetIndex);
	//
	// if (EnumHasAnyFlags(DrawParams.Flags, EDebugDrawFlags::DrawFast | EDebugDrawFlags::DrawSearchIndex))
	// {
	// 	DrawDebugPoint(DrawParams.World, BonePos, DrawParams.PointSize, Color, bPersistent, LifeTime, DepthPriority);
	// }
	// else
	// {
	// 	DrawDebugSphere(DrawParams.World, BonePos, HiDrawDebugSphereSize, HiDrawDebugSphereSegments, Color, bPersistent, LifeTime, DepthPriority);
	// }
	//
	// if (EnumHasAnyFlags(DrawParams.Flags, EDebugDrawFlags::DrawBoneNames))
	// {
	// 	DrawDebugString(DrawParams.World, BonePos + FVector(0.0, 0.0, 10.0), Schema->BoneReferences[SchemaLeftBoneIdx].BoneName.ToString(), nullptr, Color, LifeTime, false, 1.0f);
	// 	DrawDebugString(DrawParams.World, BonePos + FVector(0.0, 0.0, 10.0), Schema->BoneReferences[SchemaRightBoneIdx].BoneName.ToString(), nullptr, Color, LifeTime, false, 1.0f);
	// }
}
#endif
