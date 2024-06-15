// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Object.h"
#include "PoseSearch/PoseSearchSchema.h"
#include "PoseSearch/PoseSearchResult.h"
#include "HiPoseMatchingSchema.generated.h"


class UAnimSequenceBase;
class UAnimInstance;


/*
 * UHiPlayerPoseSearchSchema
 *    - A specially PoseMatchingSchema to deal with main movement loop animation, such as running, walking, sprinting, etc
 *    - Logically, a main leg will be selected for matching, which will be accurate to the frame
 *    - It will be used synchronously with the FootLock in the game logic
 *    - Only execute on the client side
 *    - Force binding with special functions
 */
UCLASS(BlueprintType, Category = "Animation|Pose Search")
class HIGAME_API UHiPlayerPoseSearchSchema : public UPoseSearchSchema
{
	GENERATED_BODY()

public:
#if WITH_PLUGINS_POSESEARCH
	// Use in runtime with customized search
	// virtual UE::PoseSearch::FSearchResult Search(const UAnimInstance* AnimInstance,
	// 	const UPoseSearchSequenceMetaData* MetaData, UE::PoseSearch::FSearchContext& SearchContext) const override;
#endif
};
