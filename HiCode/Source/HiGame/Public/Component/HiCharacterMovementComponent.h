// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "GameFramework/Character.h"

#include "HiCharacterMovementComponent.generated.h"


DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnMovementTickEndEvent);

class UHiAvatarLocomotionAppearance;
class UHiJumpComponent;
class UMotionWarpingComponent;


/**
 * Authoritative networked Character Movement
 */
UCLASS()
class HIGAME_API UHiCharacterMovementComponent : public UCharacterMovementComponent
{
	GENERATED_UCLASS_BODY()

	class HIGAME_API FSavedMove_Hi : public FSavedMove_Character
	{
	public:

		typedef FSavedMove_Character Super;

		virtual void Clear() override;
		virtual uint8 GetCompressedFlags() const override;
		virtual void SetMoveFor(ACharacter* Character, float InDeltaTime, FVector const& NewAccel,
		                        class FNetworkPredictionData_Client_Character& ClientData) override;
		virtual void PrepMoveFor(class ACharacter* Character) override;

		// Walk Speed Update
		EHiGait SavedAllowedGait = EHiGait::Walking;
	};

	class HIGAME_API FNetworkPredictionData_Client_Hi : public FNetworkPredictionData_Client_Character
	{
	public:
		FNetworkPredictionData_Client_Hi(const UCharacterMovementComponent& ClientMovement);

		typedef FNetworkPredictionData_Client_Character Super;

		virtual FSavedMovePtr AllocateNewMove() override;
	};

	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	virtual void UpdateFromCompressedFlags(uint8 Flags) override;
	virtual class FNetworkPredictionData_Client* GetPredictionData_Client() const override;
	virtual void HandleImpact(const FHitResult& Hit, float TimeSlice=0.f, const FVector& MoveDelta = FVector::ZeroVector) override;

	virtual void ServerMoveHandleClientError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode) override;

	virtual void ServerMove_PerformMovement(const FCharacterNetworkMoveData& MoveData) override;

	virtual void HiServerMove_MoveAutonomous( float ClientTimeStamp, float DeltaTime, uint8 CompressedFlags, const FVector& NewAccel);

	virtual bool ServerShouldUseAuthoritativePosition(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode);

	/** Updates acceleration and perform movement, called from the TickComponent on the authoritative side for controlled characters,
	 *	or on the client for characters without a controller when either playing root motion or bRunPhysicsWithNoController is true.
	 */
	virtual void ControlledCharacterMove(const FVector& InputVector, float DeltaSeconds) override;

	/** Ticks the characters pose and accumulates root motion */
	virtual void TickCharacterPose(float DeltaTime) override;

	virtual void ClientAdjustPosition_Implementation(float TimeStamp, FVector NewLoc, FVector NewVel, UPrimitiveComponent* NewBase, FName NewBaseBoneName, bool bHasBase, bool bBaseRelativePosition, uint8 ServerMovementMode, TOptional<FRotator> OptionalRotation = TOptional<FRotator>()) override;
	
	/** Special Tick for Simulated Proxies */
	virtual void SimulatedTick(float DeltaSeconds) override;

	/** changes physics based on MovementMode */
	virtual void StartNewPhysics(float deltaTime, int32 Iterations) override;

	/**
	 * Sweeps a vertical trace to find the floor for the capsule at the given location. Will attempt to perch if ShouldComputePerchResult() returns true for the downward sweep result.
	 * No floor will be found if collision is disabled on the capsule!
	 *
	 * @param CapsuleLocation		Location where the capsule sweep should originate
	 * @param OutFloorResult		[Out] Contains the result of the floor check. The HitResult will contain the valid sweep or line test upon success, or the result of the sweep upon failure.
	 * @param bCanUseCachedLocation If true, may use a cached value (can be used to avoid unnecessary floor tests, if for example the capsule was not moving since the last test).
	 * @param DownwardSweepResult	If non-null and it contains valid blocking hit info, this will be used as the result of a downward sweep test instead of doing it as part of the update.
	 */
	virtual void FindFloor(const FVector& CapsuleLocation, FFindFloorResult& OutFloorResult, bool bCanUseCachedLocation, const FHitResult* DownwardSweepResult = NULL) const override;

	/** Slows towards stop. */
	virtual void ApplyVelocityBraking(float DeltaTime, float Friction, float BrakingDeceleration) override;

	virtual void CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration) override;

	virtual FVector NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity, float DeltaTime) const;

	/**
	 * Constrain components of root motion velocity that may not be appropriate given the current movement mode (e.g. when falling Z may be ignored).
	 */
	virtual FVector ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity, const FVector& CurrentVelocity) const override;

	virtual FVector GetFallingLateralAcceleration(float DeltaTime) override;

	UFUNCTION(BlueprintCallable)
	virtual void RequestDirectMove(const FVector& MoveVelocity, bool bForceMaxSpeed) override;

	virtual void MoveAlongFloor(const FVector& InVelocity, float DeltaSeconds, FStepDownResult* OutStepDownResult = NULL);

	/**
	 * Server Trust Authoritative Position
	 */
	virtual bool ServerTrustAuthoritativePosition(float DeltaTime, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode, FVector& TrustServerWorldLocation);

	virtual float SlideAlongSurface(const FVector& Delta, float Time, const FVector& Normal, FHitResult& Hit, bool bHandleImpact) override;

	/** Verify that the supplied hit result is a valid landing spot when falling. */
	virtual bool IsValidLandingSpot(const FVector& CapsuleLocation, const FHitResult& Hit) const override;

	bool ClimbStepUp(const FVector& GravDir, const FVector& Delta, const FHitResult& Hit, FStepDownResult* OutStepDownResult = NULL);

	/**
	 * Check for Server-Client disagreement in position or other movement state important enough to trigger a client correction.
	 * @see ServerMoveHandleClientError()
	 */
	bool HiServerCheckClientError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode, bool bIgnoreMovementChange = false);

	void OnMovementSettingsChanged();

	UPROPERTY()
	EHiGait AllowedGait = EHiGait::Walking;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Movement System")
	FHiMovementSettings CurrentMovementSettings;

	float MaxWallStepHeight = 0.0f;
	
	bool bIsInServerMove = false;

	float SpeedScale = 1.0f;

	bool bForceNoCombine = true;
	
	// Set Movement Curve (Called in every instance)
	float GetMappedSpeed() const;

	bool IsInAir() const;

public:
	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetMovementSettings(FHiMovementSettings NewMovementSettings);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetSpeedScale(float speedScale);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	float GetSpeedScale() const;

	// Set Max Walking Speed (Called from the owning client)
	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetAllowedGait(EHiGait NewAllowedGait);

	UFUNCTION(Reliable, Server, Category = "Movement Settings")
	void Server_SetAllowedGait(EHiGait NewAllowedGait);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetForceNoCombine(bool value);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	bool GetForceNoCombine() const;

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	float GetGaitSpeedInSettings(const EHiGait InGait);

	void PhysMantle(float DeltaTime, int32 Iterations);

	void PhysGlide(float deltaTime, int32 Iterations);

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category="HiCharacterMovementComponent")
	void PhysSkill(float DeltaTime);

	UFUNCTION(BlueprintCallable, Category="HiCharacterMovementComponent")
	void BP_HandleImpact(const FHitResult& Hit, float TimeSlice=0.f, const FVector& MoveDelta = FVector::ZeroVector);

	UFUNCTION(BlueprintCallable, Category="HiCharacterMovementComponent")
	float BP_SlideAlongSurface(const FVector& Delta, float Time, const FVector& Normal, FHitResult& Hit, bool bHandleImpact);

	UFUNCTION(BlueprintCallable, Category="HiCharacterMovementComponent")
	bool BP_CanStepUp(const FHitResult& Hit) const;

	UFUNCTION(BlueprintCallable, Category="HiCharacterMovementComponent")
	bool BP_StepUp(const FVector& GravDir, const FVector& Delta, const FHitResult &Hit, bool& bComputedFloor, FFindFloorResult& FloorResult);
	
	UFUNCTION(BlueprintCallable, Category="HiCharacterMovementComponent")
	FVector BP_ComputeGroundMovementDelta(const FVector& Delta, const FHitResult& RampHit, const bool bHitFromLineTrace) const;

	//virtual void SetMovementMode(EMovementMode NewMovementMode, uint8 NewCustomMode = 0);

	UFUNCTION(BlueprintCallable, Category = "HiCharacterMovementComponent")
	void ChangeRootMotionOverrideType(UObject* OwnerObject, EHiRootMotionOverrideType NewRootMotionOverrideType);

	UFUNCTION(BlueprintCallable, Category = "HiCharacterMovementComponent")
	void ResetRootMotionOverrideTypeToDefault(UObject* OwnerObject);

	UFUNCTION(BlueprintCallable, Category = "HiCharacterMovementComponent")
	bool ServerCanAcceptClientPosition();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "HiCharacterMovementComponent")
	void OnPossessedBy(AController* NewController);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "HiCharacterMovementComponent")
	void OnUnPossessedBy(AController* NewController);

	void SetGlideFallSpeed(float FallSpeed);

	void ProcessGlideLanded(const FHitResult& Hit);

	void AddBufferVelocity(FVector NewBufferVelocity);

	void AddBufferAcceleratedVelocity(FVector NewBufferAcceleratedVelocity);

	void AddBufferVelocityOnlyOnce(FVector NewBufferVelocity);

	/** Get Buffer Velocity */
	virtual FVector GetBufferVelocity() const;

	/** Get Buffer Accelerated Velocity */
	virtual FVector GetBufferAcceleratedVelocity() const;

public:
	virtual void InitializeComponent() override;

	virtual void BeginPlay() override;
	
	/** Maximum height character can step up */
	UPROPERTY(Category = "Character Movement: Walking", EditAnywhere, BlueprintReadWrite, meta = (ClampMin = "0", UIMin = "0", ForceUnits = "cm"))
	float MaxFindFloorStepHeight = 20.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Physics Movement", meta = (ClampMin = "0.0", ClampMax = "90.0", UIMin = "0.0", UIMax = "90.0", ForceUnits = "degrees"))
	float MinimumSlideDeltaAngle = 0.0f;

	UPROPERTY(EditAnywhere, Category = "Physics Movement")
	bool bEnableSlideAlongSurface = true;

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "Physics Movement")
	FHiPhysMovementStatus PhyxMovementStatus;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	bool bEnableTrustClient = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	bool bNetEnableListenServerSmoothing = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	bool bTrustClient_EnableSmoothLocation = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement")
	EHiServerDealClientPosition ServerDealClientPosition = EHiServerDealClientPosition::Accept;

	// Almost invisible position error
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement", meta = (ForceUnits = "cm"))
	float TrustableTinyLocationError = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement", meta = (ForceUnits = "cm/s"))
	float TrustableVelocityError = 10.0f;

	// Almost imperceptible speed adjustment. This value is generally suitable within 20%
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Movement", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float TrustableSmoothVelocityFactor = 0.1f;

	// The distance for smooth movement cannot be large, and cannot exceed the radius of the capsule body
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Movement", meta = (ForceUnits = "cm"))
	float TrustableMaxSmoothDistancePerFrame = 4.0f;

	// The distance for smooth movement cannot be large, and cannot exceed the radius of the capsule body
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Movement", meta = (ForceUnits = "s"))
	float UntrustMaxClientDuration = 1e6f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	EHiRootMotionOverrideType RootMotionOverrideType = EHiRootMotionOverrideType::Default;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	EHiRootMotionOverrideType DefaultRootMotionOverrideType = EHiRootMotionOverrideType::Default;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	EHiServerControlRotationSimulateMode ServerControlRotationSimulateMode = EHiServerControlRotationSimulateMode::TrustClient;

	UPROPERTY(BlueprintAssignable, Category = "Movement")
	FOnMovementTickEndEvent OnMovementTickEndTrigger;

	float GlideFallSpeed = 0.0f;

	/*
	 * Count untrust duration for server smooth correct
	 * - If one frame error is within an acceptable range (see #TrustableVelocityError), use the client position
	 * - If the cumulative error is within an acceptable range (see #TrustableVelocityError), smooth it to the client position
	*/
	UPROPERTY()
	float UntrustClientDuration = 0.0f;

	friend class UHiMantleComponent;

	void UpdateWalkSpeed();

	//重复使用buffer速度
	UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Movement")
	FVector BufferVelocity;

	//重复使用buffer加速度
	UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Movement")
	FVector BufferAcceleratedVelocity;

	//一次性buffer速度
	UPROPERTY(VisibleAnywhere,BlueprintReadWrite, Category = "Movement")
	FVector BufferVelocityOnlyOnce;

#if WITH_EDITORONLY_DATA
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Debug")
	bool bDebugDrawClient = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Debug")
	bool bDebugDrawServer = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Debug")
	bool bDebugDrawSimulate = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Debug")
	FName DebugDrawSocketName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Transient, Category = "Debug")
	float DebugDrawLifeTime = 0.5f;
#endif	// WITH_EDITORONLY_DATA


protected:
	/** Remember last server movement base so we can detect mounts/dismounts and respond accordingly. */
	TWeakObjectPtr<UPrimitiveComponent> LastServerMovementBase = nullptr;

	UPROPERTY()
	TObjectPtr<UHiAvatarLocomotionAppearance> AppearanceComponent = nullptr;

	UPROPERTY()
	TObjectPtr<UHiJumpComponent> JumpComponent = nullptr;

	UPROPERTY()
	TObjectPtr<UMotionWarpingComponent> MotionWarpingComponent = nullptr;
	
private:
	void CalcVelocityForWalking(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);

	void CalcVelocityForFalling(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);

	void CalcVelocityForGliding(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);

private:
	TArray<TPair<UObject*, EHiRootMotionOverrideType>> RootMotionOverrideTypePendingList;

	float MinimumSlideDeltaCos = -1.0f;

};
