// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "HiLocomotionCharacter.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FOnCharacterComponentInitialized);


class UHiLocomotionComponent;
class UHiJumpComponent;


UCLASS(Blueprintable, BlueprintType, config=Game)
class HIGAME_API AHiLocomotionCharacter : public ACharacter
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	AHiLocomotionCharacter(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UFUNCTION(BlueprintCallable, Category = "Hi")
	UHiLocomotionComponent* GetLocomotionComponent() const { return LocomotionComponent;}

	virtual void PostInitializeComponents();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Locomotion", Meta = (AllowPrivateAccess = "true"))
	UHiLocomotionComponent* LocomotionComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Locomotion", Meta = (AllowPrivateAccess = "true"))
	UHiJumpComponent* JumpComponent;

public:
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	virtual void OnMovementModeChanged(EMovementMode PrevMovementMode, uint8 PreviousCustomMode = 0) override;

	virtual void OnJumped_Implementation() override;

	virtual void Landed(const FHitResult& Hit) override;

	/** Input */

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void ForwardMovementAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void RightMovementAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void CameraUpAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void CameraRightAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void CameraScaleAction(float Value);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void JumpAction(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void SprintAction(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void AimAction(bool bValue);
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void AttackAction(bool bValue);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void StanceAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void WalkAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void RagdollAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void VelocityDirectionAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void LookingDirectionAction();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void GetInVehicleAction(bool bValue);

	// Network Montage Interface
	/** Montage Play Replication*/
	void PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = Animation)
	void Replicated_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = Animation)
	void Server_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintCallable, Client, Reliable, Category = Animation)
	void Client_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = Animation)
	void Multicast_PlayMontage(UAnimMontage* Montage, float PlayRate = 1.0f);

	/** Montage Stop Replication*/
	void StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = Animation)
	void Replicated_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = Animation)
	void Server_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = Animation)
	void Multicast_StopMontage(UAnimMontage* Montage = nullptr, float InBlendOutTime = -1.0f);
	
	UFUNCTION(BlueprintCallable, Category = "Hi|Camera System")
	virtual ECollisionChannel GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius);

	// UFUNCTION(BlueprintCallable, Server, Reliable, Category = Animation)
	// void Server_SetPlayerTransform(const FTransform& CharacterTransform);

	// UFUNCTION()
	// void SetPlayerTransform(const FTransform& CharacterTransform);
	//
	// UFUNCTION()
	// void FlowLockInput(bool IsLock);

	virtual FTransform GetThirdPersonPivotTarget();

	float ConsumeCameraScaleInput();

	void AddCameraScaleInput(float delta);

	UFUNCTION(BlueprintCallable, Category = "Hi")
	float GetAnimCurveValue(FName CurveName) const;

	UPROPERTY(BlueprintAssignable, Category=Character)
	FOnCharacterComponentInitialized OnCharacterComponentInitialized;
	
	bool bTriggerLandedAutoJump = false;
	float AutoJumpRateScale = 1.0f;
	float LandedAutoJumpBeginRootMotionScale = 1.0f;
	float LandedAutoJumpBeginPlayRate = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Hi|CMovement")
	int LandedAutoJumpMaxDelayTick = 0;
	
	int LandedAutoJumpDelayTick = 0;
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void LandedAutoJump();
	virtual void LandedAutoJump_Implementation();
	
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void TriggerLandedAutoJump(bool Trigger = true, float RootMotionScale = 1.0f, float PlayRate= 1.0f);
	
	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Hi")
	void Server_TriggerLandedAutoJump(bool Trigger, float RootMotionScale, float PlayRate);

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Hi")
	void Multicast_TriggerLandedAutoJump(bool Trigger, float RootMotionScale, float PlayRate);
	
	virtual void EnableInput(APlayerController* PlayerController) override;
	virtual void DisableInput(APlayerController* PlayerController) override;

private:
	float CameraScaleInput = 0.0f;
	
};
