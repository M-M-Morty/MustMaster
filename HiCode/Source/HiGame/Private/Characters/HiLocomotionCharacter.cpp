// Fill out your copyright notice in the Description page of Project Settings.
#include "Characters/HiLocomotionCharacter.h"

#include "Characters/Animation/HiLocomotionAnimInstance.h"
#include "Component/HiCharacterMovementComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Net/UnrealNetwork.h"
#include "Component/HiLocomotionComponent.h"
#include "Component/HiJumpComponent.h"
#include "GameFramework/PlayerController.h"


// Sets default values
AHiLocomotionCharacter::AHiLocomotionCharacter(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	//ObjectInitializer.SetDefaultSubobjectClass<UCharacterMovementComponent>(CharacterMovementComponentName);
	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	LocomotionComponent = nullptr;//CreateDefaultSubobject<UHiLocomotionComponent>(TEXT("LocomotionComponent"));
	//LocomotionComponent->bEditableWhenInherited = true;

	bUseControllerRotationYaw = 0;
	bReplicates = true;
	SetReplicatingMovement(true);
}

void AHiLocomotionCharacter::PostInitializeComponents()
{
	LocomotionComponent = FindComponentByClass<UHiLocomotionComponent>();

	JumpComponent = FindComponentByClass<UHiJumpComponent>();
	
	Super::PostInitializeComponents();
	
	OnCharacterComponentInitialized.Broadcast();
	
	//checkSlow(LocomotionComponent);
}

float AHiLocomotionCharacter::GetAnimCurveValue(FName CurveName) const
{
	if (GetMesh()->GetAnimInstance())
	{
		return GetMesh()->GetAnimInstance()->GetCurveValue(CurveName);
	}

	return 0.0f;
}

// Called when the game starts or when spawned
void AHiLocomotionCharacter::BeginPlay()
{
	Super::BeginPlay();
}

// Called every frame
void AHiLocomotionCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
}

void AHiLocomotionCharacter::OnMovementModeChanged(EMovementMode PrevMovementMode, uint8 PreviousCustomMode)
{
	Super::OnMovementModeChanged(PrevMovementMode, PreviousCustomMode);

	if (LocomotionComponent)
		LocomotionComponent->OnMovementModeChanged(PrevMovementMode, PreviousCustomMode);
}

void AHiLocomotionCharacter::OnJumped_Implementation()
{
	Super::OnJumped_Implementation();

	if (JumpComponent)
		JumpComponent->OnJumped_Implementation();
}

void AHiLocomotionCharacter::Landed(const FHitResult& Hit)
{
	Super::Landed(Hit);

	if (LocomotionComponent)
		LocomotionComponent->Landed(Hit);

	if (JumpComponent)
		JumpComponent->Landed(Hit);
}

void AHiLocomotionCharacter::ForwardMovementAction_Implementation(float Value)
{
	if (LocomotionComponent)
		LocomotionComponent->ForwardMovementAction(Value);
}

void AHiLocomotionCharacter::RightMovementAction_Implementation(float Value)
{
	if (LocomotionComponent)
		LocomotionComponent->RightMovementAction(Value);
}

void AHiLocomotionCharacter::CameraUpAction_Implementation(float Value)
{
	if (LocomotionComponent)
		LocomotionComponent->CameraUpAction(Value);
}

void AHiLocomotionCharacter::CameraRightAction_Implementation(float Value)
{
	if (LocomotionComponent)
		LocomotionComponent->CameraRightAction(Value);
}

float AHiLocomotionCharacter::ConsumeCameraScaleInput()
{
	float LastCameraScaleInput = CameraScaleInput;
	CameraScaleInput = 0.0f;
	return LastCameraScaleInput;
}

void AHiLocomotionCharacter::AddCameraScaleInput(float delta)
{
	CameraScaleInput += delta;
}

void AHiLocomotionCharacter::CameraScaleAction_Implementation(float Value)
{
	AddCameraScaleInput(Value);
}

void AHiLocomotionCharacter::JumpAction_Implementation(bool bValue)
{

}

void AHiLocomotionCharacter::SprintAction_Implementation(bool bValue)
{
	if (LocomotionComponent)
		LocomotionComponent->SprintAction(bValue);
}

void AHiLocomotionCharacter::AimAction_Implementation(bool bValue)
{
	if (LocomotionComponent)
		LocomotionComponent->AimAction(bValue);
}

void AHiLocomotionCharacter::AttackAction_Implementation(bool bValue)
{
	
}

void AHiLocomotionCharacter::StanceAction_Implementation()
{
	//if (LocomotionComponent)
	//	LocomotionComponent->StanceAction();
}

void AHiLocomotionCharacter::WalkAction_Implementation()
{
	if (LocomotionComponent)
		LocomotionComponent->WalkAction();
}

void AHiLocomotionCharacter::RagdollAction_Implementation()
{
	if (LocomotionComponent)
		LocomotionComponent->RagdollAction();
}

void AHiLocomotionCharacter::VelocityDirectionAction_Implementation()
{
	if (LocomotionComponent)
		LocomotionComponent->VelocityDirectionAction();
}

void AHiLocomotionCharacter::LookingDirectionAction_Implementation()
{
	if (LocomotionComponent)
		LocomotionComponent->LookingDirectionAction();
}

void AHiLocomotionCharacter::GetInVehicleAction_Implementation(bool bValue)
{
	
}

ECollisionChannel AHiLocomotionCharacter::GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius)
{
	if (LocomotionComponent)
	{
		return LocomotionComponent->GetThirdPersonTraceParams(TraceOrigin, TraceRadius);
	}
	return ECC_Visibility;
}

FTransform AHiLocomotionCharacter::GetThirdPersonPivotTarget()
{
	if (LocomotionComponent)
	{
		return LocomotionComponent->GetThirdPersonPivotTarget();
	}
	return FTransform::Identity;
}

void AHiLocomotionCharacter::PlayMontage(UAnimMontage* Montage, float PlayRate/* = 1.0f*/)
{
	if (Montage && GetMesh() && GetMesh()->GetAnimInstance())
	{
		GetMesh()->GetAnimInstance()->Montage_Play(Montage, PlayRate);
	}
}

void AHiLocomotionCharacter::Replicated_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate/* = 1.0f*/)
{
	if (GetLocalRole() != ROLE_AutonomousProxy)
	{
		return;
	}

	PlayMontage(Montage, PlayRate);
	Server_PlayMontage(Montage, PlayRate);
}

void AHiLocomotionCharacter::Server_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate/* = 1.0f*/)
{
	ForceNetUpdate();
	Multicast_PlayMontage(Montage, PlayRate);
}

void AHiLocomotionCharacter::Client_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate/* = 1.0f*/)
{
	PlayMontage(Montage, PlayRate);
}

void AHiLocomotionCharacter::Multicast_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate/* = 1.0f*/)
{
	if (GetLocalRole() != ROLE_AutonomousProxy)
	{
		PlayMontage(Montage, PlayRate);
	}
}

void AHiLocomotionCharacter::StopMontage(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance)
	{
		if (InBlendOutTime < 0)
		{
			InBlendOutTime = Montage ? Montage->BlendOut.GetBlendTime() : 0.0f;
		}
		AnimInstance->Montage_Stop(InBlendOutTime, Montage);
	}
}

void AHiLocomotionCharacter::Replicated_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	StopMontage(Montage, InBlendOutTime);
	Server_StopMontage(Montage, InBlendOutTime);
}

void AHiLocomotionCharacter::Server_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	ForceNetUpdate();
	Multicast_StopMontage(Montage, InBlendOutTime);
}

void AHiLocomotionCharacter::Multicast_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	if (GetLocalRole() != ROLE_AutonomousProxy)
	{
		StopMontage(Montage, InBlendOutTime);
	}
}


void AHiLocomotionCharacter::TriggerLandedAutoJump_Implementation(bool Trigger, float RootMotionScale, float PlayRate)
{
	bTriggerLandedAutoJump = Trigger;
	LandedAutoJumpBeginRootMotionScale = RootMotionScale;
	LandedAutoJumpBeginPlayRate = PlayRate;
	UHiLocomotionAnimInstance* LocomotionAnimInstance = Cast<UHiLocomotionAnimInstance>(GetMesh()->GetLinkedAnimGraphInstanceByTag(TEXT("Locomotion")));
	if (LocomotionAnimInstance)
	{
		LocomotionAnimInstance->bAllowAutoJump = true;
	}
	if (IsLocallyControlled())
	{
		Server_TriggerLandedAutoJump(Trigger, RootMotionScale, PlayRate);
	}
}

void AHiLocomotionCharacter::LandedAutoJump_Implementation()
{
	UHiCharacterMovementComponent* HiCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(GetMovementComponent());
	if(HiCharacterMovementComponent && HiCharacterMovementComponent->MovementMode == HiCharacterMovementComponent->GetGroundMovementMode())
	{
		if(LandedAutoJumpDelayTick >= LandedAutoJumpMaxDelayTick)
		{
			LandedAutoJumpDelayTick = 0;
			if(JumpComponent)
			{
				ResetJumpState();
				if(IsLocallyControlled())
				{
					JumpComponent->LandedAutoJumpAction();
				}
				UHiLocomotionAnimInstance* LocomotionAnimInstance = Cast<UHiLocomotionAnimInstance>(GetMesh()->GetLinkedAnimGraphInstanceByTag(TEXT("Locomotion")));
				if(LocomotionAnimInstance)
				{
					LocomotionAnimInstance->bAllowAutoJump = true;
				}
				bTriggerLandedAutoJump = false;
			}
		}
		else
		{
			++LandedAutoJumpDelayTick;
		}
	}
	else
	{
		LandedAutoJumpDelayTick = 0;
	}
}

void AHiLocomotionCharacter::Server_TriggerLandedAutoJump_Implementation(bool Trigger, float RootMotionScale, float PlayRate)
{
	Multicast_TriggerLandedAutoJump(Trigger, RootMotionScale, PlayRate);
}

void AHiLocomotionCharacter::Multicast_TriggerLandedAutoJump_Implementation(bool Trigger, float RootMotionScale, float PlayRate)
{
	if (!IsLocallyControlled())
	{
		TriggerLandedAutoJump(Trigger, RootMotionScale, PlayRate);
	}
}

void AHiLocomotionCharacter::EnableInput(APlayerController* PlayerController) {
	if (!PlayerController) {
		return;
	}

	APawn::EnableInput(PlayerController);
	// APawn not invoke parent EnableInput, here invoke!
	if (PlayerController->GetPawnOrSpectator() != this) {
		AActor::EnableInput(PlayerController);
	}

	PlayerController->EnableInput(PlayerController);
}

void AHiLocomotionCharacter::DisableInput(APlayerController* PlayerController) {
	if (!PlayerController) {
		return;
	}

	APawn::DisableInput(PlayerController);
	if (PlayerController->GetPawnOrSpectator() != this) {
		AActor::DisableInput(PlayerController);
	}

	PlayerController->DisableInput(PlayerController);
}
