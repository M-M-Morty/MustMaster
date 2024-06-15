// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Containers/RingBuffer.h"
#include "HiLocomotionComponent.h"
#include "HiAvatarLocomotionAppearance.generated.h"


class UHiCharacterMovementComponent;


/**
* Tick function that does replicated montage work on appearance component. 
**/
USTRUCT()
struct FHiMovementAppearanceTickFunction : public FTickFunction
{
	GENERATED_USTRUCT_BODY()

	UHiAvatarLocomotionAppearance* Target;

	/**
	* Abstract function to execute the tick.
	* @param DeltaTime - frame time to advance, in seconds.
	* @param TickType - kind of tick for this frame.
	* @param CurrentThread - thread we are executing on, useful to pass along as new tasks are created.
	* @param MyCompletionGraphEvent - completion event for this task. Useful for holding the completetion of this task until certain child tasks are complete.
	*/
	virtual void ExecuteTick(float DeltaTime, enum ELevelTick TickType, ENamedThreads::Type CurrentThread, const FGraphEventRef& MyCompletionGraphEvent) override;
	/** Abstract function to describe this tick. Used to print messages about illegal cycles in the dependency graph. */
	virtual FString DiagnosticMessage() override;
	/** Function used to describe this tick for active tick reporting. **/
	virtual FName DiagnosticContext(bool bDetailed) override;
};

template<>
struct TStructOpsTypeTraits<FHiMovementAppearanceTickFunction> : public TStructOpsTypeTraitsBase2<FHiMovementAppearanceTickFunction>
{
	enum
	{
		WithCopy = false
	};
};


/**
 * 
 */
UCLASS(BlueprintType)
class HIGAME_API UHiAvatarLocomotionAppearance : public UHiLocomotionComponent
{
	GENERATED_BODY()
	
public:
	UHiAvatarLocomotionAppearance(const FObjectInitializer& ObjectInitializer);

	virtual void BeginPlay() override;

	virtual void OnPossessedBy_Implementation(AController* NewController) override;

	virtual void InitializeComponent() override;

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

	virtual void TickLocomotion(float DeltaTime) override;

	virtual void TickCharacterState(float DeltaTime);

	virtual void SetEssentialValues(float DeltaTime) override;

	void PresetEssentialValues(float DeltaTime, FVector Acceleration);

	void TickReplicatedMontage(float DeltaTime);

	void TickMovementAppearance(float DeltaTime);

	/** Extra animation */

	virtual UAnimMontage* GetRollAnimation_Implementation() override { return RollAnimation; };

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Movement System")
	UAnimMontage* GetSprintTurnAnimation();
	virtual UAnimMontage* GetSprintTurnAnimation_Implementation() { return SprintTurnAnimation; };

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Movement System")
	UAnimMontage* GetSprintBrakeAnimation();
	virtual UAnimMontage* GetSprintBrakeAnimation_Implementation() { return SprintBrakeAnimation; };

	/** Animation Logic*/

	virtual void EnterSkillAnim_Implementation() override;

	virtual void LeaveSkillAnim_Implementation() override;

	virtual void RagdollStart() override;

	virtual void RagdollEnd() override;

	virtual ECollisionChannel GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius) override;

	virtual FTransform GetThirdPersonPivotTarget() override;

	/** Input */

	virtual void WalkAction_Implementation() override;

	virtual void SprintAction_Implementation(bool bValue) override;

	virtual void Replicated_InterruptMovementAction(float InBlendOutTime = 0.0f) override;

	virtual void OnBreakfall_Implementation() override;

	/** DDS **/
	virtual void PostTransfer() override;

protected:
	/** Status changed callback */

	virtual void OnRotationModeChanged(EHiRotationMode PreviousRotationMode);

	virtual void OnSpeedScaleChanged(float PrevSpeedScale);

	virtual void OnMovementActionChanged(EHiMovementAction PreviousAction) override;

	/** Performance data update */

	void UpdateCharacterMovement();

	virtual void UpdateCharacterRotation(float DeltaTime) override;

	FName CalculateMovementActionSection();

	virtual void RideUpdate(float DeltaTime);

public:
	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetMoveInterruptionConstraint(bool Enabled, float ConstraintAngle = 0.0f);

	// Set skip update rotation
	UFUNCTION(BlueprintCallable, Category = "Hi|Utility")
	void SetSkipUpdateRotation();

public:

	/** Anim Graph */
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	TArray<FHiLinkAnimGraphConfig> LinkedAnimGraph;

	/** Camera animation */

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	FName CameraSocketName = TEXT("Camera_Pivot");
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	FName CameraBoneName = NAME_None;

	/** Extra animation */

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	UAnimMontage* RollAnimation = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	UAnimMontage* SprintTurnAnimation = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Hi|Extra Animations")
	UAnimMontage* SprintBrakeAnimation = nullptr;

	/** Program animation parameters */

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement")
	float SprintActionMinimumVelocity = 500.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement", meta = (ClampMin = "90.0", ClampMax = "180.0", ForceUnits = "degrees"))
	float SprintTurnMinimumAngle = 140.0f;

	UPROPERTY(BlueprintReadOnly, VisibleAnywhere, Category = "Hi|Movement System")
	FHiPhysMovementStatus PhyxMovementStatus;

	/** Input */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Hi|Input")
	EHiGait BasicSlowMoveGait = EHiGait::Running;				// Walking / Running

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Hi|Input")
	bool bIsInSprint = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Input")
	bool bEnableCustomizedRotationWithRootMotion = false;

	/** Movement */
	// Basic smoothing duration: time within this duration is considered acceptable smoothing
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.01", ClampMax = "10.0", ForceUnits = s))
	float HeightCorrection_SmoothDuration = 0.2f;

	// Time interval for restarting: do some initialization logic and distinguish it from continuous changes
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ClampMax = "10.0", ForceUnits = s))
	float HeightCorrection_StartupInterval = 0.1f;

	// The basic speed at which smoothing is just started (also the maximum speed of the first frame)
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ForceUnits = "cm/s"))
	float HeightCorrection_BaseSpeed = 150.0f;

	// The minimum speed at which smoothing has just started
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ForceUnits = "cm/s"))
	float HeightCorrection_MinSpeed = 50.0f;

	// The applied acceleration when the model position cannot keep up with the continuously changing height difference
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ForceUnits = "cm/s^2"))
	float HeightCorrection_Acceleration = 1500.0f;

	// To make the ending smoother, add a deceleration altitude interval
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ForceUnits = "cm"))
	float HeightCorrection_StartDecelerationHeight = 20.0f;

	// Constrain the maximum correction value to prevent performance errors caused by excessively large values
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ForceUnits = "cm"))
	float HeightCorrection_MaxCorrectHeight = 60.0f;

	// Time interval for restarting: do some initialization logic and distinguish it from continuous changes
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|Movement System", meta = (ClampMin = "0.0", ClampMax = "10.0", ForceUnits = s))
	float HeightCorrection_AverageNormalInterval = 0.3f;

	/** Skip Update Rotation */
	// if true, skip update rotation this tick
	bool bSkipUpdateRotation = false;

protected:
	/** Movement System */
	UPROPERTY()
	TObjectPtr<UHiCharacterMovementComponent> MyCharacterMovementComponent = nullptr;


private:
	/** Cached update data */
	
	bool bNeedsColorReset = false;

	bool bEnableMoveInterruptionConstraint = false;

	bool bDelayPlayRollAnimation = false;

	float MoveInterruptionConstraintAngle = 0.0f;

	FVector LastThirdPersonPivotTarget;

	FHiMovementAppearanceTickFunction MovementAppearanceTickFunction;

	/************* Height Correction ************/

	// Unrecovered height correction values that currently exist in Animation
	float HeightCorrection_LeftHeightCorrection = 0.0f;

	// Actor height of the previous frame cached
	FVector HeightCorrection_PreviousLocation = FVector::ZeroVector;

	// Actor height of the previous frame cached
	FVector HeightCorrection_AverageNormal = FVector::UpVector;

	// Current height correction speed
	float HeightCorrection_CorrectVelocity = 0.0f;

	// Duration of continuous non height correction
	float HeightCorrection_UnmodifiedDuration = 0.0f;

	// Duration of continuous correctable standing on the ground
	float HeightCorrection_GroundedDuration = 0.0f;
};
