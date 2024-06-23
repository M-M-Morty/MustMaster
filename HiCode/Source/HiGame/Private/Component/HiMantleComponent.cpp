// Fill out your copyright notice in the Description page of Project Settings.

#include "Component/HiMantleComponent.h"


#include "MotionWarpingComponent.h"
#include "Component/HiCharacterDebugComponent.h"
#include "Component/HiJumpComponent.h"
#include "Curves/CurveVector.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/KismetMathLibrary.h"
#include "Characters/HiCharacter.h"
#include "Characters/HiCharacterMathLibrary.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Component/HiAvatarLocomotionAppearance.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/PlayerController.h"
#include "Utils/MathHelper.h"


const FName NAME_MantleEnd(TEXT("MantleEnd"));
const FName NAME_MantleUpdate(TEXT("MantleUpdate"));
const FName NAME_MantleTimeline(TEXT("MantleTimeline"));

uint8 CC_COLLISION_UP = 1 << 0;
uint8 CC_COLLISION_SIDES = 1 << 1;
uint8 CC_COLLISION_DOWN = 1 << 2;
uint8 CC_COLLISION_LAND = 1 << 3;
uint8 CC_COLLISION_OBSTACLE = 1 << 4;

DEFINE_LOG_CATEGORY_STATIC(LogMantle, Log, All)

FName UHiMantleComponent::NAME_IgnoreOnlyPawnAndRagdoll(TEXT("IgnorePawnAndRagdoll"));


UHiMantleComponent::UHiMantleComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bStartWithTickEnabled = true;

	bWantsInitializeComponent = true;
}

void UHiMantleComponent::InitializeComponent()
{
	Super::InitializeComponent();

	AHiCharacter *CharacterOwner = Cast<AHiCharacter>(GetOwner());
	
	if (!ensureMsgf(CharacterOwner, TEXT("Invalid MantleComponent owner type: %s"), GetOwner() ? *GetOwner()->GetFName().ToString() : TEXT("None")))
	{
		return;
	}

	MyCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(CharacterOwner->GetMovementComponent());

	JumpComponent = CharacterOwner->FindComponentByClass<UHiJumpComponent>();
}

void UHiMantleComponent::BeginPlay()
{
	Super::BeginPlay();

	if (GetOwner())
	{
		OwnerCharacter = Cast<AHiCharacter>(GetOwner());
		if (OwnerCharacter)
		{
			HiCharacterDebugComponent = OwnerCharacter->FindComponentByClass<UHiCharacterDebugComponent>();

			AddTickPrerequisiteActor(OwnerCharacter); // Always tick after owner, so we'll use updated values

			APlayerController *PlayerController = GetWorld()->GetFirstPlayerController();
			if (PlayerController)
			{
				AddTickPrerequisiteActor(PlayerController);
			}

			LocomotionComponent = OwnerCharacter->GetLocomotionComponent();
			if (LocomotionComponent)
			{
				AddTickPrerequisiteComponent(LocomotionComponent); // Always tick after owner, so we'll use updated values	
			}
			
			OwnerCharacter->OnMoveBlockedBy.AddUniqueDynamic(this, &UHiMantleComponent::OnMoveBlockedBy);

			if (OwnerCharacter->GetMovementComponent())
			{
				AddTickPrerequisiteComponent(OwnerCharacter->GetMovementComponent());
			}
		}

		if (!bEnableMantle)
		{
			SetComponentTickEnabledAsync(false);
		}
	}
}

void UHiMantleComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	OwnerCharacter->OnMoveBlockedBy.RemoveDynamic(this, &UHiMantleComponent::OnMoveBlockedBy);
}

bool UHiMantleComponent::CanMantle_Implementation()
{
	return true;
}

EHiWallRunType UHiMantleComponent::CanStartClimb_Implementation(const FHitResult &HitResult)
{
	return EHiWallRunType::None;
}

bool UHiMantleComponent::CanBreakMantle_Implementation()
{
	return true;
}

void UHiMantleComponent::EnableMantle(bool enable)
{
	if (enable)
	{
		SetComponentTickEnabledAsync(true);
	}
	else
	{
		SetComponentTickEnabledAsync(false);
	}

	bEnableMantle = enable;
}

void UHiMantleComponent::CheckClimbType(float DeltaTime)
{
	if (OwnerCharacter->GetWorld()->GetNetMode() == ENetMode::NM_Client || OwnerCharacter->GetWorld()->GetNetMode() == NM_Standalone)
	{
		if (LocomotionComponent && LocomotionComponent->HasMovementInput())
		{
			switch (ClimbType)
			{
			case EHiClimbType::WallRun:
				if (WallRunType == EHiWallRunType::Sprint)
				{
					if (!(bCheckFlyOver && ObstacleCheck(SprintClimbTraceSettings, EDrawDebugTrace::Type::ForDuration)))
					{
						bCheckFlyOver = false;
						ReachRoofCheck(SprintClimbTraceSettings, EDrawDebugTrace::Type::ForDuration);
					}
				}
				else if (WallRunType == EHiWallRunType::Climb)
				{
					if (!(bCheckFlyOver && ObstacleCheck(ClimbTraceSettings, EDrawDebugTrace::Type::ForDuration)))
					{
						bCheckFlyOver = false;
						ReachRoofCheck(ClimbTraceSettings, EDrawDebugTrace::Type::ForDuration);
					}
				}
				break;
			case EHiClimbType::Mantle:
				if (CanBreakMantle())
				{
					MantleCheck(MantleTraceSettings, EDrawDebugTrace::Type::ForDuration);
				}
				break;
			case EHiClimbType::None:
				if (bBlockedByWallThisFrame && (!JumpComponent || JumpComponent->IsValidLanding()))
				{
					GroundCheck(GroundedTraceSettings, EDrawDebugTrace::Type::ForDuration, true);
				}
			default:
				break;
			}
		}
	}
}

void UHiMantleComponent::UpdateClimbType(float DeltaTime)
{
	switch (ClimbType)
	{
	case EHiClimbType::Mantle:
		MantleUpdate(DeltaTime);
		break;
	case EHiClimbType::WallRun:
		ClimbUpdate(DeltaTime);
		break;
	case EHiClimbType::Custom:
		break;
	default:
		break;
	}

	bBlockedByWallThisFrame = false;
}

void UHiMantleComponent::TickComponent(float DeltaTime, ELevelTick TickType,
                                        FActorComponentTickFunction* ThisTickFunction)
{
	if (!bEnableMantle || !OwnerCharacter)
		return;

	FrameDeltaTime = DeltaTime;
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	CheckClimbType(DeltaTime);
	
	UpdateClimbType(DeltaTime);
	
	// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleUpdate_Implementation %d %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *OwnerCharacter->K2_GetActorLocation().ToString());

	
	// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::TickComponent %d Translation = %s, Rotation = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *OwnerCharacter->GetActorLocation().ToString(), *OwnerCharacter->GetActorRotation().ToString());
}

void UHiMantleComponent::StopMantleStartAnim()
{
	UAnimInstance *AnimInstance = OwnerCharacter->GetMesh()->GetAnimInstance();
	if (MantleParams.AnimMontage && AnimInstance)
	{
		FAnimMontageInstance* MontageInstance = AnimInstance->GetActiveInstanceForMontage(MantleParams.AnimMontage);
		if (MontageInstance)
		{
			MontageInstance->OnMontageBlendingOutStarted.Unbind();
			MontageInstance->OnMontageEnded.Unbind();
		}
		OwnerCharacter->StopAnimMontage(MantleParams.AnimMontage);
	}
	MontageEndedDelegate.Unbind();
	MontageBlendingOutDelegate.Unbind();
}

void UHiMantleComponent::OnMoveBlockedBy(const FHitResult& HitResult)
{
	bBlockedByWallThisFrame = true;
	// if (OwnerCharacter->GetWorld()->GetNetMode() == ENetMode::NM_Client || OwnerCharacter->GetWorld()->GetNetMode() == NM_Standalone)
	// {
	// 	if (ClimbType == EHiClimbType::WallRun)
	// 	{
	// 		// UCapsuleComponent *CapsuleComponent = OwnerCharacter->GetCapsuleComponent();
	// 		// TObjectPtr<USceneComponent> UpdatedComponent = MyCharacterMovementComponent->UpdatedComponent;
	//
	// 		FCalculatePoseContext Context;
	// 		if (CalculateWallTransform(HitResult.ImpactPoint, Context))
	// 		{
	// 			MyCharacterMovementComponent->MoveUpdatedComponent(FVector::ZeroVector, Context.Pose, true);
	// 		}	
	// 	}
	// }
}

void UHiMantleComponent::ClimbStart_Implementation(const EHiWallRunType &WallRun_Type, const FHitResult &HitResult, const FVector &Direction)
{
	StopMantleStartAnim();
	
	CurrentActorRoll = 0.0f;

	MyCharacterMovementComponent->MaxWallStepHeight = MaxStepHeight;
	
	ClimbType = EHiClimbType::WallRun;
	WallRunType = WallRun_Type;
	
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::SprintClimbStart_Implementation %d %s %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *ClimbRotation.ToString(), *ColDirection.ToString());


	//MyCharacterMovementComponent->MoveUpdatedComponent(FVector::ZeroVector, Rotator, true);
}

void UHiMantleComponent::ClimbEnd_Implementation(int Reason)
{
	if (ClimbType == EHiClimbType::WallRun)
	{
		ClimbType = EHiClimbType::None;
	}
	WallRunType = EHiWallRunType::None;
	//OwnerCharacter->SetActorRotation(FRotator(0.0f, ClimbRotation.Yaw, 0.0f));
}

float UHiMantleComponent::GetMontageStartingPosition_Implementation(UAnimMontage* MontageToPlay)
{
	return 0.0f;
}

bool UHiMantleComponent::PlayMantleMontage(const FHiMantleAsset &MantleAsset, const FHiComponentAndTransform& MantleLedgeWS)
{
	FHiMantleParams PlayParams;
	PlayParams.AnimMontage = MantleAsset.AnimMontage;
	PlayParams.StartingOffset = MantleAsset.StartingOffset;
	PlayParams.StartingPosition = GetMontageStartingPosition(PlayParams.AnimMontage);
	PlayParams.PlayRate = 1.0f;
	
	MantleParams = PlayParams;

	// Step 2: Convert the world space target to the mantle component's local space for use in moving objects.
	MantleLedgeLS.Component = MantleLedgeWS.Component;
	if (MantleLedgeWS.Component)
	{
		MantleLedgeLS.Matrix = MantleLedgeWS.Transform.ToMatrixWithScale() * MantleLedgeWS.Component->GetComponentToWorld().ToMatrixWithScale().Inverse();
	}
	else
	{
		MantleLedgeLS.Matrix = MantleLedgeWS.Transform.ToMatrixNoScale();
	}

	// Step 3: Set the Mantle Target and calculate the Starting Offset
	// (offset amount between the actor and target transform).
	MantleTarget = MantleLedgeWS.Transform;

	// Step 5: Clear the Character Movement Mode and set the Movement State to Mantling
	// OwnerCharacter->GetCharacterMovement()->SetMovementMode(MOVE_Flying);
	//OwnerCharacter->GetCharacterMovement()->SetMovementMode(MOVE_None);
	LocomotionComponent->SetMovementState(EHiMovementState::Mantling);

	// Step 7: Play the Anim Montaget if valid.

	UHiAnimInstance *AnimInstance = Cast<UHiAnimInstance>(OwnerCharacter->GetMesh()->GetAnimInstance());
	if (MantleParams.AnimMontage && AnimInstance)
	{
		const float MontageLength = AnimInstance->Montage_Play(MantleParams.AnimMontage, MantleParams.PlayRate,
															EMontagePlayReturnType::MontageLength,
															MantleParams.StartingPosition, true);
		
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleStart %d %s, StartPosition = %f, Location = %s, Rotation = %s, Matrix = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *MantleParams.AnimMontage->GetName(), MantleParams.StartingPosition, *MantleTarget.GetLocation().ToCompactString(), *MantleTarget.GetRotation().Rotator().ToCompactString(), *MantleLedgeWS.Transform.ToString());
		
		if (MontageLength > 0.f)
		{
			AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, MantleParams.AnimMontage);
			
			AnimInstance->Montage_SetBlendingOutDelegate(MontageBlendingOutDelegate, MantleParams.AnimMontage);
			
			AActor *Owner = GetOwner();
	
			UMotionWarpingComponent *MotionWarpingComponent = Cast<UMotionWarpingComponent>(Owner->GetComponentByClass(UMotionWarpingComponent::StaticClass()));
		
			MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(MotionWarpingTargetName, MantleTarget);

			MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(LandTargetName, MantleLedgeWS.LandTransform);

			return true;
		}
	}

	return false;
}

void UHiMantleComponent::MantleStart_Implementation(const FHiMantleAsset &MantleAsset, const float &MantleHeight, const FHiComponentAndTransform& MantleLedgeWS,
                                      EHiClimbType MantleType)
{
	if (OwnerCharacter == nullptr || LocomotionComponent == nullptr || OwnerCharacter->GetWorld() == nullptr)
	{
		return;
	}

	ClimbType = EHiClimbType::Mantle;
	MontageEndedDelegate.BindUObject(this, &UHiMantleComponent::OnMontageEnded);
	MontageBlendingOutDelegate.BindUObject(this, &UHiMantleComponent::OnMontageBlendOut );

	PlayMantleMontage(MantleAsset, MantleLedgeWS);
}

void UHiMantleComponent::OnMontageEnded_Implementation(UAnimMontage* Montage, bool bInterrupted)
{
	if (OwnerCharacter == nullptr || OwnerCharacter->GetWorld() == nullptr)
	{
		return;
	}
	UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::OnMontageEnded %d %s %d"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *Montage->GetName(), bInterrupted ? 1 : 0);
}

void UHiMantleComponent::OnMontageBlendOut(UAnimMontage* Montage, bool bInterrupted)
{
	if (OwnerCharacter == nullptr || OwnerCharacter->GetWorld() == nullptr)
	{
		return;
	}
	UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::OnMontageBlendOut %d %s %d"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *Montage->GetName(), bInterrupted ? 1 : 0);
	MantleEnd();
}

void UHiMantleComponent::UpdateWall(const FVector &Point, uint8 CollisionFlag)
{
	if (CollisionFlag == CC_COLLISION_SIDES)
	{
		WallImpactPoint_Horizontal = Point;
	}
	if (CollisionFlag == CC_COLLISION_DOWN)
	{
		WallImpactPoint_Down = Point;
	}

	CollisionFlags |= CollisionFlag;
}

bool UHiMantleComponent::NeedUpdateWallNormal() const
{
	return CollisionFlags & CC_COLLISION_DOWN;
}

bool UHiMantleComponent::IsOnFloor() const
{
	FFindFloorResult Result;
	GetCharacterMovementComponent()->K2_FindFloor(OwnerCharacter->GetActorLocation(), Result);
	return Result.bBlockingHit && Result.bWalkableFloor;
}

bool UHiMantleComponent::MoveCharacter(float ActorSpaceRoll, float DeltaTime, FHitResult & StepDownHit)
{
	CollisionFlags = 0;
	WallImpactPoint_Down = FVector(0);
	WallImpactPoint_Horizontal = FVector(0);
	
	TObjectPtr<USceneComponent> UpdatedComponent = MyCharacterMovementComponent->UpdatedComponent;

	FVector OriginalPos = UpdatedComponent->GetComponentLocation();
	FRotator PawnRotation = UpdatedComponent->GetComponentRotation();

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 000 %d Delta = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *Delta.ToString());

	FScopedMovementUpdate ScopedStepUpMovement(UpdatedComponent, EScopedUpdate::DeferredUpdates);

	FVector CharacterForwardVector = UpdatedComponent->GetForwardVector();
	FVector CharacterUpDirection = -CharacterForwardVector;

	FVector OriginalUpVector = UpdatedComponent->GetUpVector();
	FVector OriginalRightVector = UpdatedComponent->GetRightVector();

	FVector MoveDirection = OriginalUpVector.RotateAngleAxis(ActorSpaceRoll, CharacterForwardVector);

	bool bDownWard = MoveDirection.Dot(FVector(0, 0, -1)) > 0;

	const FVector Delta = MoveDirection * MaxClimbMovementSpeed * DeltaTime;
	
	FVector MoveNormal, MoveHorizontal;
	FVector Move = Delta/* * (1-ForwardHit.Time)*/;// + CharacterUpDirection * ClimbGraivty * DeltaTime;
	UMathHelper::DecomposeVector(MoveNormal, MoveHorizontal, Move, CharacterUpDirection);

	FVector Step = CharacterUpDirection * MaxStepHeight;

	FVector MoveUp(0), MoveDown(0);
	if (MoveNormal.Dot(CharacterUpDirection) > 1.e-6)
	{
		MoveUp = MoveNormal;
	}
	else if (Move.Dot(CharacterUpDirection) < -1.e-6)
	{
		MoveDown = MoveNormal;
	}

	bool HasHorizontalMove = !MoveHorizontal.IsNearlyZero();
	if (HasHorizontalMove)
	{
		MoveUp += Step;
		MoveDown -= Step;
	}
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 111 %d, Location = %s, UpDirection = %s, MoveHorizontal = %s, MoveUp = %s, MoveDown = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString(), *CharacterUpDirection.ToString(), *MoveHorizontal.ToString(), *MoveUp.ToString(), *MoveDown.ToString());

	//FVector Location_3 = UpdatedComponent->GetComponentLocation();
	
	if (!MoveUp.IsNearlyZero())
	{
		FHitResult SweepUpHit(1.f);
		FVector Location_1 = UpdatedComponent->GetComponentLocation();
		MyCharacterMovementComponent->SafeMoveUpdatedComponent(MoveUp, PawnRotation, true, SweepUpHit);
		FVector Location_2 = UpdatedComponent->GetComponentLocation();
		if (SweepUpHit.bStartPenetrating)
		{
			// Undo movement
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter %d 111"),  (int32)OwnerCharacter->GetWorld()->GetNetMode());
	
			ScopedStepUpMovement.RevertMove();
			return false;
		}
	
		if (SweepUpHit.IsValidBlockingHit())
		{
			CollisionFlags |= CC_COLLISION_UP;
		}
	}

	//FVector Location_4 = UpdatedComponent->GetComponentLocation();

	bool SideCollision = false;

	FHitResult ForwardHit(1.f);
	float HorizontalHitTime = 1.0f;
	if (HasHorizontalMove)
	{
		MyCharacterMovementComponent->SafeMoveUpdatedComponent( MoveHorizontal, PawnRotation, true, ForwardHit);

		// Check result of forward movement
		if (ForwardHit.bBlockingHit)
		{
			if (ForwardHit.bStartPenetrating)
			{
				// Undo movement
				//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter %d 222"),  (int32)OwnerCharacter->GetWorld()->GetNetMode());
				ScopedStepUpMovement.RevertMove();
				return false;
			}
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::UpdateWall %d 111 %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *MoveHorizontal.GetSafeNormal().ToString());

			HorizontalHitTime = ForwardHit.Time;

			SideCollision = true;
			
			// adjust and try again
			// const float ForwardHitTime = Hit.Time;
			// const float ForwardSlideAmount = MyCharacterMovementComponent->SlideAlongSurface(Delta, 1.f - Hit.Time, Hit.Normal, Hit, true);
			//
			// // If both the forward hit and the deflection got us nowhere, there is no point in this step up.
			// if (ForwardHitTime == 0.f && ForwardSlideAmount == 0.f)
			// {
			// 	//ScopedStepUpMovement.RevertMove();
			// 	return false;
			// }
		}	
	}
	
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 222 %d, Location = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString());

	// Step down

	if (SideCollision)
	{
		ScopedStepUpMovement.RevertMove();

		MyCharacterMovementComponent->SafeMoveUpdatedComponent( MoveHorizontal, PawnRotation, true, ForwardHit);
		if (ForwardHit.bBlockingHit)
		{
			if (ForwardHit.bStartPenetrating)
			{
				// Undo movement
				//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter %d 222"),  (int32)OwnerCharacter->GetWorld()->GetNetMode());
				ScopedStepUpMovement.RevertMove();
				return false;
			}
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::UpdateWall %d 111 %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *MoveHorizontal.GetSafeNormal().ToString());

			HorizontalHitTime = ForwardHit.Time;
		}
		
		UCapsuleComponent *CapsuleComponent = OwnerCharacter->GetCapsuleComponent();

		OriginalPos = CapsuleComponent->GetComponentLocation();
		
		float CapsuleRadius = CapsuleComponent->GetScaledCapsuleRadius();
		float CapsuleHalfHeightWithoutHemisphere = CapsuleComponent->GetScaledCapsuleHalfHeight_WithoutHemisphere();
		
		FVector ImpactPoint = ForwardHit.ImpactPoint;

		float threshold = CapsuleHalfHeightWithoutHemisphere / FMath::Sqrt(CapsuleRadius * CapsuleRadius + CapsuleHalfHeightWithoutHemisphere * CapsuleHalfHeightWithoutHemisphere);

		FVector Direction = (ImpactPoint - OriginalPos).GetSafeNormal();
		
		UWorld* World = GetWorld();
		check(World);
		
		FCollisionQueryParams Params;
		Params.AddIgnoredActor(OwnerCharacter);

		//FVector ProjectedLength = FVector::VectorPlaneProject(Direction, ForwardVector);

		float Dot = Direction.Dot(OriginalUpVector);
		// 角色控制器总是会尝试朝向碰撞点
		//if (dot > 0 && dot < 0.9)
		//if (ProjectedLength.Length() )
		if (Dot > threshold)  // 头部遇到障碍物
		{
			CollisionFlags |= CC_COLLISION_OBSTACLE;
			FVector NewUpVector = OriginalUpVector.RotateAngleAxis(-ClimbPitchRotationSpeed * DeltaTime, OriginalRightVector);
			FVector TraceStart = OriginalPos - OriginalUpVector * CapsuleHalfHeightWithoutHemisphere;
			FVector TraceEnd = TraceStart + NewUpVector * CapsuleHalfHeightWithoutHemisphere * 2;

			PawnRotation = FRotationMatrix::MakeFromYZ(OriginalRightVector, NewUpVector).Rotator();

			const FCollisionShape SphereCollisionShape = FCollisionShape::MakeSphere(CapsuleRadius);

			FHitResult TryMoveHit;
		
			const bool bHit = World->SweepSingleByProfile(TryMoveHit, TraceStart, TraceEnd, FQuat::Identity, ClimbObjectDetectionProfile,
																	  SphereCollisionShape, Params);

			if (!TryMoveHit.IsValidBlockingHit())
			{
				FVector RotateCenter = OriginalPos - OriginalUpVector * CapsuleHalfHeightWithoutHemisphere;
				FVector NewLocation = RotateCenter + NewUpVector * CapsuleHalfHeightWithoutHemisphere;
				MyCharacterMovementComponent->SafeMoveUpdatedComponent(NewLocation - OriginalPos, PawnRotation, true, ForwardHit);
				
				FVector NewMoveDirection = NewUpVector.RotateAngleAxis(ActorSpaceRoll, CharacterForwardVector);

				MoveHorizontal = NewMoveDirection * MaxClimbMovementSpeed * DeltaTime * (1-HorizontalHitTime);

				MyCharacterMovementComponent->SafeMoveUpdatedComponent(MoveHorizontal, PawnRotation, true, ForwardHit);

				if (ForwardHit.IsValidBlockingHit())
				{
					HorizontalHitTime = ForwardHit.Time;
					FVector TryMoveHorizontal, TryMoveNormal;

					UMathHelper::DecomposeVector(TryMoveNormal, TryMoveHorizontal, MoveHorizontal*(1-HorizontalHitTime), ForwardHit.ImpactNormal);

					MyCharacterMovementComponent->SafeMoveUpdatedComponent( TryMoveHorizontal, PawnRotation, true, ForwardHit);

					if (ForwardHit.IsValidBlockingHit())
					{
						UpdateWall(ForwardHit.ImpactPoint, CC_COLLISION_SIDES);
					}	
				}
			}
			else
			{
				// UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
				// 								   TraceStart,
				// 								   TraceEnd,
				// 								   SphereCollisionShape,
				// 								   EDrawDebugTrace::Type::ForDuration,
				// 								   TryMoveHit.bBlockingHit,
				// 								   TryMoveHit,
				// 								   FLinearColor::Red,
				// 								   FLinearColor::Yellow,
				// 								   100.0f);
				return false;
			}
			CharacterForwardVector = UpdatedComponent->GetForwardVector();
			FVector StepDown = CharacterForwardVector * MaxDownStepHeight;
			MyCharacterMovementComponent->SafeMoveUpdatedComponent(StepDown, PawnRotation, true, StepDownHit);
			if (StepDownHit.IsValidBlockingHit())
			{
				UpdateWall(StepDownHit.ImpactPoint, CC_COLLISION_DOWN);
			}
		}
		else
		{
			FVector ProjectedDirection = FVector::VectorPlaneProject(Direction, OriginalUpVector);

			FVector RightVectorCheckCenter = ImpactPoint - ProjectedDirection;

			FVector RightVector = OriginalUpVector.Cross(ProjectedDirection).GetSafeNormal();
			

			
			UpdateWall(ForwardHit.ImpactPoint, CC_COLLISION_DOWN);

			if (bDownWard && MyCharacterMovementComponent->IsWalkable(ForwardHit))
			{
				CollisionFlags |= CC_COLLISION_LAND;
			}
		}
		
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 444 %d, Location = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString());

	}
	else
	{
		MyCharacterMovementComponent->MoveUpdatedComponent(MoveDown, PawnRotation, true, &StepDownHit);

		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 333 %d, Location = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString());
	
		if (StepDownHit.bStartPenetrating)
		{
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter %d 333"),  (int32)OwnerCharacter->GetWorld()->GetNetMode());
			ScopedStepUpMovement.RevertMove();
			return false;
		}
		
		if (StepDownHit.IsValidBlockingHit())
		{
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 555 %d, Location = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString());
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::UpdateWall %d 222 %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *MoveDown.GetSafeNormal().ToString());

			UpdateWall(StepDownHit.ImpactPoint, CC_COLLISION_DOWN);
		}
		else
		{
			FVector StepDown = CharacterForwardVector * MaxDownStepHeight;
			MyCharacterMovementComponent->SafeMoveUpdatedComponent(StepDown, PawnRotation, true, StepDownHit);
			if (StepDownHit.IsValidBlockingHit())
			{
				//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 666 %d StepDown = %s, Location = %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *StepDown.GetSafeNormal().ToString(), *UpdatedComponent->GetComponentLocation().ToString());

				UpdateWall(StepDownHit.ImpactPoint, CC_COLLISION_DOWN);
			}
			else
			{
				if (HasHorizontalMove)
				{
					FVector DeltaPos = OriginalPos - UpdatedComponent->GetComponentLocation();
					FVector Horizontal_Normal = MoveHorizontal.GetSafeNormal();
					FVector Horizontal_Vec, Vertical_Vec;
					UMathHelper::DecomposeVector(Horizontal_Vec, Vertical_Vec, DeltaPos, Horizontal_Normal);
					FVector Dirs[] = { Horizontal_Vec, Vertical_Vec };
				
					for (int i = 0; i < sizeof(Dirs) / sizeof(FVector); i++)
					{
						MyCharacterMovementComponent->SafeMoveUpdatedComponent(Dirs[i], PawnRotation, true, StepDownHit);
						if (StepDownHit.IsValidBlockingHit())
						{
							/*UHiCharacterDebugComponent::DrawDebugLineTraceSingle(GetWorld(), StepDownHit.TraceStart, StepDownHit.TraceEnd, EDrawDebugTrace::ForDuration, true, StepDownHit,
																			 FLinearColor::Red,
																			FLinearColor::Yellow,
																			10.0f);
							UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::UpdateWall %d 444 %d %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), i, *Dirs[i].GetSafeNormal().ToString());*/

							UpdateWall(StepDownHit.ImpactPoint, CC_COLLISION_DOWN);
							break;
						}
					}
				}
				if ((CollisionFlags & CC_COLLISION_DOWN) == 0)
				{
					ScopedStepUpMovement.RevertMove();
					//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter %d 555"),  (int32)OwnerCharacter->GetWorld()->GetNetMode());
					return false;
				}
				//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 777 %d Location = %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString());
			}
			// UHiCharacterDebugComponent::DrawDebugLineTraceSingle(GetWorld(), Hit.TraceStart, Hit.TraceEnd, EDrawDebugTrace::ForDuration, false, Hit,
			// 												FLinearColor::Red,
			// 											   FLinearColor::Yellow,
			// 											   60.0f);
		}
		if (bDownWard && MyCharacterMovementComponent->IsWalkable(StepDownHit))
		{
			CollisionFlags |= CC_COLLISION_LAND;
		}
	}

	//FVector Location = UpdatedComponent->GetComponentLocation();

	//FRotator Rotator = UpdatedComponent->GetComponentRotation();

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 888 %d, Pitch = %.3f, DeltaLength = %.3f, Delta = %s, OriginalPos = %s, CurrentPos = %s, MoveHorizontal = %s, UpDirection = %s, MoveUp = %s, MoveDown = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), Rotator.Pitch, (Location - OriginalPos).Length(), *(Location - OriginalPos).ToString(), *OriginalPos.ToString(), *Location.ToString(), *MoveHorizontal.ToString(), *CharacterUpDirection.ToString(), *MoveUp.ToString(), *MoveDown.ToString());
	
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::StepUp 222 %d, Hit = %d, Location = %s, ColDirection = %s, ClimbRotation = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), Hit.bBlockingHit, *Location_7.ToString(), *ColDirection.ToString(), *ClimbRotation.ToString());
	
	return true;
}

bool UHiMantleComponent::CheckLand(const FVector &Direction)
{
	UCapsuleComponent *CapsuleComponent = OwnerCharacter->GetCapsuleComponent();

	const FVector &Location = CapsuleComponent->GetComponentLocation();
	FVector ForwardVector = CapsuleComponent->GetForwardVector();
	FVector RightVector = CapsuleComponent->GetRightVector();

	float CapsuleRadius = CapsuleComponent->GetScaledCapsuleRadius();
	float CapsuleHalfHeight = CapsuleComponent->GetScaledCapsuleHalfHeight();

	float CheckDistance = CapsuleHalfHeight + CapsuleRadius;

	FVector TraceStart1, TraceEnd1, TraceStart2, TraceEnd2;

	float ShapeRadius = CapsuleRadius;
	
	TraceStart1 = Location + ForwardVector * CapsuleRadius * 0.5;
	TraceStart2 = Location - ForwardVector * CapsuleRadius * 0.5;
	
	TraceEnd1 = TraceStart1 + Direction * CheckDistance;
	TraceEnd2 = TraceStart2 + Direction * CheckDistance;

	UWorld* World = GetWorld();
	check(World);

	FHitResult ForwardHitResult;

	const FCollisionShape CapsuleCollisionShape = FCollisionShape::MakeSphere(CapsuleRadius * 0.5);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart1, TraceEnd1, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShape, Params);
	}

	if (ForwardHitResult.IsValidBlockingHit())
	{
		TraceEnd1 = ForwardHitResult.Location;
	}
	else if (ForwardHitResult.bStartPenetrating)
	{
		TraceEnd1 += ForwardHitResult.ImpactNormal * ForwardHitResult.PenetrationDepth;
	}

	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart2, TraceEnd2, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShape, Params);
	}

	if (ForwardHitResult.IsValidBlockingHit())
	{
		TraceEnd2 = ForwardHitResult.Location;
	}
	else if (ForwardHitResult.bStartPenetrating)
	{
		TraceEnd2 += ForwardHitResult.ImpactNormal * ForwardHitResult.PenetrationDepth;
	}

	ForwardVector = (TraceEnd1 - TraceEnd2).GetSafeNormal();

	FMatrix RotMatrix = FRotationMatrix::MakeFromXY(ForwardVector, RightVector);
	
	FRotator Rot = RotMatrix.Rotator();

	return Rot.Pitch > -ClimbLandSlope;
}

void UHiMantleComponent::PhysMantle_Implementation(float DeltaTime)
{
	MyCharacterMovementComponent->PhysFlying(DeltaTime, 0);
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysMantle_Implementation %d, ActorLocation = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *GetOwner()->GetActorLocation().ToString());
}

void UHiMantleComponent::PhysClimb_Implementation(float DeltaTime)
{
	if (FMath::IsNearlyZero(DeltaTime))
	{
		return;
	}
	TObjectPtr<USceneComponent> UpdatedComponent = MyCharacterMovementComponent->UpdatedComponent;
	
	if( MyCharacterMovementComponent->HasAnimRootMotion() && DeltaTime > 0.f )
	{
		MyCharacterMovementComponent->Velocity = MyCharacterMovementComponent->ConstrainAnimRootMotionVelocity(MyCharacterMovementComponent->AnimRootMotionVelocity, MyCharacterMovementComponent->Velocity);
		
		FVector OldLocation = UpdatedComponent->GetComponentLocation();
		const FVector Adjusted = MyCharacterMovementComponent->Velocity * DeltaTime;
		FHitResult Hit(1.f);
		MyCharacterMovementComponent->SafeMoveUpdatedComponent(Adjusted, UpdatedComponent->GetComponentQuat(), true, Hit);

		if (Hit.Time < 1.f)
		{
			const FVector GravDir = FVector(0.f, 0.f, -1.f);
			const FVector VelDir = MyCharacterMovementComponent->Velocity.GetSafeNormal();
			const float UpDown = GravDir | VelDir;

			bool bSteppedUp = false;
			if ((FMath::Abs(Hit.ImpactNormal.Z) < 0.2f) && (UpDown < 0.5f) && (UpDown > -0.2f) && MyCharacterMovementComponent->CanStepUp(Hit))
			{
				float stepZ = UpdatedComponent->GetComponentLocation().Z;
				bSteppedUp = MyCharacterMovementComponent->ClimbStepUp(GravDir, Adjusted * (1.f - Hit.Time), Hit);
				if (bSteppedUp)
				{
					OldLocation.Z = UpdatedComponent->GetComponentLocation().Z + (OldLocation.Z - stepZ);
				}
			}

			if (!bSteppedUp)
			{
				//adjust and try again
				MyCharacterMovementComponent->HandleImpact(Hit, DeltaTime, Adjusted);
				MyCharacterMovementComponent->SlideAlongSurface(Adjusted, (1.f - Hit.Time), Hit.Normal, Hit, true);
			}
		}
		return;
	}

	FVector OldLocation = UpdatedComponent->GetComponentLocation();

	FVector Acceleration = MyCharacterMovementComponent->Acceleration;
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysClimb_Implementation %d Acceleration = %s"), (int32)OwnerCharacter->GetLocalRole(), *Acceleration.ToString());
	
	CalcVelocityForClimb(DeltaTime, 0.0f, true, 0.0f);
	
	if (!Acceleration.IsNearlyZero())
	{
		FRotator CurrentRotator = UpdatedComponent->GetComponentRotation();
		FVector ActorUpVector = UpdatedComponent->GetUpVector();
		FVector ActorForwardVector = UpdatedComponent->GetForwardVector();
		FVector Direction = MyCharacterMovementComponent->Velocity.GetSafeNormal();
		
		TargetActorRoll = FMath::IsNearlyZero(ActorUpVector.Dot(Direction) + 1) ? 180 : FMath::Sign(ActorUpVector.Cross(Direction).Dot(ActorForwardVector)) * UKismetMathLibrary::DegAcos(ActorUpVector.Dot(Direction));
		CurrentActorRoll = TargetActorRoll;//FMath::FInterpTo(CurrentActorRoll, TargetActorRoll, DeltaTime, ClimbRollInterpSpeed);
		
		FHitResult StepDownResult;
		bool bSteppedUp = MoveCharacter(CurrentActorRoll, DeltaTime, StepDownResult);

		if (CollisionFlags & CC_COLLISION_LAND || (StepDownResult.IsValidBlockingHit() && StepDownResult.Component.IsValid() && !StepDownResult.Component->CanCharacterClimb(OwnerCharacter)))
		{
			ClimbEnd();
			return;
		}
		
		CurrentRotator = UpdatedComponent->GetComponentRotation();
		
		bool need_update_wall_normal = NeedUpdateWallNormal();
		if (need_update_wall_normal)
		{
			FCalculatePoseContext Context;
			Context.DeltaTime = DeltaTime;
			need_update_wall_normal = CalculateWallTransform(WallImpactPoint_Down, Context);
			if (Context.Pose.Pitch > ClimbPitchLimit)
			{
				if (CollisionFlags & CC_COLLISION_OBSTACLE)
				{
					bCheckFlyOver = true;
				}
				else
				{
					//ClimbEnd();
				}
				return;
			}
			ClimbRotation = Context.Pose;
		}

		if (!need_update_wall_normal)
		{
			ClimbEnd();
			return;
		}

		FRotator TargetRotator = UMathHelper::RNearestInterpTo(CurrentRotator, ClimbRotation, DeltaTime, ClimbInterpSpeed);
		//FRotator TargetRotator = ClimbRotation;
		
			
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysClimb_Implementation %d %f, Yaw = %f, %s %s %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), TargetActorRoll, ClimbRotation.Yaw, *UpdatedComponent->GetComponentLocation().ToString(), *ClimbRotation.ToString(), *ColDirection.ToString());

		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysClimb_Implementation %d NewLocation = %s CurrentRotator = %s, ClimbRotation = %s, TargetRotator = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpdatedComponent->GetComponentLocation().ToString(), *CurrentRotator.ToString(), *ClimbRotation.ToString(), *TargetRotator.ToString());
		
		FHitResult Hit(1.f);
		
		MyCharacterMovementComponent->SafeMoveUpdatedComponent(FVector::ZeroVector, TargetRotator, true, Hit);
		
		// FRotator NewRotator = UpdatedComponent->GetComponentRotation();
		//
		// if (FMath::Abs(UMathHelper::FAngleNormalized(NewRotator.Pitch) -  UMathHelper::FAngleNormalized(TargetRotator.Pitch)) > 1)
		// {
		// 	int i = 0;
		// 	i++;
		// }
		
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysClimb_Implementation %d Yaw = %.3f, Pitch = %.3f, Roll = %.3f"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), UpdatedComponent->GetComponentRotation().Yaw, UpdatedComponent->GetComponentRotation().Pitch, UpdatedComponent->GetComponentRotation().Roll);

		//FRotator Rot = UpdatedComponent->GetComponentRotation();

		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysClimb_Implementation %d OldLocation = %s, NewLocation = %s, Yaw = %f, Pitch = %f, Roll = %f"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *OldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString(), Rot.Yaw, Rot.Pitch, Rot.Roll);
	}

	FVector NewLocation = UpdatedComponent->GetComponentLocation();

	MyCharacterMovementComponent->Velocity = (NewLocation - OldLocation) / DeltaTime;
	
}

bool UHiMantleComponent::CalculateWallTransform(const FVector &ImpactPoint, FCalculatePoseContext &Context)
{
	TObjectPtr<USceneComponent> UpdatedComponent = MyCharacterMovementComponent->UpdatedComponent;

	FScopedMovementUpdate ScopedStepUpMovement(UpdatedComponent, EScopedUpdate::DeferredUpdates);
	
	FVector Location = UpdatedComponent->GetComponentLocation();
	FRotator Rotator = UpdatedComponent->GetComponentRotation();

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MoveCharacter 000 %d Delta = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *Delta.ToString());
	
	UCapsuleComponent *CapsuleComponent = OwnerCharacter->GetCapsuleComponent();

	FVector UpVector = CapsuleComponent->GetUpVector();
	FVector ForwardVector = CapsuleComponent->GetForwardVector();

	FVector PrevForwardVector = ForwardVector;
	FVector PrevUpVector = UpVector;

	float CapsuleRadius = CapsuleComponent->GetScaledCapsuleRadius();
	float CapsuleHalfHeight = CapsuleComponent->GetScaledCapsuleHalfHeight();

	float CheckDistance = WallTransformCheckDistance;

	FVector TraceStart1, TraceEnd1, TraceStart2, TraceEnd2;

	float ShapeRadius = CapsuleRadius;
	
	FVector Direction = ImpactPoint - Location;
	
	FVector ProjectedDirection = FVector::VectorPlaneProject(Direction, UpVector);
	
	FVector RightVectorCheckCenter = ImpactPoint - ProjectedDirection;

	FVector RightVector = UpVector.Cross(ProjectedDirection).GetSafeNormal();
	
	TraceStart1 = Location + UpVector * (CapsuleHalfHeight - CapsuleRadius);
	TraceStart2 = Location - UpVector * (CapsuleHalfHeight - CapsuleRadius);

	ProjectedDirection = ProjectedDirection.GetSafeNormal();
	
	TraceEnd1 = TraceStart1 + ProjectedDirection * CheckDistance;
	TraceEnd2 = TraceStart2 + ProjectedDirection * CheckDistance;

	UWorld* World = GetWorld();
	check(World);

	FHitResult ForwardHitResult, ForwardHitResult1, ForwardHitResult2, HitResult;

	const FCollisionShape CapsuleCollisionShape = FCollisionShape::MakeSphere(ShapeRadius);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult1, TraceStart1, TraceEnd1, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShape, Params);
	}

	if (ForwardHitResult1.IsValidBlockingHit())
	{
		TraceEnd1 = ForwardHitResult1.Location;
	}
	else if (ForwardHitResult1.bStartPenetrating)
	{
		TraceEnd1 += ForwardHitResult1.ImpactNormal * ForwardHitResult1.PenetrationDepth;
	}

	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult2, TraceStart2, TraceEnd2, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShape, Params);
	}

	if (ForwardHitResult2.IsValidBlockingHit())
	{
		TraceEnd2 = ForwardHitResult2.Location;
	}
	else if (ForwardHitResult2.bStartPenetrating)
	{
		TraceEnd2 += ForwardHitResult2.ImpactNormal * ForwardHitResult2.PenetrationDepth;
	}

	// if (!ForwardHitResult.IsValidBlockingHit())
	// {
	// 	::DrawDebugDirectionalArrow(World, TraceStart1, TraceEnd1, 15.0f, FLinearColor::Black.ToFColor(true), true, 100);
	// }
	
	UpVector = (TraceEnd1 - TraceEnd2).GetSafeNormal();

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::CalculateWallTransform 111 %d, UpVector = %s, Direction = %s, TraceStart1 = %s, TraceEnd1 = %s, TraceStart2 = %s, TraceEnd2 = %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *UpVector.ToString(), *Direction.ToString(), *TraceStart1.ToString(), *TraceEnd1.ToString(), *TraceStart2.ToString(), *TraceEnd2.ToString());
	
	const FCollisionShape CapsuleCollisionShapeHalfRadius = FCollisionShape::MakeSphere(CapsuleRadius * 0.5);

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::CalculateWallTransform 111 %d, Hit = %d, Forward = %s, UpVector = %s, RightVector = %s, Col_Direction = %s, TraceStart1 = %s, TraceStart2 = %s, TraceEnd1 = %s, TraceEnd2 = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), ForwardHitResult.IsValidBlockingHit() ? 1 : 0, *Direction.ToString(), *UpVector.ToString(), *RightVector.ToString(), *Direction.ToString(), *TraceStart1.ToString(), *TraceStart2.ToString(), *TraceEnd1.ToString(), *TraceEnd2.ToString());

	TraceStart1 = RightVectorCheckCenter + RightVector * CapsuleRadius * 0.5;
	TraceEnd1 = TraceStart1 + ProjectedDirection * CapsuleRadius;
	
	TraceStart2 = RightVectorCheckCenter - RightVector * CapsuleRadius * 0.5;
	TraceEnd2 = TraceStart2 + ProjectedDirection * CapsuleRadius;

	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart1, TraceEnd1, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShapeHalfRadius, Params);
	}

	bool ModifyRight = true;
	if (ForwardHitResult.IsValidBlockingHit())
	{
		TraceEnd1 = ForwardHitResult.Location;
	}
	else if (ForwardHitResult.bStartPenetrating)
	{
		TraceEnd1 += ForwardHitResult.ImpactNormal * ForwardHitResult.PenetrationDepth;
	}
	else
	{
		ModifyRight = false;
	}

	if (ModifyRight)
	{
		const bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart2, TraceEnd2, FQuat::Identity, ClimbObjectDetectionProfile,
														  CapsuleCollisionShapeHalfRadius, Params);
		if (ForwardHitResult.IsValidBlockingHit())
		{
			TraceEnd2 = ForwardHitResult.Location;
		}
		else if (ForwardHitResult.bStartPenetrating)
		{
			TraceEnd2 += ForwardHitResult.ImpactNormal * ForwardHitResult.PenetrationDepth;
		}
		else
		{
			ModifyRight = false;
		}
	}
	

	if (ModifyRight)
	{
		RightVector = (TraceEnd1 - TraceEnd2).GetSafeNormal();	
	}

	FMatrix RotMatrix = FRotationMatrix::MakeFromYZ(RightVector, UpVector);

	FQuat Q = RotMatrix.ToQuat();
	
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::CalculateWallTransform 222 %d, Hit = %d, Forward = %s, UpVector = %s, RightVector = %s, Col_Direction = %s, TraceStart1 = %s, TraceStart2 = %s, TraceEnd1 = %s, TraceEnd2 = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), ForwardHitResult.IsValidBlockingHit() ? 1 : 0, *ForwardVector.ToString(), *UpVector.ToString(), *RightVector.ToString(), *Direction.ToString(), *TraceStart1.ToString(), *TraceStart2.ToString(), *TraceEnd1.ToString(), *TraceEnd2.ToString());

	//Roll要和component的Roll保持一致
	FRotator FinalRotator = Q.Rotator();
	FinalRotator.Roll = 0;
	
	Context.Pose = FinalRotator;

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::CalculateWallTransform 222 %d, WallImpactPoint = %s, Direction = %s, Forward = %s, Up = %s, Right = %s, PrevForward = %s, PrevUp = %s, PrevRight = %s, TraceStart1 = %s, TraceEnd1 = %s, TraceStart2 = %s, TraceEnd2 = %s"),  (int32)OwnerCharacter->GetWorld()->GetNetMode(), *WallImpactPoint_Down.ToString(), *Direction.ToString(), *FinalRotator.Quaternion().GetForwardVector().ToString(), *FinalRotator.Quaternion().GetUpVector().ToString(), *FinalRotator.Quaternion().GetRightVector().ToString(), *PrevForwardVector.ToString(), *PrevUpVector.ToString(), *PrevRightVector.ToString(), *TraceStart1.ToString(), *TraceEnd1.ToString(), *TraceStart2.ToString(), *TraceEnd2.ToString());

	/*if (FinalRotator.Pitch > ClimbPitchLimit)
	{
		UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
												   TraceStart11,
												   TraceEnd11,
												   CapsuleCollisionShape,
												   EDrawDebugTrace::Type::ForDuration,
												   ForwardHitResult1.bBlockingHit,
												   ForwardHitResult1,
												   FLinearColor::Red,
												   FLinearColor::Yellow,
												   100.0f);
		
		UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
												   TraceStart12,
												   TraceEnd12,
												   CapsuleCollisionShape,
												   EDrawDebugTrace::Type::ForDuration,
												   ForwardHitResult2.bBlockingHit,
												   ForwardHitResult2,
												   FLinearColor::Red,
												   FLinearColor::Yellow,
												   100.0f);
	}*/
	
	return true;
}

bool UHiMantleComponent::WaitTimeCheck(const FHiMantleWaitTimeSettings &WaitTimeSetting)
{
	if (GFrameCounter - MantleWaitTime.LastCheckFrameCount > 1)
	{
		MantleWaitTime.TotalTime = 0.0f;
	}
	MantleWaitTime.LastCheckFrameCount = GFrameCounter;
					
	float WaitTime = IsOnFloor() ? WaitTimeSetting.WaitTime : WaitTimeSetting.WaitTimeInAir;
					
	if (MantleWaitTime.TotalTime >= WaitTime)
	{
		MantleWaitTime.TotalTime = 0.0f;
		return true;
	}
	else
	{
		MantleWaitTime.TotalTime += FrameDeltaTime;
	}
	return false;
}

bool UHiMantleComponent::FenceCheck(const MantleCheckContext &Context, UPrimitiveComponent  * &HitComponent, FVector &MantleVector, float &MaxMantleHeight)
{
	auto &TraceSettings = Context.TraceSettings;
	auto &ClimbTraceStart = Context.ClimbTraceStart;
	auto &TraceDirection = Context.TraceDirection;
	auto &CapsuleBaseLocation = Context.CapsuleBaseLocation;
	auto &DebugType = Context.DebugType;

	HitComponent = nullptr;

	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);
	
	const FCollisionShape &CollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);
	
	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();
	float CapsuleRadius = Capsule->GetScaledCapsuleRadius();
	
	for (int i = 0; i < TraceSettings.FenceOffsets.Num(); ++i)
	{
		float FenceOffset = TraceSettings.FenceOffsets[i];

		if (FenceOffset > TraceSettings.MantleWallDistance)
		{
			break;
		}

		//const FCollisionShape FenceHeightCheckShape = FCollisionShape::MakeBox(FVector(TraceSettings.ForwardTraceRadius, FenceOffset * 0.5, 1));

		const FCollisionShape &FenceHeightCheckShape = FCollisionShape::MakeCapsule(TraceSettings.ForwardTraceRadius, FenceOffset * 0.5);
		
		FVector FenceHeightCheckStart = ClimbTraceStart + TraceDirection * (FenceOffset * 0.5 + CapsuleRadius);
		FVector FenceHeightCheckEnd = FenceHeightCheckStart;
		FenceHeightCheckEnd.Z = CapsuleBaseLocation.Z;

		FHitResult FenceHeightCheckResult;

		FQuat FenceCheckQuat = TraceDirection.ToOrientationQuat() * FRotator(90, 0, 0).Quaternion();

		bool bHit = World->SweepSingleByProfile(FenceHeightCheckResult, FenceHeightCheckStart, FenceHeightCheckEnd, FenceCheckQuat,
												  MantleObjectDetectionProfile, FenceHeightCheckShape,
												  Params);

		if (!FenceHeightCheckResult.IsValidBlockingHit())
		{
			break;
		}

		if (!OwnerCharacter->GetCharacterMovement()->IsWalkable(FenceHeightCheckResult))
		{
			continue;
		}
		if (!(FenceHeightCheckResult.Component.IsValid() && FenceHeightCheckResult.Component->CanCharacterClimb(OwnerCharacter)))
		{
			continue;
		}

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
														   FenceHeightCheckStart,
														   FenceHeightCheckEnd,
														   FenceHeightCheckShape,
														   DebugType,
														   bHit,
														   FenceHeightCheckResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f,
														   TraceDirection.ToOrientationQuat() * FRotator(90, 0, 0).Quaternion());
		}
		
		float FenceHeight = FenceHeightCheckResult.ImpactPoint.Z;

		FHitResult DownHitResult;
		
		FVector DownwardTraceStart = ClimbTraceStart + TraceDirection * (FenceOffset + 2 * CapsuleRadius);
		FVector DownwardTraceEnd = DownwardTraceStart;
		DownwardTraceEnd.Z = CapsuleBaseLocation.Z + TraceSettings.ForwardTraceRadius;

		bHit = World->SweepSingleByProfile(DownHitResult, DownwardTraceStart, DownwardTraceEnd, FQuat::Identity,
												  MantleObjectDetectionProfile, CollisionShape,
												  Params);

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
														   DownwardTraceStart,
														   DownwardTraceEnd,
														   CollisionShape,
														   DebugType,
														   bHit,
														   DownHitResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f);
		}
		
		//更近的LandOffset如果发现高度差更大的落地点，后面的落地点就不用检查了
		if (DownHitResult.IsValidBlockingHit())
		{
			DownwardTraceEnd = DownHitResult.Location;
		}

		DownwardTraceEnd.Z -= TraceSettings.ForwardTraceRadius;

		const FVector& CapsuleLocationFBase = UHiCharacterMathLibrary::GetCapsuleLocationFromBase(
			DownwardTraceEnd, 2.0f, OwnerCharacter->GetCapsuleComponent());
		const bool bCapsuleHasRoom = UHiCharacterMathLibrary::CapsuleHasRoom(OwnerCharacter->GetCapsuleComponent(),
																		  CapsuleLocationFBase, MantleObjectDetectionProfile, 0.0f,
																		  0.0f, DebugType, HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces());

		if (!bCapsuleHasRoom)
		{
			// Capsule doesn't have enough room to mantle
			continue;
		}

		bool bValidFence = true;
		for (int j = 0; j <= 1; ++j)
		{
			FVector FenceEdgeCheckStart = FenceHeightCheckStart + FenceCheckQuat.GetRightVector() * TraceSettings.ForwardTraceRadius * 2 * (2 * j - 1);
			FVector FenceEdgeCheckEnd = FenceEdgeCheckStart;
			FenceEdgeCheckEnd.Z = FenceHeightCheckResult.Location.Z - TraceSettings.FenceEdgeOffset;

			FHitResult FenceEdgeCheckResult;

			bHit = World->SweepSingleByProfile(FenceEdgeCheckResult, FenceEdgeCheckStart, FenceEdgeCheckEnd, FenceCheckQuat,
													  MantleObjectDetectionProfile, FenceHeightCheckShape,
													  Params);

			// UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
			// 											   FenceEdgeCheckStart,
			// 											   FenceEdgeCheckEnd,
			// 											   FenceHeightCheckShape,
			// 											   DebugType,
			// 											   bHit,
			// 											   FenceEdgeCheckResult,
			// 											   FLinearColor::White,
			// 											   FLinearColor::Black,
			// 											   10.0f,
			// 											   FenceCheckQuat);
			
			if (!FenceEdgeCheckResult.IsValidBlockingHit())
			{
				bValidFence = false;
				break;
			}
		}

		if (bValidFence && FenceHeight - CapsuleBaseLocation.Z > TraceSettings.MinLedgeHeight && FenceHeight - DownwardTraceEnd.Z >  TraceSettings.FenceHeightOffset)
		{
			HitComponent = FenceHeightCheckResult.GetComponent();
			MantleVector = FenceHeightCheckResult.ImpactPoint;
			MaxMantleHeight = FenceHeight - CapsuleBaseLocation.Z;
			return true;
		}
	}
	return false;
}

bool UHiMantleComponent::LandPointCheck(const MantleCheckContext &Context, UPrimitiveComponent  * &HitComponent, FVector &MantleVector, float &MaxMantleHeight)
{
	auto &TraceSettings = Context.TraceSettings;
	auto &ClimbTraceStart = Context.ClimbTraceStart;
	auto &TraceDirection = Context.TraceDirection;
	auto &CapsuleBaseLocation = Context.CapsuleBaseLocation;
	auto &DebugType = Context.DebugType;
	auto &WallDistance = Context.WallDistance;

	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();
	float CapsuleRadius = Capsule->GetScaledCapsuleRadius();

	MaxMantleHeight = -10000.0f;
	HitComponent = nullptr;

	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	const FCollisionShape &CollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);
	
	check(TraceSettings.LandOffsets.Num() > 0);
	
	for (int i = 0; i < TraceSettings.LandOffsets.Num(); ++i)
	{
		float LandOffset = TraceSettings.LandOffsets[i];

		if (LandOffset > WallDistance)
		{
			break;
		}
	
		FHitResult DownHitResult;

		FVector DownwardTraceStart = ClimbTraceStart + TraceDirection * (LandOffset + CapsuleRadius);
		FVector DownwardTraceEnd = DownwardTraceStart;
		DownwardTraceEnd.Z = CapsuleBaseLocation.Z + TraceSettings.ForwardTraceRadius;

		bool bHit = World->SweepSingleByProfile(DownHitResult, DownwardTraceStart, DownwardTraceEnd, FQuat::Identity,
												  MantleObjectDetectionProfile, CollisionShape,
												  Params);

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
														   DownwardTraceStart,
														   DownwardTraceEnd,
														   CollisionShape,
														   DebugType,
														   bHit,
														   DownHitResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f);
		}
	
		//更近的LandOffset如果发现高度差更大的落地点，后面的落地点就不用检查了
		FVector ImpactPoint = DownwardTraceEnd;
		if (DownHitResult.IsValidBlockingHit())
		{
			if (!OwnerCharacter->GetCharacterMovement()->IsWalkable(DownHitResult))
			{
				continue;
			}
			if (!(DownHitResult.Component.IsValid() && DownHitResult.Component->CanCharacterClimb(OwnerCharacter)))
			{
				continue;
			}
			DownwardTraceEnd = DownHitResult.Location;
			ImpactPoint = DownHitResult.ImpactPoint;
		}
		else
		{
			ImpactPoint = DownHitResult.Location - TraceSettings.ForwardTraceRadius;
		}

		DownwardTraceEnd.Z -= TraceSettings.ForwardTraceRadius;
		
		const FVector& CapsuleLocationFBase = UHiCharacterMathLibrary::GetCapsuleLocationFromBase(
			DownwardTraceEnd, 2.0f, OwnerCharacter->GetCapsuleComponent());
		const bool bCapsuleHasRoom = UHiCharacterMathLibrary::CapsuleHasRoom(OwnerCharacter->GetCapsuleComponent(),
																		  CapsuleLocationFBase, MantleObjectDetectionProfile, 0.0f,
																		  0.0f, DebugType, HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces());

		if (!bCapsuleHasRoom)
		{
			// Capsule doesn't have enough room to mantle
			continue;
		}

		float MantleHeight = ImpactPoint.Z - CapsuleBaseLocation.Z;

		if (MantleHeight > TraceSettings.MinLedgeHeight && MantleHeight > MaxMantleHeight - TraceSettings.HeightTolerance)
		{
			MaxMantleHeight = MantleHeight;
			MantleVector = DownwardTraceEnd;
			HitComponent = DownHitResult.GetComponent();
		}
	}

	if (HitComponent)
	{
		return true;
	}

	return false;
}

//最全面的检查，检查是否能攀爬、上台阶、翻栅栏
bool UHiMantleComponent::GroundCheck(const FHiMantleTraceSettings& TraceSettings, EDrawDebugTrace::Type DebugType, bool bWait)
{
	if (!OwnerCharacter || !LocomotionComponent)
	{
		return false;
	}

	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();

	// Step 1: Trace forward to find a wall / object the character cannot walk on.
	FVector TraceDirection = OwnerCharacter->GetActorForwardVector();
	TraceDirection.Z = 0.0f;
	TraceDirection = TraceDirection.GetSafeNormal();
	const FVector &CapsuleBaseLocation = UHiCharacterMathLibrary::GetCapsuleBaseLocation(0.0f, Capsule);

	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	float MaxLedgeHeight = TraceSettings.MaxLedgeHeight;
	float MinLedgeHeight = TraceSettings.MinLedgeHeight;

	const FCollisionShape SphereCollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);
	
	FVector ClimbTraceStart = CapsuleBaseLocation;
	FVector InitialTraceNormal = -TraceDirection;

	FHitResult ForwardHitResult;
	{
		float HalfHeight = 1.0f + (MaxLedgeHeight - MinLedgeHeight) / 2.0f;
		FCollisionShape CapsuleCollisionShape = FCollisionShape::MakeCapsule(TraceSettings.ForwardTraceRadius, HalfHeight);
		
		FVector TraceStart = CapsuleBaseLocation;
		TraceStart.Z += (MaxLedgeHeight + MinLedgeHeight) / 2.0f;
		FVector TraceEnd = TraceStart + TraceDirection * TraceSettings.ReachDistance;
		bool bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart, TraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
	                                                  CapsuleCollisionShape, Params);
		if (ForwardHitResult.bStartPenetrating)
		{
			//说明头顶有屋檐结构，往上打射线确定屋檐的位置

			FVector UpTraceStart = CapsuleBaseLocation;
			UpTraceStart.Z += TraceSettings.ForwardTraceRadius;
			FVector UpTraceEnd = UpTraceStart;
			UpTraceEnd.Z += (MaxLedgeHeight - TraceSettings.ForwardTraceRadius);

			// 先往上打射线，检测头顶有没有屋檐之类结构
			FHitResult UpHitResult;

			/*const bool bHit = */World->SweepSingleByProfile(UpHitResult, UpTraceStart, UpTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
															  SphereCollisionShape, Params);

			if (UpHitResult.IsValidBlockingHit())
			{
				MaxLedgeHeight = UpHitResult.Distance + TraceSettings.ForwardTraceRadius * 2 - 1;
			}

			MinLedgeHeight = MinLedgeHeight > MaxLedgeHeight ? MaxLedgeHeight : MinLedgeHeight;

			// 重新往前打一次射线，理论上这次不会bStartPenetrating了

			TraceStart = CapsuleBaseLocation;
			TraceStart.Z += (MaxLedgeHeight + MinLedgeHeight) / 2.0f;
			TraceEnd = TraceStart + TraceDirection * TraceSettings.ReachDistance;

			HalfHeight = (MaxLedgeHeight - MinLedgeHeight) / 2.0f;
			CapsuleCollisionShape = FCollisionShape::MakeCapsule(TraceSettings.ForwardTraceRadius, HalfHeight);
			
			bHit = World->SweepSingleByProfile(ForwardHitResult, TraceStart, TraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
														  CapsuleCollisionShape, Params);
		}
		else if (!ForwardHitResult.IsValidBlockingHit())
		{
			// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d 111"), (int32)OwnerCharacter->GetWorld()->GetNetMode());
			// Not a valid surface to mantle
			return false;	
		}
		{
			if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
			{
				UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
																ForwardHitResult.TraceStart,
																ForwardHitResult.TraceEnd,
																CapsuleCollisionShape,
																DebugType,
																bHit,
																ForwardHitResult,
																FLinearColor::Green,
																FLinearColor::Blue,
																10.0f);
			}

			if (ForwardHitResult.IsValidBlockingHit() && ForwardHitResult.Component.IsValid() && !ForwardHitResult.Component->CanCharacterClimb(OwnerCharacter))
			{
				// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d 222"), (int32)OwnerCharacter->GetWorld()->GetNetMode());
				return false;
			}
			
			//打到了可能是墙壁的结构，要检查一下有没有可能是屋檐
			FVector EaveCheckTraceStart = ForwardHitResult.Location;
			EaveCheckTraceStart.Z = TraceStart.Z - (HalfHeight - TraceSettings.ForwardTraceRadius);
			FVector EaveCheckTraceEnd = EaveCheckTraceStart + TraceDirection * TraceSettings.EaveWide;

			FHitResult EaveCheckResult;
			
			bool bEaveCheckHit = World->SweepSingleByProfile(EaveCheckResult, EaveCheckTraceStart, EaveCheckTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
															  SphereCollisionShape, Params);

			if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
			{
				UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
																EaveCheckResult.TraceStart,
																EaveCheckResult.TraceEnd,
																SphereCollisionShape,
																DebugType,
																bEaveCheckHit,
																EaveCheckResult,
																FLinearColor::Green,
																FLinearColor::Blue,
																10.0f);
			}

			if (!EaveCheckResult.bStartPenetrating && !EaveCheckResult.IsValidBlockingHit())
			{
				EaveCheckTraceStart = EaveCheckTraceEnd;
				EaveCheckTraceEnd.Z -= MinLedgeHeight;

				World->SweepSingleByProfile(EaveCheckResult, EaveCheckTraceStart, EaveCheckTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
																  SphereCollisionShape, Params);

				FVector CapsuleLocationFBase = EaveCheckResult.Location;

				CapsuleLocationFBase.Z += Capsule->GetScaledCapsuleHalfHeight_WithoutHemisphere();

				const bool bCapsuleHasRoom = UHiCharacterMathLibrary::CapsuleHasRoom(OwnerCharacter->GetCapsuleComponent(),
																			  CapsuleLocationFBase, MantleObjectDetectionProfile, 1.0f,
																			  0.0f, DebugType, HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces());
				//屋檐下如果能容纳一个人，就不要触发攀爬
				if (bCapsuleHasRoom)
				{
					// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d aaa"), (int32)OwnerCharacter->GetWorld()->GetNetMode());
					return false;
				}
			}
		}

		{
			TraceStart.Z = CapsuleBaseLocation.Z + MinLedgeHeight;
			TraceEnd = TraceStart + TraceDirection * (TraceSettings.ReachDistance + TraceSettings.ForwardTraceRadius);
			FHitResult WalkableCheckResult;
			World->LineTraceSingleByProfile(WalkableCheckResult, TraceStart, TraceEnd, MantleObjectDetectionProfile, Params);
			if (WalkableCheckResult.IsValidBlockingHit())
			{
				FVector AverageSlope = (ForwardHitResult.ImpactPoint - WalkableCheckResult.ImpactPoint).GetSafeNormal();
				if (AverageSlope.Size2D() > OwnerCharacter->GetCharacterMovement()->GetWalkableFloorZ() && (ForwardHitResult.ImpactPoint - WalkableCheckResult.ImpactPoint).Size2D() < 10.0f)
				{
					TraceStart.Z = CapsuleBaseLocation.Z + MinLedgeHeight * 0.5;
					TraceEnd = TraceStart + TraceDirection * (TraceSettings.ReachDistance + TraceSettings.ForwardTraceRadius);
					
					FHitResult WalkableCheckResult2;
					World->LineTraceSingleByProfile(WalkableCheckResult2, TraceStart, TraceEnd, MantleObjectDetectionProfile, Params);

					if (WalkableCheckResult2.IsValidBlockingHit())
					{
						AverageSlope = (WalkableCheckResult2.ImpactPoint - WalkableCheckResult.ImpactPoint).GetSafeNormal();
						if (AverageSlope.Size2D() > OwnerCharacter->GetCharacterMovement()->GetWalkableFloorZ() && (ForwardHitResult.ImpactPoint - WalkableCheckResult.ImpactPoint).Size2D() < 10.0f)
						{
							// UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d 333"), (int32)OwnerCharacter->GetWorld()->GetNetMode());
							return false;
						}
					}
				}
			}
		}
		
		ClimbTraceStart = ForwardHitResult.Location;
		InitialTraceNormal = ForwardHitResult.ImpactNormal;
	}

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d %s, %s, %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *TraceDirection.ToString(), *CapsuleBaseLocation.ToString(), *OwnerCharacter->GetActorLocation().ToString());
	
	//TraceStart = TraceStart - TraceDirection * TraceSettings.StartOffset;

	UPrimitiveComponent* HitComponent = nullptr;
	FVector MantleVector = CapsuleBaseLocation;
	float MaxMantleHeight = -100000.0f;

	{
		float CapsuleRadius = Capsule->GetScaledCapsuleRadius();
		// 检测平台高度，从MaxLedgeHeight + TraceSettings.ForwardTraceRadius高度横向打射线，检测台阶状结构
		FHitResult horizontalHitResult;
		ClimbTraceStart.Z = (CapsuleBaseLocation.Z + MaxLedgeHeight - TraceSettings.ForwardTraceRadius);
		const FCollisionShape CollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);

		bool bClimb = false;
		FHitResult WallCheckResult;
		FVector ClimbTraceEnd = ClimbTraceStart + TraceDirection * TraceSettings.MantleWallDistance;
		bool bHit = World->SweepSingleByProfile(WallCheckResult, ClimbTraceStart, ClimbTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
																  CollisionShape, Params);

		float WallDistance = WallCheckResult.Distance;
		if (WallCheckResult.bStartPenetrating || WallCheckResult.IsValidBlockingHit())
		{
			bClimb = true;
		}
		else
		{
			WallDistance = TraceSettings.MantleWallDistance;
		}

		if (!bClimb)
		{
			MantleCheckContext Context;
			Context.TraceSettings = TraceSettings;
			Context.ClimbTraceStart = ClimbTraceStart;
			Context.CapsuleBaseLocation = CapsuleBaseLocation;
			Context.TraceDirection = TraceDirection;
			Context.WallDistance = WallDistance;
			Context.DebugType = DebugType;

			if (FenceCheck(Context, HitComponent, MantleVector, MaxMantleHeight))
			{
				MantleSubType = EHiMantleSubType::Fence;
			}
			else
			{
				if (LandPointCheck(Context, HitComponent, MantleVector, MaxMantleHeight))
				{
					MantleSubType = EHiMantleSubType::Ledge;
				}
			}
		}

		if (bClimb)
		{
			return TryStartClimb(ForwardHitResult, TraceDirection, WallCheckResult, bWait);
		}
		else if (HitComponent && CanMantle())
		{
			FTransform TargetTransform(
			(TraceDirection * FVector(1.0f, 1.0f, 0.0f)).ToOrientationRotator(),
			MantleVector,
			FVector::OneVector);
			return TryStartMantle(HitComponent, TargetTransform, CapsuleBaseLocation, MaxMantleHeight, bWait);
		}
	}
	return false;
}

bool UHiMantleComponent::TryStartClimb(const FHitResult &ForwardHitResult, const FVector &TraceDirection, const FHitResult &WallCheckResult, bool bWait)
{
	EHiWallRunType NewType = CanStartClimb(ForwardHitResult);
	if (NewType != EHiWallRunType::None)
	{
		const FHiMantleWaitTimeSettings &ClimbWaitTimeSettings = GetClimbWaitTime(NewType);
					
		if (!bWait || WaitTimeCheck(ClimbWaitTimeSettings))
		{
			MantleSubType = EHiMantleSubType::None;
			FTransform RootTargetTransform = FTransform::Identity;
			UMotionWarpingComponent *MotionWarpingComponent = Cast<UMotionWarpingComponent>(OwnerCharacter->GetComponentByClass(UMotionWarpingComponent::StaticClass()));
			if (MotionWarpingComponent)
			{
				if (WallCheckResult.IsValidBlockingHit())
				{
					RootTargetTransform.SetScale3D(FVector(WallCheckResult.Distance, 1.0, 1.0f));
				}
				MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(MotionWarpingTargetName, RootTargetTransform);
			}
			//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d bbb"), (int32)OwnerCharacter->GetWorld()->GetNetMode());
			const FVector &Direction = TraceDirection.GetSafeNormal();
			ClimbStart(NewType, ForwardHitResult, Direction);
			return true;
		}
	}
	return false;
}

bool UHiMantleComponent::TryStartMantle(UPrimitiveComponent* HitComponent, const FTransform &TargetTransform, const FVector &CapsuleBaseLocation, float MaxMantleHeight, bool bWait)
{
	const FHiMantleAsset &MantleAsset = GetMantleAsset(ClimbType, MaxMantleHeight);
	const FHiMantleWaitTimeSettings &MantleWaitTimeSettings = GetMantleWaitTime(MantleAsset.MantleSubType);
	
	if (!bWait || WaitTimeCheck(MantleWaitTimeSettings))
	{
		FHiComponentAndTransform MantleWS;
		
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleStart %d %f"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), Size2D);
	
		// Step 4: Determine the Mantle Type by checking the movement mode and Mantle Height.
		MantleWS.Component = HitComponent;
		MantleWS.Transform = TargetTransform;
		MantleWS.LandTransform.SetLocation(CapsuleBaseLocation);

		// Step 5: If everything checks out, start the Mantle
		MantleStart(MantleAsset, MaxMantleHeight, MantleWS, ClimbType);
		return true;
	}

	return false;
}

bool UHiMantleComponent::TryStartFlyOver(UPrimitiveComponent* HitComponent, const FTransform &TargetTransform)
{
	MantleSubType = EHiMantleSubType::FlyOver;
	const FHiMantleAsset &MantleAsset = GetMantleAsset(ClimbType);

	if (MantleAsset.AnimMontage)
	{
		FHiComponentAndTransform MantleWS;
		
		//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleStart %d %f"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), Size2D);
	
		// Step 4: Determine the Mantle Type by checking the movement mode and Mantle Height.
		MantleWS.Component = HitComponent;
		MantleWS.Transform = TargetTransform;

		FlyOverStart(MantleAsset, MantleWS);
		return true;
		// Step 5: If everything checks out, start the Mantle
	}

	return false;
}

void UHiMantleComponent::FlyOverStart_Implementation(const FHiMantleAsset &MantleAsset, const FHiComponentAndTransform& MantleWS)
{
	MontageEndedDelegate.BindUObject(this, &UHiMantleComponent::OnFlyOverMontageEnded);
	MontageBlendingOutDelegate.BindUObject(this, &UHiMantleComponent::OnFlyOverMontageEnded);
	ClimbType = EHiClimbType::Mantle;
	PlayMantleMontage(MantleAsset, MantleWS);
}

void UHiMantleComponent::FlyOverEnd_Implementation()
{
	ClimbType = EHiClimbType::WallRun;
}

void UHiMantleComponent::OnFlyOverMontageEnded_Implementation(UAnimMontage* Montage, bool bInterrupted)
{
	FlyOverEnd();
}

bool UHiMantleComponent::ObstacleCheck(const FHiMantleTraceSettings& TraceSettings, EDrawDebugTrace::Type DebugType)
{
	if (!OwnerCharacter || !LocomotionComponent)
	{
		return false;
	}

	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();
	
	FVector CapsuleLocation = Capsule->GetComponentLocation();
	float HalfHeight = Capsule->GetScaledCapsuleHalfHeight_WithoutHemisphere();
	
	FVector UpVector = Capsule->GetUpVector();

	// Step 1: Trace forward to find a wall / object the character cannot walk on.
	FVector TraceDirection = OwnerCharacter->GetActorForwardVector();
	TraceDirection.Z = 0.0f;
	TraceDirection = TraceDirection.GetSafeNormal();

	const FCollisionShape &CollisionShape = FCollisionShape::MakeCapsule(TraceSettings.ForwardTraceRadius, TraceSettings.ObstacleCheckHeight * 0.5f + TraceSettings.ForwardTraceRadius);
	
	FVector ClimbTraceStart = CapsuleLocation + UpVector * HalfHeight - TraceDirection * TraceSettings.ObstacleCheckDistance.Y;
	ClimbTraceStart.Z += TraceSettings.ObstacleCheckOffset;
	
	FVector ClimbTraceEnd = ClimbTraceStart + TraceDirection * (TraceSettings.ObstacleCheckDistance.Y - TraceSettings.ObstacleCheckDistance.X);
	
	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);
	
	FHitResult ObstacleCheckResult;
	bool bHit = World->SweepSingleByProfile(ObstacleCheckResult, ClimbTraceStart, ClimbTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
															  CollisionShape, Params);
	
	UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
														   ClimbTraceStart,
														   ClimbTraceEnd,
														   CollisionShape,
														   DebugType,
														   bHit,
														   ObstacleCheckResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f);

	if (ObstacleCheckResult.IsValidBlockingHit())
	{
		UPrimitiveComponent* HitComponent = ObstacleCheckResult.GetComponent();

		FTransform TargetTransform(
			(TraceDirection * FVector(1.0f, 1.0f, 0.0f)).ToOrientationRotator(),
			ObstacleCheckResult.ImpactPoint,
			FVector::OneVector);
			
		return TryStartFlyOver(HitComponent, TargetTransform);
	}

	return false;
}

//攀爬的时候检测能否到顶
bool UHiMantleComponent::ReachRoofCheck(const FHiMantleTraceSettings& TraceSettings, EDrawDebugTrace::Type DebugType, bool bWait)
{
	if (!OwnerCharacter || !LocomotionComponent)
	{
		return false;
	}

	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();
	float CapsuleRadius = Capsule->GetScaledCapsuleRadius();

	// Step 1: Trace forward to find a wall / object the character cannot walk on.
	FVector TraceDirection = OwnerCharacter->GetActorForwardVector();
	TraceDirection.Z = 0.0f;
	TraceDirection = TraceDirection.GetSafeNormal();
	const FVector &CapsuleBaseLocation = UHiCharacterMathLibrary::GetCapsuleBaseLocation(0.0f, Capsule);

	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	float MaxLedgeHeight = TraceSettings.MaxLedgeHeight;
	
	FVector ClimbTraceStart = CapsuleBaseLocation;
	
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d %s, %s, %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *TraceDirection.ToString(), *CapsuleBaseLocation.ToString(), *OwnerCharacter->GetActorLocation().ToString());
	
	//TraceStart = TraceStart - TraceDirection * TraceSettings.StartOffset;

	UPrimitiveComponent* HitComponent = nullptr;
	FVector MantleVector = CapsuleBaseLocation;
	float MaxMantleHeight = -100000.0f;
	
	// 检测平台高度，从MaxLedgeHeight + TraceSettings.ForwardTraceRadius高度横向打射线，检测台阶状结构
	ClimbTraceStart.Z = (CapsuleBaseLocation.Z + MaxLedgeHeight - TraceSettings.ForwardTraceRadius);
	const FCollisionShape CollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);

	FHitResult WallCheckResult;
	FVector ClimbTraceEnd = ClimbTraceStart + TraceDirection * TraceSettings.MantleWallDistance;
	bool bHit = World->SweepSingleByProfile(WallCheckResult, ClimbTraceStart, ClimbTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
															  CollisionShape, Params);

	float WallDistance = WallCheckResult.Distance;
	if (WallCheckResult.bStartPenetrating || WallCheckResult.IsValidBlockingHit())
	{
		return false;
	}
	else
	{
		WallDistance = TraceSettings.MantleWallDistance;
	}
	
	for (int i = 0; i < TraceSettings.FenceOffsets.Num(); ++i)
	{
		float FenceOffset = TraceSettings.FenceOffsets[i];

		if (FenceOffset > WallDistance)
		{
			break;
		}

		//const FCollisionShape FenceHeightCheckShape = FCollisionShape::MakeBox(FVector(TraceSettings.ForwardTraceRadius, FenceOffset * 0.5, 1));

		const FCollisionShape &FenceHeightCheckShape = FCollisionShape::MakeCapsule(TraceSettings.ForwardTraceRadius, FenceOffset * 0.5);
		
		FVector FenceHeightCheckStart = ClimbTraceStart + TraceDirection * (FenceOffset * 0.5 + CapsuleRadius);
		FVector FenceHeightCheckEnd = FenceHeightCheckStart;
		FenceHeightCheckEnd.Z = CapsuleBaseLocation.Z;

		FHitResult FenceHeightCheckResult;

		FQuat FenceCheckQuat = TraceDirection.ToOrientationQuat() * FRotator(90, 0, 0).Quaternion();

		bHit = World->SweepSingleByProfile(FenceHeightCheckResult, FenceHeightCheckStart, FenceHeightCheckEnd, FenceCheckQuat,
												  MantleObjectDetectionProfile, FenceHeightCheckShape,
												  Params);

		if (!FenceHeightCheckResult.IsValidBlockingHit())
		{
			continue;
		}

		if (!OwnerCharacter->GetCharacterMovement()->IsWalkable(FenceHeightCheckResult))
		{
			continue;
		}
		if (!(FenceHeightCheckResult.Component.IsValid() && FenceHeightCheckResult.Component->CanCharacterClimb(OwnerCharacter)))
		{
			continue;
		}

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugCapsuleTraceSingle(World,
														   FenceHeightCheckStart,
														   FenceHeightCheckEnd,
														   FenceHeightCheckShape,
														   DebugType,
														   bHit,
														   FenceHeightCheckResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f,
														   TraceDirection.ToOrientationQuat() * FRotator(90, 0, 0).Quaternion());
		}
		
		float FenceHeight = FenceHeightCheckResult.ImpactPoint.Z;

		FHitResult DownHitResult;
		
		FVector DownwardTraceStart = ClimbTraceStart + TraceDirection * (FenceOffset + CapsuleRadius * 2 + 0.1f);
		FVector DownwardTraceEnd = DownwardTraceStart;
		DownwardTraceEnd.Z = CapsuleBaseLocation.Z + TraceSettings.ForwardTraceRadius;

		bHit = World->SweepSingleByProfile(DownHitResult, DownwardTraceStart, DownwardTraceEnd, FQuat::Identity,
												  MantleObjectDetectionProfile, CollisionShape,
												  Params);

		if (HiCharacterDebugComponent && HiCharacterDebugComponent->GetShowTraces())
		{
			UHiCharacterDebugComponent::DrawDebugSphereTraceSingle(World,
														   DownwardTraceStart,
														   DownwardTraceEnd,
														   CollisionShape,
														   DebugType,
														   bHit,
														   DownHitResult,
														   FLinearColor::White,
														   FLinearColor::Black,
														   10.0f);
		}

		if (DownHitResult.bStartPenetrating)
		{
			continue;
		}
		
		//更近的LandOffset如果发现高度差更大的落地点，后面的落地点就不用检查了
		if (DownHitResult.IsValidBlockingHit())
		{
			DownwardTraceEnd = DownHitResult.Location;
		}

		DownwardTraceEnd.Z -= TraceSettings.ForwardTraceRadius;
		
		if (FenceHeight - DownwardTraceEnd.Z >  TraceSettings.FenceHeightOffset)
		{
			HitComponent = FenceHeightCheckResult.GetComponent();
			MantleVector = FenceHeightCheckResult.ImpactPoint;
			MaxMantleHeight = FenceHeight - CapsuleBaseLocation.Z;
			break;
		}
	}

	if (!HitComponent)
	{
		MantleCheckContext Context;
		Context.TraceSettings = TraceSettings;
		Context.ClimbTraceStart = ClimbTraceStart;
		Context.CapsuleBaseLocation = CapsuleBaseLocation;
		Context.TraceDirection = TraceDirection;
		Context.WallDistance = WallDistance;
		Context.DebugType = DebugType;

		LandPointCheck(Context, HitComponent, MantleVector, MaxMantleHeight);
	}

	if (HitComponent)
	{
		MantleSubType = EHiMantleSubType::Sprint;

		FTransform TargetTransform(
			(TraceDirection * FVector(1.0f, 1.0f, 0.0f)).ToOrientationRotator(),
			MantleVector,
			FVector::OneVector);
		return TryStartMantle(HitComponent, TargetTransform, CapsuleBaseLocation, MaxMantleHeight, bWait);
	}
	return false;
}

//翻越或者播放到顶的过程中检测能否打断继续攀爬
bool UHiMantleComponent::MantleCheck(const FHiMantleTraceSettings& TraceSettings, EDrawDebugTrace::Type DebugType, bool bWait)
{
	if (!OwnerCharacter || !LocomotionComponent)
	{
		return false;
	}
	
	// Step 1: Trace forward to find a wall / object the character cannot walk on.
	FVector TraceDirection = OwnerCharacter->GetActorForwardVector();
	TraceDirection.Z = 0.0f;
	TraceDirection = TraceDirection.GetSafeNormal();
	UCapsuleComponent* Capsule = OwnerCharacter->GetCapsuleComponent();
	const FVector &CapsuleBaseLocation = UHiCharacterMathLibrary::GetCapsuleBaseLocation(0.0f, Capsule);

	UWorld* World = GetWorld();
	check(World);
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(OwnerCharacter);

	float MaxLedgeHeight = TraceSettings.MaxLedgeHeight;
	
	FVector ClimbTraceStart = CapsuleBaseLocation;

	FHitResult ForwardHitResult;

	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::MantleCheck %d %s, %s, %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *TraceDirection.ToString(), *CapsuleBaseLocation.ToString(), *OwnerCharacter->GetActorLocation().ToString());
	
	//TraceStart = TraceStart - TraceDirection * TraceSettings.StartOffset;
	
	{
		// 检测平台高度，从MaxLedgeHeight + TraceSettings.ForwardTraceRadius高度横向打射线，检测台阶状结构
		ClimbTraceStart.Z = (CapsuleBaseLocation.Z + MaxLedgeHeight - TraceSettings.ForwardTraceRadius);
		const FCollisionShape CollisionShape = FCollisionShape::MakeSphere(TraceSettings.ForwardTraceRadius);

		FHitResult WallCheckResult;
		FVector ClimbTraceEnd = ClimbTraceStart + TraceDirection * TraceSettings.MantleWallDistance;
		bool bHit = World->SweepSingleByProfile(WallCheckResult, ClimbTraceStart, ClimbTraceEnd, FQuat::Identity, MantleObjectDetectionProfile,
																  CollisionShape, Params);

		if (WallCheckResult.bStartPenetrating || WallCheckResult.IsValidBlockingHit())
		{
			return TryStartClimb(ForwardHitResult, TraceDirection, WallCheckResult, bWait);
		}
	}

	return false;
}

void UHiMantleComponent::CalcVelocityForClimb(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	if (MyCharacterMovementComponent->Acceleration.IsNearlyZero())
	{
		MyCharacterMovementComponent->Velocity = FVector(0, 0, 0);
	}
	else
	{
		MyCharacterMovementComponent->Velocity = MyCharacterMovementComponent->Acceleration.GetSafeNormal() * MaxClimbMovementSpeed;
	}
}

void UHiMantleComponent::ClimbUpdate_Implementation(float DeltaTime)
{
	
}

// This function is called by "MantleTimeline" using BindUFunction in the AALSBaseCharacter::BeginPlay during the default settings initalization.
void UHiMantleComponent::MantleUpdate_Implementation(float DeltaTime)
{
	if (!OwnerCharacter)
	{
		return;
	}
	
	// Step 1: Continually update the mantle target from the stored local transform to follow along with moving objects
	if (MantleLedgeLS.Component)
	{
		MantleTarget = FTransform(MantleLedgeLS.Matrix * MantleLedgeLS.Component->GetComponentToWorld().ToMatrixWithScale());
	}
	else
	{
		MantleTarget = FTransform(MantleLedgeLS.Matrix);
	}

	AActor *Owner = GetOwner();
	
	UMotionWarpingComponent *MotionWarpingComponent = Cast<UMotionWarpingComponent>(Owner->GetComponentByClass(UMotionWarpingComponent::StaticClass()));
	MotionWarpingComponent->AddOrUpdateWarpTargetFromTransform(MotionWarpingTargetName, MantleTarget);
}

void UHiMantleComponent::MantleEnd_Implementation()
{
	if (ClimbType != EHiClimbType::Mantle)
	{
		return;
	}
	ClimbType = EHiClimbType::None;
	
	// Set the Character Movement Mode to Walking
	/*if (OwnerCharacter)
	{
		OwnerCharacter->GetCharacterMovement()->SetMovementMode(MOVE_Walking);
	}*/

	// Enable ticking back after mantle ends
	// SetComponentTickEnabledAsync(true);
}

