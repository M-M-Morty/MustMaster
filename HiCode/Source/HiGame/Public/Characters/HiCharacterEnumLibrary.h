// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiCharacterEnumLibrary.generated.h"


/* Returns the enumeration index. */
template <typename Enumeration>
static FORCEINLINE int32 GetEnumerationValueIndex(const Enumeration InValue)
{
	return StaticEnum<Enumeration>()->GetIndexByValue(static_cast<int64>(InValue));
}

/* Returns the enumeration value as string. */
template <typename Enumeration>
static FORCEINLINE FString GetEnumerationValueString(const Enumeration InValue)
{
	return StaticEnum<Enumeration>()->GetNameStringByValue(static_cast<int64>(InValue));
}

/**
 * Character input vector type
 */
UENUM(BlueprintType)
enum class EHiInputVectorMode : uint8
{
	CameraSpace = 0,
	WorldSpace = 1,
};

/**
 * Character gait state. 
 */
UENUM(BlueprintType)
enum class EHiGait : uint8
{
	Idle = 0,
	Walking = 1,
	Running = 2,
	Sprinting = 4,
	Pending = 8,
};

UENUM(BlueprintType)
enum class EHiBodySide : uint8
{
	None = 0,
	Left = 1,
	Middle = 2,
	Right = 3,
};

UENUM(BlueprintType)
enum class EHiCameraViewMode : uint8
{
	Classic = 0,
	DoubleObject = 1,
	BuildingSystem = 2,
};

UENUM(BlueprintType)
enum class EHiMovementDirection : uint8
{
	Forward,
	Right,
	Left,
	Backward
};

UENUM(BlueprintType)
enum class EHiMovementAction : uint8
{
	None,
	LowMantle,
	HighMantle,
	Rolling,
	GettingUp,
	SprintTurn,
	SprintBrake,
	Dodge,
	Custom,
	Ride,
};

/**
 * Character movement state. Note: Also edit related struct in ALSStructEnumLibrary if you add new enums
 */
UENUM(BlueprintType)
enum class EHiMovementState : uint8
{
	None,
	Grounded,
	InAir,
	Mantling,
	Ragdoll,
	Ride,
	Custom,
};

UENUM(BlueprintType)
enum class EHiVehicleState : uint8
{
	None,
	OnGrounded,
	InAir,
	InTrack,
};

UENUM(BlueprintType)
enum class EHiServerDealClientPosition : uint8
{
	Suspect,
	Accept
};

/**
 * Character rotation mode. Note: Also edit related struct in ALSStructEnumLibrary if you add new enums
 */
UENUM(BlueprintType)
enum class EHiRotationMode : uint8
{
	VelocityDirection,
	LookingDirection,
	Aiming
};

UENUM(BlueprintType)
enum class EHiInAirState : uint8
{
	None,
	Fly,
	Falling
};

UENUM(BlueprintType)
enum class EHiGroundedEntryState : uint8
{
	None,
	Roll
};

/**
 * Character stance. Note: Also edit related struct in ALSStructEnumLibrary if you add new enums
 */
UENUM(BlueprintType)
enum class EHiStance : uint8
{
	Standing,
	Fighting
};

UENUM(BlueprintType)
enum class EHiSpawnType : uint8
{
	Location,
	Attached
};

UENUM(BlueprintType)
enum class EHiFootstepType : uint8
{
	Step,
	WalkRun,
	Jump,
	Land
};

UENUM(BlueprintType)
enum class EHiJumpState : uint8
{
	None,
	Prepare,
	Jump,
};

UENUM(BlueprintType)
enum class EHiGlideState : uint8
{
	None,
	GlideIdle,
	GlideForward,
	GlideLeft,
	GlideRight
};

/** RootMotion movement modes for Characters. */
UENUM(BlueprintType)
enum class EHiRootMotionOverrideType : uint8
{
	Default,
	Velocity_Z,
	Velocity_XY,
	Velocity_ALL,
	Velocity_Rotation,
	Local_Velocity_X, 
};

UENUM(BlueprintType)
enum class EHiServerControlRotationSimulateMode : uint8
{
	TrustClient,
	IgnoreClient,
	BasedOnClient,
};