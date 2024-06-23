// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiLocomotionComponent.h"

#include "Component/HiCharacterDebugComponent.h"
#include "Utils/MathHelper.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/KismetMathLibrary.h"
#include "Kismet/GameplayStatics.h"
#include "TimerManager.h"
#include "Net/UnrealNetwork.h"
#include "MotionWarpingComponent.h"

//PRAGMA_DISABLE_OPTIMIZATION

//DEFINE_LOG_CATEGORY_STATIC(LogLocomotion, Log, All)

DEFINE_LOG_CATEGORY_STATIC(LogLocomotion, Log, All)

const FName NAME_FP_Camera(TEXT("FP_Camera"));
const FName NAME_Pelvis(TEXT("Pelvis"));
const FName NAME_RagdollPose(TEXT("RagdollPose"));
const FName NAME_pelvis(TEXT("pelvis"));
const FName NAME_root(TEXT("root"));
const FName NAME_spine_03(TEXT("spine_03"));

UHiLocomotionComponent::UHiLocomotionComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bWantsInitializeComponent = true;
	PrimaryComponentTick.bCanEverTick = true;
	SetIsReplicatedByDefault(true);
}

void UHiLocomotionComponent::InitializeComponent()
{
	Super::InitializeComponent();

	CharacterOwner = GetPawnChecked<ACharacter>();
	
	MyCharacterMovementComponent = Cast<UCharacterMovementComponent>(CharacterOwner->GetMovementComponent());
	check(MyCharacterMovementComponent);

	// Order:  Locomotion -> Mesh
	//					  -> Movement
	USkeletalMeshComponent* SkeletalMeshComponent = CharacterOwner->GetMesh();
	if (SkeletalMeshComponent)
	{
		SkeletalMeshComponent->AddTickPrerequisiteComponent(this); // Always tick after owner, so we'll use updated values
		int32 SocketBoneIndex;
		FTransform SocketLocalTransform;
		if(SkeletalMeshComponent->GetSocketInfoByName(FootBone_Left, SocketLocalTransform, SocketBoneIndex) && SkeletalMeshComponent->GetSocketInfoByName(FootBone_Right, SocketLocalTransform, SocketBoneIndex))
		{
			bHasCacheBones = true;
		}
	}
	MyCharacterMovementComponent->PrimaryComponentTick.AddPrerequisite(this, PrimaryComponentTick);
}

void UHiLocomotionComponent::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME(UHiLocomotionComponent, TargetRagdollLocation);
	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, ReplicatedCurrentAcceleration, COND_SkipOwner);
	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, ReplicatedControlRotation, COND_SkipOwner);

	DOREPLIFETIME(UHiLocomotionComponent, DesiredGait);
	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, DesiredRotationMode, COND_SkipOwner);

	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, RotationMode, COND_SkipOwner);
	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, VisibleMesh, COND_SkipOwner);
	DOREPLIFETIME_CONDITION(UHiLocomotionComponent, SpeedScale, COND_SkipOwner);
}

void UHiLocomotionComponent::OnBreakfall_Implementation()
{
	Replicated_PlayMontage(GetRollAnimation(), 1.0f);
}

void UHiLocomotionComponent::BeginPlay()
{
	Super::BeginPlay();

	// If we're in networked game, disable curved movement
	bEnableNetworkOptimizations = !IsNetMode(NM_Standalone);

	// Force update states to use the initial desired values.
	ForceUpdateCharacterState();

	// Set default rotation values.
	TargetRotation = CharacterOwner->GetActorRotation();
	LastVelocityRotation = TargetRotation;
	LastMovementInputRotation = TargetRotation;

	// HiCharacterDebugComponent = FindComponentByClass<UHiCharacterDebugComponent>();
}

void UHiLocomotionComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	TickLocomotion(DeltaTime);

	if (CharacterOwner->GetRemoteRole() == ROLE_AutonomousProxy)
	{
		return;
	}
}

void UHiLocomotionComponent::TickLocomotion(float DeltaTime)
{
	if (DeltaTime <= SMALL_NUMBER)
	{
		return;
	}

	SetEssentialValues(DeltaTime);

	switch (MovementState)
	{
	case EHiMovementState::Grounded:
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::InAir:
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::Ragdoll:
		RagdollUpdate(DeltaTime);
		break;
	default:
		break;
	}

	UpdateAnimatedLeanAmount(DeltaTime);

	// Cache values
	PreviousVelocity = CharacterOwner->GetVelocity();
	PreviousAimingYaw = AimingRotation.Yaw;

	if(bHasCacheBones)
	{
		CacheBoneTransforms();
	}
}

void UHiLocomotionComponent::RagdollStart()
{
	if (RagdollStateChangedDelegate.IsBound())
	{
		RagdollStateChangedDelegate.Broadcast(true);
	}

	/** When Networked, disables replicate movement reset TargetRagdollLocation and ServerRagdollPull variable
	and if the host is a dedicated server, change character mesh optimisation option to avoid z-location bug*/
	MyCharacterMovementComponent->bIgnoreClientMovementErrorChecksAndCorrection = 1;

	if (UKismetSystemLibrary::IsDedicatedServer(GetWorld()))
	{
		DefVisBasedTickOp = GetMesh()->VisibilityBasedAnimTickOption;
		GetMesh()->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	}
	TargetRagdollLocation = GetMesh()->GetSocketLocation(NAME_Pelvis);
	ServerRagdollPull = 0;

	// Disable URO
	bPreRagdollURO = GetMesh()->bEnableUpdateRateOptimizations;
	GetMesh()->bEnableUpdateRateOptimizations = false;

	// Step 1: Clear the Character Movement Mode and set the Movement State to Ragdoll
	CharacterOwner->GetCharacterMovement()->SetMovementMode(MOVE_None);
	SetMovementState(EHiMovementState::Ragdoll);

	// Step 2: Disable capsule collision and enable mesh physics simulation starting from the pelvis.
	CharacterOwner->GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	GetMesh()->SetCollisionObjectType(ECC_PhysicsBody);
	GetMesh()->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	GetMesh()->SetAllBodiesBelowSimulatePhysics(NAME_Pelvis, true, true);

	// Step 3: Stop any active montages.
	if (GetMesh()->GetAnimInstance())
	{
		GetMesh()->GetAnimInstance()->Montage_Stop(0.2f);
	}

	// Fixes character mesh is showing default A pose for a split-second just before ragdoll ends in listen server games
	GetMesh()->bOnlyAllowAutonomousTickPose = true;
	
	CharacterOwner->SetReplicateMovement(false);
}

void UHiLocomotionComponent::RagdollEnd()
{
	/** Re-enable Replicate Movement and if the host is a dedicated server set mesh visibility based anim
	tick option back to default*/

	if (UKismetSystemLibrary::IsDedicatedServer(GetWorld()))
	{
		GetMesh()->VisibilityBasedAnimTickOption = DefVisBasedTickOp;
	}

	GetMesh()->bEnableUpdateRateOptimizations = bPreRagdollURO;

	// Revert back to default settings
	MyCharacterMovementComponent->bIgnoreClientMovementErrorChecksAndCorrection = 0;
	GetMesh()->bOnlyAllowAutonomousTickPose = false;
	CharacterOwner->SetReplicateMovement(true);

	// Step 1: Save a snapshot of the current Ragdoll Pose for use in AnimGraph to blend out of the ragdoll
	if (GetMesh()->GetAnimInstance())
	{
		GetMesh()->GetAnimInstance()->SavePoseSnapshot(NAME_RagdollPose);
	}

	// Step 2: If the ragdoll is on the ground, set the movement mode to walking and play a Get Up animation.
	// If not, set the movement mode to falling and update the character movement velocity to match the last ragdoll velocity.
	if (bRagdollOnGround)
	{
		CharacterOwner->GetCharacterMovement()->SetMovementMode(MOVE_Walking);
		if (GetMesh()->GetAnimInstance())
		{
			GetMesh()->GetAnimInstance()->Montage_Play(GetGetUpAnimation(bRagdollFaceUp), 1.0f, EMontagePlayReturnType::MontageLength, 0.0f, true);
		}
	}
	else
	{
		CharacterOwner->GetCharacterMovement()->SetMovementMode(MOVE_Falling);
		CharacterOwner->GetCharacterMovement()->Velocity = LastRagdollVelocity;
	}

	// Step 3: Re-Enable capsule collision, and disable physics simulation on the mesh.
	CharacterOwner->GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	GetMesh()->SetCollisionObjectType(ECC_Pawn);
	GetMesh()->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	GetMesh()->SetAllBodiesSimulatePhysics(false);

	if (RagdollStateChangedDelegate.IsBound())
	{
		RagdollStateChangedDelegate.Broadcast(false);
	}
}

void UHiLocomotionComponent::Server_SetMeshLocationDuringRagdoll_Implementation(FVector MeshLocation)
{
	TargetRagdollLocation = MeshLocation;
}

void UHiLocomotionComponent::SetMovementState(const EHiMovementState NewState, bool bForce)
{
	if (bForce || MovementState != NewState)
	{
		PrevMovementState = MovementState;
		MovementState = NewState;
		if (OnMovementStateChangedDelegate.IsBound())
		{
			OnMovementStateChangedDelegate.Broadcast(MovementState);
		}
	}
}

void UHiLocomotionComponent::SetMovementAction(const EHiMovementAction NewAction, bool bForce)
{
	if (bForce || MovementAction != NewAction)
	{
		const EHiMovementAction Prev = MovementAction;
		MovementAction = NewAction;
		OnMovementActionChanged(Prev);
	}
}

void UHiLocomotionComponent::Server_SetMovementAction_Implementation(EHiMovementAction NewAction, bool bForce)
{
	this->SetMovementAction(NewAction, bForce);
}

void UHiLocomotionComponent::SetGait(const EHiGait NewGait, bool bForce)
{
	if (bForce || Gait != NewGait)
	{
		const EHiGait Prev = Gait;
		Gait = NewGait;
		OnGaitChanged(Prev);
	}
}

void UHiLocomotionComponent::SetSpeedScale(float NewSpeedScale, bool bForce)
{
	if (bForce || SpeedScale != NewSpeedScale)
	{
		float PrevSpeedScale = SpeedScale;
		SpeedScale = NewSpeedScale;
		OnSpeedScaleChanged(PrevSpeedScale);
	}
}

void UHiLocomotionComponent::Server_SetSpeedScale_Implementation(float NewSpeedScale, bool bForce)
{
	SetSpeedScale(NewSpeedScale, bForce);
}

void UHiLocomotionComponent::Multicast_SetSpeedScale_Implementation(float NewSpeedScale, bool bForce)
{
	SetSpeedScale(NewSpeedScale, bForce);

	if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy && CharacterOwner->GetNetMode() == NM_Client)
	{
		Server_SetSpeedScale(NewSpeedScale, bForce);
	}
}

float UHiLocomotionComponent::GetSpeedScale() const
{
	return SpeedScale;
}

void UHiLocomotionComponent::SetDesiredGait(const EHiGait NewGait)
{
	DesiredGait = NewGait;
	if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy)
	{
		Server_SetDesiredGait(NewGait);
	}
}

void UHiLocomotionComponent::Server_SetDesiredGait_Implementation(EHiGait NewGait)
{
	SetDesiredGait(NewGait);
}

void UHiLocomotionComponent::SetDesiredRotationMode(EHiRotationMode NewRotMode)
{
	DesiredRotationMode = NewRotMode;
	if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy && CharacterOwner->GetNetMode() == NM_Client)
	{
		Server_SetDesiredRotationMode(NewRotMode);
	}
}

void UHiLocomotionComponent::Server_SetDesiredRotationMode_Implementation(EHiRotationMode NewRotMode)
{
	SetDesiredRotationMode(NewRotMode);
}

void UHiLocomotionComponent::Multicast_SetDesiredRotationMode_Implementation(EHiRotationMode NewRotMode)
{
	SetDesiredRotationMode(NewRotMode);
}

void UHiLocomotionComponent::SetRotationMode(const EHiRotationMode NewRotationMode, bool bForce/* = false*/)
{
	if (bForce || RotationMode != NewRotationMode)
	{
		const EHiRotationMode Prev = RotationMode;
		RotationMode = NewRotationMode;
		OnRotationModeChanged(Prev);
	}
}

void UHiLocomotionComponent::Server_SetRotationMode_Implementation(EHiRotationMode NewRotationMode, bool bForce/* = false*/)
{
	SetRotationMode(NewRotationMode, bForce);
}

void UHiLocomotionComponent::Multicast_SetRotationMode(EHiRotationMode NewRotationMode, bool bForce/* = false*/)
{
	SetRotationMode(NewRotationMode, bForce);

	if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy && CharacterOwner->GetNetMode() == NM_Client)
	{
		Server_SetRotationMode(NewRotationMode, bForce);
	}
}

void UHiLocomotionComponent::SetGroundedEntryState(EHiGroundedEntryState NewState)
{
	GroundedEntryState = NewState;
}

void UHiLocomotionComponent::SetInAirState(EHiInAirState NewState)
{
	InAirState = NewState;
}

void UHiLocomotionComponent::EventOnTurnInPlace(float Angle)
{
	OnTurnInPlaceDelegate.Broadcast(Angle);
}

void UHiLocomotionComponent::EventOnLanded()
{
	const UCharacterMovementComponent* MovementComponent = CharacterOwner->GetCharacterMovement();
	const float VelZ = FMath::Abs(MovementComponent->Velocity.Z);
	const FVector HorizontalVelcity(MovementComponent->Velocity.X, MovementComponent->Velocity.Y, 0);
	const FVector HorizontalAccleration(ReplicatedCurrentAcceleration.X, ReplicatedCurrentAcceleration.Y, 0);

	OnLandDelegate.Broadcast();
	
	if (bRagdollOnLand && VelZ > RagdollOnLandVelocity)
	{
		ReplicatedRagdollStart();
	}
	else if (bHasMovementInput && VelZ >= BreakLandingToRollVelocity && HorizontalVelcity.Dot(HorizontalAccleration) > 0.1)
	{
		OnBreakfall();
	}
	else
	{
		CharacterOwner->GetCharacterMovement()->BrakingFrictionFactor = bHasMovementInput ? 0.5f : 3.0f;

		// After 0.5 secs, reset braking friction factor to zero
		GetWorldTimerManager().SetTimer(OnLandedFrictionResetTimer, this,
		                                &UHiLocomotionComponent::OnLandFrictionReset, 0.5f, false);
	}
}

void UHiLocomotionComponent::Multicast_OnLanded_Implementation()
{
	if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		EventOnLanded();
	}
}

bool UHiLocomotionComponent::Replicated_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate)
{
	if (!Montage)
	{
		return false;
	}
	if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		return false;
	}
	// Roll: Simply play a Root Motion Montage.
	if (GetMesh()->GetAnimInstance())
	{
		GetMesh()->GetAnimInstance()->Montage_Play(Montage, PlayRate);
	}

	Server_PlayMontage(Montage, PlayRate);

	return true;
}

void UHiLocomotionComponent::Server_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate)
{
	CharacterOwner->ForceNetUpdate();
	Multicast_PlayMontage(Montage, PlayRate);
}

void UHiLocomotionComponent::Multicast_PlayMontage_Implementation(UAnimMontage* Montage, float PlayRate)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance && CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		AnimInstance->Montage_Play(Montage, PlayRate);
		this->RegisterMontageCallbacks(AnimInstance, Montage);
	}
}

void UHiLocomotionComponent::Replicated_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance)
	{
		if (InBlendOutTime < 0)
		{
			InBlendOutTime = Montage->BlendOut.GetBlendTime();
		}
		AnimInstance->Montage_Stop(InBlendOutTime, Montage);
	}

	Server_StopMontage(Montage, InBlendOutTime);
}

void UHiLocomotionComponent::Server_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	CharacterOwner->ForceNetUpdate();
	Multicast_StopMontage(Montage, InBlendOutTime);
}

void UHiLocomotionComponent::Multicast_StopMontage_Implementation(UAnimMontage* Montage/* = nullptr*/, float InBlendOutTime/* = -1.0f*/)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance && CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		if (InBlendOutTime < 0)
		{
			InBlendOutTime = Montage->BlendOut.GetBlendTime();
		}
		AnimInstance->Montage_Stop(InBlendOutTime, Montage);
	}
}

void UHiLocomotionComponent::Replicated_StopMontageGroup(FName MontageGroupName, float InBlendOutTime/* = 0.0f*/)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance)
	{
		AnimInstance->Montage_StopGroupByName(InBlendOutTime, MontageGroupName);
	}

	Server_StopMontageGroup(MontageGroupName, InBlendOutTime);
}

void UHiLocomotionComponent::Server_StopMontageGroup_Implementation(FName MontageGroupName, float InBlendOutTime/* = 0.0f*/)
{
	CharacterOwner->ForceNetUpdate();
	Multicast_StopMontageGroup(MontageGroupName, InBlendOutTime);
}

void UHiLocomotionComponent::Multicast_StopMontageGroup_Implementation(FName MontageGroupName, float InBlendOutTime/* = 0.0f*/)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance && CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		AnimInstance->Montage_StopGroupByName(InBlendOutTime, MontageGroupName);
	}
}

void UHiLocomotionComponent::Replicated_MontageJumpToSection(FName SectionName, const UAnimMontage* Montage)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance)
	{
		AnimInstance->Montage_JumpToSection(SectionName, Montage);
	}

	Server_MontageJumpToSection(SectionName, Montage);
}

void UHiLocomotionComponent::Server_MontageJumpToSection_Implementation(FName SectionName, const UAnimMontage* Montage)
{
	CharacterOwner->ForceNetUpdate();
	Multicast_MontageJumpToSection(SectionName, Montage);
}

void UHiLocomotionComponent::Multicast_MontageJumpToSection_Implementation(FName SectionName, const UAnimMontage* Montage)
{
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (AnimInstance && CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		AnimInstance->Montage_JumpToSection(SectionName, Montage);
	}
}

void UHiLocomotionComponent::RegisterMontageCallbacks(UAnimInstance* AnimInstance, UAnimMontage* AnimMontage)
{
	BlendingOutDelegate.BindUObject(this, &UHiLocomotionComponent::OnMontageBlendingOutCallback);
	AnimInstance->Montage_SetBlendingOutDelegate(BlendingOutDelegate, AnimMontage);

	MontageEndedDelegate.BindUObject(this, &UHiLocomotionComponent::OnMontageEndedCallback);
	AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, AnimMontage);
}

void UHiLocomotionComponent::OnMontageBlendingOutCallback(UAnimMontage* Montage, bool bInterrupted)
{
	OnMontageBlendingOut.Broadcast(Montage, bInterrupted);
}

void UHiLocomotionComponent::OnMontageEndedCallback(UAnimMontage* Montage, bool bInterrupted)
{
	OnMontageEnded.Broadcast(Montage, bInterrupted);
}

void UHiLocomotionComponent::OnTurnInPlaceMontageEnded(UAnimMontage* Montage, bool bInterrupted)
{
	bPlayingTurnInPlace = false;
}

void UHiLocomotionComponent::PlayTurnInPlaceAnimation(float TurnAngle, const FHiTurnInPlaceAsset &TargetTurnAsset)
{
	if (bPlayingTurnInPlace)
	{
		return;
	}
	
	bPlayingTurnInPlace = true;

	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();

	const float MontageLength = AnimInstance->Montage_Play(TargetTurnAsset.Animation, 1.0f, EMontagePlayReturnType::MontageLength, 0.0f);
	bool bPlayedSuccessfully = (MontageLength > 0.f);
	if (bPlayedSuccessfully)
	{
		MontageEndedDelegate.BindUObject(this, &UHiLocomotionComponent::OnTurnInPlaceMontageEnded);
		AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, TargetTurnAsset.Animation);
	}
	else
	{
		OnTurnInPlaceMontageEnded(TargetTurnAsset.Animation, true);
	}
	
	
	UMotionWarpingComponent *MotionWarpingComponent = Cast<UMotionWarpingComponent>(GetOwner()->GetComponentByClass(UMotionWarpingComponent::StaticClass()));
	
	FRotator TargetRotator(0, TurnAngle, 0);
	FTransform MantleTarget;
	MantleTarget.SetRotation(TargetRotator.Quaternion());
	MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(TurnInPlaceWarpTargetName, MantleTarget);
	
	EventOnTurnInPlace(TurnAngle);
}

FHiTurnInPlaceAsset UHiLocomotionComponent::GetTurnInPlaceAsset_Implementation(float TurnAngle, const FHiAnimTurnInPlace &Values)
{
	FHiTurnInPlaceAsset TargetTurnAsset;
	if (FMath::Abs(TurnAngle) < Values.Turn180Threshold)
	{
		TargetTurnAsset = TurnAngle < 0.0f
							  ? Values.N_TurnIP_L90
							  : Values.N_TurnIP_R90;
	}
	else
	{
		TargetTurnAsset = TurnAngle < 0.0f
							  ? Values.N_TurnIP_L180
							  : Values.N_TurnIP_R180;
	}

	return TargetTurnAsset;
}

void UHiLocomotionComponent::Multicast_TurnInPlace_Implementation(float TurnAngle)
{
	if (CharacterOwner->GetLocalRole() != ROLE_Authority || CharacterOwner->GetNetMode() == NM_Standalone)
	{
		TurnInPlace(TurnAngle);	
	}
}

void UHiLocomotionComponent::TurnInPlace(float TurnAngle)
{
	FHiTurnInPlaceAsset TargetTurnAsset = GetTurnInPlaceAsset(TurnAngle, TurnInPlaceValues);

	PlayTurnInPlaceAnimation(TurnAngle, TargetTurnAsset);
}

void UHiLocomotionComponent::Server_RagdollStart_Implementation()
{
	Multicast_RagdollStart();
}

void UHiLocomotionComponent::Multicast_RagdollStart_Implementation()
{
	RagdollStart();
}

void UHiLocomotionComponent::Server_RagdollEnd_Implementation(FVector CharacterLocation)
{
	Multicast_RagdollEnd(CharacterLocation);
}

void UHiLocomotionComponent::Multicast_RagdollEnd_Implementation(FVector CharacterLocation)
{
	RagdollEnd();
}

void UHiLocomotionComponent::SetActorLocationAndTargetRotation(FVector NewLocation, FRotator NewRotation)
{
	CharacterOwner->SetActorLocationAndRotation(NewLocation, NewRotation);
	TargetRotation = NewRotation;
}

void UHiLocomotionComponent::ForceUpdateCharacterState()
{
	SetGait(DesiredGait, true);
	SetRotationMode(DesiredRotationMode, true);
	SetMovementState(MovementState, true);
	SetMovementAction(MovementAction, true);
	SetSpeedScale(SpeedScale, true);
}

bool UHiLocomotionComponent::CanSprint() const
{
	// Determine if the character is currently able to sprint based on the Rotation mode and current acceleration
	// (input) rotation. If the character is in the Looking Rotation mode, only allow sprinting if there is full
	// movement input and it is faced forward relative to the camera + or - 50 degrees.

	if (!bHasMovementInput || RotationMode == EHiRotationMode::Aiming)
	{
		return false;
	}

	const bool bValidInputAmount = MovementInputAmount > 0.9f;

	if (RotationMode == EHiRotationMode::VelocityDirection)
	{
		// It is prohibited to automatically adjust and switch sprint / run when the speed drops.
		return true;
	}

	if (RotationMode == EHiRotationMode::LookingDirection)
	{
		const FRotator AccRot = ReplicatedCurrentAcceleration.ToOrientationRotator().Clamp();
		FRotator Delta = AccRot - AimingRotation;
		Delta.Normalize();

		return bValidInputAmount && FMath::Abs(Delta.Yaw) < 50.0f;
	}

	return false;
}

void UHiLocomotionComponent::SetIsMoving(bool bNewIsMoving)
{
	if (bIsMoving != bNewIsMoving)
	{
		if (IsMovingChangedDelegate.IsBound())
		{
			IsMovingChangedDelegate.Broadcast(bNewIsMoving);
		}
	}
	bIsMoving = bNewIsMoving;
}

void UHiLocomotionComponent::SetEssentialValues(float DeltaTime)
{
	if (CharacterOwner->GetLocalRole() != ROLE_SimulatedProxy)
	{
		ReplicatedCurrentAcceleration = CharacterOwner->GetCharacterMovement()->GetCurrentAcceleration();
		ReplicatedControlRotation = CharacterOwner->GetControlRotation();
		EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration();
	}
	else
	{
		EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration() != 0
			                       ? CharacterOwner->GetCharacterMovement()->GetMaxAcceleration()
			                       : EasedMaxAcceleration / 2;
	}

	// Ignore interp AimingRotation to current control rotation for smooth character rotation movement. Decrease InterpSpeed
	// for slower but smoother movement.
	FRotator TargetRotator = ReplicatedControlRotation;
	if (MovementState == EHiMovementState::Grounded || InAirState == EHiInAirState::Falling)
	{
		TargetRotator.Pitch = AimingRotation.Pitch;
	}
	AimingRotation = TargetRotator;

	// These values represent how the capsule is moving as well as how it wants to move, and therefore are essential
	// for any data driven animation system. They are also used throughout the system for various functions,
	// so I found it is easiest to manage them all in one place.

	const FVector CurrentVel = CharacterOwner->GetVelocity();

	// Set the amount of Acceleration.
	Acceleration = (CurrentVel - PreviousVelocity) / DeltaTime;

	// Determine if the character is moving by getting it's speed. The Speed equals the length of the horizontal (x y)
	// velocity, so it does not take vertical movement into account. If the character is moving, update the last
	// velocity rotation. This value is saved because it might be useful to know the last orientation of movement
	// even after the character has stopped.
	Speed = CurrentVel.Size2D();
	SetIsMoving(Speed > 1.0f);
	if (bIsMoving)
	{
		LastVelocityRotation = CurrentVel.ToOrientationRotator().Clamp();
	}

	Speed3D = CurrentVel.Length();

	// Determine if the character has movement input by getting its movement input amount.
	// The Movement Input Amount is equal to the current acceleration divided by the max acceleration so that
	// it has a range of 0-1, 1 being the maximum possible amount of input, and 0 being none.
	// If the character has movement input, update the Last Movement Input Rotation.
	MovementInputAmount = ReplicatedCurrentAcceleration.Size() / EasedMaxAcceleration;
	bool bOldMovementInput = bHasMovementInput;
	bHasMovementInput = MovementInputAmount > 0.0f;
	if (bHasMovementInput)
	{
		LastMovementInputRotation = ReplicatedCurrentAcceleration.ToOrientationRotator().Clamp();
	}
	if (bOldMovementInput != bHasMovementInput && MovementInputChangedDelegate.IsBound())
	{
		MovementInputChangedDelegate.Broadcast(bHasMovementInput);
	}

	// Set the Aim Yaw rate by comparing the current and previous Aim Yaw value, divided by Delta Seconds.
	// This represents the speed the camera is rotating left to right.
	AimYawRate = FMath::Abs((AimingRotation.Yaw - PreviousAimingYaw) / DeltaTime);
}

FVector UHiLocomotionComponent::GetMovementInput() const
{
	return ReplicatedCurrentAcceleration;
}

float UHiLocomotionComponent::GetAnimCurveValue(FName CurveName) const
{
	if (GetMesh()->GetAnimInstance())
	{
		return GetMesh()->GetAnimInstance()->GetCurveValue(CurveName);
	}

	return 0.0f;
}

void UHiLocomotionComponent::SmoothActorRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	SmoothCharacterRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
}

void UHiLocomotionComponent::Multicast_SmoothActorRotation_Implementation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	// if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
	}
}

void UHiLocomotionComponent::Server_SmoothActorRotation_Implementation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	Multicast_SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
}

void UHiLocomotionComponent::Replicated_SmoothActorRotation_Implementation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
	Server_SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
}

void UHiLocomotionComponent::SmoothAimingRotation(FRotator Target, float InterpSpeed, float DeltaTime)
{
	// AimingRotation = Rotation;
	AimingRotation = FMath::RInterpConstantTo(AimingRotation, Target, DeltaTime, InterpSpeed);
}

void UHiLocomotionComponent::Multicast_SmoothAimingRotation_Implementation(FRotator Target, float InterpSpeed, float DeltaTime)
{
	// if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		SmoothAimingRotation(Target, InterpSpeed, DeltaTime);
	}
}

void UHiLocomotionComponent::Server_SmoothAimingRotation_Implementation(FRotator Target, float InterpSpeed, float DeltaTime)
{
	Multicast_SmoothAimingRotation(Target, InterpSpeed, DeltaTime);
}

void UHiLocomotionComponent::Replicated_SmoothAimingRotation_Implementation(FRotator Target, float InterpSpeed, float DeltaTime)
{
	SmoothAimingRotation(Target, InterpSpeed, DeltaTime);
	Server_SmoothAimingRotation(Target, InterpSpeed, DeltaTime);
}

void UHiLocomotionComponent::SmoothActorLocation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep, FHitResult& OutSweepHitResult, bool bTeleport)
{
	CharacterOwner->SetActorLocation(FMath::VInterpConstantTo(CharacterOwner->GetActorLocation(), TargetLocation, DeltaTime, InterpSpeed), bSweep, (bSweep ? &OutSweepHitResult : nullptr), TeleportFlagToEnum(bTeleport));
}

void UHiLocomotionComponent::Multicast_SmoothActorLocation_Implementation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep, bool bTeleport)
{
	// if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
	{
		FHitResult OutSweepHitResult;
		SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime, bSweep, OutSweepHitResult, bTeleport);
	}
}

void UHiLocomotionComponent::Server_SmoothActorLocation_Implementation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep, bool bTeleport)
{
	Multicast_SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime, bSweep, bTeleport);
}

void UHiLocomotionComponent::Replicated_SmoothActorLocation_Implementation(FVector TargetLocation, float InterpSpeed, float DeltaTime, bool bSweep, bool bTeleport)
{
	FHitResult OutSweepHitResult;
	SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime, bSweep, OutSweepHitResult, bTeleport);
	Server_SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime, bSweep, bTeleport);
}

// void UHiLocomotionComponent::SmoothActorLocationAndRotation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
// {
// 	CharacterOwner->SetActorLocation(FMath::VInterpConstantTo(CharacterOwner->GetActorLocation(), TargetLocation, DeltaTime, InterpSpeed));
// 	SmoothCharacterRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
// }
//
// void UHiLocomotionComponent::Multicast_SmoothActorLocationAndRotation_Implementation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
// {
// 	// if (CharacterOwner->GetLocalRole() != ROLE_AutonomousProxy)
// 	{
// 		SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime);
// 		SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
// 	}
// }
//
// void UHiLocomotionComponent::Server_SmoothActorLocationAndRotation_Implementation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
// {
// 	Multicast_SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime);
// 	Multicast_SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
// }
//
// void UHiLocomotionComponent::Replicated_SmoothActorLocationAndRotation_Implementation(FVector TargetLocation, float InterpSpeed, FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
// {
// 	SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime);
// 	Server_SmoothActorLocation(TargetLocation, InterpSpeed, DeltaTime);
// 	
// 	SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
// 	Server_SmoothActorRotation(Target, TargetInterpSpeed, ActorInterpSpeed, DeltaTime);
// }

void UHiLocomotionComponent::EnterSkillAnim_Implementation()
{ 
	if (!bIsInSkillAnim)
	{
		bIsInSkillAnim = true;
		if (OnSkillAnimStateChangedDelegate.IsBound())
		{
			OnSkillAnimStateChangedDelegate.Broadcast(bIsInSkillAnim);
		}
	}
}

void UHiLocomotionComponent::LeaveSkillAnim_Implementation()
{
	if (bIsInSkillAnim)
	{
		bIsInSkillAnim = false;
		if (OnSkillAnimStateChangedDelegate.IsBound())
		{
			OnSkillAnimStateChangedDelegate.Broadcast(bIsInSkillAnim);
		}
	}
}

void UHiLocomotionComponent::SetVisibleMesh(USkeletalMesh* NewVisibleMesh)
{
	if (VisibleMesh != NewVisibleMesh)
	{
		const USkeletalMesh* Prev = VisibleMesh;
		VisibleMesh = NewVisibleMesh;
		OnVisibleMeshChanged(Prev);

		if (CharacterOwner->GetLocalRole() != ROLE_Authority || CharacterOwner->GetNetMode() == NM_Standalone)
		{
			Server_SetVisibleMesh(NewVisibleMesh);
		}
	}
}

void UHiLocomotionComponent::Server_SetVisibleMesh_Implementation(USkeletalMesh* NewVisibleMesh)
{
	SetVisibleMesh(NewVisibleMesh);
}

const EHiBodySide UHiLocomotionComponent::GetFrontFoot()
{
	if (CurrentRightFoot.GetTranslation().X > CurrentLeftFoot.GetTranslation().X)
	{
		return EHiBodySide::Right;
	}
	return EHiBodySide::Left;
}

const EHiBodySide UHiLocomotionComponent::GetMovingForwardFoot()
{
	float LeftForwardMovement = CurrentLeftFoot.GetTranslation().X - PreviousLeftFoot.GetTranslation().X;
	float RightForwardMovement = CurrentRightFoot.GetTranslation().X - PreviousRightFoot.GetTranslation().X;
	return (LeftForwardMovement > RightForwardMovement) ? EHiBodySide::Left : EHiBodySide::Right;
}

ECollisionChannel UHiLocomotionComponent::GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius)
{
	TraceOrigin = CharacterOwner->GetActorLocation();
	TraceRadius = 10.0f;
	return ECC_Visibility;
}

FTransform UHiLocomotionComponent::GetThirdPersonPivotTarget()
{
	return CharacterOwner->GetActorTransform();
}

void UHiLocomotionComponent::RagdollUpdate(float DeltaTime)
{
	GetMesh()->bOnlyAllowAutonomousTickPose = false;
	
	// Set the Last Ragdoll Velocity.
	const FVector NewRagdollVel = GetMesh()->GetPhysicsLinearVelocity(NAME_root);
	LastRagdollVelocity = (NewRagdollVel != FVector::ZeroVector || CharacterOwner->IsLocallyControlled())
		                      ? NewRagdollVel
		                      : LastRagdollVelocity / 2;

	// Use the Ragdoll Velocity to scale the ragdoll's joint strength for physical animation.
	const float SpringValue = FMath::GetMappedRangeValueClamped<float, float>({0.0f, 1000.0f}, {0.0f, 25000.0f},
	                                                            LastRagdollVelocity.Size());
	GetMesh()->SetAllMotorsAngularDriveParams(SpringValue, 0.0f, 0.0f, false);

	// Disable Gravity if falling faster than -4000 to prevent continual acceleration.
	// This also prevents the ragdoll from going through the floor.
	const bool bEnableGrav = LastRagdollVelocity.Z > -4000.0f;
	GetMesh()->SetEnableGravity(bEnableGrav);

	// Update the Actor location to follow the ragdoll.
	SetActorLocationDuringRagdoll(DeltaTime);
}

void UHiLocomotionComponent::SetActorLocationDuringRagdoll(float DeltaTime)
{
	if (CharacterOwner->IsLocallyControlled())
	{
		// Set the pelvis as the target location.
		TargetRagdollLocation = GetMesh()->GetSocketLocation(NAME_Pelvis);
		if (!HasAuthority())
		{
			Server_SetMeshLocationDuringRagdoll(TargetRagdollLocation);
		}
	}

	// Determine wether the ragdoll is facing up or down and set the target rotation accordingly.
	const FRotator PelvisRot = GetMesh()->GetSocketRotation(NAME_Pelvis);

	if (bReversedPelvis) {
		bRagdollFaceUp = PelvisRot.Roll > 0.0f;
	} else
	{
		bRagdollFaceUp = PelvisRot.Roll < 0.0f;
	}


	const FRotator TargetRagdollRotation(0.0f, bRagdollFaceUp ? PelvisRot.Yaw - 180.0f : PelvisRot.Yaw, 0.0f);

	// Trace downward from the target location to offset the target location,
	// preventing the lower half of the capsule from going through the floor when the ragdoll is laying on the ground.
	const FVector TraceVect(TargetRagdollLocation.X, TargetRagdollLocation.Y,
	                        TargetRagdollLocation.Z - CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight());

	UWorld* World = GetWorld();
	check(World);

	FCollisionQueryParams Params;
	Params.AddIgnoredActor(CharacterOwner);

	FHitResult HitResult;
	const bool bHit = World->LineTraceSingleByChannel(HitResult, TargetRagdollLocation, TraceVect,
	                                                  ECC_Visibility, Params);

	// if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
	// {
	// 	UHiCharacterDebugComponent::DrawDebugLineTraceSingle(World,
	// 	                                             TargetRagdollLocation,
	// 	                                             TraceVect,
	// 	                                             EDrawDebugTrace::Type::ForOneFrame,
	// 	                                             bHit,
	// 	                                             HitResult,
	// 	                                             FLinearColor::Red,
	// 	                                             FLinearColor::Green,
	// 	                                             1.0f);
	// }

	bRagdollOnGround = HitResult.IsValidBlockingHit();
	FVector NewRagdollLoc = TargetRagdollLocation;

	if (bRagdollOnGround)
	{
		const float ImpactDistZ = FMath::Abs(HitResult.ImpactPoint.Z - HitResult.TraceStart.Z);
		NewRagdollLoc.Z += CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight() - ImpactDistZ + 2.0f;
	}
	if (!CharacterOwner->IsLocallyControlled())
	{
		ServerRagdollPull = FMath::FInterpTo(ServerRagdollPull, 750.0f, DeltaTime, 0.6f);
		float RagdollSpeed = FVector(LastRagdollVelocity.X, LastRagdollVelocity.Y, 0).Size();
		FName RagdollSocketPullName = RagdollSpeed > 300 ? NAME_spine_03 : NAME_pelvis;
		GetMesh()->AddForce(
			(TargetRagdollLocation - GetMesh()->GetSocketLocation(RagdollSocketPullName)) * ServerRagdollPull,
			RagdollSocketPullName, true);
	}
	SetActorLocationAndTargetRotation(bRagdollOnGround ? NewRagdollLoc : TargetRagdollLocation, TargetRagdollRotation);
}

void UHiLocomotionComponent::OnMovementModeChanged(EMovementMode PrevMovementMode, uint8 PreviousCustomMode)
{
	// Use the Character Movement Mode changes to set the Movement States to the right values. This allows you to have
	// a custom set of movement states but still use the functionality of the default character movement component.

	switch (CharacterOwner->GetCharacterMovement()->MovementMode)
	{
	case MOVE_Walking:
	case MOVE_NavWalking:
		SetMovementState(EHiMovementState::Grounded);
		SetInAirState(EHiInAirState::None);
		break;
	case MOVE_Falling:
		SetMovementState(EHiMovementState::InAir);
		SetInAirState(EHiInAirState::Falling);
		break;
	case MOVE_Flying:
		SetMovementState(EHiMovementState::InAir);
		SetInAirState(EHiInAirState::Fly);
		break;
	case MOVE_Custom:
		SetMovementState(EHiMovementState::Custom);
	default:
		break;
	}
}

void UHiLocomotionComponent::OnMovementActionChanged(const EHiMovementAction PreviousAction)
{
	if (CameraBehavior)
	{
		CameraBehavior->MovementAction = MovementAction;
	}
}

void UHiLocomotionComponent::SmoothCustomRotation(float DeltaTime)
{
	if (MyCharacterMovementComponent->GetLastUpdateRotation().Equals(CustomSmoothContext.CustomRotation))
	{
		OnCustomSmoothCompletedDelegate.Broadcast();
		bUseCustomRotation = false;
	}
	if (bUseCustomRotation)
	{
		SmoothCharacterRotationConstant(CustomSmoothContext.CustomRotation, CustomSmoothContext.TargetInterpSpeed, CustomSmoothContext.ActorInterpSpeed, DeltaTime);
	}
}

void UHiLocomotionComponent::Replicated_SetCharacterRotation(const FRotator& Rotation, bool Smooth/* = false*/, const FCustomSmoothContext& Context/* = FCustomSmoothContext()*/)
{
	SetCharacterRotation(Rotation, Smooth, Context);
	Server_SetCharacterRotation(Rotation, Smooth, Context);
}

void UHiLocomotionComponent::Server_SetCharacterRotation_Implementation(const FRotator& Rotation, bool Smooth/* = false*/, const FCustomSmoothContext& Context/* = FCustomSmoothContext()*/)
{
	Multicast_SetCharacterRotation(Rotation, Smooth, Context);
}

void UHiLocomotionComponent::Multicast_SetCharacterRotation_Implementation(const FRotator &Rotation, bool Smooth,
	const FCustomSmoothContext & Context, bool bIncludeLocalController, bool bRotateCamera)
{
	if (!CharacterOwner->IsLocallyControlled() || bIncludeLocalController)
	{
		SetCharacterRotation(Rotation, Smooth, Context);

		if (CharacterOwner->IsLocallyControlled() && bRotateCamera)
		{
			OnActorRotateUpdateCamera(Rotation);
		}
	}
}

void UHiLocomotionComponent::OnActorRotateUpdateCamera_Implementation(const FRotator& Rotation)
{
	
}

bool UHiLocomotionComponent::SetCharacterRotation(const FRotator &Rotation, bool Smooth, const FCustomSmoothContext &Context)
{
	// UE_LOG(LogLocomotion, Warning, TEXT("UHiLocomotionComponent::SetCharacterRotation %s, rotation: %s, smooth: %d, role: %d"), *UKismetSystemLibrary::GetDisplayName(CharacterOwner), *Rotation.ToString(), Smooth, CharacterOwner->GetLocalRole());
	// FDebug::DumpStackTraceToLog(ELogVerbosity::Warning);
	if (!Smooth)
	{
		if (CharacterOwner->SetActorRotation(Rotation))
		{
			if (bUseCustomRotation)
			{
				OnCustomSmoothInterruptDelegate.Broadcast();
				bUseCustomRotation = false;
			}
			TargetRotation = Rotation;
			return true;
		}
		return false;
	}
	else
	{
		if (bUseCustomRotation)
		{
			OnCustomSmoothInterruptDelegate.Broadcast();
		}

		bUseCustomRotation = true;
		CustomSmoothContext = Context;
		CustomSmoothContext.CustomRotation = Rotation;
		return true;
	}
}

void UHiLocomotionComponent::Multicast_SetActorLocationAndRotation_Implementation(FVector NewLocation, FRotator NewRotation, bool bSweep, bool bTeleport) {
	FHitResult Hit;
	CharacterOwner->SetActorLocationAndRotation(NewLocation, NewRotation, bSweep, (bSweep ? &Hit : nullptr), TeleportFlagToEnum(bTeleport));
}

void UHiLocomotionComponent::OnRotationModeChanged(EHiRotationMode PreviousRotationMode)
{
	if (CameraBehavior)
	{
		CameraBehavior->SetRotationMode(RotationMode);
	}

}

void UHiLocomotionComponent::OnGaitChanged(const EHiGait PreviousGait)
{
	if (CameraBehavior)
	{
		CameraBehavior->SetGait(Gait);
	}
	if (OnGaitChangedDelegate.IsBound())
	{
		OnGaitChangedDelegate.Broadcast();
	}
}

void UHiLocomotionComponent::OnVisibleMeshChanged(const USkeletalMesh* PrevVisibleMesh)
{
	// Update the Skeletal Mesh before we update materials and anim bp variables
	GetMesh()->SetSkeletalMesh(VisibleMesh);

	// Reset materials to their new mesh defaults
	if (GetMesh() != nullptr)
	{
		for (int32 MaterialIndex = 0; MaterialIndex < GetMesh()->GetNumMaterials(); ++MaterialIndex)
		{
			GetMesh()->SetMaterial(MaterialIndex, nullptr);
		}
	}

	// Force set variables. This ensures anim instance & character stay synchronized on mesh changes
	ForceUpdateCharacterState();
}

void UHiLocomotionComponent::OnSpeedScaleChanged(float PrevSpeedScale)
{
	
}

void UHiLocomotionComponent::Landed(const FHitResult& Hit)
{
	if (CharacterOwner->IsLocallyControlled())
	{
		EventOnLanded();
	}
	if (HasAuthority())
	{
		Multicast_OnLanded();
	}
}

void UHiLocomotionComponent::OnLandFrictionReset()
{
	// Reset the braking friction
	CharacterOwner->GetCharacterMovement()->BrakingFrictionFactor = 0.0f;
}

void UHiLocomotionComponent::UpdateCharacterRotation(float DeltaTime)
{
	if (CharacterOwner->HasAnyRootMotion())
	{
		return;
	}

	const bool bCanUpdateMovingRot = (bIsMoving && bHasMovementInput && InAirState != EHiInAirState::Falling) || Speed > 150.0f;
	if (bCanUpdateMovingRot)
	{
		if (RotationMode == EHiRotationMode::VelocityDirection)
		{
			SmoothCharacterRotation({0.0f, LastVelocityRotation.Yaw, 0.0f}, 0.0f, 5.0f * RotationSpeedScale, DeltaTime);
		}
		else if (RotationMode == EHiRotationMode::LookingDirection)
		{
			SmoothCharacterRotation({0.0f, AimingRotation.Yaw, 0.0f}, 0.0f, 5.0f * RotationSpeedScale, DeltaTime);
		}
		else if (RotationMode == EHiRotationMode::Aiming)
		{
			SmoothCharacterRotation({0.0f, AimingRotation.Yaw, 0.0f}, 0.0f, 15.0f * RotationSpeedScale, DeltaTime);
		}
	}
	else
	{
		
	}
}

void UHiLocomotionComponent::UpdateAnimatedLeanAmount(float DeltaTime)
{
	// Calculate the Relative Acceleration Amount. This value represents the current amount of acceleration / deceleration
	// relative to the actor rotation. It is normalized to a range of -1 to 1 so that -1 equals the Max Braking Deceleration,
	// and 1 equals the Max Acceleration of the Character Movement Component.
	if (Acceleration.IsNearlyZero())
	{
		LeanAmount.FB = 0.0f;
		LeanAmount.LR = 0.0f;
	}
	else if (FVector::DotProduct(Acceleration, MyCharacterMovementComponent->Velocity) > 0.0f)
	{
		const float MaxAcc = MyCharacterMovementComponent->GetMaxAcceleration();
		FVector RelativeAcceleration = Acceleration.GetClampedToMaxSize(MaxAcc) / MaxAcc;
		RelativeAcceleration = CharacterOwner->GetActorRotation().UnrotateVector(RelativeAcceleration);
		LeanAmount.LR = RelativeAcceleration.Y;
		LeanAmount.FB = RelativeAcceleration.X;
	}
	else
	{
		const float MaxBrakingDec = MyCharacterMovementComponent->GetMaxBrakingDeceleration();
		if (FMath::IsNearlyZero(MaxBrakingDec))
		{
			FVector RelativeAcceleration = CharacterOwner->GetActorRotation().UnrotateVector(Acceleration);
			RelativeAcceleration.Normalize();
			LeanAmount.LR = RelativeAcceleration.Y;
			LeanAmount.FB = RelativeAcceleration.X;
		}
		else
		{
			FVector RelativeAcceleration = Acceleration.GetClampedToMaxSize(MaxBrakingDec) / MaxBrakingDec;
			RelativeAcceleration = CharacterOwner->GetActorRotation().UnrotateVector(RelativeAcceleration);
			LeanAmount.LR = RelativeAcceleration.Y;
			LeanAmount.FB = RelativeAcceleration.X;
		}
	}
	return;
}

void UHiLocomotionComponent::CacheBoneTransforms()
{
	PreviousLeftFoot = CurrentLeftFoot;
	PreviousRightFoot = CurrentRightFoot;

	CurrentLeftFoot = GetMesh()->GetSocketTransform(FootBone_Left, RTS_Actor);
	CurrentRightFoot = GetMesh()->GetSocketTransform(FootBone_Right, RTS_Actor);
}

EHiGait UHiLocomotionComponent::GetAllowedGait() const
{
	// Calculate the Allowed Gait. This represents the maximum Gait the character is currently allowed to be in,
	// and can be determined by the desired gait, the rotation mode, the stance, etc. For example,
	// if you wanted to force the character into a walking state while indoors, this could be done here.

	//if (Stance == EHiStance::Standing)
	//{
	//	if (RotationMode != EHiRotationMode::Aiming)
	//	{
	//		if (DesiredGait == EHiGait::Sprinting)
	//		{
	//			return CanSprint() ? EHiGait::Sprinting : EHiGait::Running;
	//		}
	//		return DesiredGait;
	//	}
	//}

	//// Crouching stance & Aiming rot mode has same behaviour
	//if (DesiredGait == EHiGait::Sprinting)
	//{
	//	return EHiGait::Running;
	//}

	return DesiredGait;
}

EHiGait UHiLocomotionComponent::GetActualGait(EHiGait AllowedGait) const
{
	return EHiGait::Walking;
}

void UHiLocomotionComponent::SmoothCharacterRotation(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	// Interpolate the Target Rotation for extra smooth rotation behavior
	TargetRotation = UMathHelper::RNearestInterpConstantTo(TargetRotation, Target, DeltaTime, TargetInterpSpeed);
	const FRotator ResultActorRotation = UMathHelper::RNearestInterpTo(CharacterOwner->GetActorRotation(), TargetRotation, DeltaTime, ActorInterpSpeed);
	CharacterOwner->SetActorRotation(ResultActorRotation);
}

void UHiLocomotionComponent::SmoothCharacterRotationConstant(FRotator Target, float TargetInterpSpeed, float ActorInterpSpeed, float DeltaTime)
{
	TargetRotation = UMathHelper::RNearestInterpConstantTo(TargetRotation, Target, DeltaTime, TargetInterpSpeed);
	const FRotator ResultActorRotation = UMathHelper::RNearestInterpConstantTo(CharacterOwner->GetActorRotation(), TargetRotation, DeltaTime, ActorInterpSpeed);
	CharacterOwner->SetActorRotation(ResultActorRotation);
}

double UHiLocomotionComponent::GetShortestSmoothRotationAngle(double Target, double Current, double InterpSpeed, RotationEasingType EasingType, float DeltaTime)
{
	double DeltaAngle = FMath::FindDeltaAngleDegrees(Current, Target);
	if (FMath::IsNearlyZero(DeltaAngle))
	{
		return Target;
	}
	double InterpValue = Current;
	double ShortestTarget = Current + DeltaAngle;
	switch (EasingType)
	{
	case RotationEasingType::Interp:
		InterpValue = FMath::FInterpTo(Current, ShortestTarget, DeltaTime, InterpSpeed);
		break;
	case RotationEasingType::InterpConstant:
		InterpValue = FMath::FInterpConstantTo(Current, ShortestTarget, DeltaTime, InterpSpeed);
		break;
	default:
		break;
	}
	return InterpValue;
}

void UHiLocomotionComponent::LimitRotation(float AimYawMin, float AimYawMax, float InterpSpeed, float DeltaTime)
{
	// Prevent the character from rotating past a certain angle.
	FRotator Delta = AimingRotation - CharacterOwner->GetActorRotation();
	Delta.Normalize();
	const float RangeVal = Delta.Yaw;

	if (RangeVal < AimYawMin || RangeVal > AimYawMax)
	{
		const float ControlRotYaw = AimingRotation.Yaw;
		const float TargetYaw = ControlRotYaw + (RangeVal > 0.0f ? AimYawMin : AimYawMax);
		SmoothCharacterRotation({0.0f, TargetYaw, 0.0f}, 0.0f, InterpSpeed, DeltaTime);
	}
}

void UHiLocomotionComponent::ForwardMovementAction_Implementation(float Value)
{
	// Default camera relative movement behavior, see AHiPlayerCameraManager::ProcessViewRotation
	FVector DirVector = FVector::ForwardVector;
	CharacterOwner->AddMovementInput(DirVector, Value);
}

void UHiLocomotionComponent::RightMovementAction_Implementation(float Value)
{
	// Default camera relative movement behavior, see AHiPlayerCameraManager::ProcessViewRotation
	FVector DirVector = FVector::RightVector;
	CharacterOwner->AddMovementInput(DirVector, Value);
}

void UHiLocomotionComponent::WalkAction_Implementation()
{
	if (DesiredGait == EHiGait::Walking)
	{
		SetDesiredGait(EHiGait::Running);
	}
	else if (DesiredGait == EHiGait::Running)
	{
		SetDesiredGait(EHiGait::Walking);
	}
}

void UHiLocomotionComponent::SprintAction_Implementation(bool bValue)
{
	if (bValue)
	{
		SetDesiredGait(EHiGait::Sprinting);
	}
	else
	{
		SetDesiredGait(EHiGait::Running);
	}
}

void UHiLocomotionComponent::CameraUpAction_Implementation(float Value)
{
	CharacterOwner->AddControllerPitchInput(LookUpDownRate * Value);
}

void UHiLocomotionComponent::CameraRightAction_Implementation(float Value)
{
	CharacterOwner->AddControllerYawInput(LookLeftRightRate * Value);
}

void UHiLocomotionComponent::AimAction_Implementation(bool bValue)
{
	if (bValue)
	{
		// AimAction: Hold "AimAction" to enter the aiming mode, release to revert back the desired rotation mode.
		SetRotationMode(EHiRotationMode::Aiming);
	}
	else
	{
		SetRotationMode(DesiredRotationMode);
	}
}

void UHiLocomotionComponent::RagdollAction_Implementation()
{
	// Ragdoll Action: Press "Ragdoll Action" to toggle the ragdoll state on or off.

	//if (GetMovementState() == EHiMovementState::Ragdoll)
	//{
	//	ReplicatedRagdollEnd();
	//}
	//else
	//{
	//	ReplicatedRagdollStart();
	//}
}

void UHiLocomotionComponent::VelocityDirectionAction_Implementation()
{
	// Select Rotation Mode: Switch the desired (default) rotation mode to Velocity or Looking Direction.
	// This will be the mode the character reverts back to when un-aiming
	SetDesiredRotationMode(EHiRotationMode::VelocityDirection);
	SetRotationMode(EHiRotationMode::VelocityDirection);
}

void UHiLocomotionComponent::LookingDirectionAction_Implementation()
{
	SetDesiredRotationMode(EHiRotationMode::LookingDirection);
	SetRotationMode(EHiRotationMode::LookingDirection);
}

void UHiLocomotionComponent::ReplicatedRagdollStart()
{
	if (HasAuthority())
	{
		Multicast_RagdollStart();
	}
	else
	{
		Server_RagdollStart();
	}
}

void UHiLocomotionComponent::ReplicatedRagdollEnd()
{
	if (HasAuthority())
	{
		Multicast_RagdollEnd(CharacterOwner->GetActorLocation());
	}
	else
	{
		Server_RagdollEnd(CharacterOwner->GetActorLocation());
	}
}

void UHiLocomotionComponent::OnRep_RotationMode(EHiRotationMode PrevRotMode)
{
	OnRotationModeChanged(PrevRotMode);
}

void UHiLocomotionComponent::OnRep_VisibleMesh(USkeletalMesh* PrevVisibleMesh)
{
	OnVisibleMeshChanged(PrevVisibleMesh);
}

void UHiLocomotionComponent::OnRep_SpeedScale(float PrevSpeedScale)
{
	OnSpeedScaleChanged(PrevSpeedScale);
}
