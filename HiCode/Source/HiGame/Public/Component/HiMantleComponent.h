// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "Components/ActorComponent.h"
#include "Components/TimelineComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Characters/HiCharacter.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "HiMantleComponent.generated.h"

// forward declarations
class UHiCharacterDebugComponent;
class UHiJumpComponent;

UENUM(BlueprintType)
enum class EHiWallRunType : uint8
{
	None,
	Climb,
	Sprint,
	Custom
};

UENUM(BlueprintType)
enum class EHiClimbType : uint8
{
	None,
	Mantle,
	WallRun,
	Custom
};

USTRUCT(BlueprintType)
struct FHiComponentAndMatrix
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Character Struct Library")
	FMatrix Matrix = FMatrix::Identity;

	UPROPERTY(EditAnywhere, Category = "Character Struct Library")
	TObjectPtr<UPrimitiveComponent> Component = nullptr;
};

USTRUCT(BlueprintType)
struct FHiMantleWaitTimeSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float WaitTime = 0.1f;

	UPROPERTY(EditAnywhere, Category = "Mantle System")
	float WaitTimeInAir = 0.0f;
};

USTRUCT(BlueprintType)
struct FHiMantleWaitTime
{
	GENERATED_BODY()

	float TotalTime = 0.0f;

	uint64 LastCheckFrameCount = 0;
};

struct FCalculatePoseContext
{
	FRotator Pose;
	float DeltaTime = 0.0f;
};

struct MantleCheckContext
{
	FHiMantleTraceSettings TraceSettings;
	FVector ClimbTraceStart;
	FVector CapsuleBaseLocation;
	FVector TraceDirection;
	float WallDistance;
	EDrawDebugTrace::Type DebugType;
};

UCLASS(Blueprintable, BlueprintType)
class HIGAME_API UHiMantleComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UHiMantleComponent(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	virtual void InitializeComponent() override;
	
	bool MantleCheck(const FHiMantleTraceSettings& TraceSettings,
	                 EDrawDebugTrace::Type DebugType, bool bWait=false);

	UFUNCTION(BlueprintCallable, Category = "Hi|Mantle System")
	bool GroundCheck(const FHiMantleTraceSettings& TraceSettings,
					 EDrawDebugTrace::Type DebugType, bool bWait=false);

	bool ReachRoofCheck(const FHiMantleTraceSettings& TraceSettings,
					 EDrawDebugTrace::Type DebugType, bool bWait=false);

	bool FenceCheck(const MantleCheckContext &Context, UPrimitiveComponent  * &HitComponent, FVector &MantleVector, float &MaxMantleHeight);

	bool LandPointCheck(const MantleCheckContext &Context, UPrimitiveComponent  * &HitComponent, FVector &MantleVector, float &MaxMantleHeight);

	bool ObstacleCheck(const FHiMantleTraceSettings& TraceSettings, EDrawDebugTrace::Type DebugType);

	bool PlayMantleMontage(const FHiMantleAsset &MantleAsset, const FHiComponentAndTransform& MantleLedgeWS);
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void MantleStart(const FHiMantleAsset &Asset, const float &MantleHeight, const FHiComponentAndTransform& MantleLedgeWS,
	                EHiClimbType MantleType);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	float GetMontageStartingPosition(UAnimMontage* MontageToPlay);
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void MantleUpdate(float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void ClimbUpdate(float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void OnMontageEnded(UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION()
	void OnMontageBlendOut(UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void MantleEnd();

	/** Implement on BP to get correct mantle parameter set according to character state */
	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, Category = "Hi|Mantle System")
	FHiMantleAsset GetMantleAsset(EHiClimbType MantleType, float MantleHeight = 0.0f);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void ClimbStart(const EHiWallRunType &WallRun_Type, const FHitResult &HitResult, const FVector &Direction);
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void ClimbEnd(int Reason = 0);
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Mantle System")
	void EnableMantle(bool enable);

	UFUNCTION()
	void OnMoveBlockedBy(const FHitResult& HitResult);

	void CalcVelocityForClimb(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);

	FORCEINLINE virtual UCharacterMovementComponent* GetCharacterMovementComponent() const { return MyCharacterMovementComponent;}
protected:
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, 
	                           FActorComponentTickFunction* ThisTickFunction) override;

	// Called when the game starts
	virtual void BeginPlay() override;

	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	virtual void CheckClimbType(float DeltaTime);

	virtual void UpdateClimbType(float DeltaTime);

	UFUNCTION(BlueprintCallable, Category = "Hi|Mantle System")
	void StopMantleStartAnim();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	EHiWallRunType CanStartClimb(const FHitResult &HitResult);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	bool CanMantle();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	bool CanBreakMantle();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void PhysClimb(float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void PhysMantle(float DeltaTime);

	virtual void PhysMantle_Implementation(float DeltaTime);
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Mantle System")
	bool WaitTimeCheck(const FHiMantleWaitTimeSettings &WaitTime);

	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, Category = "Hi|Mantle System")
	FHiMantleWaitTimeSettings GetMantleWaitTime(const EHiMantleSubType &SubType);

	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, Category = "Hi|Mantle System")
	FHiMantleWaitTimeSettings GetClimbWaitTime(const EHiWallRunType &ClimbSubType);
	
	bool MoveCharacter(float ActorSpaceRoll, float DeltaTime, FHitResult & OutStepDownResult);

	bool CalculateWallTransform(const FVector &dir, FCalculatePoseContext &Context);

	bool CheckLand(const FVector &Direction);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void FlyOverStart(const FHiMantleAsset &Asset, const FHiComponentAndTransform& MantleLedgeWS);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void FlyOverEnd();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Mantle System")
	void OnFlyOverMontageEnded(UAnimMontage* Montage, bool bInterrupted);

	bool TryStartFlyOver(UPrimitiveComponent* HitComponent, const FTransform &TargetTransform);

	bool TryStartClimb(const FHitResult &ForwardHitResult, const FVector &TraceDirection, const FHitResult &WallCheckResult, bool bWait=false);

	bool TryStartMantle(UPrimitiveComponent* HitComponent, const FTransform &TargetTransform, const FVector &CapsuleBaseLocation, float MaxMantleHeight, bool bWait=false);

protected:
	TObjectPtr<UHiCharacterMovementComponent> MyCharacterMovementComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	FHiMantleTraceSettings GroundedTraceSettings;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	FHiMantleTraceSettings SprintClimbTraceSettings;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	FHiMantleTraceSettings ClimbTraceSettings;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	FHiMantleTraceSettings MantleTraceSettings;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	TObjectPtr<UCurveFloat> MantleTimelineCurve;

	static FName NAME_IgnoreOnlyPawnAndRagdoll;
	/** Profile to use to detect objects we allow mantling */
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	FName MantleObjectDetectionProfile = NAME_IgnoreOnlyPawnAndRagdoll;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Jump System")
	FName ClimbObjectDetectionProfile = NAME_IgnoreOnlyPawnAndRagdoll;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Mantle System")
	FHiMantleParams MantleParams;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Mantle System")
	FHiComponentAndMatrix MantleLedgeLS;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Mantle System")
	FTransform MantleTarget = FTransform::Identity;

	/** If a dynamic object has a velocity bigger than this value, do not start mantle */
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float AcceptableVelocityWhileMantling = 10.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Mantle System")
	bool bEnableMantle = false;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Mantle System", meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0"))
	float MantleAngle = 45.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Mantle System", meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0"))
	float WallTransformCheckDistance = 35.0f;

	uint8 CollisionFlags = 0;

	FOnMontageEnded MontageEndedDelegate;
	
	FOnMontageBlendingOutStarted MontageBlendingOutDelegate;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	EHiClimbType ClimbType = EHiClimbType::None;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	EHiWallRunType WallRunType = EHiWallRunType::None;
	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	EHiMantleSubType MantleSubType = EHiMantleSubType::None;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float MaxStepHeight = 50;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float MaxDownStepHeight = 50;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbGraivty = -980;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float MaxClimbMovementSpeed = 200;
	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ForwardInputValue = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	float RightInputValue = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	float TargetActorRoll = 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbInterpSpeed = 20.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbRollInterpSpeed = 20.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbPitchRotationSpeed = 270.0f;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbPitchLimit = 60.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	float ClimbLandSlope = 45.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Hi|Mantle System")
	float CurrentActorRoll = 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	FName MotionWarpingTargetName = "RootTarget";
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Mantle System")
	FName LandTargetName = "LandTarget";

	FHiMantleWaitTime MantleWaitTime;
	
	bool bCheckFlyOver = false;

	FORCEINLINE bool IsBlockedByWallThisFrame() const { return bBlockedByWallThisFrame; }
	
private:
	void UpdateWall(const FVector &Direction, uint8 CollisionFlag);

	bool NeedUpdateWallNormal() const;

	bool IsOnFloor() const;
	
	UPROPERTY()
	TObjectPtr<AHiCharacter> OwnerCharacter = nullptr;

	UPROPERTY()
	TObjectPtr<UHiLocomotionComponent> LocomotionComponent = nullptr;

	UPROPERTY()
	TObjectPtr<UHiJumpComponent> JumpComponent = nullptr;

	FVector WallImpactPoint_Horizontal = FVector(0);
	FVector WallImpactPoint_Down = FVector(0);

	//FVector VerticalVelocity;
	
	FRotator ClimbRotation;

	bool HasMovementInput = false;
	
	float FrameDeltaTime = 0.0f;

	bool bBlockedByWallThisFrame = false;
	
	UPROPERTY()
	TObjectPtr<UHiCharacterDebugComponent> HiCharacterDebugComponent = nullptr;
};
