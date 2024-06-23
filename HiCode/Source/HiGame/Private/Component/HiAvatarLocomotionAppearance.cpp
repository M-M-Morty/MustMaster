// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiAvatarLocomotionAppearance.h"

#include "Characters/HiLocomotionCharacter.h"
#include "Characters/Animation/HiRootMotionModifier.h"
#include "Kismet/KismetMathLibrary.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Component/HiJumpComponent.h"


const FName NAME_AvatarYawOffset(TEXT("YawOffset"));
const FName NAME_AvatarRotationAmount(TEXT("RotationAmount"));
const FName NAME_AvatarLocomotionGraphTag(TEXT("Locomotion"));
const FName NAME_MovementActionGroupName(TEXT("MovementActionGroup"));
const FName NAME_FeetPositionCurve(TEXT("Feet_Position"));

const FName NAME_MontageAction_LeftFoot(TEXT("Left"));
const FName NAME_MontageAction_RightFoot(TEXT("Right"));
DEFINE_LOG_CATEGORY_STATIC(LogAvatarLocomation, Log, All);


/********************************* MovementAppearanceTickFunction *************************************/

void FHiMovementAppearanceTickFunction::ExecuteTick(float DeltaTime, enum ELevelTick TickType, ENamedThreads::Type CurrentThread, const FGraphEventRef& MyCompletionGraphEvent)
{
	FActorComponentTickFunction::ExecuteTickHelper(Target, true, DeltaTime, TickType, [this](float DilatedTime)
	{
		Target->TickMovementAppearance(DilatedTime);
	});
}

FString FHiMovementAppearanceTickFunction::DiagnosticMessage()
{
	if (Target)
	{
		return Target->GetFullName() + TEXT("[ReplicatedMontageTick]");
	}
	return TEXT("<NULL>[ReplicatedMontageTick]");
}

FName FHiMovementAppearanceTickFunction::DiagnosticContext(bool bDetailed)
{
	return FName(TEXT("HiAvatarReplicatedMontageTick"));
}

/********************************* AvatarLocomotionAppearance *************************************/

UHiAvatarLocomotionAppearance::UHiAvatarLocomotionAppearance(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bTickEvenWhenPaused = true;
	PrimaryComponentTick.bAllowTickOnDedicatedServer = true;
	PrimaryComponentTick.TickGroup = TG_PrePhysics;
}

void UHiAvatarLocomotionAppearance::InitializeComponent()
{
	Super::InitializeComponent();

	MyCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(CharacterOwner->GetMovementComponent());
	check(MyCharacterMovementComponent);

	USkeletalMeshComponent* MeshComponent = CharacterOwner->GetMesh();
	check(MeshComponent);
	for (FHiLinkAnimGraphConfig& LinkedAnimGraphConfig : LinkedAnimGraph)
	{
		MeshComponent->LinkAnimGraphByTag(LinkedAnimGraphConfig.Tag, LinkedAnimGraphConfig.AnimBlueprintClass);
	}

	// Setup AppearanceTickFunction
	if (!MovementAppearanceTickFunction.IsTickFunctionRegistered())
	{
		// Order: Movement Tick -> Movement Appearance Tick (New)

		// Correction of performance after movement
		MovementAppearanceTickFunction.Target = this;
		MovementAppearanceTickFunction.bCanEverTick = true;
		MovementAppearanceTickFunction.bTickEvenWhenPaused = true;
		MovementAppearanceTickFunction.bAllowTickOnDedicatedServer = false;
		MovementAppearanceTickFunction.TickGroup = TG_PrePhysics;

		MovementAppearanceTickFunction.AddPrerequisite(MyCharacterMovementComponent, MyCharacterMovementComponent->PrimaryComponentTick);

		SetupActorComponentTickFunction(&MovementAppearanceTickFunction);
	}
}

void UHiAvatarLocomotionAppearance::BeginPlay()
{
	Super::BeginPlay();
}

void UHiAvatarLocomotionAppearance::OnPossessedBy_Implementation(AController* NewController)
{
	// Order: Controller Tick -> Appearance Tick
	PrimaryComponentTick.AddPrerequisite(NewController, NewController->PrimaryActorTick);

	MyCharacterMovementComponent->SetMovementSettings(GetTargetMovementSettings());

	// Cache Values
	PreviousAimingYaw = CharacterOwner->GetActorRotation().Yaw;
}

void UHiAvatarLocomotionAppearance::TickReplicatedMontage(float DeltaTime)
{
	// Replicated logic in #ROLE_AutonomousProxy
	// Needs to be executed between TickInput @ Controller and TickMovement @ MovementComponent
	// It can ensure that the execution sequence on the server side is consistent with that on the client side

	FVector InputVector = CharacterOwner->GetPendingMovementInputVector();
	InputVector.Z = 0;		// Ignore vertical input
	const bool bIsZeroInput = FMath::IsNearlyZero(InputVector.Size());

	if (MovementState != EHiMovementState::Grounded)
	{
		return;
	}
	if (MyCharacterMovementComponent->MovementMode != MOVE_Walking)
	{
		return;
	}
	UAnimInstance* AnimInstance = GetMesh()->GetAnimInstance();
	if (!AnimInstance)
	{
		return;
	}

	// The montage here can only be triggered when running or sprinting
	float AnimGaitValue = AnimInstance->GetCurveValue(TEXT("W_Gait"));
	uint8 LogicRunningValue = static_cast<int8>(EHiGait::Running);

	if (bDelayPlayRollAnimation)
	{
		Replicated_PlayMontage(GetRollAnimation(), 1.0f);
		bDelayPlayRollAnimation = false;
	}

	if (MovementAction == EHiMovementAction::SprintBrake)
	{
		// Check interruption after exiting SprintBrake MovementAction.
		if (!bIsZeroInput && AnimInstance)
		{
			// Transition to sprint animation.
			UAnimMontage* SprintBrakeMontage = GetSprintBrakeAnimation();
			float MontagePosition = AnimInstance->Montage_GetPosition(SprintBrakeMontage);
			Replicated_StopMontage(SprintBrakeMontage, 0.15f);

			if (AnimGaitValue >= LogicRunningValue)
			{
				float DeltaAngle = FMath::FindDeltaAngleDegrees(CharacterOwner->GetActorRotation().Yaw, InputVector.ToOrientationRotator().Yaw);
				if (FMath::Abs(DeltaAngle) > SprintTurnMinimumAngle)
				{
					UAnimMontage* SprintTurnMontage = GetSprintTurnAnimation();
					Replicated_PlayMontage(SprintTurnMontage, 1.0f);
					Replicated_MontageJumpToSection(CalculateMovementActionSection(), SprintTurnMontage);
				}
			}
		}
	}
	else if (MovementAction == EHiMovementAction::SprintTurn)
	{
		float DeltaAngle = FMath::FindDeltaAngleDegrees(CharacterOwner->GetActorRotation().Yaw, InputVector.ToOrientationRotator().Yaw);
		// Check interruption after exiting SprintTurn MovementAction.
		if (!bIsZeroInput && !(bEnableMoveInterruptionConstraint && FMath::Abs(DeltaAngle) <= MoveInterruptionConstraintAngle))
		{
			// Transition to sprint animation.
			Replicated_StopMontage(GetSprintTurnAnimation(), 0.1f);
		}
	}
	else if (MovementAction == EHiMovementAction::None && !bIsInSkillAnim && AnimGaitValue >= LogicRunningValue)
	{
		// Check entry for sprint brake
		if (bIsZeroInput && PreviousVelocity.Size() > SprintActionMinimumVelocity)
		{
			//UE_LOG(LogTemp, Warning, L"[ZL] entry brake %.2f", AnimGaitValue);
			UAnimMontage* SprintBrakeMontage = GetSprintBrakeAnimation();
			Replicated_PlayMontage(SprintBrakeMontage, 1.0f);
			Replicated_MontageJumpToSection(CalculateMovementActionSection(), SprintBrakeMontage);
		}
		// Check entry for sprint turn
		if (!bIsZeroInput && PreviousVelocity.Size() > SprintActionMinimumVelocity)
		{
			float DeltaAngle = FMath::FindDeltaAngleDegrees(CharacterOwner->GetActorRotation().Yaw, InputVector.ToOrientationRotator().Yaw);
			if (FMath::Abs(DeltaAngle) > SprintTurnMinimumAngle)
			{
				//UE_LOG(LogTemp, Warning, L"[ZL] entry turn %.2f", AnimGaitValue);
				UAnimMontage* SprintTurnMontage = GetSprintTurnAnimation();
				Replicated_PlayMontage(SprintTurnMontage, 1.0f);
				Replicated_MontageJumpToSection(CalculateMovementActionSection(), SprintTurnMontage);
			}
		}
	}
}

void UHiAvatarLocomotionAppearance::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	check(CharacterOwner);
	if (CharacterOwner->IsLocallyControlled())
	{
		CharacterOwner->CheckJumpInput(DeltaTime);
		TickReplicatedMontage(DeltaTime);
	}
	TickLocomotion(DeltaTime);
}

void UHiAvatarLocomotionAppearance::TickLocomotion(float DeltaTime)
{
	if (DeltaTime <= SMALL_NUMBER)
	{
		return;
	}

	if (GetOwnerRole() == ENetRole::ROLE_Authority && CharacterOwner->GetNetMode() != NM_Standalone)
	{
		// Do nothing on server Tick
		return;
	}

	TickCharacterState(DeltaTime);
}

void UHiAvatarLocomotionAppearance::TickCharacterState(float DeltaTime)
{
	float OldCharacterYaw = CharacterOwner->GetActorRotation().Yaw;
	SetEssentialValues(DeltaTime);

	switch (MovementState)
	{
	case EHiMovementState::Grounded:
		UpdateCharacterMovement();
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::InAir:
		UpdateCharacterRotation(DeltaTime);
		break;
	case EHiMovementState::Ragdoll:
		RagdollUpdate(DeltaTime);
		break;
	case EHiMovementState::Ride:
		RideUpdate(DeltaTime);
		break;
	case EHiMovementState::Custom:
		break;
	default:
		break;
	}
	
	// Cache values
	PreviousVelocity = CharacterOwner->GetVelocity();
	// DeltaAimYaw update should be delayed, to match the camera rotation exactly
	float DeltaAimYaw = FMath::FindDeltaAngleDegrees(PreviousAimingYaw, AimingRotation.Yaw);
	PreviousAimingYaw = AimingRotation.Yaw;
	// Set the Aim Yaw rate by comparing the current and previous Aim Yaw value, divided by Delta Seconds.
	// This represents the speed the camera is rotating left to right.
	AimYawRate = FMath::Abs((DeltaAimYaw) / DeltaTime);

	if(bHasCacheBones)
	{
		CacheBoneTransforms();
	}
}

void UHiAvatarLocomotionAppearance::SetEssentialValues(float DeltaTime)
{
	if(CharacterOwner->GetNetMode() == NM_Standalone)
	{
		FVector InputVector = CharacterOwner->GetPendingMovementInputVector();
		InputVector.Z = 0;		// Ignore vertical input
		MovementInputAmount = InputVector.Size();

		ReplicatedControlRotation = CharacterOwner->GetControlRotation();
		EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration();
		ReplicatedCurrentAcceleration = InputVector * EasedMaxAcceleration;
	}
	else
	{
		// 1st. Gather #MovementInput related parameters
		switch (CharacterOwner->GetLocalRole())
		{
		case ROLE_SimulatedProxy:
			{
				// #ReplicatedControlRotation & #ReplicatedCurrentAcceleration have been Set from Replicated
				EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration() != 0
					? CharacterOwner->GetCharacterMovement()->GetMaxAcceleration()
					: EasedMaxAcceleration / 2;
				// Determine if the character has movement input by getting its movement input amount.
				// The Movement Input Amount is equal to the current acceleration divided by the max acceleration so that
				// it has a range of 0-1, 1 being the maximum possible amount of input, and 0 being none.
				// If the character has movement input, update the Last Movement Input Rotation.
				MovementInputAmount = ReplicatedCurrentAcceleration.Size() / EasedMaxAcceleration;
				break;
			}
		case ROLE_AutonomousProxy:
			{
				// AutonomousProxy can get input vector
				FVector InputVector = CharacterOwner->GetPendingMovementInputVector();
				InputVector.Z = 0;		// Ignore vertical input
				MovementInputAmount = InputVector.Size();

				ReplicatedControlRotation = CharacterOwner->GetControlRotation();
				EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration();
				ReplicatedCurrentAcceleration = InputVector * EasedMaxAcceleration;
				break;
			}
		case ROLE_Authority:
			{
				// #ReplicatedCurrentAcceleration has been Set from PresetEssentialValues
				ReplicatedControlRotation = CharacterOwner->GetControlRotation();
				EasedMaxAcceleration = CharacterOwner->GetCharacterMovement()->GetMaxAcceleration();
				// Same as ROLE_SimulatedProxy
				MovementInputAmount = ReplicatedCurrentAcceleration.Size() / EasedMaxAcceleration;
				break;
			}
		default:
			break;
		}
	}
	
	bool bOldMovementInput = bHasMovementInput;
	bHasMovementInput = !FMath::IsNearlyZero(MovementInputAmount);
	if (bHasMovementInput)
	{
		LastMovementInputRotation = ReplicatedCurrentAcceleration.ToOrientationRotator().Clamp();
	}
	if (bOldMovementInput != bHasMovementInput && MovementInputChangedDelegate.IsBound())
	{
		MovementInputChangedDelegate.Broadcast(bHasMovementInput);
	}

	// Interp AimingRotation to current control rotation for smooth character rotation movement. Decrease InterpSpeed
	// for slower but smoother movement.
	FRotator TargetRotator = ReplicatedControlRotation;
	if (MovementState == EHiMovementState::Grounded || InAirState == EHiInAirState::Falling)
	{
		TargetRotator.Pitch = AimingRotation.Pitch;
	}
	//AimingRotation = FMath::RInterpTo(AimingRotation, TargetRotator, DeltaTime, 30);
	AimingRotation = TargetRotator;

	// These values represent how the capsule is moving as well as how it wants to move, and therefore are essential
	// for any data driven animation system. They are also used throughout the system for various functions,
	// so I found it is easiest to manage them all in one place.

	const FVector CurrentVel = CharacterOwner->GetVelocity();

	// Set the amount of Acceleration.
	const FVector NewAcceleration = (CurrentVel - PreviousVelocity) / DeltaTime;
	Acceleration = NewAcceleration.IsNearlyZero() || CharacterOwner->IsLocallyControlled() ? NewAcceleration : Acceleration / 2;

	// Parameters of physical movement
	PhyxMovementStatus = MyCharacterMovementComponent->PhyxMovementStatus;

	// Determine if the character is moving by getting it's speed. The Speed equals the length of the horizontal (x y)
	// velocity, so it does not take vertical movement into account. If the character is moving, update the last
	// velocity rotation. This value is saved because it might be useful to know the last orientation of movement
	// even after the character has stopped.
	Speed = CurrentVel.Size2D();
	if (PhyxMovementStatus.bIsHorizontalSliding)
	{
		Speed = MyCharacterMovementComponent->GetGaitSpeedInSettings(DesiredGait);
	}
	SetIsMoving(Speed > 1.0f);
	if (bIsMoving)
	{
		LastVelocityRotation = CurrentVel.ToOrientationRotator().Clamp();
	}

	Speed3D = CurrentVel.Length();
}

void UHiAvatarLocomotionAppearance::PresetEssentialValues(float DeltaTime, FVector InputAcceleration)
{
	ReplicatedCurrentAcceleration = InputAcceleration;
	TickCharacterState(DeltaTime);
}

FName UHiAvatarLocomotionAppearance::CalculateMovementActionSection()
{
	const float FeetPosition = GetAnimCurveValue(NAME_FeetPositionCurve);
	FName SectionName = NAME_MontageAction_RightFoot;
	if (FeetPosition < 0)
	{
		SectionName = NAME_MontageAction_LeftFoot;
	}
	return SectionName;
}

void UHiAvatarLocomotionAppearance::RideUpdate(float DeltaTime)
{
	
}

void UHiAvatarLocomotionAppearance::WalkAction_Implementation()
{
	if (BasicSlowMoveGait == EHiGait::Walking)
	{
		BasicSlowMoveGait = EHiGait::Running;
	}
	else if (BasicSlowMoveGait == EHiGait::Running)
	{
		BasicSlowMoveGait = EHiGait::Walking;
	}
	if (!bIsInSprint)
	{
		SetDesiredGait(BasicSlowMoveGait);
	}
}

void UHiAvatarLocomotionAppearance::SprintAction_Implementation(bool bValue)
{
	bIsInSprint = bValue;
	if (bValue)
	{
		SetDesiredGait(EHiGait::Sprinting);
	}
	else
	{
		SetDesiredGait(BasicSlowMoveGait);
	}
}

void UHiAvatarLocomotionAppearance::Replicated_InterruptMovementAction(float InBlendOutTime/* = 0.0f*/)
{
	Replicated_StopMontageGroup(NAME_MovementActionGroupName, InBlendOutTime);
}

void UHiAvatarLocomotionAppearance::OnBreakfall_Implementation()
{
	if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy)
	{
		bDelayPlayRollAnimation = true;
	}
}

void UHiAvatarLocomotionAppearance::EnterSkillAnim_Implementation()
{
	Super::EnterSkillAnim_Implementation();
	Replicated_InterruptMovementAction();
}

void UHiAvatarLocomotionAppearance::LeaveSkillAnim_Implementation()
{
	Super::LeaveSkillAnim_Implementation();
}

void UHiAvatarLocomotionAppearance::RagdollStart()
{
	Super::RagdollStart();
}

void UHiAvatarLocomotionAppearance::RagdollEnd()
{
	Super::RagdollEnd();
}

ECollisionChannel UHiAvatarLocomotionAppearance::GetThirdPersonTraceParams(FVector& TraceOrigin, float& TraceRadius)
{
	TraceOrigin = GetMesh()->GetSocketLocation(CameraSocketName);
	TraceRadius = 15.0f;
	return ECC_Camera;
}

FTransform UHiAvatarLocomotionAppearance::GetThirdPersonPivotTarget()
{
	float Alpha = 0.f;
	FTransform AdjustmentBoneTransform;
	FVector Location;
	if (CameraBoneName != NAME_None)
	{
		URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::GetAdjustmentBoneTransformAndAlpha(CharacterOwner, CameraBoneName, AdjustmentBoneTransform, Alpha);

		if (Alpha != 1.f)
		{
			Location = GetMesh()->GetSocketTransform(CameraBoneName).GetLocation();
			LastThirdPersonPivotTarget = Location;
			//UE_LOG(LogAvatarLocomation, Error, TEXT("UHiAvatarLocomotionAppearance::GetThirdPersonPivotTarget 111 %s AdjustmentBoneTransform = %s, Mesh = %s, Original = %s, %s, Root = %s"), *CameraBoneName.ToString(), *Location.ToString(), *GetMesh()->GetComponentTransform().GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName).GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName, RTS_ParentBoneSpace).GetLocation().ToString(), *GetMesh()->GetSocketTransform("root_jnt").GetLocation().ToString());

		}
		else
		{
			Location = LastThirdPersonPivotTarget + AdjustmentBoneTransform.GetLocation();
			LastThirdPersonPivotTarget = Location;
			//UE_LOG(LogAvatarLocomation, Error, TEXT("UHiAvatarLocomotionAppearance::GetThirdPersonPivotTarget 222 AdjustmentBoneTransform = %s, Mesh = %s, Original = %s, %s, Root = %s"), *Location.ToString(), *GetMesh()->GetComponentTransform().GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName).GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName, RTS_ParentBoneSpace).GetLocation().ToString(), *GetMesh()->GetSocketTransform("root_jnt").GetLocation().ToString());
		}
		/*else
		{
			FTransform trans = AdjustmentBoneTransform * GetMesh()->GetComponentTransform();
			UE_LOG(LogAvatarLocomation, Error, TEXT("UHiAvatarLocomotionAppearance::GetThirdPersonPivotTarget AdjustmentBoneTransform = %s, Mesh = %s, WorldSpace = %s, Original = %s, %s, Root = %s"), *AdjustmentBoneTransform.GetLocation().ToString(), *GetMesh()->GetComponentTransform().GetLocation().ToString(), *trans.GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName).GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraBoneName, RTS_ParentBoneSpace).GetLocation().ToString(), *GetMesh()->GetSocketTransform("root_jnt").GetLocation().ToString());
			//AdjustmentBoneTransform = trans;
		}*/
	}
	else
	{
		Location = GetMesh()->GetSocketLocation(CameraSocketName);
		LastThirdPersonPivotTarget = Location;
		//UE_LOG(LogAvatarLocomation, Error, TEXT("UHiAvatarLocomotionAppearance::GetThirdPersonPivotTarget 333 AdjustmentBoneTransform = %s, Mesh = %s, Original = %s, %s, Root = %s"), *Location.ToString(), *GetMesh()->GetComponentTransform().GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraSocketName).GetLocation().ToString(), *GetMesh()->GetSocketTransform(CameraSocketName, RTS_ParentBoneSpace).GetLocation().ToString(), *GetMesh()->GetSocketTransform("root_jnt").GetLocation().ToString());

	}
	return FTransform(CharacterOwner->GetActorRotation(), Location, FVector::OneVector);
}

void UHiAvatarLocomotionAppearance::OnRotationModeChanged(EHiRotationMode PreviousRotationMode)
{
	Super::OnRotationModeChanged(PreviousRotationMode);
	MyCharacterMovementComponent->SetMovementSettings(GetTargetMovementSettings());
}

void UHiAvatarLocomotionAppearance::OnSpeedScaleChanged(float PrevSpeedScale)
{
	Super::OnSpeedScaleChanged(PrevSpeedScale);
	
	if (MyCharacterMovementComponent->GetSpeedScale() != SpeedScale)
	{
		MyCharacterMovementComponent->SetSpeedScale(SpeedScale);
	}
}

void UHiAvatarLocomotionAppearance::UpdateCharacterMovement()
{
	// Set the Allowed Gait
	EHiGait AllowedGait = GetAllowedGait();

	if (AllowedGait != Gait)
	{
		SetGait(AllowedGait);
	}
	
	// Update the Character Max Walk Speed to the configured speeds based on the currently Allowed Gait.
	MyCharacterMovementComponent->SetAllowedGait(AllowedGait);
}

void UHiAvatarLocomotionAppearance::UpdateCharacterRotation(float DeltaTime)
{
	// Skip update rotation this tick
	if(bSkipUpdateRotation)
	{
		TargetRotation = CharacterOwner->GetActorRotation();
		LastVelocityRotation = TargetRotation;
		bSkipUpdateRotation = false;
		return;
	}
	
	if (bUseCustomRotation && CustomSmoothContext.CustomRotationStage == RotationStage_0)
	{
		SmoothCustomRotation(DeltaTime);
		return;
	}
	
	if (bIsInSkillAnim)
	{
		return;	
	}

	if (bUseCustomRotation && CustomSmoothContext.CustomRotationStage == RotationStage_1)
	{
		SmoothCustomRotation(DeltaTime);
		return;
	}

	//auto owner = CharacterOwner.Get();
	if (MovementAction == EHiMovementAction::None)
	{
		if (InAirState == EHiInAirState::Falling)
		{
			// The game designer said it is forbidden to change the direction when jumping into the air

			// To ensure when falling, character pith and roll be normal.
			FRotator Rotation = CharacterOwner->GetActorRotation();
			float TargetInterpSpeed = 1.0f;
			float ActorInterpSpeed = 1e8f;	// Rotate charater immediately
			if (RotationMode == EHiRotationMode::VelocityDirection)
			{
				TargetInterpSpeed = 800.0f;
			}
			else if (RotationMode == EHiRotationMode::LookingDirection)
			{
				TargetInterpSpeed = 500.0f;
			}
			else if (RotationMode == EHiRotationMode::Aiming)
			{
				TargetInterpSpeed = 1000.0f;
				ActorInterpSpeed = 20.0f;
			}
			Rotation.Pitch = 0.0f;
			Rotation.Roll = 0.0f;
			SmoothCharacterRotation(Rotation, TargetInterpSpeed * RotationSpeedScale, ActorInterpSpeed * RotationSpeedScale, DeltaTime);
		}
		else if (bHasMovementInput)
		{
			//bUseCustomRotation = false;
			FRotator Rotation;
			float TargetInterpSpeed = 1.0f;
			float ActorInterpSpeed = 1.0f;
			if (RotationMode == EHiRotationMode::VelocityDirection)
			{
				//if (CharacterOwner->HasAnyRootMotion())
				//{
				//	// The velocity orientation is invalid in Root Motion, so it needs to be replaced by the MovementInputRotation.
				//	Rotation = { LastMovementInputRotation.Pitch, LastMovementInputRotation.Yaw, 0.0f };
				//	TargetInterpSpeed = 500.0f;
				//	ActorInterpSpeed = 15.0f;
				//}
				//else
				{
					// If character hit a wall, the character needs to face the movement input direction, not the velocity direction
					Rotation = { LastVelocityRotation.Pitch, LastMovementInputRotation.Yaw, 0.0f };
					ActorInterpSpeed = TargetInterpSpeed = 1e8f;	// Rotate charater immediately
				}
			}
			else if (RotationMode == EHiRotationMode::LookingDirection)
			{
				// Looking Direction Rotation
				float YawValue;
				if (Gait == EHiGait::Sprinting)
				{
					YawValue = LastVelocityRotation.Yaw;
				}
				else
				{
					// Walking or Running..
					const float YawOffsetCurveVal = GetAnimCurveValue(NAME_AvatarYawOffset);
					YawValue = AimingRotation.Yaw + YawOffsetCurveVal;
				}
				Rotation = {0, YawValue, 0.0f};
				TargetInterpSpeed = 500.0f;
			}
			else if (RotationMode == EHiRotationMode::Aiming)
			{
				Rotation = {AimingRotation.Pitch, AimingRotation.Yaw, 0.0f};
				TargetInterpSpeed = 1000.0f;
				ActorInterpSpeed = 20.0f;
			}
			if (MovementState == EHiMovementState::Grounded || InAirState == EHiInAirState::Falling || InAirState == EHiInAirState::Fly)
			{
				Rotation.Pitch = 0.0f;
			}
			SmoothCharacterRotation(Rotation, TargetInterpSpeed * RotationSpeedScale, ActorInterpSpeed * RotationSpeedScale, DeltaTime);
		}
		else
		{
			if (MovementState == EHiMovementState::Grounded /*|| InAirState == EHiInAirState::Falling*/)
			{
				FRotator Rotation = CharacterOwner->GetActorRotation();
				if (!FMath::IsNearlyZero(Rotation.Pitch))
				{
					float TargetInterpSpeed = 1.0f;
					float ActorInterpSpeed = 1e8f;	// Rotate charater immediately
					if (RotationMode == EHiRotationMode::VelocityDirection)
					{
						TargetInterpSpeed = 800.0f;
					}
					else if (RotationMode == EHiRotationMode::LookingDirection)
					{
						TargetInterpSpeed = 500.0f;
					}
					else if (RotationMode == EHiRotationMode::Aiming)
					{
						TargetInterpSpeed = 1000.0f;
						ActorInterpSpeed = 20.0f;
					}
					Rotation.Pitch = 0.0f;
					SmoothCharacterRotation(Rotation, TargetInterpSpeed * RotationSpeedScale, ActorInterpSpeed * RotationSpeedScale, DeltaTime);
				}
			}
			
			if (bUseCustomRotation && CustomSmoothContext.CustomRotationStage == RotationStage_2)
			{
				SmoothCustomRotation(DeltaTime);
				return;
			}

			// Apply the RotationAmount curve from Turn In Place Animations.
			// The Rotation Amount curve defines how much rotation should be applied each frame,
			// and is calculated for animations that are animated at 30fps.

			const float RotAmountCurve = GetAnimCurveValue(NAME_AvatarRotationAmount);

			if (FMath::Abs(RotAmountCurve) > 0.001f)
			{
				if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy)
				{
					TargetRotation.Yaw = UKismetMathLibrary::NormalizeAxis(
						TargetRotation.Yaw + (RotAmountCurve * (DeltaTime / (1.0f / 30.0f))));
					CharacterOwner->SetActorRotation(TargetRotation);
				}
				else
				{
					CharacterOwner->AddActorWorldRotation({0, RotAmountCurve * (DeltaTime / (1.0f / 30.0f)), 0});
				}
				TargetRotation = CharacterOwner->GetActorRotation();
			}
		}
	}
	else if (MovementAction == EHiMovementAction::Rolling)
	{
		// Rolling Rotation (Not allowed on networked games)
		if (!bEnableNetworkOptimizations && bHasMovementInput)
		{
			SmoothCharacterRotation({0.0f, LastMovementInputRotation.Yaw, 0.0f}, 0.0f, 2.0f * RotationSpeedScale, DeltaTime);
		}
	}

	// Other actions are ignored...
}

void UHiAvatarLocomotionAppearance::OnMovementActionChanged(EHiMovementAction PreviousAction)
{
	Super::OnMovementActionChanged(PreviousAction);
	//if (MovementAction == EHiMovementAction::SprintTurn)
	//{
	//	FRotator OwnerOrientation = CharacterOwner->GetActorRotation();
	//	OwnerOrientation.Yaw = (OwnerOrientation.Yaw < 0) ? OwnerOrientation.Yaw + 180 : OwnerOrientation.Yaw - 180;
	//	CharacterOwner->SetActorRotation(OwnerOrientation);
	//}
}

void UHiAvatarLocomotionAppearance::SetMoveInterruptionConstraint(bool Enabled, float ConstraintAngle/* = 0.0f*/)
{ 
	bEnableMoveInterruptionConstraint = Enabled;
	MoveInterruptionConstraintAngle = ConstraintAngle;
}

void UHiAvatarLocomotionAppearance::SetSkipUpdateRotation()
{
	bSkipUpdateRotation = true;
}

void UHiAvatarLocomotionAppearance::TickMovementAppearance(float DeltaTime)
{
	USkeletalMeshComponent* MeshComponent = CharacterOwner->GetMesh();
	if (!MeshComponent)
	{
		return;
	}
	if (HeightCorrection_MaxCorrectHeight < UE_KINDA_SMALL_NUMBER)
	{
		// shut down
		return;
	}

	const UPrimitiveComponent* MovementBase = CharacterOwner->GetMovementBase();
	const bool bUseRelativeLocation = MovementBaseUtility::UseRelativeLocation(MovementBase);
	const bool bNonVerticalMotionAction = bool(MovementAction != EHiMovementAction::LowMantle && MovementAction != EHiMovementAction::HighMantle
		&& MovementAction != EHiMovementAction::Ride && MovementAction != EHiMovementAction::GettingUp);

	// Status check
	if (MovementState == EHiMovementState::Grounded && bNonVerticalMotionAction && !bUseRelativeLocation && HeightCorrection_AverageNormal.Z > UE_KINDA_SMALL_NUMBER)
	{
		const FVector CurrentActorLocation = CharacterOwner->GetActorLocation();
		const FVector CurrentFloorNormal = MyCharacterMovementComponent->CurrentFloor.HitResult.Normal;

		if (HeightCorrection_GroundedDuration > HeightCorrection_StartupInterval)
		{
			FVector HorizontalMovement = CurrentActorLocation - HeightCorrection_PreviousLocation;
			HorizontalMovement.Z = 0.0f;
			const float VerticalProjectMovement = -(HorizontalMovement | HeightCorrection_AverageNormal) / HeightCorrection_AverageNormal.Z;
			const float ActorHeightMovement = CurrentActorLocation.Z - HeightCorrection_PreviousLocation.Z;

			HeightCorrection_LeftHeightCorrection -= (ActorHeightMovement * VerticalProjectMovement < 0) ? ActorHeightMovement : ActorHeightMovement - VerticalProjectMovement;
		}
		else
		{
			HeightCorrection_GroundedDuration += DeltaTime;
		}

		if (DeltaTime - HeightCorrection_AverageNormalInterval > UE_KINDA_SMALL_NUMBER)
		{
			HeightCorrection_AverageNormal = CurrentFloorNormal;
		}
		else
		{
			HeightCorrection_AverageNormal = (HeightCorrection_AverageNormal * (HeightCorrection_AverageNormalInterval - DeltaTime) + CurrentFloorNormal * DeltaTime) / HeightCorrection_AverageNormalInterval;
		}
		HeightCorrection_PreviousLocation = CurrentActorLocation;
	}
	else
	{
		HeightCorrection_GroundedDuration = 0.0f;
		HeightCorrection_AverageNormal = FVector::UpVector;
	}

	if (!FMath::IsNearlyZero(HeightCorrection_LeftHeightCorrection))
	{
		// Initial smooth velocity
		if (HeightCorrection_UnmodifiedDuration > HeightCorrection_StartupInterval)
		{
			// Ensure that smaller steps can exist for a relatively smooth time
			HeightCorrection_UnmodifiedDuration = 0.0f;		// Clear Timer
			HeightCorrection_CorrectVelocity = FMath::Clamp(FMath::Abs(HeightCorrection_LeftHeightCorrection / HeightCorrection_SmoothDuration), HeightCorrection_MinSpeed, HeightCorrection_BaseSpeed);
		}

		float LeftHeightCorrectionDuration = FMath::Abs(HeightCorrection_LeftHeightCorrection / HeightCorrection_CorrectVelocity);

		if (LeftHeightCorrectionDuration > HeightCorrection_SmoothDuration)
		{
			// Accelerate to ensure relative position during continuous step up
			HeightCorrection_CorrectVelocity += HeightCorrection_Acceleration * DeltaTime;
		}
		else if (HeightCorrection_LeftHeightCorrection > -HeightCorrection_StartDecelerationHeight
			&& HeightCorrection_CorrectVelocity > HeightCorrection_BaseSpeed && LeftHeightCorrectionDuration < HeightCorrection_SmoothDuration)
		{
			// Slow down to ensure speed is not too fast
			HeightCorrection_CorrectVelocity = FMath::Max(HeightCorrection_CorrectVelocity - HeightCorrection_Acceleration * DeltaTime, HeightCorrection_BaseSpeed);
		}

		if (HeightCorrection_LeftHeightCorrection < 0)
		{
			// Step up
			HeightCorrection_LeftHeightCorrection = FMath::Min(HeightCorrection_LeftHeightCorrection + HeightCorrection_CorrectVelocity * DeltaTime, 0.0f);
		}
		else if (HeightCorrection_LeftHeightCorrection > 0)
		{
			// Step down
			HeightCorrection_LeftHeightCorrection = FMath::Max(HeightCorrection_LeftHeightCorrection - HeightCorrection_CorrectVelocity * DeltaTime, 0.0f);
		}

		HeightCorrection_LeftHeightCorrection = FMath::Clamp(HeightCorrection_LeftHeightCorrection, -HeightCorrection_MaxCorrectHeight, HeightCorrection_MaxCorrectHeight);

		// Todo: 这个要挪到动画图里面计算，这种改骨骼数据，又慢又不推荐
		// 代码太丑陋了，一定要改
		const FVector LocationCorrection = FVector(0, 0, HeightCorrection_LeftHeightCorrection);
		const TArray<FTransform>& EditTransforms = MeshComponent->GetComponentSpaceTransforms();
		TArray<FTransform>* EditTransformsPtr = const_cast<TArray<FTransform>*>(&EditTransforms);
		for (FTransform& EditTransform : *EditTransformsPtr)
		{
			EditTransform.SetLocation(EditTransform.GetLocation() + LocationCorrection);
		}
	}
	else
	{
		HeightCorrection_UnmodifiedDuration = FMath::Min(HeightCorrection_UnmodifiedDuration, HeightCorrection_StartupInterval) + DeltaTime;
	}
}

void UHiAvatarLocomotionAppearance::PostTransfer()
{
	Super::PostTransfer();
	SetGait(GetAllowedGait(), true);

	MyCharacterMovementComponent->UpdateWalkSpeed();
}
