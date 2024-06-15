// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiVehicleMovementComponent.h"
#include "Components/CapsuleComponent.h"
#include "Kismet/KismetSystemLibrary.h"

#define NOT_EQUAL_ZERO(A)   (abs(A) > 0.0001f)
#define SGN(A) (A >= 0? 1 : -1)

DEFINE_LOG_CATEGORY_STATIC(LogVehicleMovement, Log, All);

void UHiVehicleMovementComponent::BeginPlay()
{
	Super::BeginPlay();
	CashedMaxStepHeight = MaxStepHeight;
	MaxStepHeight = 0;
}

void UHiVehicleMovementComponent::SetMovementSettings(FHiMovementSettings NewMovementSettings)
{
	// Set the current movement settings from the owner
	CurrentMovementSettings = NewMovementSettings;
	OnMovementSettingsChanged();
}

void UHiVehicleMovementComponent::SetSpeedScale(float speedScale)
{
	SpeedScale = speedScale;
	OnMovementSettingsChanged();
}

float UHiVehicleMovementComponent::GetSpeedScale() const
{
	return SpeedScale;
}

void UHiVehicleMovementComponent::OnMovementSettingsChanged()
{
	// Set Movement Settings
	const float UpdateMaxWalkSpeed = CurrentMovementSettings.GetSpeedForGait(AllowedGait) * SpeedScale;

	MaxWalkSpeed = UpdateMaxWalkSpeed;
	MaxWalkSpeedCrouched = UpdateMaxWalkSpeed;
}

void UHiVehicleMovementComponent::SetAllowedGait(EHiGait NewAllowedGait)
{
	if (AllowedGait != NewAllowedGait)
	{
		AllowedGait = NewAllowedGait;
		OnMovementSettingsChanged();

		if (PawnOwner->IsLocallyControlled())
		{
			if (GetCharacterOwner() && GetCharacterOwner()->GetLocalRole() == ROLE_AutonomousProxy)
			{
				Server_SetAllowedGait(NewAllowedGait);
			}
		}
	}
}

void UHiVehicleMovementComponent::Server_SetAllowedGait_Implementation(EHiGait NewAllowedGait)
{
	SetAllowedGait(NewAllowedGait);
}


void UHiVehicleMovementComponent::ChangeRootMotionOverrideType(UObject* OwnerObject,
	EHiRootMotionOverrideType NewRootMotionOverrideType)
{
	RootMotionOverrideType = NewRootMotionOverrideType;
	RootMotionOverrideTypePendingList.Add(TPair<UObject*, EHiRootMotionOverrideType>(OwnerObject, NewRootMotionOverrideType));
}

void UHiVehicleMovementComponent::ResetRootMotionOverrideTypeToDefault(UObject* OwnerObject)
{
	for (int32 Index = 0; Index < RootMotionOverrideTypePendingList.Num(); ++Index)
	{
		if (RootMotionOverrideTypePendingList[Index].Key == OwnerObject)
		{
			RootMotionOverrideTypePendingList.RemoveAt(Index);
			break;
		}
	}
	if (RootMotionOverrideTypePendingList.Num())
	{
		RootMotionOverrideType = RootMotionOverrideTypePendingList.Last().Value;
	}
	else
	{
		RootMotionOverrideType = DefaultRootMotionOverrideType;
	}
}

bool UHiVehicleMovementComponent::CanAttemptJump() const
{
	return IsJumpAllowed() &&
		   !bWantsToCrouch && IsMovingOnGround();
}

bool UHiVehicleMovementComponent::StepUp(const FVector& GravDir, const FVector& Delta, const FHitResult& Hit,
	FStepDownResult* OutStepDownResult)
{
	MaxStepHeight = CashedMaxStepHeight;
	bool ret = Super::StepUp(GravDir, Delta, Hit, OutStepDownResult);
	MaxStepHeight = 0;
	return ret;
}

void UHiVehicleMovementComponent::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)

{
#if WITH_EDITOR
	if(FixDeltaTime)
	{
		DeltaTime = FixDeltaTime;
	}
	if(JustUpdateOwnerClient)
	{
		if (CharacterOwner->GetLocalRole() != ROLE_Authority || CharacterOwner->GetNetMode() != NM_Client)
		{
			return;
		}
	}
#endif

	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
}

void UHiVehicleMovementComponent::ControlledCharacterMove(const FVector& InputVector, float DeltaSeconds)
{
	Super::ControlledCharacterMove(InputVector, DeltaSeconds);
	UpdateCharacterRotation(DeltaSeconds);
#if WITH_EDITOR
	if(EnableDraw)
	{
		const UWorld * MyWorld = GetWorld();
		if (!MyWorld)
		{
			return;
		}
		if (CharacterOwner->GetLocalRole() != ROLE_Authority || MyWorld->GetNetMode() != NM_Client)
		{
			return;
		}
		const auto Transform = this->UpdatedComponent->GetComponentTransform();
		FVector Location = Transform.GetLocation();
		if ((LastLocation - Location).Size() > 1)
		{
			auto ForwardVector = this->UpdatedComponent->GetForwardVector();
			UKismetSystemLibrary::DrawDebugPoint(MyWorld, Location, 10, FLinearColor::Red, 35.0);
			UKismetSystemLibrary::DrawDebugArrow(MyWorld, Location, Location + ForwardVector * 20, 2.0f, FLinearColor::Red, 35.0);
		}
	}
#endif
	FVector Location = this->UpdatedComponent->GetComponentTransform().GetLocation();
	if((LastLocation - Location).Size() > 0.01)
	{
		LinearVelocity = Location - LastLocation;
		LastLocation = Location;
	}
}

void UHiVehicleMovementComponent::UpdateCharacterRotation(float DeltaTime)
{
	const UWorld * MyWorld = GetWorld();
	if (!MyWorld)
	{
		return;
	}
	if(HasAnimRootMotion() )
	{
		return;
	}
	if (RootMotionOverrideType != EHiRootMotionOverrideType::Default)
	{
		return;
	}
	if (CharacterOwner->GetLocalRole() != ROLE_Authority || MyWorld->GetNetMode() != NM_Client)
	{
		return;
	}
	if (Velocity.IsNearlyZero())
	{
		return;
	}	
	switch (VehicleState)
	{
	case EHiVehicleState::None:break;
	case EHiVehicleState::OnGrounded:
		{
			UpdateRotationOnGround(DeltaTime);
			break;
		};
	case EHiVehicleState::InAir:
		{
			UpdateRotationInAir( DeltaTime);
			break;
		};
	case EHiVehicleState::InTrack:
		{
			UpdateRotationInTrack(DeltaTime);
			break;
		};;
	default:
		{
			VehicleState = EHiVehicleState::None;
			break;
		}
	}
	
	
}

void UHiVehicleMovementComponent::UpdateRotationOnGround(float DeltaTime)
{
	const UWorld * MyWorld = GetWorld();
	if (!MyWorld)
	{
		return;
	}
	FHitResult HeadHitResult;
	FHitResult TailHitResult;
	float PawnRadius, PawnHalfHeight;
	CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleSize(PawnRadius, PawnHalfHeight);
	const auto Transform = this->UpdatedComponent->GetComponentTransform();
	auto ForwardVector = this->UpdatedComponent->GetForwardVector().GetSafeNormal();

	FVector Location = Transform.GetLocation();
	FVector Head = Location + ForwardVector * 40;
	FVector Tail = Location - ForwardVector * 40;
	//FVector Target = Location + FVector(0,0,-1) * (PawnHalfHeight *2);
	float check_down_height = PawnHalfHeight * 2;
	FCollisionQueryParams Params;
	for ( AActor * actor : this->UpdatedPrimitive->GetMoveIgnoreActors())
	{
		Params.AddIgnoredActor(actor);
	}
	Params.AddIgnoredActor(CharacterOwner);
	const ECollisionChannel CollisionChannel = this->UpdatedPrimitive->GetCollisionObjectType();
	const bool HeadHit = MyWorld->LineTraceSingleByChannel(
		HeadHitResult, Head, Head + FVector(0,0,-1) * check_down_height,CollisionChannel, Params
		);
	const bool TailHit = MyWorld->LineTraceSingleByChannel(
		TailHitResult, Tail, Tail + FVector(0,0,-1) * check_down_height,CollisionChannel, Params
		);
	auto AngVelocity = LocalAngularVelocity;
	auto Rotation = CharacterOwner->GetActorRotation();
	float deltaYaw = FMath::RadiansToDegrees(AngVelocity.Z * DeltaTime);
	Rotation.Yaw += deltaYaw;
	float Pitch = 0;
	float CharacterZ = Location.Z - PawnHalfHeight;
	if (HeadHit && TailHit)
	{
		FVector HeadImpactPoint = HeadHitResult.ImpactPoint;
		FVector TailImpactPoint = TailHitResult.ImpactPoint;
		FRotator Rotator = (HeadImpactPoint - TailImpactPoint).Rotation();
		Pitch = Rotator.Pitch;
		//if (abs(Rotation.Pitch - TargetPitch) < 15)
		//{
		//	Pitch = TargetPitch;
		//}
	}
	
	Rotation.Roll = 0;
	VisibilityPitch = FMath::FInterpTo(VisibilityPitch, Pitch, DeltaTime, 5);
	CharacterOwner->SetActorRotation(Rotation);
}

void UHiVehicleMovementComponent::UpdateRotationInAir(float DeltaTime)
{
	auto AngVelocity = LocalAngularVelocity;
	auto Rotation = CharacterOwner->GetActorRotation();
	float deltaYaw = FMath::RadiansToDegrees(AngVelocity.Z * DeltaTime);
	Rotation.Yaw += deltaYaw;
	if (InAirTime > 0.3 && Velocity.Z <=0)
	{
		float Pitch = 0;
		//Rotation.Pitch = FMath::FInterpTo(Rotation.Pitch, Pitch, DeltaTime, 30);
		VisibilityPitch = FMath::FInterpTo(VisibilityPitch, Pitch, DeltaTime, 5);
	}
	CharacterOwner->SetActorRotation(Rotation);
}

void UHiVehicleMovementComponent::UpdateRotationInTrack(float DeltaTime)
{
}

bool UHiVehicleMovementComponent::IsValidLandingSpot(const FVector& CapsuleLocation, const FHitResult& Hit) const
{
	bool bRet = Super::IsValidLandingSpot(CapsuleLocation, Hit);
	if (bRet && !IsValidLanding())
	{
		return false;
	}
	return bRet;
}

bool UHiVehicleMovementComponent::IsValidLanding_Implementation() const
{
	float CurveValue = 0;
	if (const UAnimInstance * AnimInstance = CharacterOwner->GetMesh()->GetAnimInstance())
	{
		CurveValue = AnimInstance->GetCurveValue(JumpUpCurveName);
	}
	if (CurveValue > UE_SMALL_NUMBER)
	{
		return false;
	}
	return true;
}

void UHiVehicleMovementComponent::OnMovementModeChanged(EMovementMode PreviousMovementMode, uint8 PreviousCustomMode)
{
	switch (MovementMode)
	{
	case MOVE_Walking:
		VehicleState = EHiVehicleState::OnGrounded;
		break;
	case MOVE_Falling:
		VehicleState = EHiVehicleState::InAir;
		break;
	default:
		break;
	}
	Super::OnMovementModeChanged(PreviousMovementMode, PreviousCustomMode);
}

FVector UHiVehicleMovementComponent::ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity,
                                                                     const FVector& CurrentVelocity) const
{
	FVector Result = CurrentVelocity;
	switch (RootMotionOverrideType)
	{
	case EHiRootMotionOverrideType::Velocity_ALL:
		{
			Result = RootMotionVelocity;
			break;
		}
	case EHiRootMotionOverrideType::Velocity_Z:
		{
			Result.Z = RootMotionVelocity.Z;
			break;
		}
	case EHiRootMotionOverrideType::Velocity_XY:
		{
			Result.X = RootMotionVelocity.X;
			Result.Y = RootMotionVelocity.Y;
        	break;
		}
	case EHiRootMotionOverrideType::Velocity_Rotation:
		{
			//keep Speed
			const FVector TargetRootMotionVelocity = RootMotionVelocity.GetSafeNormal() * CurrentVelocity.Length();
			Result.X = TargetRootMotionVelocity.X;
			Result.Y = TargetRootMotionVelocity.Y;
			break;
		}
	case EHiRootMotionOverrideType::Local_Velocity_X:
		{
			const auto Transform = this->UpdatedComponent->GetComponentTransform();
			FVector CurrentLocalVelocity = Transform.InverseTransformVector(CurrentVelocity);
			FVector RootMotionLocalVelocity = Transform.InverseTransformVector(RootMotionVelocity);
			Result = CurrentLocalVelocity;
			Result.X = RootMotionLocalVelocity.X;
			Result = Transform.TransformVector(Result);
			//Result = Result.GetSafeNormal() * CurrentVelocity.Length();
			break;
		}
	case EHiRootMotionOverrideType::Default:
		break;
	default:
		break;
	}
	return Result;
}

void UHiVehicleMovementComponent::CalcVelocityOnGround(float DeltaTime, float Friction, bool bFluid,
                                                       float BrakingDeceleration)
{
	InAirTickTimes = 0;
	InAirTime = 0;
	VehicleState= EHiVehicleState::OnGrounded;
	// Do not update velocity when using root motion or when SimulatedProxy and not simulating root motion - SimulatedProxy are repped their Velocity
	if (!HasValidData() || HasAnimRootMotion() || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bWasSimulatingRootMotion))
	{
		return;
	}
	float MaxSpeed = SpeedLimit + ExtraSpeedLimit;
	auto LocalAngularVel = LocalAngularVelocity;
	auto LocalLinearVel = LocalVelocity;
	
	if (RootMotionOverrideType == EHiRootMotionOverrideType::Default)
	{
		float AngularVelYaw = 0;
		if (NOT_EQUAL_ZERO(Steering))
		{
			float Radius = TurnRadiusCurve->GetFloatValue(SpeedMps);
			float R = 0.5 * Radius / Steering;
			AngularVelYaw = SpeedMps  * SGN(SpeedHeadMps)/R;
		}
		else
		{
			AngularVelYaw = FMath::FInterpTo(LocalAngularVel.Z, AngularVelYaw, DeltaTime, AngularInterpSpeed);
		}
		LocalAngularVel.Z = AngularVelYaw;
		SetLocalAngularVelocity(LocalAngularVel);

		// rotation LinearVel
		float damping = 0.f;
		float Yaw = LocalLinearVel.Rotation().Yaw;
		if (SpeedMps > 0.01)
		{
			auto Rotation = LocalLinearVel.Rotation();
			Rotation.Yaw = FMath::FInterpTo(Yaw, 0, DeltaTime, LocalVelRotationInterSpeed);;
			LocalLinearVel = Rotation.Vector().GetSafeNormal() * SpeedMps * 100;
		}
	}
	
	float MPSS = 0; //加速度
	float MaxSpeedMps = MaxSpeed * 0.01;
	if(Accel)
	{
		float x = SpeedMps / MaxSpeedMps;
		MPSS = NormalForwardAccel * 0.01 * AccelerationCurve->GetFloatValue(x) * SpeedUpRatio + ExtraNormalAccel; 
	}
	else
	{
		MPSS = NormalBrakingDeceleration * 0.01 * DecelerationCurve->GetFloatValue(SpeedMps);
		if (Braking)
		{
			MPSS -= Braking * 5;
		}
	}
	if (SteeringTime > 0.3)
	{
		MPSS +=  TurnAccelerationCurve->GetFloatValue(abs(Steering)) * 0.01;
	}

	float NewHeadSpeed = FMath::Max(LocalLinearVel.X + DeltaTime * MPSS * 100 * PowerCoef, 0);
	LocalLinearVel.X = NewHeadSpeed;
	float NewSpeed = LocalLinearVel.Size();
	//NewSpeed = FMath::Max(NewSpeed - FrictionDeceleration * DeltaTime, 0);
	//LocalLinearVel = LocalLinearVel.GetSafeNormal() * NewSpeed;
	
	if (NewSpeed <= ForceStopSpeedInBraking && !Accel)
	{
		LocalLinearVel = FVector::ZeroVector;
	}
	float SpeedXY = LocalLinearVel.Size2D();
	if (SpeedXY > MaxSpeed)
	{
		LocalLinearVel = LocalLinearVel.GetSafeNormal() * (LocalLinearVel.Size() * MaxSpeed/SpeedXY);
	}
	SetLocalVelocity(LocalLinearVel);
}

void UHiVehicleMovementComponent::CalcVelocityInAir(float DeltaTime, float Friction, bool bFluid,
	float BrakingDeceleration)
{
	InAirTime += DeltaTime;
	InAirTickTimes += 1;
	VehicleState= EHiVehicleState::InAir;
	auto LocalAngularVel = LocalAngularVelocity;
	float TargetAngularZ = 0;
	if (NOT_EQUAL_ZERO(Steering))
	{
		TargetAngularZ = AirTurnAngularCurve->GetFloatValue(InputYaw);
	}
	LocalAngularVel.Z = FMath::FInterpTo(LocalAngularVel.Z, TargetAngularZ, DeltaTime, AngularInterpSpeed);
	SetLocalAngularVelocity(LocalAngularVel);
#if WITH_EDITOR
	if (EnableLog)
	{
		UE_LOG(LogTemp, Log, TEXT("CalcVelocityInAir, LocalAngularVelocity Z< %f >"), LocalAngularVelocity.Z);
	}
#endif
	
	// Do not update velocity when using root motion or when SimulatedProxy and not simulating root motion - SimulatedProxy are repped their Velocity
	if (!HasValidData()/* || HasAnimRootMotion()*/ || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bWasSimulatingRootMotion))
	{
		return;
	}

	Friction = FMath::Max(0.f, Friction);
	const float ForwardAccel = InAirForwardAccel;
	float MaxSpeed = SpeedLimit + ExtraSpeedLimit;
	const FVector OldVelocity = Velocity;

	// Check if path following requested movement
	bool bZeroRequestedAcceleration = true;
	FVector RequestedAcceleration = FVector::ZeroVector;
	float RequestedSpeed = 0.0f;
	if (ApplyRequestedMove(DeltaTime, ForwardAccel, MaxSpeed, Friction, BrakingDeceleration, RequestedAcceleration, RequestedSpeed))
	{
		bZeroRequestedAcceleration = false;
	}

	// Path following above didn't care about the analog modifier, but we do for everything else below, so get the fully modified value.
	// Use max of requested speed and max speed if we modified the speed in ApplyRequestedMove above.

	// Zale: The analoginputmodifier adjusts due to acceleration, but after adjusting the upper speed limit, the overall speed will be unstable
	const float MaxInputSpeed = FMath::Max(MaxSpeed, GetMinAnalogSpeed());
	MaxSpeed = FMath::Max(RequestedSpeed, MaxInputSpeed);

	// Apply Braking or deceleration
	const bool bZeroAcceleration = Acceleration.IsZero();
	const bool bVelocityOverMax = IsExceedingMaxSpeed(MaxSpeed);
	const float ActualBrakingFriction = (bUseSeparateBrakingFriction ? BrakingFriction : Friction);
	
	FVector LinearVel = Velocity;
	// Only apply Braking if there is no acceleration, or we are over our max speed and need to slow down to it.
	if (bVelocityOverMax)
	{
		LinearVel = OldVelocity.GetSafeNormal() * MaxSpeed;
	}

	// Apply fluid friction
	if (bFluid)
	{
		LinearVel = LinearVel * (1.f - FMath::Min(Friction * DeltaTime, 1.f));
	}

	// Apply input acceleration
	if (!bZeroAcceleration)
	{
		const float NewMaxInputSpeed = IsExceedingMaxSpeed(MaxInputSpeed) ? LinearVel.Size() : MaxInputSpeed;
		LinearVel += Acceleration * DeltaTime;
		LinearVel = LinearVel.GetClampedToMaxSize(NewMaxInputSpeed);
	}

	// Apply additional requested acceleration
	if (!bZeroRequestedAcceleration)
	{
		const float NewMaxRequestedSpeed = IsExceedingMaxSpeed(RequestedSpeed) ? Velocity.Size() : RequestedSpeed;
		LinearVel += RequestedAcceleration * DeltaTime;
		LinearVel = LinearVel.GetClampedToMaxSize(NewMaxRequestedSpeed);
	}

	if (FVector::DotProduct(LinearVel, UpdatedComponent->GetForwardVector()) < 0.0f)
	{
		LinearVel = FVector(0, 0, OldVelocity.Z);
	}

	if (bUseRVOAvoidance)
	{
		CalcAvoidanceVelocity(DeltaTime);
	}
	//if(InAirFirstTick)
	//{
	//	const FVector Forward = this->UpdatedComponent->GetComponentTransform().GetLocation() - LastLocation;
	//	LinearVel = Forward.GetSafeNormal() * LinearVel.Length();
	//}
	SetVelocity(LinearVel);
}

FVector UHiVehicleMovementComponent::NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity,
	float DeltaTime) const
{
	if (InAirTickTimes == 1) 
	{
		FVector Forward =  this->UpdatedComponent->GetForwardVector();
		FRotator Rotator = FRotator::ZeroRotator ;
		Rotator.Pitch = VisibilityPitch;
		Rotator.Normalize();
		FVector VectorForward = Rotator.RotateVector(Forward);
		float OldSpeed = InitialVelocity.Length();
		FVector Result = VectorForward.GetSafeNormal() * OldSpeed;
		if (Result.Size2D() > 0.0001 )
		{
			//Result.Z *= GravityScale;
			const float scale = OldSpeed / Result.Size2D();
			Result *= scale; // Restore horizontal Speed
			if(Result.ContainsNaN())
			{
				Result = Forward.GetSafeNormal() * OldSpeed;;
			}
		}
		return Result;
	}
	FVector VehicleGravity = Gravity;
	if (GravityScale > 0)
	{
		VehicleGravity *= (1.0/GravityScale);
	}
	return Super::NewFallVelocity(InitialVelocity, VehicleGravity, DeltaTime);
}

void UHiVehicleMovementComponent::CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	
	UpdateInputControl(PawnOwner ? PawnOwner->GetLastMovementInputVector() : FVector::ZeroVector,DeltaTime);
	UpdateLocalSpeed();
	
	switch (MovementMode)
	{
	case MOVE_Walking:
		CalcVelocityOnGround(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	case MOVE_Falling:
		CalcVelocityInAir(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	default:
		Super::CalcVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	}
}

void UHiVehicleMovementComponent::UpdateInputControl(const FVector& InputVector, float DeltaSeconds)
{
	const auto Transform = this->UpdatedComponent->GetComponentTransform();
	const FVector LocalInput = Transform.InverseTransformVector(InputVector);
	InputYaw = LocalInput.Rotation().Yaw;
	if (InputVector.IsNearlyZero())
	{
		Accel = 0;
		Braking = 0; 
	}
	else
	{
		float CosYaw = FMath::Cos( FMath::DegreesToRadians(InputYaw));
		if (  CosYaw > 0)
		{
			Accel = CosYaw;
			Braking = 0;
		}
		else
		{
			Accel = 0;
			Braking = 1;
		}
	}
	LastSteering = Steering;
	Steering = LocalInput.Y;
	
	if (NOT_EQUAL_ZERO(InputYaw))
	{
		if (Steering * LastSteering > 0)
		{
			SteeringTime += DeltaSeconds;
		}
		else
		{
			SteeringTime = DeltaSeconds;
		}
	}
	else
	{

		SteeringTime = 0;
	}
#if WITH_EDITOR
	if (EnableLog)
	{
		UE_LOG(LogTemp, Log, TEXT("ControlledCharacterMove. InputYaw:%f°,Steering : %f -> %f (time:%f), ACC(%f)"),
			InputYaw, LastSteering, Steering, SteeringTime, Accel);
	}
#endif
	
}

void UHiVehicleMovementComponent::UpdateLocalSpeed()
{
	const auto Transform = this->UpdatedComponent->GetComponentTransform();
	LocalVelocity = Transform.InverseTransformVector(Velocity);
	UpdateSpeedProperty();
	//(LogTemp, Log, TEXT("UpdateLocalSpeed %s,  Velocity:<%f, %f, %f>, LocalVelocity:<%f, %f, %f>, VD:%f"),*PawnOwner->GetName(),  Velocity.X, Velocity.Y, Velocity.Z,
	//	LocalVelocity.X, LocalVelocity.Y, LocalVelocity.Z, VdAngle);
}

void UHiVehicleMovementComponent::UpdateSpeedProperty()
{
	VdAngle = LocalVelocity.Rotation().Yaw;
	VdRadian = FMath::DegreesToRadians(VdAngle);
	SpeedMps = Velocity.Size() * 0.01;
	SpeedHeadMps = SpeedMps * cos(VdRadian);
}

void UHiVehicleMovementComponent::SetLocalAngularVelocity(const FVector& _LocalVelocity)
{
	LocalAngularVelocity = _LocalVelocity;
}

void UHiVehicleMovementComponent::SetVelocity(const FVector& _Velocity)
{
	const auto Transform = this->UpdatedComponent->GetComponentTransform();
	Velocity = _Velocity;
	LocalVelocity = Transform.InverseTransformVector(Velocity);
	UpdateSpeedProperty();
}

void UHiVehicleMovementComponent::SetLocalVelocity(const FVector& _LocalVelocity)
{
	LocalVelocity = _LocalVelocity;
	const auto Transform = this->UpdatedComponent->GetComponentTransform();
	Velocity = Transform.TransformVector(LocalVelocity);
	UpdateSpeedProperty();
}

