// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiCharacterEnumLibrary.h"
#include "HiCharacterStructLibrary.generated.h"

class UAnimMontage;
class UCurveVector;


USTRUCT(BlueprintType)
struct FHiLeanAmount
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	float LR = 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	float FB = 0.0f;
};


USTRUCT(BlueprintType)
struct FHiDynamicMontageParams
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Dynamic Transition")
	TObjectPtr<UAnimSequenceBase> Animation = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Dynamic Transition")
	float BlendInTime = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Dynamic Transition")
	float BlendOutTime = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Dynamic Transition")
	float PlayRate = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Dynamic Transition")
	float StartTime = 0.0f;
};

/**
 * Character gait state. 
 */
USTRUCT(BlueprintType)
struct FHiMovementSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Movement Settings")
	float WalkSpeed = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Movement Settings")
	float RunSpeed = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Movement Settings")
	float SprintSpeed = 0.0f;

	float GetSpeedForGait(const EHiGait Gait) const
	{
		switch (Gait)
		{
		case EHiGait::Running:
			return RunSpeed;
		case EHiGait::Sprinting:
			return SprintSpeed;
		case EHiGait::Walking:
			return WalkSpeed;
		default:
			return RunSpeed;
		}
	}
};


USTRUCT(BlueprintType)
struct FHiAnimGroundedConfig
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gait", meta = (ClampMin = "0.0"))
	float AnimatedWalkSpeed = 175.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gait", meta = (ClampMin = "0.0"))
	float AnimatedRunSpeed = 350.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gait", meta = (ClampMin = "0.0"))
	float AnimatedSprintSpeed = 650.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Gait", meta = (ClampMin = "0.0"))
	float GroundedLeanInterpSpeed = 4.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Yaw Offset", meta = (ClampMin = "0.001", ForceUnits = s))
	float YawRestoreHalfLife = 0.04f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Yaw Offset", meta = (ClampMin = "0.0"))
	float ReverseYawAlphaFactor = 0.6f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Yaw Offset", meta = (ClampMin = "0.0", ForceUnits = s))
	float ReverseYawAlphaIncreaseDuration = 0.6f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lean", meta = (ClampMin = "0.0", ForceUnits = s))
	float LeanFilteringDuration = 0.16f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Lean")
	FHiLeanAmount LeanSpeedFactor { 1.0f, 1.0f };

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Pedal", meta = (ClampMin = "0.0", ForceUnits = s))
	float BreakControlRotateDuration = 0.2f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Pedal")
	float PedalRotationMinSpeed = 200.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Pedal", meta = (ClampMin = "0.1", ClampMax = "180.0", ForceUnits = "degrees"))
	float PedalRotationMinAngle = 75.0f;

	UPROPERTY(EditDefaultsOnly, Category = "Body Adjust")
	FBoneReference BodyBone;		// Control the whole body, but not the root bone
};


USTRUCT(BlueprintType)
struct FHiAnimGraphGrounded
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	bool bShouldMove = false;		// Should be false initially

	UPROPERTY(EditInstanceOnly, BlueprintReadWrite)
	bool bWalkStop = false;		// Should be false initially

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	float AnimatedYawOffset = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	float ControlRotateYaw = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	FHiLeanAmount LeanAmount;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	float StandingPlayRate = 1.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	EHiBodySide PedalRotationDirection = EHiBodySide::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	bool bIsTriggeredPedal = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	FVector BodyBoneOffset = FVector::ZeroVector;
};


USTRUCT(BlueprintType)
struct FHiTurnInPlaceAsset
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	TObjectPtr<UAnimMontage> Animation = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float AnimatedAngle = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	FName SlotName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float PlayRate = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	bool ScaleTurnAngle = true;
};


USTRUCT(BlueprintType)
struct FHiAnimTurnInPlace
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float TurnCheckMinAngle = 45.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float Turn180Threshold = 130.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float AimYawRateLimit = 50.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float ElapsedDelayTime = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float MinAngleDelay = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	float MaxAngleDelay = 0.75f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	FHiTurnInPlaceAsset N_TurnIP_L90;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	FHiTurnInPlaceAsset N_TurnIP_R90;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	FHiTurnInPlaceAsset N_TurnIP_L180;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Turn In Place")
	FHiTurnInPlaceAsset N_TurnIP_R180;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Turn In Place")
	float TurnInPlaceAngle = 0.0f;
};


USTRUCT(BlueprintType)
struct FHiFootAnimConfig
{
	GENERATED_BODY()

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	FName IkFootL_BoneName = FName(TEXT("ik_foot_l"));

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	FName IkFootR_BoneName = FName(TEXT("ik_foot_r"));

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	FName FootLock_BoneName_Left = FName(TEXT("ball_l"));

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	FName FootLock_BoneName_Right = FName(TEXT("ball_r"));

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	float FootLockDurationWhenEnterMoving = 0.2f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	float FootLockAutoDecayDuration = 0.2f;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	float FootHeight = 5.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock", meta = (ClampMin = "0.0", ClampMax = "180.0", ForceUnits = "degrees"))
	float AnimatedRotationMinAngle = 10.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot Lock")
	float FootLockHeightDeviation = 2.5f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot IK")
	float IK_TraceDistanceAboveFoot = 50.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Foot IK")
	float IK_TraceDistanceBelowFoot = 45.0f;
};


USTRUCT(BlueprintType)
struct FHiFootLockValues
{
	GENERATED_BODY()

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly)
	float Alpha = 0.0f;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly)
	FVector Location = FVector::ZeroVector;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadOnly)
	FRotator Rotator = FRotator::ZeroRotator;
};


USTRUCT(BlueprintType)
struct FHiFootAnimValues
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Foot Lock", Meta = (ShowOnlyInnerProperties))
	FHiFootLockValues FootLock_Left;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Foot Lock", Meta = (ShowOnlyInnerProperties))
	FHiFootLockValues FootLock_Right;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Foot Values")
	EHiBodySide StopFrontFoot = EHiBodySide::Left;
};


USTRUCT(BlueprintType)
struct FHiLandingAnimConfig
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration")
	TObjectPtr<UAnimSequence> LandingSequence = nullptr;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration", meta = (ClampMin = "0.0", ForceUnits = "cm/s"))
	float EffectiveLandingSpeed = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration", meta = (ClampMin = "0.0", ForceUnits = s))
	float PreLandingAnimTime = 0.0f;
};


USTRUCT(BlueprintType)
struct FHiInAirAnimConfig
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration")
	float InAirLeanInterpSpeed = 4.0f;

	// When switching states from #Grounded to #InAir, if the predicted time is maintained for less than the setting's time, maintain the grounded animation
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration")
	float MaxPredictedLandingTime_KeepGroundAnimation = 0.3f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration")
	TArray<FHiLandingAnimConfig> LandingAnimArray;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration", meta = (ClampMin = "0.001"))
	float AnimatedLandLeadScale = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Main Configuration", meta = (ClampMin = "1"))
	int LandPredictionIterations = 2;
};


USTRUCT(BlueprintType)
struct FHiInAirAnimValues
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	bool bJumped = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float JumpPlayRate = 1.2f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float FallSpeed = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	FVector PredictionLandingMovement = FVector::ZeroVector;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float LandPrediction = -1.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float LandPredictAnimationRate = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float AnimatedPredictLandingTime = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	TObjectPtr<UAnimSequence> SelectLandingSequence = nullptr;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	EHiJumpState JumpState = EHiJumpState::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "In Air")
	float JumpFeetPosition = 0.0f;
};

USTRUCT(BlueprintType)
struct FHiGlideValues
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Glide")
	EHiGlideState GlideState = EHiGlideState::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Glide")
	float AccelerationDirection;
	
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float ActorInterpSpeed;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float MinTurnYaw;
};

USTRUCT(BlueprintType)
struct FHiTargetMoveValues
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float VelocityBlendForward;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float VelocityBlendBack;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float VelocityBlendLeft;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float VelocityBlendRight;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "TargetedMove")
	float MoveDirection;
};

USTRUCT(BlueprintType)
struct FHiAnimGraphAimingValues
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	FRotator SmoothedAimingRotation = FRotator::ZeroRotator;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	FRotator SpineRotation = FRotator::ZeroRotator;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	FVector2D AimingAngle = FVector2D::ZeroVector;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	float AimSweepTime = 0.5f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	float InputYawOffsetTime = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	float ForwardYawTime = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	float LeftYawTime = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Anim Graph - Aiming Values")
	float RightYawTime = 0.0f;
};

USTRUCT(BlueprintType)
struct FHiAnimCharacterInformation
{
	GENERATED_BODY()

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	FRotator AimingRotation = FRotator::ZeroRotator;;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	FRotator CharacterActorRotation = FRotator::ZeroRotator;;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	FVector Velocity = FVector::ZeroVector;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	FVector Acceleration = FVector::ZeroVector;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	FVector MovementInput = FVector::ZeroVector;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	bool bIsMoving = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	bool bHasMovementInput = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	bool bIsAccelerating = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	float Speed = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	float MovementInputAmount = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	float AimYawRate = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	float DirectionYaw = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	EHiMovementAction MovementAction = EHiMovementAction::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	EHiMovementState PrevMovementState = EHiMovementState::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	EHiRotationMode RotationMode = EHiRotationMode::VelocityDirection;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	bool bInVehicle = false;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Hi|Character Information")
	bool bIsInSkillAnim = false;
};


/**
 * Store physical status during character movement
*/
USTRUCT(BlueprintType)
struct FHiPhysMovementStatus
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "Physics Movement Status")
	bool bIsHorizontalSliding = false;
};


USTRUCT(BlueprintType)
struct FHiMantleTraceSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float MaxLedgeHeight = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float MinLedgeHeight = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float ReachDistance = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float ForwardTraceRadius = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float DownwardTraceRadius = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float HeightTolerance = 10.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float MantleWallDistance = 100.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float EaveWide = 50.0f;
	
	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float ObstacleCheckHeight = 50.0f;
	
	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float ObstacleCheckOffset = 50.0f;
	
	UPROPERTY(EditAnywhere, Category = "Mantle System")
	FVector2D ObstacleCheckDistance = FVector2D(30, 100);

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TArray<float> LandOffsets = { 70.0f, 200.0f };

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float FenceHeightOffset = 50.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float FenceEdgeOffset = 20.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TArray<float> FenceOffsets = { 35.0f, };
};

USTRUCT(BlueprintType)
struct FHiMantleParams
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TObjectPtr<UAnimMontage> AnimMontage = nullptr;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TObjectPtr<UCurveVector> PositionCorrectionCurve = nullptr;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float StartingPosition = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float PlayRate = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	FVector StartingOffset = FVector::ZeroVector;
};

UENUM(BlueprintType)
enum class EHiMantleSubType : uint8
{
	None,
	Ledge,
	Fence,
	StepUp,
	Sprint,
	FlyOver,
	Custom
};

USTRUCT(BlueprintType)
struct FHiMantleAsset
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TObjectPtr<UAnimMontage> AnimMontage = nullptr;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	TObjectPtr<UCurveVector> PositionCorrectionCurve = nullptr;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	FVector StartingOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float LowHeight = 50.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float LowPlayRate = 1.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float LowStartPosition = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float HighHeight = 150.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float HighPlayRate = 1.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float HighStartPosition = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	EHiMantleSubType MantleSubType = EHiMantleSubType::Ledge;
};

USTRUCT(BlueprintType)
struct FHiComponentAndTransform
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Character Struct Library")
	FTransform Transform;
	
	UPROPERTY(EditAnywhere, Category = "Character Struct Library")
	FTransform LandTransform;

	UPROPERTY(EditAnywhere, Category = "Character Struct Library")
	TObjectPtr<UPrimitiveComponent> Component = nullptr;
};

USTRUCT(BlueprintType)
struct FHiLinkAnimGraphConfig
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Anim Graph")
	FName Tag;

	UPROPERTY(EditAnywhere, Category = "Anim Graph")
	TSubclassOf<UAnimInstance> AnimBlueprintClass;
};
