// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Kismet/KismetSystemLibrary.h"
#include "CoreMinimal.h"
#include "Characters/HiCharacterStructLibrary.h"

#include "HiCharacterMathLibrary.generated.h"

class UCapsuleComponent;

/**
 * Math library functions for Character
 */
UCLASS()
class HIGAME_API UHiCharacterMathLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static FTransform MantleComponentLocalToWorld(const FHiComponentAndTransform& CompAndTransform);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static FTransform TransfromSub(const FTransform& T1, const FTransform& T2)
	{
		return FTransform(T1.GetRotation().Rotator() - T2.GetRotation().Rotator(),
		                  T1.GetLocation() - T2.GetLocation(), T1.GetScale3D() - T2.GetScale3D());
	}

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static FTransform TransfromAdd(const FTransform& T1, const FTransform& T2)
	{
		return FTransform(T1.GetRotation().Rotator() + T2.GetRotation().Rotator(),
		                  T1.GetLocation() + T2.GetLocation(), T1.GetScale3D() + T2.GetScale3D());
	}

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static FVector GetCapsuleBaseLocation(float ZOffset, UCapsuleComponent* Capsule);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static FVector GetCapsuleLocationFromBase(FVector BaseLocation, float ZOffset, UCapsuleComponent* Capsule);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static bool CapsuleHasRoomCheck(UCapsuleComponent* Capsule, FVector TargetLocation, float HeightOffset,
	                                float RadiusOffset, EDrawDebugTrace::Type DebugType = EDrawDebugTrace::Type::None, bool DrawDebugTrace = false);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static bool CapsuleHasRoom(UCapsuleComponent* Capsule, FVector TargetLocation, FName ProfileName, float HeightOffset,
									float RadiusOffset, EDrawDebugTrace::Type DebugType = EDrawDebugTrace::Type::None, bool DrawDebugTrace = false);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static bool AngleInRange(float Angle, float MinAngle, float MaxAngle, float Buffer, bool IncreaseBuffer);

	UFUNCTION(BlueprintCallable, Category = "Hi|Math Utils")
	static EHiMovementDirection CalculateQuadrant(EHiMovementDirection Current, float FRThreshold, float FLThreshold,
	                                               float BRThreshold,
	                                               float BLThreshold, float Buffer, float Angle);
};
