// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "HiTargetActorSpec.generated.h"
/**
 * 
 */

// TA calculate type.
UENUM(BlueprintType)
enum ECalcType
{
	Instant		UMETA(DisplayName = "Instant"),
	Projectile	UMETA(DisplayName = "Projectile")
};

// TA start position type.
UENUM(BlueprintType)
enum EStartPosType
{
	Source			UMETA(DisplayName = "Source"),
	Ally			UMETA(DisplayName = "Ally"),
	Enemy			UMETA(DisplayName = "Enemy")
};

// TA movement type.
UENUM(BlueprintType)
enum EMoveType
{
	MoveTypeFixed	UMETA(DisplayName = "Fixed position"),
	SourceForward	UMETA(DisplayName = "Move from source forward"),
	FollowTarget	UMETA(DisplayName = "Move from source and follow target"),
	BindTarget		UMETA(DisplayName = "Bind target")
};

// Projectile calculate type.
UENUM(BlueprintType)
enum EProjectileCalcType
{
	Collision	UMETA(DisplayName = "On collision"),
	Period		UMETA(DisplayName = "Period")
};

// TA calculate destroy type.
UENUM(BlueprintType)
enum ECalcDestroyType
{
	NotDestroy			UMETA(DisplayName = "Not destroy"),
	DestroyAfterCalc	UMETA(DisplayName = "Destroy after calculation")
};

// Calculate Range type.
UENUM(BlueprintType)
enum ECalcRangeType
{
	Circle	UMETA(DisplayName = "Circle"),
	CalcRangeTypeRect	UMETA(DisplayName = "Rect"),
	Section UMETA(DisplayName = "Section")
};

// Calculate filter type.
UENUM(BlueprintType)
enum ECalcFilterType
{
	AllActor			UMETA(DisplayName = "All Actor"),
	AllEnemy			UMETA(DisplayName = "All enemy"),
	AllAlly				UMETA(DisplayName = "All ally"),
	AliveEnemy			UMETA(DisplayName = "Alive enemy"),
	AliveAlly			UMETA(DisplayName = "Alive ally"),
	AliveAll			UMETA(DisplayName = "Alive all"),
	DeadEnemy			UMETA(DisplayName = "Dead enemy"),
	DeadAlly			UMETA(DisplayName = "Dead ally"),
	DeadAll				UMETA(DisplayName = "Dead all"),
	Self				UMETA(DisplayName = "Self"),
	NoSelf				UMETA(DisplayName = "No self"),
};

// Calculate priority type.
UENUM(BlueprintType)
enum ECalcPriorityType
{
	CalcPriorityTypeNone	UMETA(DisplayName = "None"),
	HighestHealth			UMETA(DisplayName = "Highest health"),
	LowestHealth			UMETA(DisplayName = "Lowest health")
};

USTRUCT(BlueprintType)
struct HIGAME_API FHiTargetActorSpec
{
	GENERATED_BODY()
	
	/** Start pos type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	TEnumAsByte<EStartPosType> StartPosType = Source;

	/** Start pos offset */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	FVector StartPosOffset = FVector::ZeroVector;

	/** Projectile movement type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	TEnumAsByte<EMoveType> MoveType = MoveTypeFixed;
	
	/** Projectile horizontal init speed */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	float HSpeed = 0.0f;

	/** Projectile vertical init speed */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	float VSpeed = 0.0f;

	/** Projectile horizontal Accelerate speed */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	float HAccSpeed = 0.0f;

	/** Projectile vertical Accelerate speed */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Movement)
	float VAccSpeed = 0.0f;

	/** Projectile calculation type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	TEnumAsByte<EProjectileCalcType> ProjectileCalcType = Collision;
	
	/** Projectile calculation period */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (EditCondition = "ProjectileCalcType == EProjectileCalcType::Period"), Category = Calculation)
	float CalcPeriod = 0.0f;

	/** Calculation target filter type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Calculation)
	TEnumAsByte<ECalcFilterType> CalcFilterType = NoSelf;
	
	/** Projectile calculation count limit, -1 is no limit */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Calculation)
	int CalcCountLimit = 1;

	/** Target count limit in single calculation */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Calculation)
	int CalcTargetLimit = 1;

	/** Projectile calculation destroy type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Calculation)
	TEnumAsByte<ECalcDestroyType> CalcDestroyType = NotDestroy;

	/** Projectile exist max duration */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Calculation)
	float Duration = 1;
	
	/** Projectile destroy effect actor */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Display)
	UParticleSystem* DestroyEffect = nullptr;
	
	/** Calculation range type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	TEnumAsByte<ECalcRangeType> CalcRangeType = Circle;

	/** Calculation radius for circle or section type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (EditCondition = "CalcRangeType != ECalcRangeType::CalcRangeTypeRect"), Category = Targeting)
	float Radius = 0.0f;

	/** Calculation length for rect type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (EditCondition = "CalcRangeType == ECalcRangeType::CalcRangeTypeRect"), Category = Targeting)
	float Length = 0.0f;

	/** Calculation half width for rect type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (EditCondition = "CalcRangeType == ECalcRangeType::CalcRangeTypeRect"), Category = Targeting)
	float HalfWidth = 0.0f;
	
	/** Upside limit height */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	float UpHeight = 200;

	/** Downside limit height */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	float DownHeight = 200;
	
	/** Angle for section type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, meta = (EditCondition = "CalcRangeType == ECalcRangeType::Section"), Category = Targeting)
	float Angle = 0.0f;
};
