// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiPawnComponent.h"
#include "Characters/HiCharacterEnumLibrary.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "Characters/Camera/HiPlayerCameraBehavior.h"
#include "GameFramework/Character.h"
#include "HiLocomotionComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnGaitChangedEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnLandEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnTurnInPlaceEvent, float, Angle);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnCustomSmoothCompletedEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnCustomSmoothInterruptedEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnSkillAnimStateChangedEvent, bool, bIsInSkillAnim);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FRagdollStateChangedEvent, bool, bRagdollState);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FIsMovingChangedEvent, bool, bIsMoving);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FHasMovementInputEvent, bool, bHasInput);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMovementStateChangedEvent, EHiMovementState, MovementState);

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FMontageCallbackDelegate, UAnimMontage*, Montage, bool, bInterrupted);

UENUM(BlueprintType)
enum ECustomRotationStage
{
	RotationStage_0 UMETA(DisplayName = "RotationStage_0"),
	RotationStage_1 UMETA(DisplayName = "RotationStage_1"),
	RotationStage_2 UMETA(DisplayName = "RotationStage_2"),
};

USTRUCT(BlueprintType)
struct FCustomSmoothContext
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Target")
	FRotator CustomRotation = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Interp")
	float TargetInterpSpeed = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Interp")
	float ActorInterpSpeed = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "RotationStage")
	float CustomRotationStage = RotationStage_2;
};

enum RotationEasingType
{
	Interp,
	InterpConstant,
};

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable)
class HIGAME_API UHiLocomotionComponent : public UHiPawnComponent
{
	GENERATED_BODY()

public:
	UHiLocomotionComponent(const FObjectInitializer& ObjectInitializer);

	virtual void TickLocomotion(float DeltaTime);

	virtual void InitializeComponent() override;

	virtual void BeginPlay() override;
	
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

public:
	UFUNCTION(BlueprintCallable, Category = "Hi|Movement")
	FORCEINLINE class UCharacterMovementComponent* GetMyMovementComponent() const
	{
		return MyCharacterMovementComponent;
	}

	UFUNCTION(BlueprintCallable, Category = "Hi|Rotation System")
	bool SetCharacterRotation(const FRotator &Rotation, bool Smooth=false, const FCustomSmoothContext& Context = FCustomSmoothContext());

	UFUNCTION(BlueprintCallable, Category = "Hi|Rotation System")
	void Replicated_SetCharacterRotation(const FRotator& Rotation, bool Smooth = false, const FCustomSmoothContext& Context = FCustomSmoothContext());

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetCharacterRotation(const FRotator& Rotation, bool Smooth=false, const FCustomSmoothContext& Context = FCustomSmoothContext());

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Movement")
	void Multicast_SetActorLocationAndRotation(FVector NewLocation, FRotator NewRotation, bool bSweep, bool bTeleport);

	/**
	 * @brief 
	 * @param Rotation 
	 * @param Smooth 
	 * @param Context 
	 * @param bIncludeLocalController Whether invoke on autonomous local controlled client.
	 * @param bRotateCamera Whether rotate camera after invoke on autonomous.
	 */
	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_SetCharacterRotation(const FRotator& Rotation, bool Smooth=false, const FCustomSmoothContext& Context = FCustomSmoothContext(), bool bIncludeLocalController = false, bool bRotateCamera = false);
	/** Ragdoll System */

	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category="Hi|Camera")
	void OnActorRotateUpdateCamera(const FRotator& Rotation);

	/** Implement on BP to get required get up animation according to character's state */
	UFUNCTION(BlueprintCallable, BlueprintImplementableEvent, Category = "Hi|Ragdoll System")
	UAnimMontage* GetGetUpAnimation(bool bRagdollFaceUpState);

	UFUNCTION(BlueprintCallable, Category = "Hi|Ragdoll System")
	virtual void RagdollStart();

	UFUNCTION(BlueprintCallable, Category = "Hi|Ragdoll System")
	virtual void RagdollEnd();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	FHiTurnInPlaceAsset GetTurnInPlaceAsset(float DeltaYaw, const FHiAnimTurnInPlace &Values);

	UFUNCTION(BlueprintCallable, Server, Unreliable, Category = "Hi|Ragdoll System")
	void Server_SetMeshLocationDuringRagdoll(FVector MeshLocation);

	/** Character States */

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetMovementState(EHiMovementState NewState, bool bForce = false);

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiMovementState GetMovementState() const { return MovementState; }

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiMovementState GetPrevMovementState() const { return PrevMovementState; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetMovementAction(EHiMovementAction NewAction, bool bForce = false);
	
	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetMovementAction(EHiMovementAction NewAction, bool bForce = false);

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiMovementAction GetMovementAction() const { return MovementAction; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetGait(EHiGait NewGait, bool bForce = false);

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiGait GetGait() const { return Gait; }

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	virtual EHiGait GetMoveGait() const { return Gait; }

	UFUNCTION(BlueprintGetter, Category = "Hi|CharacterStates")
	EHiGait GetDesiredGait() const { return DesiredGait; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetSpeedScale(float scale, bool bForce = false);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	float GetSpeedScale() const;

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetSpeedScale(float NewSpeedScale, bool bForce);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_SetSpeedScale(float NewSpeedScale, bool bForce);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetRotationMode(EHiRotationMode NewRotationMode, bool bForce = false);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetRotationMode(EHiRotationMode NewRotationMode, bool bForce);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void Multicast_SetRotationMode(EHiRotationMode NewRotationMode, bool bForce = false);

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiRotationMode GetRotationMode() const { return RotationMode; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetGroundedEntryState(EHiGroundedEntryState NewState);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	EHiInAirState GetInAirState() const { return InAirState; };

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void SetInAirState(EHiInAirState InAirState);

	UFUNCTION(BlueprintGetter, Category = "Hi|Character States")
	EHiGroundedEntryState GetGroundedEntryState() const { return GroundedEntryState; }

	/** Landed, Jumped, Rolling, Mantling and Ragdoll*/
	/** On Landed*/
	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void EventOnLanded();
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void EventOnTurnInPlace(float Angle);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_OnLanded();

	/** Rolling Montage Play Replication*/
	FOnMontageBlendingOutStarted BlendingOutDelegate;
	FOnMontageEnded MontageEndedDelegate;
	
	UPROPERTY(BlueprintAssignable)
	FMontageCallbackDelegate OnMontageBlendingOut;

	UPROPERTY(BlueprintAssignable)
	FMontageCallbackDelegate OnMontageEnded;
	
	virtual void Replicated_InterruptMovementAction(float InBlendOutTime = 0.0f) {};

	/** BP implementable function that called when A Montage starts, e.g. during rolling */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Movement System")
	bool Replicated_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	/** Montage Stop Replication*/
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Character States")
	void Replicated_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	/** Montage Stop Replication*/
	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void Replicated_StopMontageGroup(FName MontageGroupName, float InBlendOutTime = 0.0f);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_StopMontageGroup(FName MontageGroupName, float InBlendOutTime = 0.0f);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_StopMontageGroup(FName MontageGroupName, float InBlendOutTime = 0.0f);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void Replicated_MontageJumpToSection(FName SectionName, const UAnimMontage* Montage);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_MontageJumpToSection(FName SectionName, const UAnimMontage* Montage);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_MontageJumpToSection(FName SectionName, const UAnimMontage* Montage);

	void RegisterMontageCallbacks(UAnimInstance* AnimInstance, UAnimMontage* AnimMontage);
	
	UFUNCTION()
	void OnMontageBlendingOutCallback(UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION()
	void OnMontageEndedCallback(UAnimMontage* Montage, bool bInterrupted);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void TurnInPlace(float TurnAngle);

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void PlayTurnInPlaceAnimation(float TurnAngle, const FHiTurnInPlaceAsset &TargetTurnAsset);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_TurnInPlace(float TurnAngle);

	UFUNCTION()
	void OnTurnInPlaceMontageEnded(UAnimMontage* Montage, bool bInterrupted);

	/** Ragdolling*/
	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void ReplicatedRagdollStart();

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_RagdollStart();

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_RagdollStart();

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	void ReplicatedRagdollEnd();

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_RagdollEnd(FVector CharacterLocation);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_RagdollEnd(FVector CharacterLocation);

	/** Input */

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnLandEvent OnLandDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnTurnInPlaceEvent OnTurnInPlaceDelegate;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName TurnInPlaceWarpTargetName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	bool bPlayingTurnInPlace = false;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnCustomSmoothCompletedEvent OnCustomSmoothCompletedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnCustomSmoothCompletedEvent OnCustomSmoothInterruptDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnCustomSmoothInterruptedEvent OnCustomSmoothInterruptedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FRagdollStateChangedEvent RagdollStateChangedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnSkillAnimStateChangedEvent OnSkillAnimStateChangedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FIsMovingChangedEvent IsMovingChangedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FHasMovementInputEvent MovementInputChangedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FMovementStateChangedEvent OnMovementStateChangedDelegate;

	UPROPERTY(BlueprintAssignable, Category = "Hi|Input")
	FOnGaitChangedEvent OnGaitChangedDelegate;

	UPROPERTY(BlueprintReadOnly, Replicated, Category = "Hi|Essential Information")
	FVector ReplicatedCurrentAcceleration = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly, Replicated, Category = "Hi|Essential Information")
	FRotator ReplicatedControlRotation = FRotator::ZeroRotator;

	UFUNCTION(BlueprintCallable, Category = "Hi|Character States")
	virtual void SetDesiredGait(EHiGait NewGait);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetDesiredGait(EHiGait NewGait);

	UFUNCTION(BlueprintCallable, Category = "Hi|Input")
	EHiRotationMode GetDesiredRotationMode() const { return DesiredRotationMode; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Input")
	void SetDesiredRotationMode(EHiRotationMode NewRotMode);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Character States")
	void Server_SetDesiredRotationMode(EHiRotationMode NewRotMode);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Character States")
	void Multicast_SetDesiredRotationMode(EHiRotationMode NewRotMode);
	
	/** Rotation System */

	UFUNCTION(BlueprintCallable, Category = "Hi|Rotation System")
	void SetActorLocationAndTargetRotation(FVector NewLocation, FRotator NewRotation);

	/** Movement System */

	UFUNCTION(BlueprintCallable, Category = "Hi|Movement System")
	const FHiMovementSettings GetTargetMovementSettings() const { return MovementData; };

	UFUNCTION(BlueprintGetter, Category = "Hi|Movement System")
	bool HasMovementInput() const { return bHasMovementInput; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Movement System")
	EHiGait GetAllowedGait() const;

	UFUNCTION(BlueprintCallable, Category = "Hi|Movement System")
	virtual EHiGait GetActualGait(EHiGait AllowedGait) const;

	UFUNCTION(BlueprintCallable, Category = "Hi|Movement System")
	bool CanSprint() const;

	/** BP implementable function that called when Breakfall starts */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Movement System")
	void OnBreakfall();
	virtual void OnBreakfall_Implementation();

	/** Implement on BP to get required roll animation according to character's state */
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Movement System")
	UAnimMontage* GetRollAnimation();
	virtual UAnimMontage* GetRollAnimation_Implementation() { return nullptr; };

	UFUNCTION(BlueprintImplementableEvent, Category = "Hi|Movement System")
	void MoveBlockedBy(const FHitResult& Impact);

	/** Utility */
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Utility")
	float GetAnimCurveValue(FName CurveName) const;

	UFUNCTION(BlueprintCallable, Category = "Hi|Utility")
	void SetVisibleMesh(USkeletalMesh* NewSkeletalMesh);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Utility")
	void Server_SetVisibleMesh(USkeletalMesh* NewSkeletalMesh);

	/** Camera System */

	UFUNCTION(BlueprintCallable, Category = "Hi|Camera System")
	virtual ECollisionChannel GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius);

	virtual FTransform GetThirdPersonPivotTarget();

	UFUNCTION(BlueprintCallable, Category = "Hi|Camera System")
	void SetCameraBehavior(UHiPlayerCameraBehavior* CamBeh) { CameraBehavior = CamBeh; }

	/** Essential Information Getters/Setters */

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	FVector GetAcceleration() const { return Acceleration; }

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	bool IsMoving() const { return bIsMoving; }
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	FVector GetMovementInput() const;

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	float GetMovementInputAmount() const { return MovementInputAmount; }
	
	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	float GetSpeed() const { return Speed; }

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	float GetSpeed3D() const { return Speed3D; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	void SmoothActorRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Essential Information")
	void Multicast_SmoothActorRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Essential Information")
	void Server_SmoothActorRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Essential Information")
	void Replicated_SmoothActorRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	virtual void Replicated_SmoothActorRotation_Implementation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	void SmoothAimingRotation(FRotator Target, float InterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Essential Information")
	void Multicast_SmoothAimingRotation(FRotator Target, float InterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Essential Information")
	void Server_SmoothAimingRotation(FRotator Target, float InterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Essential Information")
	void Replicated_SmoothAimingRotation(FRotator Target, float InterpSpeed, float DeltaTime);
	virtual void Replicated_SmoothAimingRotation_Implementation(FRotator Target, float InterpSpeed, float DeltaTime);

	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	void SmoothActorLocation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep, FHitResult& SweepHitResult, bool bTeleport);
	
	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Essential Information")
	void Multicast_SmoothActorLocation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep = false, bool bTeleport = false);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Essential Information")
	void Server_SmoothActorLocation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep = false, bool bTeleport = false);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Essential Information")
	void Replicated_SmoothActorLocation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep = false, bool bTeleport = false);
	virtual void Replicated_SmoothActorLocation_Implementation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep = false, bool bTeleport = false);

	// UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	// void SmoothActorLocationAndRotation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	//
	// UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi|Essential Information")
	// void Multicast_SmoothActorLocationAndRotation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	//
	// UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi|Essential Information")
	// void Server_SmoothActorLocationAndRotation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	//
	// UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Essential Information")
	// void Replicated_SmoothActorLocationAndRotation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	// virtual void Replicated_SmoothActorLocationAndRotation_Implementation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	FRotator GetAimingRotation() const { return AimingRotation; }

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	float GetAimYawRate() const { return AimYawRate; }
	
	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	FHiLeanAmount GetCharacterLeanAmount() const { return LeanAmount; }

	UFUNCTION(BlueprintNativeEvent, Category = "Hi|Essential Information")
	void EnterSkillAnim();
	virtual void EnterSkillAnim_Implementation();

	UFUNCTION(BlueprintNativeEvent, Category = "Hi|Essential Information")
	void LeaveSkillAnim();
	virtual void LeaveSkillAnim_Implementation();

	UFUNCTION(BlueprintGetter, Category = "Hi|Essential Information")
	bool IsInSkillAnim() const { return bIsInSkillAnim; }

	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	const EHiBodySide GetFrontFoot();

	UFUNCTION(BlueprintCallable, Category = "Hi|Essential Information")
	const EHiBodySide GetMovingForwardFoot();

	const FTransform GetLeftFootTransform() { return CurrentLeftFoot; }

	const FTransform GetRightFootTransform() { return CurrentRightFoot; }

	/** Input */

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void ForwardMovementAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void RightMovementAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void WalkAction();
	virtual void WalkAction_Implementation();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void SprintAction(bool bValue);
	virtual void SprintAction_Implementation(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void CameraUpAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void CameraRightAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void AimAction(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void RagdollAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void VelocityDirectionAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void LookingDirectionAction();

	virtual void OnMovementModeChanged(EMovementMode PrevMovementMode, uint8 PreviousCustomMode = 0);
	
	virtual void Landed(const FHitResult& Hit);
	
protected:
	/** Ragdoll System */

	void RagdollUpdate(float DeltaTime);

	void SetActorLocationDuringRagdoll(float DeltaTime);

	/** State Changes */

	virtual void OnMovementActionChanged(EHiMovementAction PreviousAction);

	virtual void OnRotationModeChanged(EHiRotationMode PreviousRotationMode);

	virtual void OnGaitChanged(EHiGait PreviousGait);

	virtual void OnVisibleMeshChanged(const USkeletalMesh* PreviousSkeletalMesh);

	virtual void OnSpeedScaleChanged(float PrevSpeedScale);

	virtual void SetEssentialValues(float DeltaTime);

	void OnLandFrictionReset();

	void SetIsMoving(bool bNewIsMoving);

	void CacheBoneTransforms();

	virtual void UpdateCharacterRotation(float DeltaTime);

	virtual void UpdateAnimatedLeanAmount(float DeltaTime);

	/** Utils */
	void SmoothCharacterRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	void SmoothCharacterRotationConstant(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime);

	double GetShortestSmoothRotationAngle(double Target, double Current, double InterpSpeed, RotationEasingType EasingType, float DeltaTime);

	void LimitRotation(float AimYawMin, float AimYawMax, float InterpSpeed, float DeltaTime);
	
	void ForceUpdateCharacterState();

	void SmoothCustomRotation(float DeltaTime);

	/** Replication */
	UFUNCTION(Category = "Hi|Replication")
	void OnRep_RotationMode(EHiRotationMode PrevRotMode);

	UFUNCTION(Category = "Hi|Replication")
	void OnRep_VisibleMesh(USkeletalMesh* PrevVisibleMesh);

	UFUNCTION(Category = "Hi|Replication")
	void OnRep_SpeedScale(float PrevSpeedScale);

protected:
	/* Custom movement component*/
	TObjectPtr<UCharacterMovementComponent> MyCharacterMovementComponent;
	
	/** Input */

	UPROPERTY(EditAnywhere, Replicated, BlueprintReadWrite, Category = "Hi|Input")
	EHiRotationMode DesiredRotationMode = EHiRotationMode::LookingDirection;

	UPROPERTY(EditAnywhere, Replicated, BlueprintReadWrite, Category = "Hi|Input")
	EHiGait DesiredGait = EHiGait::Running;

	UPROPERTY(Replicated, BlueprintReadOnly, Category = "Hi|Input")
	float DesiredSpeedScale = 1.0;

	UPROPERTY(EditDefaultsOnly, Category = "Hi|Input", BlueprintReadOnly)
	float LookUpDownRate = 1.25f;

	UPROPERTY(EditDefaultsOnly, Category = "Hi|Input", BlueprintReadOnly)
	float LookLeftRightRate = 1.25f;

	UPROPERTY(EditDefaultsOnly, Category = "Hi|Input", BlueprintReadOnly)
	float RollDoubleTapTimeout = 0.3f;
	
	UPROPERTY(Category = "Hi|Input", BlueprintReadOnly)
	bool bBreakFall = false;

	UPROPERTY(Category = "Hi|Input", BlueprintReadOnly)
	bool bSprintHeld = false;

	/** Movement System */

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement System")
	FHiMovementSettings MovementData;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement System")
	FHiAnimTurnInPlace TurnInPlaceValues;

	bool bHasCacheBones = false;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement System")
	FName FootBone_Left = TEXT("lf_foot_mjnt");
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Hi|Movement System")
	FName FootBone_Right = TEXT("rt_foot_mjnt");

	/** Essential Information */

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	FVector Acceleration = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	bool bIsMoving = false;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	bool bHasMovementInput = false;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	FRotator LastVelocityRotation;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	FRotator LastMovementInputRotation;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	float Speed = 0.0f;
	
	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	float Speed3D = 0.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	float MovementInputAmount = 0.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	float AimYawRate = 0.0f;

	/** Replicated Essential Information*/

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Essential Information")
	float EasedMaxAcceleration = 0.0f;

	/** Replicated Skeletal Mesh Information*/
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Skeletal Mesh", ReplicatedUsing = OnRep_VisibleMesh)
	TObjectPtr<USkeletalMesh> VisibleMesh = nullptr;

	/** State Values */

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiGroundedEntryState GroundedEntryState;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiMovementState MovementState = EHiMovementState::None;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiInAirState InAirState = EHiInAirState::None;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiMovementAction MovementAction = EHiMovementAction::None;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiMovementState PrevMovementState = EHiMovementState::None;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values", ReplicatedUsing = OnRep_RotationMode)
	EHiRotationMode RotationMode = EHiRotationMode::LookingDirection;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values", ReplicatedUsing = OnRep_SpeedScale)
	float SpeedScale = 1.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|State Values")
	EHiGait Gait = EHiGait::Walking;

	UPROPERTY(BlueprintReadWrite, Category = "Hi|State Values")
	float RotationSpeedScale = 1.0f;

	/** Rotation System */

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Rotation System")
	FRotator TargetRotation = FRotator::ZeroRotator;

	//UPROPERTY(BlueprintReadOnly, Category = "Hi|Rotation System")
	//float YawOffset = 0.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Rotation System")
	FHiLeanAmount LeanAmount;

	/** Breakfall System */

	/** If player hits to the ground with an amount of velocity greater than specified value, switch to breakfall state */
	UPROPERTY(BlueprintReadWrite, EditDefaultsOnly, Category = "Hi|Breakfall System")
	float BreakLandingToRollVelocity = 1860.0f;

	/** Ragdoll System */

	/** If the skeleton uses a reversed pelvis bone, flip the calculation operator */
	UPROPERTY(BlueprintReadWrite, EditDefaultsOnly, Category = "Hi|Ragdoll System")
	bool bReversedPelvis = false;

	/** If player hits to the ground with a specified amount of velocity, switch to ragdoll state */
	UPROPERTY(BlueprintReadWrite, EditDefaultsOnly, Category = "Hi|Ragdoll System")
	bool bRagdollOnLand = false;

	/** If player hits to the ground with an amount of velocity greater than specified value, switch to ragdoll state */
	UPROPERTY(BlueprintReadWrite, EditDefaultsOnly, Category = "Hi|Ragdoll System", meta = (EditCondition ="bRagdollOnLand"))
	float RagdollOnLandVelocity = 1000.0f;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Ragdoll System")
	bool bRagdollOnGround = false;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Ragdoll System")
	bool bRagdollFaceUp = false;

	UPROPERTY(BlueprintReadOnly, Category = "Hi|Ragdoll System")
	FVector LastRagdollVelocity = FVector::ZeroVector;

	UPROPERTY(BlueprintReadOnly, Replicated, Category = "Hi|Ragdoll System")
	FVector TargetRagdollLocation = FVector::ZeroVector;

	/* Server ragdoll pull force storage*/
	float ServerRagdollPull = 0.0f;

	/* Dedicated server mesh default visibility based anim tick option*/
	EVisibilityBasedAnimTickOption DefVisBasedTickOp;

	bool bPreRagdollURO = false;

	/** Cached Variables */

	FVector PreviousVelocity = FVector::ZeroVector;

	float PreviousAimingYaw = 0.0f;
	
	UPROPERTY(BlueprintReadOnly, Category = "Hi|Camera")
	TObjectPtr<UHiPlayerCameraBehavior> CameraBehavior;

	/** Last time the 'first' crouch/roll button is pressed */
	float LastStanceInputTime = 0.0f;
	
	/* Timer to manage reset of braking friction factor after on landed event */
	FTimerHandle OnLandedFrictionResetTimer;

	/* Smooth out aiming by interping control rotation*/
	FRotator AimingRotation = FRotator::ZeroRotator;

	/** We won't use curve based movement and a few other features on networked games */
	bool bEnableNetworkOptimizations = false;

	bool bUseCustomRotation = false;

	bool bIsInSkillAnim = false;

	UPROPERTY(BlueprintReadOnly, Category = "Custom Smooth")
	FCustomSmoothContext CustomSmoothContext;

	/* Foot Transform */
	FTransform CurrentLeftFoot;

	FTransform CurrentRightFoot;

	FTransform PreviousLeftFoot;

	FTransform PreviousRightFoot;

protected:
	UPROPERTY(Transient, DuplicateTransient)
	TObjectPtr<ACharacter> CharacterOwner;

	USkeletalMeshComponent *GetMesh() const { return CharacterOwner->GetMesh(); }
	
// 	UPROPERTY()
// 	TObjectPtr<UHiCharacterDebugComponent> HiCharacterDebugComponent = nullptr;
};
