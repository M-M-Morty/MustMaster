// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiPawnComponent.h"
#include "Component/HiPawnComponent.h"
#include "Component/HiCharacterDebugComponent.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "HiJumpComponent.generated.h"

class AHiCharacter;
class UHiLocomotionComponent;
class UHiCharacterMovementComponent;

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FJumpPressedEvent);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_ThreeParams(FOnJumpedEvent, EHiJumpState, JumpState, int, JumpCount, EHiBodySide, JumpFoot);

USTRUCT(BlueprintType)
struct FHiJumpAssistTraceSettings
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Jump System")
	float ReachDistance = 300.0f;

	UPROPERTY(EditAnywhere, Category = "Jump System")
	float ExtendHeightAbove = 50.0f;
	
	UPROPERTY(EditAnywhere, Category = "Jump System")
	float ExtendHeightBelow = 100.0f;
	
	UPROPERTY(EditAnywhere, Category = "Jump System")
	float LandOffset = 30.0f;
};

USTRUCT(BlueprintType)
struct FHiJumpAssistParams
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, Category = "Jump System")
	float MaxDesiredVelocityZ = -0.1f;

	UPROPERTY(EditAnywhere, Category = "Jump System")
	float MaxGravity = 100.0f;
};

// This component is currently only supports Player and does not support monster
UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiJumpComponent : public UHiPawnComponent
{
	GENERATED_BODY()

public:
	// Sets default values for this component's properties
	UHiJumpComponent(const FObjectInitializer& ObjectInitializer);

	virtual void InitializeComponent() override;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	void JumpAction(bool bValue);

	UFUNCTION(BlueprintNativeEvent)
	void LandedAutoJumpAction();

	virtual void OnJumped_Implementation();

	virtual void Landed(const FHitResult& Hit);

	/** Landed, Jumped, Rolling, Mantling and Ragdoll*/
	/** On Landed*/
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	void EventOnLanded();

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Jump System")
	void Multicast_OnLanded();

	UFUNCTION(BlueprintCallable, BlueprintCallable, Category = "Jump System")
	void StopJump();

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Jump System")
	void Multicast_OnStopJump();
	
	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Jump System")
	void Server_OnStopJump();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	void OnStopJump();

	UFUNCTION(BlueprintCallable, Category = "Jump System")
	void SetJumpState(EHiJumpState NewJumpState);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	void PreJumpBehavior(FVector InputVector);

	UFUNCTION(BlueprintCallable, BlueprintCallable, Category = "Jump System")
	void Replicated_PreJumpBehavior(FVector InputVector);

	UFUNCTION(BlueprintCallable, Server, Reliable, Category = "Jump System")
	void Server_PreJumpBehavior(FVector InputVector);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	bool IsValidLanding();

protected:
	
	// Called when the game starts
	virtual void BeginPlay() override;

	/** On Jumped*/
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	void EventOnJumped();

	UFUNCTION(BlueprintCallable, NetMulticast, Reliable, Category = "Jump System")
	void Multicast_OnJumped(int JumpCurrentCount, FRotator ControlledOwnerOrientation);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Jump System")
	bool JumpAssistCheck(float DeltaTime);

	UPROPERTY(Transient, DuplicateTransient)
	TObjectPtr<AHiCharacter> CharacterOwner;

	/** Input */

	UPROPERTY(BlueprintAssignable, Category = "Jump System")
	FJumpPressedEvent JumpPressedDelegate;

	UPROPERTY()
	TObjectPtr<UHiLocomotionComponent> LocomotionComponent;

	static FName NAME_IgnoreOnlyPawn;
	
	bool bJumping = false;

	bool bChangeGravity = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Jump System")
	bool bEnableJumpAssist = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Jump System")
	FHiJumpAssistParams JumpAssistParams;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Jump System")
	FHiJumpAssistTraceSettings JumpAssistTraceSettings;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Jump System")
	FName JumpAssistObjectDetectionProfile = NAME_IgnoreOnlyPawn;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Jump System")
	TEnumAsByte<ECollisionChannel> WalkableSurfaceDetectionChannel = ECC_Visibility;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Jump System")
	FName WalkableSurfaceDetectionProfileName;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Jump System")
	float AxisWeightRatioOfJumpFootSelect = 2.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Jump System")
	FName JumpUpCurveName = TEXT("JumpUp");

public:
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
	                           FActorComponentTickFunction* ThisTickFunction) override;

	UPROPERTY(BlueprintAssignable, Category = "Jump System")
	FOnJumpedEvent OnJumpedDelegate;

	UPROPERTY()
	TObjectPtr<UHiCharacterDebugComponent> HiCharacterDebugComponent = nullptr;

	UPROPERTY()
	TObjectPtr<UHiCharacterMovementComponent> HiCharacterMovementComponent = nullptr;

	UPROPERTY()
	float OriginalGravityScale = 1.0f;

	UPROPERTY()
	EHiBodySide JumpFoot = EHiBodySide::Middle;

	UPROPERTY()
	EHiJumpState JumpState = EHiJumpState::None;
};

