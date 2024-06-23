// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Containers/RingBuffer.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "Component/HiCharacterDebugComponent.h"
#include "HiFootAnimUpdater.h"
#include "HiInAirAnimationUpdater.h"
#include "HiLocomotionAnimInstance.generated.h"


class UHiLocomotionComponent;

/**
 * Animation blueprint sub instance.
 * Specially designed for walking, running and jumping.
 */
UCLASS()
class HIGAME_API UHiLocomotionAnimInstance : public UHiAnimInstance
{
	GENERATED_BODY()

public:

	/** Native Interfaces **/
	virtual void NativeInitializeAnimation() override;

	virtual void NativeUninitializeAnimation() override;

	virtual void NativeBeginPlay() override;

	virtual void NativeUpdateAnimation(float DeltaSeconds) override;

	virtual void NativePostEvaluateAnimation() override;

public:
	/** Enable Movement Animations if IsMoving and HasMovementInput, or if the Speed is greater than 150. */
	UFUNCTION(BlueprintCallable, Category = "Hi|Grounded")
	bool ShouldMoveCheck() const;

	/**
	 * Only perform a Dynamic Transition check if the "Enable Transition" curve is fully weighted.
	 * The Enable_Transition curve is modified within certain states of the AnimBP so
	 * that the character can only transition while in those states.
	 */
	UFUNCTION(BlueprintCallable, Category = "Hi|Grounded")
	bool CanDynamicTransition() const;

	UFUNCTION(BlueprintCallable, Category = "Hi|Animation")
	void PlayDynamicTransition(float ReTriggerDelay, FHiDynamicMontageParams Parameters);

	UFUNCTION(BlueprintCallable, Category = "Hi|Animation")
	void PlayTransition(const FHiDynamicMontageParams& Parameters);

	void PlayDynamicTransitionDelay();

public:
	const bool IsTurningLeft() const;

	const bool IsTurningRight() const;

	const bool IsLockingLeftFoot() const;

	const bool IsLockingRightFoot() const;

protected:
	/** Update Values */

	virtual void UpdateInGroundValues(float DeltaSeconds);

private:

	/** Updating data for animation from the character blueprint, including displacement data, logic state, etc. */
	void UpdateCharacterInformation(float DeltaSeconds);

	/** Updating some movement data on land. */
	void UpdateMovementValues(float DeltaSeconds);

	/** The yaw angle difference between model and character is calculated here. 
	  *     Note: The character rotates immediately in advance, while the model slowly turns to the character. */
	void UpdateAnimatedYawOffset(float DeltaSeconds);

	/** Adjust the lean amount of the moving animation based on the acceleration direction of the character displacement. */
	void UpdateAnimatedLeanAmount(float DeltaTime);

	/** Calculate the model yaw offset angle based on the difference between the current character orientation the current model orientation. */
	float CalculateTargetYawOffset(float RotationYaw);

	/** Choose whether to play pedal animation based on the control rotational yaw angle. 
	  *     Controled rotational yaw is the sum of the time window(#BreakControlRotateDuration).*/
	void UpdateRunningTurnValues(float DeltaSeconds);

	/** Adjust the foot lock animation based on the current logic state of the character. */
	void UpdateAnimatedFootLock(float DeltaSeconds, EHiGait PreviousLogicGait);

	void UpdateTargetMoveValues(float DeltaSeconds);

	void UpdateGlideValues(float DeltaSeconds);

	/** Movement */

	float CalculateStandingPlayRate() const;

	void DynamicTransitionCheck();

	const float GetAnimatedRotateYawDegrees() const;

	/** Util */

	float GetValueClamped(float Name, float Bias, float ClampMin, float ClampMax) const;

public:
	/** Character Information */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data", Meta = (
		ShowOnlyInnerProperties))
	FHiAnimCharacterInformation CharacterInformation;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementState MovementState = EHiMovementState::Grounded;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementState AnimatedMovementState = EHiMovementState::Grounded;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiMovementAction MovementAction = EHiMovementAction::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiInAirState InAirState = EHiInAirState::None;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiRotationMode RotationMode = EHiRotationMode::VelocityDirection;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiGait LogicGait = EHiGait::Idle;				// Idle / Walking / Running / Sprinting

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	EHiGait LogicMoveGait = EHiGait::Idle;				// Walking / Running / Sprinting

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	float GaitCurveValue = 0.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Character Information")
	float Speed3D = 0.0f;

	UPROPERTY(BlueprintReadWrite)
	bool bAllowAutoJump = false;

	UPROPERTY(BlueprintReadWrite)
	float AutoJumpRateScale = 1.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Anim Graph - Grounded")
	EHiGroundedEntryState GroundedEntryState = EHiGroundedEntryState::None;

	/** Anim Graph - Aiming Values */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Anim Graph - Aiming Values", Meta = (
		ShowOnlyInnerProperties))
	FHiAnimGraphAimingValues AimingValues;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Anim Graph - Aiming Values")
	FVector2D SmoothedAimingAngle = FVector2D::ZeroVector;

	/** Anim Graph - Ragdoll */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Read Only Data|Anim Graph - Ragdoll")
	float FlailRate = 0.0f;

	/** Blend Curves */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config|Blend Curves")
	TObjectPtr<UCurveFloat> LeanInAirCurve = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config|Dynamic Transition")
	TObjectPtr<UAnimSequenceBase> TransitionAnim_R = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config|Dynamic Transition")
	TObjectPtr<UAnimSequenceBase> TransitionAnim_L = nullptr;

public:
	UFUNCTION(BlueprintCallable, Category = "Hi|Grounded")
	void SetGroundedEntryState(EHiGroundedEntryState NewState) { GroundedEntryState = NewState; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Event")
	void ResetJumpState();

	// Set skip update animted yaw offset this tick
	UFUNCTION(BlueprintCallable, Category = "Hi|Grounded")
	void SetSkipUpdateAnimatedYawOffset();

protected:
	UFUNCTION(BlueprintCallable, Category = "Hi|Event")
	void OnJumped(EHiJumpState JumpState, int JumpCount, EHiBodySide JumpFoot);

	UFUNCTION(BlueprintCallable, Category = "Hi|Event")
	void OnMovementStateChanged(EHiMovementState InMovementState);

	virtual void OnUpdateComponent() override;

public:

	/** Anim Graph - Grounded */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiAnimGraphGrounded Grounded;

	/** In Air - Values */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiInAirAnimValues InAirValues;
	
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiGlideValues GlideValues;

	/** Foot IK - Values */
	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiFootAnimValues FootAnimValues;

	/** Configuration */
	//UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	//FALSAnimConfiguration Config;

	/** Foot IK - Configuration */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	FHiFootAnimConfig FootAnimConfig;

	/** Grounded - Configuration */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	FHiAnimGroundedConfig GroundedConfig;

	/** InAir - Configuration */
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Config")
	FHiInAirAnimConfig InAirConfig;

	/** TargetedMovement */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Config|TargetedMove")
	bool bUseTargetedMovement = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Config|TargetedMove")
	float VelocityBlendInterpSpeed = 12.0f;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Evaluation Data")
	FHiTargetMoveValues TargetMoveValues;
	
private:
	/** Foot IK - Updater */
	HiFootAnimUpdater FootAnimUpdater;

	/** In Air - Updater */
	HiInAirAnimationUpdater InAirAnimationUpdater;

private:
	UPROPERTY()
	TObjectPtr<UHiCharacterDebugComponent> HiCharacterDebugComponent = nullptr;

	FTimerHandle PlayDynamicTransitionTimer;

	FTimerHandle OnPivotTimer;

	bool bCanPlayDynamicTransition = true;

private:
	
	/** Cached intermediate value */

	float PreviousAimingYaw = 0.0f;

	float PreviousAnimatedYawOffsetDecline = 0.0f;

	float PreviousAnimatedYawOrientation = 0.0f;

	float MaxYawRestoreDecayAlpha = 15.0f;

	float YawRestoreDecayAlpha = 15.0f;

	float RemainingReverseYawTime = 0.0f;

	float ControlRotateYawHistory = 0.0f;

	bool bPreviousHasMovementInput = false;

	struct RotateYawItem
	{
		float TimeOffset;
		float Yaw;
	};

	TRingBuffer<RotateYawItem> ControlRotateYawArray;

	bool bSkipUpdateAnimatedYawOffset = false;
};
