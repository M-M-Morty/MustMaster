// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiPoseMatchingSchema.h"

#include "Animation/AnimInstance.h"
#include "Animation/AnimInstanceProxy.h"
#include "Characters/Animation/HiPoseSearchFeatureChannels.h"
#include "Characters/Animation/HiLocomotionAnimInstance.h"

#if WITH_PLUGINS_POSESEARCH
const int32 ForwardPositionValueOffset = 1;
const int32 ValuesSizeForOneBone = 4;		// Position & Velocity
const float NotMovingVelocity = 0.1f;

/********************************************** Custom Compare *****************************************************/

// void SearchIndexInForwardDirection(const FPoseSearchIndex& SearchIndex, const int32 ValueOffset, const bool bIsForward, const SampleValueBounds* Bounds, UE::PoseSearch::FSearchResult& OutResult)
// {
// 	if (!ensure(SearchIndex.IsValid()))
// 	{
// 		return;
// 	}
//
// 	auto CalculateDissimilarity = [](float ValueA, float ValueB)
// 	{
// 		float Distance = ValueA - ValueB;
// 		return Distance * Distance;
// 	};
//
// 	// Prepare data range
// 	const float ForwardPosition = OutResult.ComposedQuery.GetValues()[ValueOffset];
// 	FVector2D SearchIndexRange, SearchValueRange;
// 	if (bIsForward)
// 	{
// 		SearchIndexRange = FVector2D(Bounds->MinBoundIndex, Bounds->MaxBoundIndex);
// 		SearchValueRange = FVector2D(Bounds->MinBoundValue, Bounds->MaxBoundValue);
// 	}
// 	else
// 	{
// 		SearchIndexRange = FVector2D(Bounds->MaxBoundIndex, Bounds->MinBoundIndex);
// 		SearchValueRange = FVector2D(Bounds->MaxBoundValue, Bounds->MinBoundValue);
// 	}
//
// 	// 1. Rough query
// 	//    Simple binary search for forward position
// 	SearchIndexRange.Y = (SearchIndexRange.X < SearchIndexRange.Y) ? SearchIndexRange.Y : SearchIndexRange.Y + SearchIndex.NumPoses;
// 	int32 BestPoseIdx = FMath::RoundToInt32(FMath::GetMappedRangeValueClamped(SearchValueRange, SearchIndexRange, ForwardPosition));
// 	BestPoseIdx = (BestPoseIdx >= SearchIndex.NumPoses) ? BestPoseIdx - SearchIndex.NumPoses : BestPoseIdx;
// 	float BestPoseDissimilarity = CalculateDissimilarity(SearchIndex.GetPoseValues(BestPoseIdx)[ValueOffset], ForwardPosition);
//
// 	// 2. Exact query
// 	//    Sequentially find the frames with the least difference
// 	int32 PrevSearchPoseIndex = 0, NextSearchPoseIndex = 0, ScanPoseIndex = 0;
// 	float PoseDissimilarity = BestPoseDissimilarity;
// 	bool bIsPriorityForwardLookup = bool(bIsForward == bool(SearchIndex.GetPoseValues(BestPoseIdx)[ValueOffset] < ForwardPosition));
// 	int ScanStep = 2;	// Default use Faster detection speed
// 	while (ScanStep > 0)
// 	{
// 		PrevSearchPoseIndex = (BestPoseIdx < ScanStep) ? BestPoseIdx - ScanStep + SearchIndex.NumPoses: BestPoseIdx - ScanStep;
// 		NextSearchPoseIndex = (BestPoseIdx + ScanStep >= SearchIndex.NumPoses) ? BestPoseIdx + ScanStep - SearchIndex.NumPoses : BestPoseIdx + ScanStep;
//
// 		// 2.1 Scan the priority pose index
// 		ScanPoseIndex = (bIsPriorityForwardLookup) ? NextSearchPoseIndex : PrevSearchPoseIndex;
// 		PoseDissimilarity = CalculateDissimilarity(SearchIndex.GetPoseValues(ScanPoseIndex)[ValueOffset], ForwardPosition);
// 		if (PoseDissimilarity < BestPoseDissimilarity)
// 		{
// 			BestPoseDissimilarity = PoseDissimilarity;
// 			BestPoseIdx = ScanPoseIndex;
// 			continue;
// 		}
// 		// 2.2 Scan the anothor pose index
// 		ScanPoseIndex = (bIsPriorityForwardLookup) ? PrevSearchPoseIndex : NextSearchPoseIndex;
// 		PoseDissimilarity = CalculateDissimilarity(SearchIndex.GetPoseValues(ScanPoseIndex)[ValueOffset], ForwardPosition);
// 		if (PoseDissimilarity < BestPoseDissimilarity)
// 		{
// 			BestPoseDissimilarity = PoseDissimilarity;
// 			BestPoseIdx = ScanPoseIndex;
// 			continue;
// 		}
// 		ScanStep--;
// 	}
// 	ensure(BestPoseIdx != INDEX_NONE);
//
// 	// 3. Final find a suitable pose
// 	//    BestPose is calculated by the data of the previous frame, it is necessary to consider the updated delta time and delay the current animation frame
// 	OutResult.PoseIdx = NextSearchPoseIndex;		// TODO: More accurate calculation
// 	//Result.PoseCost.ContinuingPoseCostAddend = CalculateDissimilarity(SearchIndex.GetPoseValues(NextSearchPoseIndex)[ValueOffset], ForwardPosition);
// 	OutResult.SearchIndexAsset = SearchIndex.FindAssetForPose(NextSearchPoseIndex);
// 	OutResult.AssetTime = SearchIndex.GetAssetTime(NextSearchPoseIndex, OutResult.SearchIndexAsset);
// 	OutResult.Database = nullptr;
// }
//
// /************************************************ Public Interface *******************************************************/
//
//
// UE::PoseSearch::FSearchResult UHiPlayerPoseSearchSchema::Search(const UAnimInstance* AnimInstance,
// 	const UPoseSearchSequenceMetaData* MetaData, UE::PoseSearch::FSearchContext& SearchContext) const
// {
// 	using namespace UE::PoseSearch;
//
// 	FSearchResult Result;
//
// 	if (AnimInstance->GetOwningActor()->GetLocalRole() == ROLE_Authority)
// 	{
// 		// Ignore the calculation of the PoseSearch for player move on the server
// 		return Result;
// 	}
//
// 	if (!ensure(MetaData->SearchIndex.IsValid() && !MetaData->SearchIndex.IsEmpty()))
// 	{
// 		return Result;
// 	}
//
// 	if (!MetaData->Schema->BuildQuery(SearchContext, Result.ComposedQuery))
// 	{
// 		UE_LOG(LogTemp, Error, TEXT("UHiPlayerPoseSearchSchema: Build query failed"));
// 		return Result;
// 	}
// 	TArrayView<const float> QueryValues = Result.ComposedQuery.GetValues();
//
// 	if (!ensure(QueryValues.Num() == MetaData->SearchIndex.Schema->SchemaCardinality))
// 	{
// 		UE_LOG(LogTemp, Error, TEXT("UHiPlayerPoseSearchSchema: Unmatched query value size with Schema"));
// 		return Result;
// 	}
//
// 	if (QueryValues.Num() < ValuesSizeForOneBone * 2)
// 	{
// 		UE_LOG(LogTemp, Error, TEXT("UHiPlayerPoseSearchSchema: Unmatched query value size with Logic"));
// 		return Result;
// 	}
//
// 	const float LeftBoneForwardVelocity = QueryValues[ValuesSizeForOneBone - 1];
// 	const float RightFootForwardVelocity = QueryValues[ValuesSizeForOneBone * 2 - 1];
// 	bool bIsMatchLeftSide = false;
// 	bool bIsMovingForward = false;
//
// 	// TODO: Memory allocation optimization & multithreading conflict troubleshooting
// 	// Construct weight
// 	const UHiLocomotionAnimInstance* LocomotionAnimInstance = Cast<UHiLocomotionAnimInstance>(AnimInstance);
//
// 	if (LocomotionAnimInstance && LocomotionAnimInstance->IsLockingLeftFoot())
// 	{
// 		bIsMatchLeftSide = false;
// 		bIsMovingForward = true;
// 	}
// 	else if (LocomotionAnimInstance && LocomotionAnimInstance->IsLockingRightFoot())
// 	{
// 		bIsMatchLeftSide = true;
// 		bIsMovingForward = true;
// 	}
// 	else if (LocomotionAnimInstance && LocomotionAnimInstance->IsTurningLeft())
// 	{
// 		// Rotate to the left will lock the right foot, so PoseMatch needs to match the <left> foot animation
// 		bIsMatchLeftSide = true;
// 		bIsMovingForward = true;
// 	}
// 	else if (LocomotionAnimInstance && LocomotionAnimInstance->IsTurningRight())
// 	{
// 		// Rotate to the right will lock the left foot, so PoseMatch needs to match the <right> foot animation
// 		bIsMatchLeftSide = false;
// 		bIsMovingForward = true;
// 	}
// 	else
// 	{
// 		// Without rotation, match the animation of the front foot 
// 		const float LeftBoneForwardPosition = QueryValues[ForwardPositionValueOffset];
// 		const float RightBoneForwardPosition = QueryValues[ForwardPositionValueOffset + ValuesSizeForOneBone];
// 		if (LeftBoneForwardPosition > RightBoneForwardPosition)
// 		{
// 			bIsMatchLeftSide = true;
// 			bIsMovingForward = bool(LeftBoneForwardVelocity > NotMovingVelocity);
// 		}
// 		else
// 		{
// 			bIsMatchLeftSide = false;
// 			bIsMovingForward = bool(RightFootForwardVelocity > NotMovingVelocity);
// 		}
// 	}
//
// 	// Do Search
// 	const FPoseSearchIndex& SearchIndex = MetaData->SearchIndex;
//
// 	check(SearchIndex.SampleBounds.Num() == sizeof(SampleValueBounds) / sizeof(float) * 2);
// 	if (bIsMatchLeftSide)
// 	{
// 		const SampleValueBounds* BoundsData = reinterpret_cast<const SampleValueBounds*>(SearchIndex.SampleBounds.GetData());
// 		SearchIndexInForwardDirection(SearchIndex, ForwardPositionValueOffset, bIsMovingForward, BoundsData, Result);
// 	}
// 	else
// 	{
// 		const SampleValueBounds* BoundsData = reinterpret_cast<const SampleValueBounds*>(SearchIndex.SampleBounds.GetData()) + 1;
// 		SearchIndexInForwardDirection(SearchIndex, ForwardPositionValueOffset + ValuesSizeForOneBone, bIsMovingForward, BoundsData, Result);
// 	}
//
//
// 	// {
// 	// 	const float LeftBoneForwardPosition = QueryValues[ForwardPositionValueOffset];
// 	// 	const float RightBoneForwardPosition = QueryValues[ForwardPositionValueOffset + ValuesSizeForOneBone];
// 	// 	UE_LOG(LogTemp, Warning, L"[ZLA] Search Meta   Forward: L %.2f  R %.2f    Param: (LR)%d, (FB)%d     Result: %d (Time: %.2f)"
// 	// 		, LeftBoneForwardPosition, RightBoneForwardPosition
// 	// 		, bIsMatchLeftSide, bIsMovingForward
// 	// 		, Result.PoseIdx, Result.AssetTime
// 	// 	);
// 	// }
//
// 	return Result;
// }
#endif
