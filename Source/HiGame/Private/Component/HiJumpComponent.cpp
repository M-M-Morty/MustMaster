// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiJumpComponent.h"
#include "GameFramework/Character.h"
#include "Characters/HiCharacter.h"
#include "Components/CapsuleComponent.h"
#include "Component/HiLocomotionComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Characters/HiPlayerController.h"
#include "Characters/HiCharacterMathLibrary.h"

FName UHiJumpComponent::NAME_IgnoreOnlyPawn(TEXT("IgnoreOnlyPawn"));

DEFINE_LOG_CATEGORY_STATIC(LogJump, Log, All)


// Sets default values for this component's properties
UHiJumpComponent::UHiJumpComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bStartWithTickEnabled = true;
	PrimaryComponentTick.TickGroup = TG_PrePhysics;
	bWantsInitializeComponent = true;
}

// Called when the game starts
void UHiJumpComponent::BeginPlay()
{
	Super::BeginPlay();

	if (CharacterOwner)
	{
		LocomotionComponent = CharacterOwner->GetLocomotionComponent();
		ensureMsgf(LocomotionComponent, TEXT("Missing LocomotionComponent for Character: %s"), *CharacterOwner->GetFName().ToString());
		HiCharacterDebugComponent = CharacterOwner->FindComponentByClass<UHiCharacterDebugComponent>();	

		HiCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(CharacterOwner->GetCharacterMovement());
		ensureMsgf(HiCharacterMovementComponent, TEXT("Missing HiCharacterMovementComponent for Character: %s"), *CharacterOwner->GetFName().ToString());
		if (HiCharacterMovementComponent)
		{
			OriginalGravityScale = HiCharacterMovementComponent->GravityScale;
		}
	}
	// ...
	
}

void UHiJumpComponent::InitializeComponent()
{
	Super::InitializeComponent();

	CharacterOwner = GetPawnChecked<AHiCharacter>();

	if (bChangeGravity)
	{
		UCharacterMovementComponent* CharacterMovement = CharacterOwner->GetCharacterMovement();

		if (CharacterMovement)
		{
			CharacterMovement->GravityScale = OriginalGravityScale;
		}
		bChangeGravity = false;
	}
}

void UHiJumpComponent::LandedAutoJumpAction_Implementation()
{

}

void UHiJumpComponent::OnJumped_Implementation()
{
	if (CharacterOwner->IsLocallyControlled())
	{
		EventOnJumped();
	}
	if (HasAuthority())
	{
		Multicast_OnJumped(CharacterOwner->JumpCurrentCount, CharacterOwner->GetActorRotation());
	}
}

void UHiJumpComponent::Landed(const FHitResult& Hit)
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

void UHiJumpComponent::EventOnLanded_Implementation()
{
	OnStopJump();
}

void UHiJumpComponent::Multicast_OnLanded_Implementation()
{
	if (!CharacterOwner->IsLocallyControlled())
	{
		if (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy)
		{
			CharacterOwner->JumpCurrentCount = 0;
		}

		EventOnLanded();
	}
}

void UHiJumpComponent::StopJump()
{
	if (CharacterOwner->IsLocallyControlled())
	{
		OnStopJump();
		Server_OnStopJump();
	}
}

void UHiJumpComponent::Multicast_OnStopJump_Implementation()
{
	if (!CharacterOwner->IsLocallyControlled())
	{
		OnStopJump();
	}
}

void UHiJumpComponent::Server_OnStopJump_Implementation()
{
	if (HasAuthority())
	{
		Multicast_OnStopJump();
	}
}

void UHiJumpComponent::SetJumpState(EHiJumpState NewJumpState)
{
	JumpState = NewJumpState;
	OnJumpedDelegate.Broadcast(JumpState, CharacterOwner->JumpCurrentCount, JumpFoot);
}

void UHiJumpComponent::OnStopJump_Implementation()
{
	if (bJumping)
	{
		bJumping = false;
	}

	SetJumpState(EHiJumpState::None);

	if (bChangeGravity)
	{
		if (HiCharacterMovementComponent)
		{
			HiCharacterMovementComponent->GravityScale = OriginalGravityScale;
		}
		bChangeGravity = false;
	}
}

void UHiJumpComponent::Multicast_OnJumped_Implementation(int JumpCurrentCount, FRotator ControlledOwnerOrientation)
{
	if (!CharacterOwner->IsLocallyControlled())
	{
		if (CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && LocomotionComponent)
		{
			// Directly set the Simulated Client orientation, ignoring smoothing processing
			FRotator InputOrientation = CharacterOwner->GetActorRotation();
			InputOrientation.Yaw = ControlledOwnerOrientation.Yaw;
			LocomotionComponent->SetCharacterRotation(InputOrientation, false);
			// Use Server JumpCount
			CharacterOwner->JumpCurrentCount = JumpCurrentCount;
		}
#if LQT_DISTRIBUTED_DS
		if (CharacterOwner->GetLocalRole() == ROLE_ServerSimulatedProxy)
		{
			return;
		}
#endif
		// Do Jumped
		EventOnJumped();
	}
}

void UHiJumpComponent::EventOnJumped_Implementation()
{
	if (LocomotionComponent)
	{
		// TODO: 这个配置应该写在动画资源里面，而不是事件里面
		// 这里是一个一次性的黑配置，保证当帧是正确的，但是需要改掉
		if (CharacterOwner->GetMesh() && CharacterOwner->GetMesh()->IsPlayingRootMotionFromEverythingNetwork())
		{
			HiCharacterMovementComponent->RootMotionOverrideType = EHiRootMotionOverrideType::Velocity_Z;
		}
		if (CharacterOwner->JumpCurrentCount == 1)
		{
			if (LocomotionComponent->IsMoving())
			{
				// Find jump foot
				const FTransform& LeftFootTransform = LocomotionComponent->GetLeftFootTransform();
				const FTransform& RightFootTransform = LocomotionComponent->GetRightFootTransform();
				float DeltaX = RightFootTransform.GetTranslation().X - LeftFootTransform.GetTranslation().X;
				float DeltaZ = RightFootTransform.GetTranslation().Z - LeftFootTransform.GetTranslation().Z;
				if (DeltaX - AxisWeightRatioOfJumpFootSelect * DeltaZ > 0.0f)
				{
					JumpFoot = EHiBodySide::Right;
				}
				else
				{
					JumpFoot = EHiBodySide::Left;
				}
			}
			else
			{
				JumpFoot = EHiBodySide::Middle;
			}
		}
		else
		{
			check(CharacterOwner->JumpCurrentCount > 1)

			if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy)
			{
				FVector InputVector = CharacterOwner->GetPendingMovementInputVector();
				InputVector.Z = 0.0f;
				Replicated_PreJumpBehavior(InputVector);
			}
		}
	}

	bJumping = true;
	SetJumpState(EHiJumpState::Jump);
}

void UHiJumpComponent::Replicated_PreJumpBehavior(FVector InputVector)
{
	PreJumpBehavior(InputVector);
	Server_PreJumpBehavior(InputVector);
}

void UHiJumpComponent::PreJumpBehavior_Implementation(FVector InputVector)
{
	if (!HiCharacterMovementComponent)
	{
		return;
	}
	if (InputVector.IsNearlyZero())
	{
		HiCharacterMovementComponent->Velocity = FVector::ZeroVector;
	}
	else if (LocomotionComponent)
	{
		FRotator InputOrientation = InputVector.ToOrientationRotator();
		LocomotionComponent->SetCharacterRotation(InputOrientation, false);
		FVector VelocityDirection = FRotator(0, InputOrientation.Yaw, 0).Vector();
		HiCharacterMovementComponent->Velocity = VelocityDirection * HiCharacterMovementComponent->GetMaxSpeed();
	}
	else
	{
		FRotator InputOrientation = InputVector.ToOrientationRotator();
		CharacterOwner->SetActorRotation(InputOrientation);
		FVector VelocityDirection = FRotator(0, InputOrientation.Yaw, 0).Vector();
		HiCharacterMovementComponent->Velocity = VelocityDirection * HiCharacterMovementComponent->GetMaxSpeed();
	}
}

void UHiJumpComponent::Server_PreJumpBehavior_Implementation(FVector InputVector)
{
	PreJumpBehavior(InputVector);
}

void UHiJumpComponent::JumpAction_Implementation(bool bValue)
{
	if (!LocomotionComponent)
	{
		return;
	}
	if (bValue)
	{
		// Jump Action: Press "Jump Action" to end the ragdoll if ragdolling, stand up if crouching, or jump if standing.
		if (JumpPressedDelegate.IsBound())
		{
			JumpPressedDelegate.Broadcast();
		}

		EHiMovementAction MovementAction = LocomotionComponent->GetMovementAction();
		EHiMovementState MovementState = LocomotionComponent->GetMovementState();
		EHiInAirState InAirState = LocomotionComponent->GetInAirState();
		if (MovementAction == EHiMovementAction::None)
		{
			if (MovementState == EHiMovementState::Grounded)
			{
				CharacterOwner->Jump();
			}
			else if (MovementState == EHiMovementState::InAir && InAirState == EHiInAirState::Falling)
			{
				CharacterOwner->Jump();
			}
			else if (MovementState == EHiMovementState::Ragdoll)
			{
				LocomotionComponent->ReplicatedRagdollEnd();
			}
		}
		else if (MovementState == EHiMovementState::Grounded)
		{
			LocomotionComponent->Replicated_InterruptMovementAction(0.1f);
			CharacterOwner->Jump();
		}
	}
}

// Called every frame
void UHiJumpComponent::TickComponent(float DeltaTime, ELevelTick TickType,
                                     FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (bJumping && bEnableJumpAssist)
	{
		JumpAssistCheck(DeltaTime);
	}
}

bool UHiJumpComponent::JumpAssistCheck_Implementation(float DeltaTime)
{
	if (!CharacterOwner)
	{
		return false;
	}

	if (!HiCharacterMovementComponent)
	{
		return false;
	}
	
	const FVector &Velocity = HiCharacterMovementComponent->Velocity;
	float Gravity = HiCharacterMovementComponent->GetGravityZ();

	//const FVector &VelocityZ = FVector(0, 0, Velocity.Z);
	const FVector &VelocityXY = FVector(Velocity.X, Velocity.Y, 0);

	const FVector& TraceDirection = Velocity.GetSafeNormal2D();

	if (TraceDirection.IsZero())
	{
		return false;
	}

	UCapsuleComponent *CapsuleComponent = CharacterOwner->GetCapsuleComponent();

	float CapsuleRadius = CapsuleComponent->GetScaledCapsuleRadius();
	float CapsuleHalfHeight = CapsuleComponent->GetScaledCapsuleHalfHeight();

	UWorld* World = GetWorld();
	check(World);

	const FVector& ActorLocation = CharacterOwner->K2_GetActorLocation();

	const FVector &TraceStart = ActorLocation;
	const FVector &TraceEnd = TraceStart + TraceDirection * JumpAssistTraceSettings.ReachDistance;
	//const float HalfHeight = CapsuleComponent->GetScaledCapsuleHalfHeight();

	const FCollisionShape CapsuleCollisionShape = FCollisionShape::MakeCapsule(CapsuleRadius, CapsuleHalfHeight);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(CharacterOwner);
	
	FHitResult ForwardHitResult, HitResult;
	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart, TraceEnd, FQuat::Identity, JumpAssistObjectDetectionProfile,
													  CapsuleCollisionShape, Params);

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
															TraceStart,
															TraceEnd,
															CapsuleCollisionShape,
															EDrawDebugTrace::Type::ForDuration,
															bHit,
															ForwardHitResult,
															FLinearColor::Green,
															FLinearColor::Blue,
															1.0f);
		}
	}
	
	if (!ForwardHitResult.IsValidBlockingHit()/* || OwnerCharacter->GetCharacterMovement()->IsWalkable(ForwardHitResult)*/)
	{
		// Not a valid surface to mantle
		return false;
	}

	const FVector& CapsuleBaseLocation = UHiCharacterMathLibrary::GetCapsuleBaseLocation(
		2.0f, CharacterOwner->GetCapsuleComponent());

	const FVector &InitialTraceImpactPoint = ForwardHitResult.ImpactPoint;
	//const FVector InitialTraceNormal = ForwardHitResult.ImpactNormal;
	FVector DownwardTraceStart = InitialTraceImpactPoint;
	DownwardTraceStart.Z = (CapsuleBaseLocation.Z + CapsuleHalfHeight + JumpAssistTraceSettings.ExtendHeightAbove);
	DownwardTraceStart += TraceDirection * JumpAssistTraceSettings.LandOffset;

	FVector DownwardTraceEnd = DownwardTraceStart;
	DownwardTraceEnd.Z -= JumpAssistTraceSettings.ExtendHeightBelow;
	
	{
		const bool bHit = World->SweepSingleByProfile(HitResult, DownwardTraceStart, DownwardTraceEnd, FQuat::Identity,
													  WalkableSurfaceDetectionProfileName, CapsuleCollisionShape,
													  Params);
		if (!HitResult.IsValidBlockingHit())
		{
			// Not a valid surface to mantle
			return false;
		}
		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
														   DownwardTraceStart,
														   DownwardTraceEnd,
														   CapsuleCollisionShape,
														   EDrawDebugTrace::Type::ForDuration,
														   bHit,
														   HitResult,
														   FLinearColor::Red,
														   FLinearColor::Yellow,
														   10.0f);
		}	

	}

	FVector Delta = HitResult.Location - ActorLocation;
	FVector DeltaXY(Delta.X, Delta.Y, 0);
	//FVector DeltaZ(0, 0, Delta.Z);
	float Duration = DeltaXY.Size() / VelocityXY.Size();

	float HeightDelta = Velocity.Z * Duration +  0.5 * Gravity * Duration * Duration;
	if (HeightDelta < Delta.Z)
	{
		float NewGravity = (Delta.Z - Velocity.Z * Duration) * 2 / (Duration * Duration);

		if (NewGravity > JumpAssistParams.MaxGravity)
		{
			return false;
		}

		float DesiredVelocityZ = Velocity.Z + Duration * NewGravity;
		if (DesiredVelocityZ > JumpAssistParams.MaxDesiredVelocityZ)
		{
			return false;
		}

		bChangeGravity = true;
		HiCharacterMovementComponent->GravityScale = NewGravity / Gravity * HiCharacterMovementComponent->GravityScale;
		// UE_LOG(LogJump, Error, TEXT("UHiJumpComponent::JumpAssistCheck %d %f"), (int32)CharacterOwner->GetWorld()->GetNetMode(), CharacterMovement->GravityScale);
	}
	

	return true;
}

bool UHiJumpComponent::IsValidLanding_Implementation()
{
	if (JumpState != EHiJumpState::Jump)
	{
		return true;
	}
	// Do not trigger landing during the jump up process
	float CurveValue = CharacterOwner->GetAnimCurveValue(JumpUpCurveName);
	if (CurveValue > UE_SMALL_NUMBER)
	{
		return false;
	}
	return true;
}
