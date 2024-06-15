// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiCharacterMovementComponent.h"
#include "GameFramework/Character.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "HiVehicleMovementComponent.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiVehicleMovementComponent : public UCharacterMovementComponent
{
	GENERATED_BODY()
public:
	
	virtual void BeginPlay() override;
	
	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetMovementSettings(FHiMovementSettings NewMovementSettings);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetSpeedScale(float speedScale);

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	float GetSpeedScale() const;
	void OnMovementSettingsChanged();

	UFUNCTION(BlueprintCallable, Category = "Movement Settings")
	void SetAllowedGait(EHiGait NewAllowedGait);

	UFUNCTION(Reliable, Server, Category = "Movement Settings")
	void Server_SetAllowedGait(EHiGait NewAllowedGait);

	UFUNCTION(BlueprintCallable, Category = "HiCharacterMovementComponent")
	void ChangeRootMotionOverrideType(UObject* OwnerObject, EHiRootMotionOverrideType NewRootMotionOverrideType);

	UFUNCTION(BlueprintCallable, Category = "HiCharacterMovementComponent")
	void ResetRootMotionOverrideTypeToDefault(UObject* OwnerObject);

	virtual bool CanAttemptJump() const;
	
	UFUNCTION(BlueprintCallable, Category = "Input")
	FORCEINLINE float GetSteering() const { return Steering;}

	UFUNCTION(BlueprintCallable, Category = "Input")
	FORCEINLINE bool IsAccelerating() const { return Accel > 0.0f;}
	
	virtual bool StepUp(const FVector& GravDir, const FVector& Delta, const FHitResult &Hit, FStepDownResult* OutStepDownResult = nullptr) override;
	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
	virtual void ControlledCharacterMove(const FVector& InputVector, float DeltaSeconds) override;
	virtual void UpdateCharacterRotation(float DeltaSeconds);
	virtual void UpdateRotationOnGround(float DeltaTime);
	virtual void UpdateRotationInAir(float DeltaTime);
	virtual void UpdateRotationInTrack(float DeltaTime);

	virtual bool IsValidLandingSpot(const FVector& CapsuleLocation, const FHitResult& Hit) const override;
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump")
	bool IsValidLanding() const;
	
	
	virtual void OnMovementModeChanged(EMovementMode PreviousMovementMode, uint8 PreviousCustomMode) override;

	virtual FVector ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity, const FVector& CurrentVelocity) const override;
	
	void CalcVelocityOnGround(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);
	
	void CalcVelocityInAir(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration);
	
	virtual FVector NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity, float DeltaTime) const override;

	virtual void CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration) override;
	void UpdateInputControl(const FVector& InputVector, float DeltaSeconds);
	void UpdateLocalSpeed();
	void UpdateSpeedProperty();

	UFUNCTION(BlueprintCallable, Category = "Hi|Velocity")
	void SetLocalAngularVelocity(const FVector& LocalAngularVel);

	UFUNCTION(BlueprintCallable, Category = "Hi|Velocity")
	void SetVelocity(const FVector& Vel);
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Velocity")
	void SetLocalVelocity(const FVector& LocalVel);

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Jump")
	FName JumpUpCurveName = TEXT("JumpUp");
	
	UPROPERTY()
	EHiGait AllowedGait = EHiGait::Walking;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Movement System")
	FHiMovementSettings CurrentMovementSettings;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	EHiVehicleState VehicleState = EHiVehicleState::OnGrounded;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	EHiRootMotionOverrideType RootMotionOverrideType = EHiRootMotionOverrideType::Default;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Movement")
	EHiRootMotionOverrideType DefaultRootMotionOverrideType = EHiRootMotionOverrideType::Default;
	
	float SpeedScale = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hi|Rotation")
	float VisibilityPitch = 0.f;
	
	/** Current angular velocity of updated component. */
	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	FVector LocalVelocity;
	
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	FVector LocalAngularVelocity;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float VdAngle;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float VdRadian;
	
	

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float SpeedMps;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float SpeedHeadMps;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float PowerCoef = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float NormalForwardAccel = 2000;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float InAirForwardAccel = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float NormalBrakingDeceleration = -2000;
	
	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, Category="Hi|Velocity")
	float ExtraNormalAccel = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Sprint")
	float SprintExtraAccel = 2000;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Sprint")
	float SprintExtraSpeedLimit = 400;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float SpeedUpRatio = 1.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float SpeedLimit = 1200;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float MinSpeedLimitZ = -1000;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Hi|Velocity")
	float MinSpeedInAccel = 500;

	UPROPERTY(VisibleDefaultsOnly, BlueprintReadWrite, Category="Hi|Velocity")
	float ExtraSpeedLimit = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float AngularInterpSpeed = 3;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float LocalVelRotationInterSpeed = 90;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float ForceStopSpeedInBraking = 200;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	float FrictionDeceleration = 100;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> TurnRadiusCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> AccelerationCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> AccelerationExtraCurve;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> DecelerationCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> TurnAccelerationCurve;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Hi|Velocity")
	TObjectPtr<UCurveFloat> AirTurnAngularCurve;
	
#if WITH_EDITORONLY_DATA
	UPROPERTY(EditAnywhere, Category="Debug")
	bool EnableLog = false;

	UPROPERTY(EditAnywhere, Category="Debug")
	bool EnableDraw = false;

	UPROPERTY(EditAnywhere, Category="Debug")
	float FixDeltaTime = 0.f;

	UPROPERTY(EditAnywhere, Category="Debug")
	bool JustUpdateOwnerClient = false;
	
#endif

private:
	TArray<TPair<UObject*, EHiRootMotionOverrideType>> RootMotionOverrideTypePendingList;
	
	UPROPERTY()
	float Accel = 0.f;

	UPROPERTY()
	float Braking = 0.f;
	
	UPROPERTY()
	float Steering = 0.f;

	UPROPERTY()
	float LastSteering = 0.f;

	UPROPERTY()
	float SteeringTime = 0.f;

	UPROPERTY()
	float InputYaw = 0.f;

	UPROPERTY()
	float CashedMaxStepHeight = 0;

	int32 InAirTickTimes = 0;

	UPROPERTY()
	float InAirTime = 0;

	UPROPERTY()
	FVector LastLocation = FVector::ZeroVector;
	
	UPROPERTY()
	FVector LinearVelocity = FVector::ZeroVector;
};
