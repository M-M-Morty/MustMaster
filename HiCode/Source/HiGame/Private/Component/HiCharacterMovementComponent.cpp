#include "Component/HiCharacterMovementComponent.h"

#include "HiWorldSettings.h"
#include "MotionWarpingComponent.h"
#include "Characters/HiLocomotionCharacter.h"
#include "Characters/HiPlayerCameraManager.h"
#include "Net/PerfCountersHelpers.h"
#include "Stats/Stats2.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/GameNetworkManager.h"
#include "GameFramework/WorldSettings.h"
#include "GameFramework/PhysicsVolume.h"
#include "Component/HiAvatarLocomotionAppearance.h"
#include "Component/HiJumpComponent.h"
#include "Components/CapsuleComponent.h"
#include "Engine/ScopedMovementUpdate.h"
#include "Characters/HiCharacter.h"

#include "Curves/CurveVector.h"


DECLARE_CYCLE_STAT(TEXT("Char Update Acceleration"), STAT_CharUpdateAcceleration, STATGROUP_Character);
DECLARE_CYCLE_STAT(TEXT("Char FindFloor"), STAT_CharFindFloor, STATGROUP_Character);
DECLARE_CYCLE_STAT(TEXT("Char SprintClimbStepUp"), STAT_CharSprintClimbStepUp, STATGROUP_Character);
DECLARE_CYCLE_STAT(TEXT("Char PhysGlide"), STAT_CharPhysGlide, STATGROUP_Character);
DECLARE_CYCLE_STAT(TEXT("Char ProcessGlideLanded"), STAT_CharProcessGlideLanded, STATGROUP_Character);

DEFINE_LOG_CATEGORY_STATIC(LogHiCharacterMovement, Log, All);

static const FString PerfCounter_NumServerMoves = TEXT("NumServerMoves");
static const FString PerfCounter_NumServerMoveCorrections = TEXT("NumServerMoveCorrections");

namespace HiCharacterMovementCVars
{
	static float NetServerMoveTimestampExpiredWarningThreshold = 1.0f;
	FAutoConsoleVariableRef CVarNetServerMoveTimestampExpiredWarningThreshold(
		TEXT("net.NetServerMoveTimestampExpiredWarningThreshold"),
		NetServerMoveTimestampExpiredWarningThreshold,
		TEXT("Tolerance for ServerMove() to warn when client moves are expired more than this time threshold behind the server."),
		ECVF_Default);
	
	static float ClientAuthorityThresholdOnBaseChange = 0.f;
	FAutoConsoleVariableRef CVarClientAuthorityThresholdOnBaseChange(
		TEXT("p.ClientAuthorityThresholdOnBaseChange"),
		ClientAuthorityThresholdOnBaseChange,
		TEXT("When a pawn moves onto or off of a moving base, this can cause an abrupt correction. In these cases, trust the client up to this distance away from the server component location."),
		ECVF_Default);

	static float MaxFallingCorrectionLeash = 0.f;
	FAutoConsoleVariableRef CVarMaxFallingCorrectionLeash(
		TEXT("p.MaxFallingCorrectionLeash"),
		MaxFallingCorrectionLeash,
		TEXT("When airborne, some distance between the server and client locations may remain to avoid sudden corrections as clients jump from moving bases. This value is the maximum allowed distance."),
		ECVF_Default);

	static float MaxFallingCorrectionLeashBuffer = 10.f;
	FAutoConsoleVariableRef CVarMaxFallingCorrectionLeashBuffer(
		TEXT("p.MaxFallingCorrectionLeashBuffer"),
		MaxFallingCorrectionLeashBuffer,
		TEXT("To avoid constant corrections, when an airborne server and client are further than p.MaxFallingCorrectionLeash cm apart, they'll be pulled in to that distance minus this value."),
		ECVF_Default);

#if !UE_BUILD_SHIPPING

	int32 NetShowCorrections = 0;
	FAutoConsoleVariableRef CVarNetShowCorrections(
		TEXT("p.NetShowCorrections"),
		NetShowCorrections,
		TEXT("Whether to draw client position corrections (red is incorrect, green is corrected).\n")
		TEXT("0: Disable, 1: Enable"),
		ECVF_Cheat);

	float NetCorrectionLifetime = 4.f;
	FAutoConsoleVariableRef CVarNetCorrectionLifetime(
		TEXT("p.NetCorrectionLifetime"),
		NetCorrectionLifetime,
		TEXT("How long a visualized network correction persists.\n")
		TEXT("Time in seconds each visualized network correction persists."),
		ECVF_Cheat);

#endif // !UE_BUILD_SHIPPING

#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)

	static float NetForceClientAdjustmentPercent = 0.f;
	FAutoConsoleVariableRef CVarNetForceClientAdjustmentPercent(
		TEXT("p.NetForceClientAdjustmentPercent"),
		NetForceClientAdjustmentPercent,
		TEXT("Percent of ServerCheckClientError checks to return true regardless of actual error.\n")
		TEXT("Useful for testing client correction code.\n")
		TEXT("<=0: Disable, 0.05: 5% of checks will return failed, 1.0: Always send client adjustments"),
		ECVF_Cheat);

#endif  // !(UE_BUILD_SHIPPING || UE_BUILD_TEST)

}

namespace HiCharacterMovementConstants
{
	// MAGIC NUMBERS
	const float MAX_STEP_SIDE_Z = 0.08f;	// maximum z value for the normal on the vertical side of steps
}

/********** UHiCharacterMovementComponent ***********/
UHiCharacterMovementComponent::UHiCharacterMovementComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	MinimumSlideDeltaCos = FMath::Cos(FMath::DegreesToRadians(180 - MinimumSlideDeltaAngle));
	BufferVelocity = FVector::ZeroVector;
	BufferAcceleratedVelocity = FVector::ZeroVector;
}

void UHiCharacterMovementComponent::InitializeComponent()
{
	Super::InitializeComponent();


	if (AHiCharacter* HiCharacter = Cast<AHiCharacter>(CharacterOwner))
	{
		HiCharacter->OnPossessedByDelegate.AddUniqueDynamic(this, &UHiCharacterMovementComponent::OnPossessedBy);
		HiCharacter->OnUnPossessedByDelegate.AddUniqueDynamic(this, &UHiCharacterMovementComponent::OnUnPossessedBy);
	}
}

void UHiCharacterMovementComponent::BeginPlay()
{
	Super::BeginPlay();

	// Order: MotionWarping --> Movement
	MotionWarpingComponent = CharacterOwner->FindComponentByClass<UMotionWarpingComponent>();
	if (MotionWarpingComponent)
	{
		AddTickPrerequisiteComponent(MotionWarpingComponent);
	}

	JumpComponent = CharacterOwner->FindComponentByClass<UHiJumpComponent>();

	AppearanceComponent = CharacterOwner->FindComponentByClass<UHiAvatarLocomotionAppearance>();

	MaxWallStepHeight = MaxStepHeight;
}

void UHiCharacterMovementComponent::OnPossessedBy_Implementation(AController* NewController)
{
    // Fixed mesh offset caused by character switching (Simulated Character -> Autonomous Character)
	CharacterOwner->GetMesh()->SetRelativeLocationAndRotation(CharacterOwner->GetBaseTranslationOffset(), CharacterOwner->GetBaseRotationOffset(), false, nullptr, ETeleportType::ResetPhysics);
}

void UHiCharacterMovementComponent::OnUnPossessedBy_Implementation(AController* NewController)
{
}

void UHiCharacterMovementComponent::TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (OnMovementTickEndTrigger.IsBound())
	{
		OnMovementTickEndTrigger.Broadcast();
		OnMovementTickEndTrigger.Clear();
	}

	AHiLocomotionCharacter* HiLocomotionCharacter = Cast<AHiLocomotionCharacter>(CharacterOwner);
	if(HiLocomotionCharacter && HiLocomotionCharacter->bTriggerLandedAutoJump)
	{
		HiLocomotionCharacter->LandedAutoJump();
	}
}

void UHiCharacterMovementComponent::HandleImpact(const FHitResult& Hit, float TimeSlice, const FVector& MoveDelta)
{
	Super::HandleImpact(Hit, TimeSlice, MoveDelta);
}

void UHiCharacterMovementComponent::ClientAdjustPosition_Implementation
	(
	float TimeStamp,
	FVector NewLocation,
	FVector NewVelocity,
	UPrimitiveComponent* NewBase,
	FName NewBaseBoneName,
	bool bHasBase,
	bool bBaseRelativePosition,
	uint8 ServerMovementMode,
	TOptional<FRotator> OptionalRotation /* = TOptional<FRotator>()*/
	)
{
	if (ServerCanAcceptClientPosition())
	{
		return;
	}
	Super::ClientAdjustPosition_Implementation(TimeStamp, NewLocation, NewVelocity, NewBase, NewBaseBoneName, bHasBase, bBaseRelativePosition, ServerMovementMode, OptionalRotation);
}

void UHiCharacterMovementComponent::ServerMove_PerformMovement(const FCharacterNetworkMoveData& MoveData)
{
	//SCOPE_CYCLE_COUNTER(STAT_CharacterMovementServerMove);
	//CSV_SCOPED_TIMING_STAT(CharacterMovement, CharacterMovementServerMove);

	if (!HasValidData() || !IsActive())
	{
		return;
	}	

	const float ClientTimeStamp = MoveData.TimeStamp;
	FVector_NetQuantize10 ClientAccel = MoveData.Acceleration;
	const uint8 ClientMoveFlags = MoveData.CompressedMoveFlags;
	const FRotator ClientControlRotation = MoveData.ControlRotation;

	FNetworkPredictionData_Server_Character* ServerData = GetPredictionData_Server_Character();
	check(ServerData);

	if( !VerifyClientTimeStamp(ClientTimeStamp, *ServerData) )
	{
		const float ServerTimeStamp = ServerData->CurrentClientTimeStamp;
		// This is more severe if the timestamp has a large discrepancy and hasn't been recently reset.
		if (ServerTimeStamp > 1.0f && FMath::Abs(ServerTimeStamp - ClientTimeStamp) > HiCharacterMovementCVars::NetServerMoveTimestampExpiredWarningThreshold)
		{
			UE_LOG(LogNetPlayerMovement, Warning, TEXT("ServerMove: TimeStamp expired: %f, CurrentTimeStamp: %f, Character: %s"), ClientTimeStamp, ServerTimeStamp, *GetNameSafe(CharacterOwner));
		}
		else
		{
			UE_LOG(LogNetPlayerMovement, Log, TEXT("ServerMove: TimeStamp expired: %f, CurrentTimeStamp: %f, Character: %s"), ClientTimeStamp, ServerTimeStamp, *GetNameSafe(CharacterOwner));
		}		
		return;
	}

	bool bServerReadyForClient = true;
	APlayerController* PC = Cast<APlayerController>(CharacterOwner->GetController());
	if (PC)
	{
		bServerReadyForClient = PC->NotifyServerReceivedClientData(CharacterOwner, ClientTimeStamp);
#if LQT_DISTRIBUTED_DS
		bServerReadyForClient = bServerReadyForClient || CharacterOwner->GetLocalRole() == ROLE_Authority;
#endif
		if (!bServerReadyForClient)
		{
			ClientAccel = FVector::ZeroVector;
		}
	}

	const UWorld* MyWorld = GetWorld();
	const float DeltaTime = ServerData->GetServerMoveDeltaTime(ClientTimeStamp, CharacterOwner->GetActorTimeDilation(*MyWorld));

	if (DeltaTime > 0.f)
	{
		ServerData->CurrentClientTimeStamp = ClientTimeStamp;
		ServerData->ServerAccumulatedClientTimeStamp += DeltaTime;
		ServerData->ServerTimeStamp = MyWorld->GetTimeSeconds();
		ServerData->ServerTimeStampLastServerMove = ServerData->ServerTimeStamp;

		const bool bPerformActualMovement = (MyWorld->GetWorldSettings()->GetPauserPlayerState() == NULL);

		if (PC && (!bServerReadyForClient || !bPerformActualMovement))
		{
			PC->SetControlRotation(ClientControlRotation);
		}

		if (!bServerReadyForClient)
		{
			return;
		}

		// Perform actual movement
		if (bPerformActualMovement)
		{
			if (PC)
			{
				if (ServerControlRotationSimulateMode == EHiServerControlRotationSimulateMode::BasedOnClient)
				{
					// The original UE calculation logic
					// Will cause the server to update again after the client has already updated one frame, resulting in incorrect frames
					PC->SetControlRotation(ClientControlRotation);
				}
				// Update with previous Control Rotation
				PC->UpdateRotation(DeltaTime);
				if (ServerControlRotationSimulateMode == EHiServerControlRotationSimulateMode::TrustClient)
				{
					// Trust Client Control Rotation
					PC->SetControlRotation(ClientControlRotation);
				}
			}
			
			UpdateFromCompressedFlags(ClientMoveFlags);
			CharacterOwner->CheckJumpInput(DeltaTime);
			
			if (AppearanceComponent)
			{
				AppearanceComponent->PresetEssentialValues(DeltaTime, ClientAccel);
			}

			bIsInServerMove = true;
			
			HiServerMove_MoveAutonomous(ClientTimeStamp, DeltaTime, ClientMoveFlags, ClientAccel);

			bIsInServerMove = false;
		}

		UE_CLOG(CharacterOwner && UpdatedComponent, LogNetPlayerMovement, VeryVerbose, TEXT("ServerMove Time %f Acceleration %s Velocity %s Position %s Rotation %s DeltaTime %f Mode %s MovementBase %s.%s (Dynamic:%d)"),
			ClientTimeStamp, *ClientAccel.ToString(), *Velocity.ToString(), *UpdatedComponent->GetComponentLocation().ToString(), *UpdatedComponent->GetComponentRotation().ToCompactString(), DeltaTime, *GetMovementName(),
			*GetNameSafe(GetMovementBase()), *CharacterOwner->GetBasedMovement().BoneName.ToString(), MovementBaseUtility::IsDynamicBase(GetMovementBase()) ? 1 : 0);

	}

	// Validate move only after old and first dual portion, after all moves are completed.
	if (MoveData.NetworkMoveType == FCharacterNetworkMoveData::ENetworkMoveType::NewMove)
	{
		ServerMoveHandleClientError(ClientTimeStamp, DeltaTime, ClientAccel, MoveData.Location, MoveData.MovementBase, MoveData.MovementBaseBoneName, MoveData.MovementMode);
	}

	if (OnMovementTickEndTrigger.IsBound())
	{
		OnMovementTickEndTrigger.Broadcast();
		OnMovementTickEndTrigger.Clear();
	}

	/**
	 *  Bugfix:
	 *		To fix mutiltimes call from CharacterMovementComponent TickCharacterPose, may cause #AnimEvents cleared by each call #TickPose.
	 *		Here only used in server:
	 *           Needs Immediate Update to #PostUpdateAnimation (when closing multi-thread update), so #AnimEvents is prepared to wait ConditionallyDispatchQueuedAnimEvents
	 *			 #ConditionallyDispatchQueuedAnimEvents can not called in Client (allowed multi-thread), because #PostUpdateAnimation is not called will loss montage events.
	 *		Add #ShouldPostUpdateAnimScriptInstance check because #TickAnimation directly triggers #PostUpdateAnimation that require triggering of #AnimEvents (when closing multi-thread update)
	 */
	check(CharacterOwner && CharacterOwner->GetMesh());
	USkeletalMeshComponent* CharacterMesh = CharacterOwner->GetMesh();
	if (!CharacterMesh->ShouldPostUpdateAnimScriptInstance())
	{
		CharacterMesh->ConditionallyDispatchQueuedAnimEvents(true);
	}

#if WITH_EDITOR
	if (bDebugDrawServer)
	{
		FVector SocketLocation = CharacterMesh->GetSocketLocation(DebugDrawSocketName);
		::DrawDebugPoint(GetWorld(), SocketLocation, 5, FColor::Red, false, DebugDrawLifeTime);
	}
#endif	// WITH_EDITOR
}

void UHiCharacterMovementComponent::HiServerMove_MoveAutonomous(float ClientTimeStamp, float DeltaTime,
	uint8 CompressedFlags, const FVector& NewAccel)
{
	if (!HasValidData())
	{
		return;
	}
	
	Acceleration = ConstrainInputAcceleration(NewAccel);
	Acceleration = Acceleration.GetClampedToMaxSize(GetMaxAcceleration());
	AnalogInputModifier = ComputeAnalogInputModifier();
	
	const FVector OldLocation = UpdatedComponent->GetComponentLocation();
	const FQuat OldRotation = UpdatedComponent->GetComponentQuat();

	const bool bWasPlayingRootMotion = CharacterOwner->IsPlayingRootMotion();

	PerformMovement(DeltaTime);

	// Check if data is valid as PerformMovement can mark character for pending kill
	if (!HasValidData())
	{
		return;
	}
	
	// If not playing root motion, tick animations after physics. We do this here to keep events, notifies, states and transitions in sync with client updates.
	if( CharacterOwner && !CharacterOwner->bClientUpdating && !CharacterOwner->IsPlayingRootMotion() && CharacterOwner->GetMesh() )
	{
		if (!bWasPlayingRootMotion) // If we were playing root motion before PerformMovement but aren't anymore, we're on the last frame of anim root motion and have already ticked character
		{
			TickCharacterPose(DeltaTime);
		}
		// TODO: SaveBaseLocation() in case tick moves us?
		
		if (CharacterOwner->GetMesh()->ShouldOnlyTickMontages(DeltaTime))
		{
			// If we're not doing a full anim graph update on the server, 
			// trigger events right away, as we could be receiving multiple ServerMoves per frame.
			CharacterOwner->GetMesh()->ConditionallyDispatchQueuedAnimEvents();
		}
	}

	if (CharacterOwner && UpdatedComponent)
	{
		// Smooth local view of remote clients on listen servers
		if (bNetEnableListenServerSmoothing &&
			CharacterOwner->GetRemoteRole() == ROLE_AutonomousProxy &&
			IsNetMode(NM_ListenServer))
		{
			SmoothCorrection(OldLocation, OldRotation, UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat());
		}
	}
}

bool UHiCharacterMovementComponent::ServerShouldUseAuthoritativePosition(float ClientTimeStamp, float DeltaTime,
	const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation,
	UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
	if (ServerCanAcceptClientPosition())
	{
		return true;
	}

	const AGameNetworkManager* GameNetworkManager = (const AGameNetworkManager*)(AGameNetworkManager::StaticClass()->GetDefaultObject());
	if (GameNetworkManager->ClientAuthorativePosition)
	{
		return true;
	}

	return false;
}

void UHiCharacterMovementComponent::ControlledCharacterMove(const FVector& InputVector, float DeltaSeconds)
{
	{
		SCOPE_CYCLE_COUNTER(STAT_CharUpdateAcceleration);

		// Move To UHiAvatarLocomotionAppearance::TickComponent
		// - Fix the issue of inconsistent processing flow between the client and server
		// CharacterOwner->CheckJumpInput(DeltaSeconds);

		// apply input to acceleration
		Acceleration = ScaleInputAcceleration(ConstrainInputAcceleration(InputVector));
		AnalogInputModifier = ComputeAnalogInputModifier();
	}

	if (CharacterOwner->GetLocalRole() == ROLE_Authority)
	{
		PerformMovement(DeltaSeconds);
	}
	else if (CharacterOwner->GetLocalRole() == ROLE_AutonomousProxy && IsNetMode(NM_Client))
	{
		ReplicateMoveToServer(DeltaSeconds, Acceleration);

#if WITH_EDITOR
		if (bDebugDrawClient && CharacterOwner->GetMesh())
		{
			FVector SocketLocation = CharacterOwner->GetMesh()->GetSocketLocation(DebugDrawSocketName);
			::DrawDebugPoint(GetWorld(), SocketLocation, 5, FColor::Green, false, DebugDrawLifeTime);
		}
#endif	// WITH_EDITOR
	}
}

bool UHiCharacterMovementComponent::ClimbStepUp(const FVector& GravDir, const FVector& Delta, const FHitResult &InHit, FStepDownResult* OutStepDownResult)
{
	SCOPE_CYCLE_COUNTER(STAT_CharSprintClimbStepUp);

	if (!CanStepUp(InHit) || MaxWallStepHeight <= 0.f)
	{
		return false;
	}

	const FVector OldLocation = UpdatedComponent->GetComponentLocation();
	float PawnRadius, PawnHalfHeight;
	CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleSize(PawnRadius, PawnHalfHeight);

	// Don't bother stepping up if top of capsule is hitting something.
	const float InitialImpactZ = InHit.ImpactPoint.Z;
	if (InitialImpactZ > OldLocation.Z + (PawnHalfHeight - PawnRadius))
	{
		return false;
	}

	if (GravDir.IsZero())
	{
		return false;
	}

	// Gravity should be a normalized direction
	ensure(GravDir.IsNormalized());

	float StepTravelUpHeight = MaxWallStepHeight;
	float StepTravelDownHeight = StepTravelUpHeight;
	const float StepSideZ = -1.f * FVector::DotProduct(InHit.ImpactNormal, GravDir);
	float PawnInitialFloorBaseZ = OldLocation.Z - PawnHalfHeight;
	float PawnFloorPointZ = PawnInitialFloorBaseZ;

	if (IsMovingOnGround() && CurrentFloor.IsWalkableFloor())
	{
		// Since we float a variable amount off the floor, we need to enforce max step height off the actual point of impact with the floor.
		const float FloorDist = FMath::Max(0.f, CurrentFloor.GetDistanceToFloor());
		PawnInitialFloorBaseZ -= FloorDist;
		StepTravelUpHeight = FMath::Max(StepTravelUpHeight - FloorDist, 0.f);
		StepTravelDownHeight = (MaxWallStepHeight + MAX_FLOOR_DIST*2.f);

		const bool bHitVerticalFace = !IsWithinEdgeTolerance(InHit.Location, InHit.ImpactPoint, PawnRadius);
		if (!CurrentFloor.bLineTrace && !bHitVerticalFace)
		{
			PawnFloorPointZ = CurrentFloor.HitResult.ImpactPoint.Z;
		}
		else
		{
			// Base floor point is the base of the capsule moved down by how far we are hovering over the surface we are hitting.
			PawnFloorPointZ -= CurrentFloor.FloorDist;
		}
	}

	// Don't step up if the impact is below us, accounting for distance from floor.
	if (InitialImpactZ <= PawnInitialFloorBaseZ)
	{
		return false;
	}

	// Scope our movement updates, and do not apply them until all intermediate moves are completed.
	FScopedMovementUpdate ScopedStepUpMovement(UpdatedComponent, EScopedUpdate::DeferredUpdates);

	// step up - treat as vertical wall
	FHitResult SweepUpHit(1.f);
	const FQuat PawnRotation = UpdatedComponent->GetComponentQuat();
	MoveUpdatedComponent(-GravDir * StepTravelUpHeight, PawnRotation, true, &SweepUpHit);

	if (SweepUpHit.bStartPenetrating)
	{
		// Undo movement
		ScopedStepUpMovement.RevertMove();
		return false;
	}

	// step fwd
	FHitResult Hit(1.f);
	MoveUpdatedComponent( Delta, PawnRotation, true, &Hit);

	// Check result of forward movement
	if (Hit.bBlockingHit)
	{
		if (Hit.bStartPenetrating)
		{
			// Undo movement
			ScopedStepUpMovement.RevertMove();
			return false;
		}

		// If we hit something above us and also something ahead of us, we should notify about the upward hit as well.
		// The forward hit will be handled later (in the bSteppedOver case below).
		// In the case of hitting something above but not forward, we are not blocked from moving so we don't need the notification.
		if (SweepUpHit.bBlockingHit && Hit.bBlockingHit)
		{
			HandleImpact(SweepUpHit);
		}

		// pawn ran into a wall
		HandleImpact(Hit);
		if (IsFalling())
		{
			return true;
		}

		// adjust and try again
		const float ForwardHitTime = Hit.Time;
		const float ForwardSlideAmount = SlideAlongSurface(Delta, 1.f - Hit.Time, Hit.Normal, Hit, true);
		
		if (IsFalling())
		{
			ScopedStepUpMovement.RevertMove();
			return false;
		}

		// If both the forward hit and the deflection got us nowhere, there is no point in this step up.
		if (ForwardHitTime == 0.f && ForwardSlideAmount == 0.f)
		{
			ScopedStepUpMovement.RevertMove();
			return false;
		}
	}
	
	// Step down
	MoveUpdatedComponent(GravDir * StepTravelDownHeight, UpdatedComponent->GetComponentQuat(), true, &Hit);

	// If step down was initially penetrating abort the step up
	if (Hit.bStartPenetrating)
	{
		ScopedStepUpMovement.RevertMove();
		return false;
	}

	FStepDownResult StepDownResult;
	if (Hit.IsValidBlockingHit())
	{	
		// See if this step sequence would have allowed us to travel higher than our max step height allows.
		const float DeltaZ = Hit.ImpactPoint.Z - PawnFloorPointZ;
		if (DeltaZ > MaxWallStepHeight)
		{
			//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("- Reject StepUp (too high Height %.3f) up from floor base %f to %f"), DeltaZ, PawnInitialFloorBaseZ, NewLocation.Z);
			ScopedStepUpMovement.RevertMove();
			return false;
		}

		// Reject unwalkable surface normals here.
		if (!IsWalkable(Hit))
		{
			// Reject if normal opposes movement direction
			const bool bNormalTowardsMe = (Delta | Hit.ImpactNormal) < 0.f;
			if (bNormalTowardsMe)
			{
				//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("- Reject StepUp (unwalkable normal %s opposed to movement)"), *Hit.ImpactNormal.ToString());
				ScopedStepUpMovement.RevertMove();
				return false;
			}

			// Also reject if we would end up being higher than our starting location by stepping down.
			// It's fine to step down onto an unwalkable normal below us, we will just slide off. Rejecting those moves would prevent us from being able to walk off the edge.
			if (Hit.Location.Z > OldLocation.Z)
			{
				//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("- Reject StepUp (unwalkable normal %s above old position)"), *Hit.ImpactNormal.ToString());
				ScopedStepUpMovement.RevertMove();
				return false;
			}
		}

		// Reject moves where the downward sweep hit something very close to the edge of the capsule. This maintains consistency with FindFloor as well.
		if (!IsWithinEdgeTolerance(Hit.Location, Hit.ImpactPoint, PawnRadius))
		{
			//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("- Reject StepUp (outside edge tolerance)"));
			ScopedStepUpMovement.RevertMove();
			return false;
		}

		// Don't step up onto invalid surfaces if traveling higher.
		if (DeltaZ > 0.f && !CanStepUp(Hit))
		{
			//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("- Reject StepUp (up onto surface with !CanStepUp())"));
			ScopedStepUpMovement.RevertMove();
			return false;
		}

		// See if we can validate the floor as a result of this step down. In almost all cases this should succeed, and we can avoid computing the floor outside this method.
		if (OutStepDownResult != NULL)
		{
			FindFloor(UpdatedComponent->GetComponentLocation(), StepDownResult.FloorResult, false, &Hit);

			// Reject unwalkable normals if we end up higher than our initial height.
			// It's fine to walk down onto an unwalkable surface, don't reject those moves.
			if (Hit.Location.Z > OldLocation.Z)
			{
				// We should reject the floor result if we are trying to step up an actual step where we are not able to perch (this is rare).
				// In those cases we should instead abort the step up and try to slide along the stair.
				if (!StepDownResult.FloorResult.bBlockingHit && StepSideZ < HiCharacterMovementConstants::MAX_STEP_SIDE_Z)
				{
					ScopedStepUpMovement.RevertMove();
					return false;
				}
			}

			StepDownResult.bComputedFloor = true;
		}
	}
	
	// Copy step down result.
	if (OutStepDownResult != NULL)
	{
		*OutStepDownResult = StepDownResult;
	}

	// Don't recalculate velocity based on this height adjustment, if considering vertical adjustments.
	bJustTeleported |= !bMaintainHorizontalGroundVelocity;

	return true;
}


void UHiCharacterMovementComponent::TickCharacterPose(float DeltaTime)
{
	if (DeltaTime < UCharacterMovementComponent::MIN_TICK_TIME)
	{
		return;
	}

	check(CharacterOwner && CharacterOwner->GetMesh());
	USkeletalMeshComponent* CharacterMesh = CharacterOwner->GetMesh();

	// bAutonomousTickPose is set, we control TickPose from the Character's Movement and Networking updates, and bypass the Component's update.
	// (Or Simulating Root Motion for remote clients)
	CharacterMesh->bIsAutonomousTickPose = bIsInServerMove;

	// Keep track of if we're playing root motion, just in case the root motion montage ends this frame.
	const bool bWasPlayingRootMotion = CharacterOwner->IsPlayingRootMotion();

	if (CharacterMesh->ShouldTickPose())
	{
		CharacterMesh->TickPose(DeltaTime, true);
		if (MotionWarpingComponent)
		{
			// Todo: MotionWarping的计算必须依赖Tick，所以如果需要保证客户端和服务端一致，服务端也需要接到位移RPC后强制Tick一次
			MotionWarpingComponent->TickComponent(DeltaTime, ELevelTick::LEVELTICK_All, nullptr);
		}
	}

	//UE_LOG(LogTemp, Warning, L"[ZL] <Control: %d> Actor: %s [TickCharacterPose] Start"
	//	, CharacterOwner->GetLocalRole(), *CharacterOwner->GetFName().ToString()
	//);

	// Grab root motion now that we have ticked the pose
	if (CharacterOwner->IsPlayingRootMotion() || bWasPlayingRootMotion)
	{
		FRootMotionMovementParams RootMotion = CharacterMesh->ConsumeRootMotion();
		if (RootMotion.bHasRootMotion)
		{
			RootMotion.ScaleRootMotionTranslation(CharacterOwner->GetAnimRootMotionTranslationScale());
			RootMotionParams.Accumulate(RootMotion);
			RootMotionParams.BlendWeight = RootMotion.BlendWeight;

			//UE_LOG(LogTemp, Warning, TEXT("[ZL] <Control: %d> Actor: %s [TickCharacterPose] Get Root Motion: %s   Vel: %s  This: %p")
			//	, CharacterOwner->GetLocalRole(), *CharacterOwner->GetFName().ToString()
			//	, *RootMotionParams.GetRootMotionTransform().GetLocation().ToString()
			//	, *(RootMotionParams.GetRootMotionTransform().GetLocation() / DeltaTime).ToString()
			//	, this
			//);
		}
	}

	CharacterMesh->bIsAutonomousTickPose = false;
}

bool UHiCharacterMovementComponent::HiServerCheckClientError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode, bool bIgnoreMovementChange)
{
	// Check location difference against global setting
	if (!bIgnoreClientMovementErrorChecksAndCorrection)
	{
#if ROOT_MOTION_DEBUG
		if (RootMotionSourceDebug::CVarDebugRootMotionSources.GetValueOnGameThread() == 1)
		{
			const FVector LocDiff = UpdatedComponent->GetComponentLocation() - ClientWorldLocation;
			FString AdjustedDebugString = FString::Printf(TEXT("HiServerCheckClientError LocDiff(%.1f) ExceedsAllowablePositionError(%d) TimeStamp(%f)"),
				LocDiff.Size(), GetDefault<AGameNetworkManager>()->ExceedsAllowablePositionError(LocDiff), ClientTimeStamp);
			RootMotionSourceDebug::PrintOnScreen(*CharacterOwner, AdjustedDebugString);
		}
#endif

		// Check for disagreement in movement mode
		const uint8 CurrentPackedMovementMode = PackNetworkMovementMode();
		if (CurrentPackedMovementMode != ClientMovementMode && !bIgnoreMovementChange)
		{
			UE_LOG(LogNetPlayerMovement, Error, TEXT("*** Client Correction  for MovementMode   Client: %d    Server: %d    MovementMode: %s"), ClientMovementMode, PackNetworkMovementMode(), *GetMovementName());
			return true;
		}

		// Check for disagreement in movement location
		const FVector LocDiff = UpdatedComponent->GetComponentLocation() - ClientWorldLocation;
		const AGameNetworkManager* GameNetworkManager = (const AGameNetworkManager*)(AGameNetworkManager::StaticClass()->GetDefaultObject());
		if (GameNetworkManager->ExceedsAllowablePositionError(LocDiff))
		{
			bNetworkLargeClientCorrection |= (LocDiff.SizeSquared() > FMath::Square(NetworkLargeClientCorrectionDistance));
			UE_LOG(LogNetPlayerMovement, Error, TEXT("*** Client Correction  for Location   Client: %s    Server: %s"), *ClientWorldLocation.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
			return true;
		}

#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
		if (HiCharacterMovementCVars::NetForceClientAdjustmentPercent > UE_SMALL_NUMBER)
		{
			if (RandomStream.FRand() < HiCharacterMovementCVars::NetForceClientAdjustmentPercent)
			{
				UE_LOG(LogNetPlayerMovement, VeryVerbose, TEXT("** HiServerCheckClientError forced by p.NetForceClientAdjustmentPercent"));
				return true;
			}
		}
#endif
	}
	else
	{
#if !UE_BUILD_SHIPPING
		if (HiCharacterMovementCVars::NetShowCorrections != 0)
		{
			UE_LOG(LogNetPlayerMovement, Warning, TEXT("*** Server: %s is set to ignore error checks and corrections."), *GetNameSafe(CharacterOwner));
		}
#endif // !UE_BUILD_SHIPPING
	}

	return false;
}

bool UHiCharacterMovementComponent::ServerTrustAuthoritativePosition(float DeltaTime, const FVector& ClientWorldLocation, const FVector& RelativeClientLocation, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode, FVector& TrustServerWorldLocation)
{
	/* Switches */
	if (!bEnableTrustClient)
	{
		return false;
	}

	/* States check */
	UPrimitiveComponent* ServerMovementBase = GetMovementBase();
	if (ServerMovementBase != ClientMovementBase)
	{
		return false;
	}
	if (ClientMovementMode != PackNetworkMovementMode())
	{
		return false;
	}
	FName ServerBaseBoneName = CharacterOwner->GetBasedMovement().BoneName;
	if (ServerBaseBoneName != ClientBaseBoneName)
	{
		return false;
	}
	if (FMath::IsNearlyZero(DeltaTime))
	{
		return false;
	}

	/* Find Trust Client Location */
	FVector LocDiff = FVector::ZeroVector;
	float LocDiffDistance = 0.0f;
	FVector TestServerWorldLocation = FVector::ZeroVector;

	if (MovementBaseUtility::UseRelativeLocation(ClientMovementBase))
	{
		FVector BaseLocation;
		FQuat BaseQuat;
		MovementBaseUtility::GetMovementBaseTransform(ServerMovementBase, ServerBaseBoneName, BaseLocation, BaseQuat);

		const FVector RelativeServerLocation = UpdatedComponent->GetComponentLocation() - BaseLocation;

		LocDiff = RelativeServerLocation - RelativeClientLocation;
		LocDiffDistance = LocDiff.Size();
		TestServerWorldLocation = RelativeClientLocation + BaseLocation;
	}
	else
	{
		LocDiff = UpdatedComponent->GetComponentLocation() - ClientWorldLocation;
		LocDiffDistance = LocDiff.Size();
		TestServerWorldLocation = ClientWorldLocation;
	}

	/* Do Check Client Location */
	if (LocDiffDistance < TrustableTinyLocationError)
	{
		if (OverlapTest(TestServerWorldLocation, UpdatedComponent->GetComponentQuat(), UpdatedComponent->GetCollisionObjectType(), GetPawnCapsuleCollisionShape(SHRINK_None), CharacterOwner))
		{
			//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>  Use Client Failed -- location: %s -> %s   UntrustTime: %.2f"), *UpdatedComponent->GetComponentLocation().ToString(), *TrustServerWorldLocation.ToString(), UntrustClientDuration);
			return false;
		}

		//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>  Use Client Success -- location: %s -> %s   UntrustTime: %.2f"), *UpdatedComponent->GetComponentLocation().ToString(), *TrustServerWorldLocation.ToString(), UntrustClientDuration);
		TrustServerWorldLocation = TestServerWorldLocation;
		UntrustClientDuration = 0.0f;
	}
	else if (bTrustClient_EnableSmoothLocation && LocDiffDistance < TrustableVelocityError * (UntrustClientDuration + DeltaTime))
	{
		const float CurrectVelocityCorrectSize = TrustableSmoothVelocityFactor * Velocity.Size() * DeltaTime;
		const float SmoothCorrectDistance = FMath::Min(CurrectVelocityCorrectSize, FMath::Min(LocDiffDistance, TrustableMaxSmoothDistancePerFrame));
		if (FMath::IsNearlyZero(SmoothCorrectDistance))
		{
			//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>   Smooth to client Ignore -- location: %s (Server) -> %s (Client)"), *UpdatedComponent->GetComponentLocation().ToString(), *TestServerWorldLocation.ToString());
			return false;
		}
		TestServerWorldLocation += LocDiff * ((LocDiffDistance - SmoothCorrectDistance) / LocDiffDistance);
		if (OverlapTest(TestServerWorldLocation, UpdatedComponent->GetComponentQuat(), UpdatedComponent->GetCollisionObjectType(), GetPawnCapsuleCollisionShape(SHRINK_None), CharacterOwner))
		{
			//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>   Smooth to client Failed -- location: %s (Server) -> %s (Client)"), *UpdatedComponent->GetComponentLocation().ToString(), *TestServerWorldLocation.ToString());
			return false;
		}
		TrustServerWorldLocation = TestServerWorldLocation;
		//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>   Smooth to client Success -- location: %s -> %s   CorrectDis: %.2f (DiffDis: %.2f   AfterDiffDis: %.2f)   UntrsutTime: %.2f   TrustDis: %.2f   ClientWorldPosition: %s")
		//	, *UpdatedComponent->GetComponentLocation().ToString(), *TrustServerWorldLocation.ToString(), SmoothCorrectDistance, LocDiffDistance
		//	, (TrustServerWorldLocation - ClientWorldLocation).Size(), UntrustClientDuration, TrustableVelocityError * (UntrustClientDuration + DeltaTime)
		//	, *ClientWorldLocation.ToString()
		//);
	}
	else
	{
		//UE_LOG(LogHiCharacterMovement, Error, TEXT("[ZL] <TrustClient>   Check failed -- location: %s (Server) -> %s (Client)   DiffDis: %.2f   UntrsutTime: %.2f   TrustDis: %.2f")
		//	, *UpdatedComponent->GetComponentLocation().ToString(), *TestServerWorldLocation.ToString(), LocDiffDistance, UntrustClientDuration, TrustableVelocityError * (UntrustClientDuration + DeltaTime));
		return false;
	}

	return true;
}

void UHiCharacterMovementComponent::ServerMoveHandleClientError(float ClientTimeStamp, float DeltaTime, const FVector& Accel, const FVector& RelativeClientLoc, UPrimitiveComponent* ClientMovementBase, FName ClientBaseBoneName, uint8 ClientMovementMode)
{
	if (!ShouldUsePackedMovementRPCs())
	{
		if (RelativeClientLoc == FVector(1.f,2.f,3.f)) // first part of double servermove
		{
			return;
		}
	}

	FNetworkPredictionData_Server_Character* ServerData = GetPredictionData_Server_Character();
	check(ServerData);

	// Don't prevent more recent updates from being sent if received this frame.
	// We're going to send out an update anyway, might as well be the most recent one.
	APlayerController* PC = Cast<APlayerController>(CharacterOwner->GetController());
	if( (ServerData->LastUpdateTime != GetWorld()->TimeSeconds))
	{
		const AGameNetworkManager* GameNetworkManager = (const AGameNetworkManager*)(AGameNetworkManager::StaticClass()->GetDefaultObject());
		if (GameNetworkManager->WithinUpdateDelayBounds(PC, ServerData->LastUpdateTime))
		{
			return;
		}
	}

	// Offset may be relative to base component
	FVector ClientLoc = RelativeClientLoc;
	if (MovementBaseUtility::UseRelativeLocation(ClientMovementBase))
	{
		FVector BaseLocation;
		FQuat BaseRotation;
		MovementBaseUtility::GetMovementBaseTransform(ClientMovementBase, ClientBaseBoneName, BaseLocation, BaseRotation);
		ClientLoc += BaseLocation;
	}
	else
	{
		ClientLoc = FRepMovement::RebaseOntoLocalOrigin(ClientLoc, this);
	}

	FVector ServerLoc = UpdatedComponent->GetComponentLocation();

	// Unpack Movement mode
	TEnumAsByte<EMovementMode> UnpackClientMovementMode(MOVE_None);
	TEnumAsByte<EMovementMode> UnpackClientGroundMode(MOVE_None);
	uint8 UnpackClientCustomMode(0);
	UnpackNetworkMovementMode(ClientMovementMode, UnpackClientMovementMode, UnpackClientCustomMode, UnpackClientGroundMode);

	// Client may send a null movement base when walking on bases with no relative location (to save bandwidth).
	// In this case don't check movement base in error conditions, use the server one (which avoids an error based on differing bases). Position will still be validated.
	if (ClientMovementBase == nullptr)
	{
		if (UnpackClientMovementMode == MOVE_Walking)
		{
			ClientMovementBase = CharacterOwner->GetBasedMovement().MovementBase;
			ClientBaseBoneName = CharacterOwner->GetBasedMovement().BoneName;
		}
	}

	// If base location is out of sync on server and client, changing base can result in a jarring correction.
	// So in the case that the base has just changed on server or client, server trusts the client (within a threshold)
	UPrimitiveComponent* MovementBase = CharacterOwner->GetMovementBase();
	FName MovementBaseBoneName = CharacterOwner->GetBasedMovement().BoneName;
	const bool bServerIsFalling = IsFalling();
	const bool bClientIsFalling = ClientMovementMode == MOVE_Falling;
	const bool bServerJustLanded = bLastServerIsFalling && !bServerIsFalling;
	const bool bClientJustLanded = bLastClientIsFalling && !bClientIsFalling;

	const bool bInFreeMovement = (UnpackClientMovementMode == MOVE_Walking || UnpackClientMovementMode == MOVE_Falling)
		&& (MovementMode == MOVE_Walking || MovementMode == MOVE_Falling);

	FVector RelativeLocation = ServerLoc;
	FVector RelativeVelocity = Velocity;
	bool bUseLastBase = false;
	bool bFallingWithinAcceptableError = false;

	// Potentially trust the client a little when landing
	const float ClientAuthorityThreshold = HiCharacterMovementCVars::ClientAuthorityThresholdOnBaseChange;
	const float MaxFallingCorrectionLeash = HiCharacterMovementCVars::MaxFallingCorrectionLeash;
	const bool bDeferServerCorrectionsWhenFalling = ClientAuthorityThreshold > 0.f || MaxFallingCorrectionLeash > 0.f;
	if (bDeferServerCorrectionsWhenFalling)
	{
		// Teleports and other movement modes mean we should just trust the server like we normally would
		if (bTeleportedSinceLastUpdate || (MovementMode != MOVE_Walking && MovementMode != MOVE_Falling))
		{
			MaxServerClientErrorWhileFalling = 0.f;
			bCanTrustClientOnLanding = false;
		}

		// MaxFallingCorrectionLeash indicates we'll use a variable correction size based on the error on take-off and the direction of movement.
		// ClientAuthorityThreshold is an static client-trusting correction upon landing.
		// If both are set, use the smaller of the two. If only one is set, use that. If neither are set, we wouldn't even be inside this block.
		float MaxLandingCorrection = 0.f;
		if (ClientAuthorityThreshold > 0.f && MaxFallingCorrectionLeash > 0.f)
		{
			MaxLandingCorrection = FMath::Min(ClientAuthorityThreshold, MaxServerClientErrorWhileFalling);
		}
		else
		{
			MaxLandingCorrection = FMath::Max(ClientAuthorityThreshold, MaxServerClientErrorWhileFalling);
		}

		if (bCanTrustClientOnLanding && MaxLandingCorrection > 0.f && (bClientJustLanded || bServerJustLanded))
		{
			// no longer falling; server should trust client up to a point to finish the landing as the client sees it
			const FVector LocDiff = ServerLoc - ClientLoc;

			if (!LocDiff.IsNearlyZero(KINDA_SMALL_NUMBER))
			{
				if (LocDiff.SizeSquared() < FMath::Square(MaxLandingCorrection))
				{
					ServerLoc = ClientLoc;
					UpdatedComponent->MoveComponent(ServerLoc - UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat(), true, nullptr, EMoveComponentFlags::MOVECOMP_NoFlags, ETeleportType::TeleportPhysics);
					bJustTeleported = true;
				}
				else
				{
					const FVector ClampedDiff = LocDiff.GetSafeNormal() * MaxLandingCorrection;
					ServerLoc -= ClampedDiff;
					UpdatedComponent->MoveComponent(ServerLoc - UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat(), true, nullptr, EMoveComponentFlags::MOVECOMP_NoFlags, ETeleportType::TeleportPhysics);
					bJustTeleported = true;
				}
			}

			MaxServerClientErrorWhileFalling = 0.f;
			bCanTrustClientOnLanding = false;
		}

		if (bServerIsFalling && bLastServerIsWalking && !bTeleportedSinceLastUpdate)
		{
			float ClientForwardFactor = 1.f;
			UPrimitiveComponent* LastServerMovementBasePtr = LastServerMovementBase.Get();
			if (IsValid(LastServerMovementBasePtr) && MovementBaseUtility::IsDynamicBase(LastServerMovementBasePtr) && MaxWalkSpeed > KINDA_SMALL_NUMBER)
			{
				const FVector LastBaseVelocity = MovementBaseUtility::GetMovementBaseVelocity(LastServerMovementBasePtr, LastServerMovementBaseBoneName);
				RelativeVelocity = Velocity - LastBaseVelocity;
				const FVector BaseDirection = LastBaseVelocity.GetSafeNormal2D();
				const FVector RelativeDirection = RelativeVelocity * (1.f / MaxWalkSpeed);

				ClientForwardFactor = FMath::Clamp(FVector::DotProduct(BaseDirection, RelativeDirection), 0.f, 1.f);

				// To improve position syncing, use old base for take-off
				if (MovementBaseUtility::UseRelativeLocation(LastServerMovementBasePtr))
				{
					FVector BaseLocation;
					FQuat BaseQuat;
					MovementBaseUtility::GetMovementBaseTransform(LastServerMovementBasePtr, LastServerMovementBaseBoneName, BaseLocation, BaseQuat);

					// Relative Location
					RelativeLocation = UpdatedComponent->GetComponentLocation() - BaseLocation;
					bUseLastBase = true;
				}
			}

			if (ClientAuthorityThreshold > 0.f && ClientForwardFactor < 1.f)
			{
				const float AdjustedClientAuthorityThreshold = ClientAuthorityThreshold * (1.f - ClientForwardFactor);
				const FVector LocDiff = ServerLoc - ClientLoc;

				// Potentially trust the client a little when taking off in the opposite direction to the base (to help not get corrected back onto the base)
				if (!LocDiff.IsNearlyZero(KINDA_SMALL_NUMBER))
				{
					if (LocDiff.SizeSquared() < FMath::Square(AdjustedClientAuthorityThreshold))
					{
						ServerLoc = ClientLoc;
						UpdatedComponent->MoveComponent(ServerLoc - UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat(), true, nullptr, EMoveComponentFlags::MOVECOMP_NoFlags, ETeleportType::TeleportPhysics);
						bJustTeleported = true;
					}
					else
					{
						const FVector ClampedDiff = LocDiff.GetSafeNormal() * AdjustedClientAuthorityThreshold;
						ServerLoc -= ClampedDiff;
						UpdatedComponent->MoveComponent(ServerLoc - UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat(), true, nullptr, EMoveComponentFlags::MOVECOMP_NoFlags, ETeleportType::TeleportPhysics);
						bJustTeleported = true;
					}
				}
			}

			if (ClientForwardFactor < 1.f)
			{
				MaxServerClientErrorWhileFalling = FMath::Min((ServerLoc - ClientLoc).Size() * (1.f - ClientForwardFactor), MaxFallingCorrectionLeash);
				bCanTrustClientOnLanding = true;
			}
			else
			{
				MaxServerClientErrorWhileFalling = 0.f;
				bCanTrustClientOnLanding = false;
			}
		}
		else if (!bServerIsFalling && bCanTrustClientOnLanding)
		{
			MaxServerClientErrorWhileFalling = 0.f;
			bCanTrustClientOnLanding = false;
		}

		if (MaxServerClientErrorWhileFalling > 0.f && (bServerIsFalling || bClientIsFalling))
		{
			const FVector LocDiff = ServerLoc - ClientLoc;
			if (LocDiff.SizeSquared() <= FMath::Square(MaxServerClientErrorWhileFalling))
			{
				ServerLoc = ClientLoc;
				// Still want a velocity update when we first take off
				bFallingWithinAcceptableError = true;
			}
			else
			{
				// Change ServerLoc to be on the edge of the acceptable error rather than doing a full correction.
				// This is not actually changing the server position, but changing it as far as corrections are concerned.
				// This means we're just holding the client on a longer leash while we're falling.
				ServerLoc = ServerLoc - LocDiff.GetSafeNormal() * FMath::Clamp(MaxServerClientErrorWhileFalling - HiCharacterMovementCVars::MaxFallingCorrectionLeashBuffer, 0.f, MaxServerClientErrorWhileFalling);
			}
		}
	}

	// Compute the client error from the server's position
	// If client has accumulated a noticeable positional error, correct them.
	bNetworkLargeClientCorrection = ServerData->bForceClientUpdate;

	if (ServerShouldUseAuthoritativePosition(ClientTimeStamp, DeltaTime, Accel, ClientLoc, RelativeClientLoc, ClientMovementBase, ClientBaseBoneName, ClientMovementMode))
	{
		const FVector LocDiff = UpdatedComponent->GetComponentLocation() - ClientLoc; //-V595
		if (!LocDiff.IsZero() || ClientMovementMode != PackNetworkMovementMode() || GetMovementBase() != ClientMovementBase || (CharacterOwner && CharacterOwner->GetBasedMovement().BoneName != ClientBaseBoneName))
		{
			// Just set the position. On subsequent moves we will resolve initially overlapping conditions.
			UpdatedComponent->SetWorldLocation(ClientLoc, false); //-V595

			// Trust the client's movement mode.
			ApplyNetworkMovementMode(ClientMovementMode);

			// Update base and floor at new location.
			SetBase(ClientMovementBase, ClientBaseBoneName);
			UpdateFloorFromAdjustment();

			// Even if base has not changed, we need to recompute the relative offsets (since we've moved).
			SaveBaseLocation();

			LastUpdateLocation = UpdatedComponent->GetComponentLocation();
			LastUpdateRotation = UpdatedComponent->GetComponentQuat();
			LastUpdateVelocity = Velocity;
		}
		// acknowledge receipt of this successful servermove()
		ServerData->PendingAdjustment.TimeStamp = ClientTimeStamp;
		ServerData->PendingAdjustment.bAckGoodMove = true;

		UntrustClientDuration = 0.0f;
	}
	else if (ServerData->bForceClientUpdate || (!bFallingWithinAcceptableError && HiServerCheckClientError(ClientTimeStamp, DeltaTime, Accel, ClientLoc, RelativeClientLoc, ClientMovementBase, ClientBaseBoneName, ClientMovementMode, bInFreeMovement)))
	{
		ServerData->PendingAdjustment.NewVel = Velocity;
		ServerData->PendingAdjustment.NewBase = MovementBase;
		ServerData->PendingAdjustment.NewBaseBoneName = MovementBaseBoneName;
		ServerData->PendingAdjustment.NewLoc = FRepMovement::RebaseOntoZeroOrigin(ServerLoc, this);
		ServerData->PendingAdjustment.NewRot = UpdatedComponent->GetComponentRotation();

		ServerData->PendingAdjustment.bBaseRelativePosition = (bDeferServerCorrectionsWhenFalling && bUseLastBase) || MovementBaseUtility::UseRelativeLocation(MovementBase);
		if (ServerData->PendingAdjustment.bBaseRelativePosition)
		{
			// Relative location
			if (bDeferServerCorrectionsWhenFalling && bUseLastBase)
			{
				ServerData->PendingAdjustment.NewVel = RelativeVelocity;
				ServerData->PendingAdjustment.NewBase = LastServerMovementBase.Get();
				ServerData->PendingAdjustment.NewBaseBoneName = LastServerMovementBaseBoneName;
				ServerData->PendingAdjustment.NewLoc = RelativeLocation;
			}
			else
			{
				ServerData->PendingAdjustment.NewLoc = CharacterOwner->GetBasedMovement().Location;
			}
			
			// TODO: this could be a relative rotation, but all client corrections ignore rotation right now except the root motion one, which would need to be updated.
			//ServerData->PendingAdjustment.NewRot = CharacterOwner->GetBasedMovement().Rotation;
		}


#if !UE_BUILD_SHIPPING
		if (HiCharacterMovementCVars::NetShowCorrections != 0)
		{
			const FVector LocDiff = UpdatedComponent->GetComponentLocation() - ClientLoc;
			const FString BaseString = MovementBase ? MovementBase->GetPathName(MovementBase->GetOutermost()) : TEXT("None");
			UE_LOG(LogNetPlayerMovement, Warning, TEXT("*** Server: Error for %s at Time=%.3f is %3.3f LocDiff(%s) ClientLoc(%s) ServerLoc(%s) Base: %s Bone: %s Accel(%s) Velocity(%s)"),
				*GetNameSafe(CharacterOwner), ClientTimeStamp, LocDiff.Size(), *LocDiff.ToString(), *ClientLoc.ToString(), *UpdatedComponent->GetComponentLocation().ToString(), *BaseString, *ServerData->PendingAdjustment.NewBaseBoneName.ToString(), *Accel.ToString(), *Velocity.ToString());
			const float DebugLifetime = HiCharacterMovementCVars::NetCorrectionLifetime;
			DrawDebugCapsule(GetWorld(), UpdatedComponent->GetComponentLocation(), CharacterOwner->GetSimpleCollisionHalfHeight(), CharacterOwner->GetSimpleCollisionRadius(), FQuat::Identity, FColor(100, 255, 100), false, DebugLifetime);
			DrawDebugCapsule(GetWorld(), ClientLoc                    , CharacterOwner->GetSimpleCollisionHalfHeight(), CharacterOwner->GetSimpleCollisionRadius(), FQuat::Identity, FColor(255, 100, 100), false, DebugLifetime);
		}
#endif

		ServerData->LastUpdateTime = GetWorld()->TimeSeconds;
		ServerData->PendingAdjustment.DeltaTime = DeltaTime;
		ServerData->PendingAdjustment.TimeStamp = ClientTimeStamp;
		ServerData->PendingAdjustment.bAckGoodMove = false;
		ServerData->PendingAdjustment.MovementMode = PackNetworkMovementMode();

#if USE_SERVER_PERF_COUNTERS
		PerfCountersIncrement(PerfCounter_NumServerMoveCorrections);
#endif

		UntrustClientDuration += DeltaTime;
	}
	else
	{
		// Trust the client's free movement mode between: Walking & Falling
		if (bInFreeMovement && MovementMode != UnpackClientMovementMode)
		{
			ApplyNetworkMovementMode(ClientMovementMode);
		}

		if (ServerTrustAuthoritativePosition(DeltaTime, ClientLoc, RelativeClientLoc, ClientMovementBase, ClientBaseBoneName, ClientMovementMode, ServerLoc))
		{
			UpdatedComponent->SetWorldLocation(ServerLoc, false);

			LastUpdateLocation = UpdatedComponent->GetComponentLocation();
			LastUpdateRotation = UpdatedComponent->GetComponentQuat();
			LastUpdateVelocity = Velocity;
		}
		else
		{
			// Accept but do not trust
			UntrustClientDuration += DeltaTime;
		}

		// acknowledge receipt of this successful servermove()
		ServerData->PendingAdjustment.TimeStamp = ClientTimeStamp;
		ServerData->PendingAdjustment.bAckGoodMove = true;
	}

	UntrustClientDuration = FMath::Min(UntrustClientDuration, UntrustMaxClientDuration);

#if USE_SERVER_PERF_COUNTERS
	PerfCountersIncrement(PerfCounter_NumServerMoves);
#endif

	ServerData->bForceClientUpdate = false;

	LastServerMovementBase = MovementBase;
	LastServerMovementBaseBoneName = MovementBaseBoneName;
	bLastClientIsFalling = bClientIsFalling;
	bLastServerIsFalling = bServerIsFalling;
	bLastServerIsWalking = MovementMode == MOVE_Walking;
}

FVector UHiCharacterMovementComponent::ConstrainAnimRootMotionVelocity(const FVector& RootMotionVelocity, const FVector& CurrentVelocity) const
{
	FVector Result = CurrentVelocity;

	switch (RootMotionOverrideType)
	{
	case EHiRootMotionOverrideType::Velocity_ALL:
		Result = RootMotionVelocity;
		break;
	case EHiRootMotionOverrideType::Velocity_Z:
		Result.Z = RootMotionVelocity.Z;
		break;
	case EHiRootMotionOverrideType::Velocity_XY:
		Result.X = RootMotionVelocity.X;
		Result.Y = RootMotionVelocity.Y;
		break;
	case EHiRootMotionOverrideType::Default:
		Result = Super::ConstrainAnimRootMotionVelocity(RootMotionVelocity, CurrentVelocity);
		break;
	default:
		break;
	}

	return Result;
}

void UHiCharacterMovementComponent::OnMovementSettingsChanged()
{
	// Set Movement Settings
	// if (bRequestMovementSettingsChange)
	// {
	// 	UpdateWalkSpeed();
	// 	bRequestMovementSettingsChange = false;
	// }
	const float UpdateMaxWalkSpeed = CurrentMovementSettings.GetSpeedForGait(AllowedGait) * SpeedScale;

	MaxWalkSpeed = UpdateMaxWalkSpeed;
	MaxWalkSpeedCrouched = UpdateMaxWalkSpeed;
}

void UHiCharacterMovementComponent::StartNewPhysics(float DeltaTime, int32 Iterations)
{
	if ((DeltaTime < MIN_TICK_TIME) || (Iterations >= MaxSimulationIterations))
	{
		return;
	}

	PhyxMovementStatus.bIsHorizontalSliding = false;
	Super::StartNewPhysics(DeltaTime, Iterations);
}

void UHiCharacterMovementComponent::RequestDirectMove(const FVector& MoveVelocity, bool bForceMaxSpeed)
{
	Super::RequestDirectMove(MoveVelocity, bForceMaxSpeed);
}

void UHiCharacterMovementComponent::MoveAlongFloor(const FVector& InVelocity, float DeltaSeconds, FStepDownResult* OutStepDownResult)
{
	if (!CurrentFloor.IsWalkableFloor())
	{
		return;
	}

	FScopedMovementUpdate ScopedStepUpMovement(UpdatedComponent, EScopedUpdate::DeferredUpdates);
	// Move along the current floor
	const FVector Delta = FVector(InVelocity.X, InVelocity.Y, 0.f) * DeltaSeconds;
	FHitResult Hit(1.f);
	FVector RampVector = ComputeGroundMovementDelta(Delta, CurrentFloor.HitResult, CurrentFloor.bLineTrace);
	SafeMoveUpdatedComponent(RampVector, UpdatedComponent->GetComponentQuat(), true, Hit);
	float LastMoveTimeSlice = DeltaSeconds;
	
	if (Hit.bStartPenetrating)
	{
		ScopedStepUpMovement.RevertMove();
		// Allow this hit to be used as an impact we can deflect off, otherwise we do nothing the rest of the update and appear to hitch.
		HandleImpact(Hit);
		//SlideAlongSurface(Delta, 1.f, Hit.Normal, Hit, true);

		if (Hit.bStartPenetrating)
		{
			OnCharacterStuckInGeometry(&Hit);
		}
	}
	else if (Hit.IsValidBlockingHit())
	{
		// We impacted something (most likely another ramp, but possibly a barrier).
		float PercentTimeApplied = Hit.Time;
		if ((Hit.Time > 0.f) && (Hit.Normal.Z > UE_KINDA_SMALL_NUMBER) && IsWalkable(Hit))
		{
			// Another walkable ramp.
			const float InitialPercentRemaining = 1.f - PercentTimeApplied;
			RampVector = ComputeGroundMovementDelta(Delta * InitialPercentRemaining, Hit, false);
			LastMoveTimeSlice = InitialPercentRemaining * LastMoveTimeSlice;
			SafeMoveUpdatedComponent(RampVector, UpdatedComponent->GetComponentQuat(), true, Hit);

			const float SecondHitPercent = Hit.Time * InitialPercentRemaining;
			PercentTimeApplied = FMath::Clamp(PercentTimeApplied + SecondHitPercent, 0.f, 1.f);
		}

		if (Hit.IsValidBlockingHit())
		{
			if (CanStepUp(Hit) || (CharacterOwner->GetMovementBase() != nullptr && Hit.HitObjectHandle == CharacterOwner->GetMovementBase()->GetOwner()))
			{
				// hit a barrier, try to step up
				const FVector PreStepUpLocation = UpdatedComponent->GetComponentLocation();
				const FVector GravDir(0.f, 0.f, -1.f);
				if (!StepUp(GravDir, Delta * (1.f - PercentTimeApplied), Hit, OutStepDownResult))
				{
					UE_LOG(LogNetPlayerMovement, Verbose, TEXT("- StepUp (ImpactNormal %s, Normal %s"), *Hit.ImpactNormal.ToString(), *Hit.Normal.ToString());
					HandleImpact(Hit, LastMoveTimeSlice, RampVector);
					SlideAlongSurface(Delta, 1.f - PercentTimeApplied, Hit.Normal, Hit, true);
				}
				else
				{
					UE_LOG(LogNetPlayerMovement, Verbose, TEXT("+ StepUp (ImpactNormal %s, Normal %s"), *Hit.ImpactNormal.ToString(), *Hit.Normal.ToString());
					if (!bMaintainHorizontalGroundVelocity)
					{
						// Don't recalculate velocity based on this height adjustment, if considering vertical adjustments. Only consider horizontal movement.
						bJustTeleported = true;
						const float StepUpTimeSlice = (1.f - PercentTimeApplied) * DeltaSeconds;
						if (!HasAnimRootMotion() && !CurrentRootMotion.HasOverrideVelocity() && StepUpTimeSlice >= UE_KINDA_SMALL_NUMBER)
						{
							Velocity = (UpdatedComponent->GetComponentLocation() - PreStepUpLocation) / StepUpTimeSlice;
							Velocity.Z = 0;
						}
					}
				}
			}
			else if ( Hit.Component.IsValid() && !Hit.Component.Get()->CanCharacterStepUp(CharacterOwner) )
			{
				HandleImpact(Hit, LastMoveTimeSlice, RampVector);
				SlideAlongSurface(Delta, 1.f - PercentTimeApplied, Hit.Normal, Hit, true);
			}
		}
	}
}

void UHiCharacterMovementComponent::UpdateFromCompressedFlags(uint8 Flags) // Client only
{
	Super::UpdateFromCompressedFlags(Flags);

	// if ((Flags & FSavedMove_Character::FLAG_Custom_0) != 0)
	// {
	// 	OnMovementSettingsChanged();
	// }
}

class FNetworkPredictionData_Client* UHiCharacterMovementComponent::GetPredictionData_Client() const
{
	check(PawnOwner != nullptr);

	if (!ClientPredictionData)
	{
		UHiCharacterMovementComponent* MutableThis = const_cast<UHiCharacterMovementComponent*>(this);

		MutableThis->ClientPredictionData = new FNetworkPredictionData_Client_Hi(*this);
		MutableThis->ClientPredictionData->MaxSmoothNetUpdateDist = 92.f;
		MutableThis->ClientPredictionData->NoSmoothNetUpdateDist = 140.f;
	}

	return ClientPredictionData;
}

void UHiCharacterMovementComponent::FSavedMove_Hi::Clear()
{
	Super::Clear();

	SavedAllowedGait = EHiGait::Walking;
}

uint8 UHiCharacterMovementComponent::FSavedMove_Hi::GetCompressedFlags() const
{
	uint8 Result = Super::GetCompressedFlags();

	return Result;
}

void UHiCharacterMovementComponent::FSavedMove_Hi::SetMoveFor(ACharacter* Character, float InDeltaTime,
                                                               FVector const& NewAccel,
                                                               class FNetworkPredictionData_Client_Character&
                                                               ClientData)
{
	Super::SetMoveFor(Character, InDeltaTime, NewAccel, ClientData);

	UHiCharacterMovementComponent* CharacterMovement = Cast<UHiCharacterMovementComponent>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
		SavedAllowedGait = CharacterMovement->AllowedGait;

		if (CharacterMovement->GetForceNoCombine())
		{
			bForceNoCombine = true;
		}
	}
}

void UHiCharacterMovementComponent::FSavedMove_Hi::PrepMoveFor(ACharacter* Character)
{
	Super::PrepMoveFor(Character);

	UHiCharacterMovementComponent* CharacterMovement = Cast<UHiCharacterMovementComponent>(Character->GetCharacterMovement());
	if (CharacterMovement)
	{
		CharacterMovement->SetAllowedGait(SavedAllowedGait);
	}
}

UHiCharacterMovementComponent::FNetworkPredictionData_Client_Hi::FNetworkPredictionData_Client_Hi(
	const UCharacterMovementComponent& ClientMovement)
	: Super(ClientMovement)
{
}

FSavedMovePtr UHiCharacterMovementComponent::FNetworkPredictionData_Client_Hi::AllocateNewMove()
{
	return MakeShared<FSavedMove_Hi>();
}

void UHiCharacterMovementComponent::Server_SetAllowedGait_Implementation(const EHiGait NewAllowedGait)
{
	SetAllowedGait(NewAllowedGait);
}

float UHiCharacterMovementComponent::SlideAlongSurface(const FVector& Delta, float Time, const FVector& InNormal, FHitResult& Hit, bool bHandleImpact)
{
	if (!Hit.bBlockingHit)
	{
		return 0.f;
	}

	if (!bEnableSlideAlongSurface)
	{
		return 0.f;
	}

	PhyxMovementStatus.bIsHorizontalSliding = true;
	// Ignore small angle sliding
	FVector ProjectedNormal = InNormal;
	if (bConstrainToPlane)
	{
		ProjectedNormal = ConstrainNormalToPlane(InNormal);
	}
	if (ProjectedNormal.CosineAngle2D(Delta) < MinimumSlideDeltaCos)
	{
		return 0.f;
	}
	// Do Slide
	return Super::SlideAlongSurface(Delta, Time, InNormal, Hit, bHandleImpact);
}

bool UHiCharacterMovementComponent::IsValidLandingSpot(const FVector& CapsuleLocation, const FHitResult& Hit) const
{
	bool bRet = Super::IsValidLandingSpot(CapsuleLocation, Hit);
	if (bRet && JumpComponent && !JumpComponent->IsValidLanding())
	{
		return false;
	}
	return bRet;
}

void UHiCharacterMovementComponent::ProcessGlideLanded(const FHitResult& Hit)
{
	SCOPE_CYCLE_COUNTER(STAT_CharProcessGlideLanded);

	if( CharacterOwner && CharacterOwner->ShouldNotifyLanded(Hit) )
	{
		CharacterOwner->Landed(Hit);
	}
	
	IPathFollowingAgentInterface* PFAgent = GetPathFollowingAgent();
	if (PFAgent)
	{
		PFAgent->OnLanded();
	}
}

void UHiCharacterMovementComponent::AddBufferVelocity(FVector NewBufferVelocity)
{
	BufferVelocity += NewBufferVelocity;
}

void UHiCharacterMovementComponent::AddBufferAcceleratedVelocity(FVector NewBufferAcceleratedVelocity)
{
	BufferAcceleratedVelocity += NewBufferAcceleratedVelocity;
}

void UHiCharacterMovementComponent::AddBufferVelocityOnlyOnce(FVector NewBufferVelocity)
{
	BufferVelocityOnlyOnce += NewBufferVelocity;
}

FVector UHiCharacterMovementComponent::GetBufferVelocity() const
{
	return BufferVelocity;
}

FVector UHiCharacterMovementComponent::GetBufferAcceleratedVelocity() const
{
	return BufferAcceleratedVelocity;
}

void UHiCharacterMovementComponent::SetGlideFallSpeed(float FallSpeed)
{
	GlideFallSpeed = FallSpeed;
}

void UHiCharacterMovementComponent::PhysGlide(float deltaTime, int32 Iterations)
{
	SCOPE_CYCLE_COUNTER(STAT_CharPhysGlide);

	if (deltaTime < MIN_TICK_TIME)
	{
		return;
	}
	
	//UE_LOG(LogTemp, Error, TEXT("UHiCharacterMovementComponent::PhysGlide 111 %d %s %s"), (int32)GetWorld()->GetNetMode(), *Velocity.ToString(), *UpdatedComponent->GetComponentLocation().ToString());


	float remainingTime = deltaTime;
	while( (remainingTime >= MIN_TICK_TIME) && (Iterations < MaxSimulationIterations) )
	{
		Iterations++;
		float timeTick = GetSimulationTimeStep(remainingTime, Iterations);
		remainingTime -= timeTick;
		
		const FVector OldLocation = UpdatedComponent->GetComponentLocation();
		const FQuat PawnRotation = UpdatedComponent->GetComponentQuat();
		bJustTeleported = false;

		RestorePreAdditiveRootMotionVelocity();

		const FVector OldVelocity = Velocity;

		// Apply input
		const float MaxDecel = GetMaxBrakingDeceleration();
		if (!HasAnimRootMotion() && !CurrentRootMotion.HasOverrideVelocity())
		{
			// Compute Velocity
			{
				// Acceleration = FallAcceleration for CalcVelocity(), but we restore it after using it.
				Velocity.Z = 0.f;
				CalcVelocityForGliding(timeTick, FallingLateralFriction, false, MaxDecel);

				//UE_LOG(LogTemp, Error, TEXT("UHiCharacterMovementComponent::PhysGlide 222 %d %s %s"), (int32)GetWorld()->GetNetMode(), *Velocity.ToString(), *UpdatedComponent->GetComponentLocation().ToString());
				Velocity.Z = OldVelocity.Z;
			}
		}

		// Apply gravity
		if (BufferVelocity.Z==0&& BufferAcceleratedVelocity.Z==0)
		{
			Velocity.Z = -GlideFallSpeed;
		}
		else
		{
			Velocity.Z += BufferVelocity.Z;
			Velocity += BufferAcceleratedVelocity * deltaTime;

		}
 		
		const FVector OldVelocityWithRootMotion = Velocity;

		// //UE_LOG(LogCharacterMovement, Log, TEXT("dt=(%.6f) OldLocation=(%s) OldVelocity=(%s) OldVelocityWithRootMotion=(%s) NewVelocity=(%s)"), timeTick, *(UpdatedComponent->GetComponentLocation()).ToString(), *OldVelocity.ToString(), *OldVelocityWithRootMotion.ToString(), *Velocity.ToString());
		// ApplyRootMotionToVelocity(timeTick);
		// DecayFormerBaseVelocity(timeTick);
		//
		// // See if we need to sub-step to exactly reach the apex. This is important for avoiding "cutting off the top" of the trajectory as framerate varies.
		// if (/*CharacterMovementCVars::ForceJumpPeakSubstep && */OldVelocityWithRootMotion.Z > 0.f && Velocity.Z <= 0.f && NumJumpApexAttempts < MaxJumpApexAttemptsPerSimulation)
		// {
		// 	const FVector DerivedAccel = (Velocity - OldVelocityWithRootMotion) / timeTick;
		// 	if (!FMath::IsNearlyZero(DerivedAccel.Z))
		// 	{
		// 		const float TimeToApex = -OldVelocityWithRootMotion.Z / DerivedAccel.Z;
		// 		
		// 		// The time-to-apex calculation should be precise, and we want to avoid adding a substep when we are basically already at the apex from the previous iteration's work.
		// 		const float ApexTimeMinimum = 0.0001f;
		// 		if (TimeToApex >= ApexTimeMinimum && TimeToApex < timeTick)
		// 		{
		// 			const FVector ApexVelocity = OldVelocityWithRootMotion + (DerivedAccel * TimeToApex);
		// 			Velocity = ApexVelocity;
		// 			Velocity.Z = 0.f; // Should be nearly zero anyway, but this makes apex notifications consistent.
		//
		// 			// We only want to move the amount of time it takes to reach the apex, and refund the unused time for next iteration.
		// 			const float TimeToRefund = (timeTick - TimeToApex);
		//
		// 			remainingTime += TimeToRefund;
		// 			timeTick = TimeToApex;
		// 			Iterations--;
		// 			NumJumpApexAttempts++;
		//
		// 			// Refund time to any active Root Motion Sources as well
		// 			for (TSharedPtr<FRootMotionSource> RootMotionSource : CurrentRootMotion.RootMotionSources)
		// 			{
		// 				const float RewoundRMSTime = FMath::Max(0.0f, RootMotionSource->GetTime() - TimeToRefund);
		// 				RootMotionSource->SetTime(RewoundRMSTime);
		// 			}
		// 		}
		// 	}
		// }
		//
		// if (bNotifyApex && (Velocity.Z < 0.f))
		// {
		// 	// Just passed jump apex since now going down
		// 	bNotifyApex = false;
		// 	NotifyJumpApex();
		// }

		// Compute change in position (using midpoint integration method).
		FVector Adjusted = 0.5f * (OldVelocityWithRootMotion + Velocity) * timeTick;

		// Move
		FHitResult Hit(1.f);
		SafeMoveUpdatedComponent( Adjusted, PawnRotation, true, Hit);
		
		if (!HasValidData())
		{
			return;
		}
		
		float LastMoveTimeSlice = timeTick;
		float subTimeTickRemaining = timeTick * (1.f - Hit.Time);
		
		if ( IsSwimming() ) //just entered water
		{
			remainingTime += subTimeTickRemaining;
			StartSwimming(OldLocation, OldVelocity, timeTick, remainingTime, Iterations);
			return;
		}
		else if ( Hit.bBlockingHit )
		{
			if (IsValidLandingSpot(UpdatedComponent->GetComponentLocation(), Hit))
			{
				remainingTime += subTimeTickRemaining;
				ProcessGlideLanded(Hit);
				return;
			}
			else
			{
				// Compute impact deflection based on final velocity, not integration step.
				// This allows us to compute a new velocity from the deflected vector, and ensures the full gravity effect is included in the slide result.
				Adjusted = Velocity * timeTick;

				// See if we can convert a normally invalid landing spot (based on the hit result) to a usable one.
				if (!Hit.bStartPenetrating && ShouldCheckForValidLandingSpot(timeTick, Adjusted, Hit))
				{
					const FVector PawnLocation = UpdatedComponent->GetComponentLocation();
					FFindFloorResult FloorResult;
					FindFloor(PawnLocation, FloorResult, false);
					if (FloorResult.IsWalkableFloor() && IsValidLandingSpot(PawnLocation, FloorResult.HitResult))
					{
						remainingTime += subTimeTickRemaining;
						ProcessGlideLanded(FloorResult.HitResult);
						return;
					}
				}

				HandleImpact(Hit, LastMoveTimeSlice, Adjusted);
				
				// If we've changed physics mode, abort.
				if (!HasValidData() || !IsFalling())
				{
					return;
				}

				// Limit air control based on what we hit.
				// We moved to the impact point using air control, but may want to deflect from there based on a limited air control acceleration.
				const FVector OldHitNormal = Hit.Normal;
				const FVector OldHitImpactNormal = Hit.ImpactNormal;				
				FVector Delta = ComputeSlideVector(Adjusted, 1.f - Hit.Time, OldHitNormal, Hit);

				// Compute velocity after deflection (only gravity component for RootMotion)
				const UPrimitiveComponent* HitComponent = Hit.GetComponent();
				if (/*CharacterMovementCVars::UseTargetVelocityOnImpact && */!Velocity.IsNearlyZero() && MovementBaseUtility::IsSimulatedBase(HitComponent))
				{
					const FVector ContactVelocity = MovementBaseUtility::GetMovementBaseVelocity(HitComponent, NAME_None) + MovementBaseUtility::GetMovementBaseTangentialVelocity(HitComponent, NAME_None, Hit.ImpactPoint);
					const FVector NewVelocity = Velocity - Hit.ImpactNormal * FVector::DotProduct(Velocity - ContactVelocity, Hit.ImpactNormal);
					Velocity = HasAnimRootMotion() || CurrentRootMotion.HasOverrideVelocityWithIgnoreZAccumulate() ? FVector(Velocity.X, Velocity.Y, NewVelocity.Z) : NewVelocity;
				}
				else if (subTimeTickRemaining > UE_KINDA_SMALL_NUMBER && !bJustTeleported)
				{
					const FVector NewVelocity = (Delta / subTimeTickRemaining);
					Velocity = HasAnimRootMotion() || CurrentRootMotion.HasOverrideVelocityWithIgnoreZAccumulate() ? FVector(Velocity.X, Velocity.Y, NewVelocity.Z) : NewVelocity;
				}

				if (subTimeTickRemaining > UE_KINDA_SMALL_NUMBER && (Delta | Adjusted) > 0.f)
				{
					// Move in deflected direction.
					SafeMoveUpdatedComponent( Delta, PawnRotation, true, Hit);
					
					if (Hit.bBlockingHit)
					{
						// hit second wall
						LastMoveTimeSlice = subTimeTickRemaining;
						subTimeTickRemaining = subTimeTickRemaining * (1.f - Hit.Time);

						if (IsValidLandingSpot(UpdatedComponent->GetComponentLocation(), Hit))
						{
							remainingTime += subTimeTickRemaining;
							ProcessGlideLanded(Hit);
							return;
						}

						HandleImpact(Hit, LastMoveTimeSlice, Delta);

						// If we've changed physics mode, abort.
						if (!HasValidData())
						{
							return;
						}

						FVector PreTwoWallDelta = Delta;
						TwoWallAdjust(Delta, Hit, OldHitNormal);

						// Compute velocity after deflection (only gravity component for RootMotion)
						if (subTimeTickRemaining > UE_KINDA_SMALL_NUMBER && !bJustTeleported)
						{
							const FVector NewVelocity = (Delta / subTimeTickRemaining);
							Velocity = HasAnimRootMotion() || CurrentRootMotion.HasOverrideVelocityWithIgnoreZAccumulate() ? FVector(Velocity.X, Velocity.Y, NewVelocity.Z) : NewVelocity;
						}

						// bDitch=true means that pawn is straddling two slopes, neither of which it can stand on
						bool bDitch = ( (OldHitImpactNormal.Z > 0.f) && (Hit.ImpactNormal.Z > 0.f) && (FMath::Abs(Delta.Z) <= UE_KINDA_SMALL_NUMBER) && ((Hit.ImpactNormal | OldHitImpactNormal) < 0.f) );
						SafeMoveUpdatedComponent( Delta, PawnRotation, true, Hit);
						if ( Hit.Time == 0.f )
						{
							// if we are stuck then try to side step
							FVector SideDelta = (OldHitNormal + Hit.ImpactNormal).GetSafeNormal2D();
							if ( SideDelta.IsNearlyZero() )
							{
								SideDelta = FVector(OldHitNormal.Y, -OldHitNormal.X, 0).GetSafeNormal();
							}
							SafeMoveUpdatedComponent( SideDelta, PawnRotation, true, Hit);
						}
							
						if ( bDitch || IsValidLandingSpot(UpdatedComponent->GetComponentLocation(), Hit) || Hit.Time == 0.f  )
						{
							remainingTime = 0.f;
							ProcessGlideLanded(Hit);
							return;
						}
						else if (GetPerchRadiusThreshold() > 0.f && Hit.Time == 1.f && OldHitImpactNormal.Z >= 0.71f)
						{
							// We might be in a virtual 'ditch' within our perch radius. This is rare.
							const FVector PawnLocation = UpdatedComponent->GetComponentLocation();
							const float ZMovedDist = FMath::Abs(PawnLocation.Z - OldLocation.Z);
							const float MovedDist2DSq = (PawnLocation - OldLocation).SizeSquared2D();
							if (ZMovedDist <= 0.2f * timeTick && MovedDist2DSq <= 4.f * timeTick)
							{
								Velocity.X += 0.25f * GetMaxSpeed() * (RandomStream.FRand() - 0.5f);
								Velocity.Y += 0.25f * GetMaxSpeed() * (RandomStream.FRand() - 0.5f);
								Velocity.Z = FMath::Max<float>(JumpZVelocity * 0.25f, 1.f);
								Delta = Velocity * timeTick;
								SafeMoveUpdatedComponent(Delta, PawnRotation, true, Hit);
							}
						}
					}
				}
			}
		}

		//UE_LOG(LogTemp, Error, TEXT("UHiCharacterMovementComponent::PhysGlide 333 %d %s %s"), (int32)GetWorld()->GetNetMode(), *Velocity.ToString(), *UpdatedComponent->GetComponentLocation().ToString());

		if (Velocity.SizeSquared2D() <= UE_KINDA_SMALL_NUMBER * 10.f)
		{
			Velocity.X = 0.f;
			Velocity.Y = 0.f;
		}
	}
}

void UHiCharacterMovementComponent::PhysMantle(float deltaTime, int32 Iterations)
{
	if (deltaTime < MIN_TICK_TIME)
	{
		return;
	}

	RestorePreAdditiveRootMotionVelocity();

	if( !HasAnimRootMotion() && !CurrentRootMotion.HasOverrideVelocity() )
	{
		if( bCheatFlying && Acceleration.IsZero() )
		{
			Velocity = FVector::ZeroVector;
		}
		const float Friction = 0.5f * GetPhysicsVolume()->FluidFriction;
		CalcVelocity(deltaTime, Friction, true, GetMaxBrakingDeceleration());
	}

	ApplyRootMotionToVelocity(deltaTime);

	Iterations++;
	bJustTeleported = false;

	FVector OldLocation = UpdatedComponent->GetComponentLocation();
	const FVector Adjusted = Velocity * deltaTime;
	FHitResult Hit(1.f);
	SafeMoveUpdatedComponent(Adjusted, UpdatedComponent->GetComponentQuat(), true, Hit);

	if (Hit.Time < 1.f)
	{
		const FVector GravDir = FVector(0.f, 0.f, -1.f);
		const FVector VelDir = Velocity.GetSafeNormal();
		const float UpDown = GravDir | VelDir;
		
		bool bSteppedUp = false;
		if ((FMath::Abs(Hit.ImpactNormal.Z) < 0.2f) && (UpDown < 0.5f) && (UpDown > -0.2f) && CanStepUp(Hit))
		{
			float stepZ = UpdatedComponent->GetComponentLocation().Z;
			bSteppedUp = StepUp(GravDir, Adjusted * (1.f - Hit.Time), Hit);
			if (bSteppedUp)
			{
				OldLocation.Z = UpdatedComponent->GetComponentLocation().Z + (OldLocation.Z - stepZ);
			}
		}
		
		if (!bSteppedUp)
		{
			//adjust and try again
			HandleImpact(Hit, deltaTime, Adjusted);
			SlideAlongSurface(Adjusted, (1.f - Hit.Time), Hit.Normal, Hit, true);
		}
	}

	if( !bJustTeleported && !HasAnimRootMotion() && !CurrentRootMotion.HasOverrideVelocity() )
	{
		Velocity = (UpdatedComponent->GetComponentLocation() - OldLocation) / deltaTime;
	}
}

void UHiCharacterMovementComponent::PhysSkill_Implementation(float DeltaTime)
{
	this->PhysFlying(DeltaTime, 0);
}

void UHiCharacterMovementComponent::FindFloor(const FVector& CapsuleLocation, FFindFloorResult& OutFloorResult, bool bCanUseCachedLocation, const FHitResult* DownwardSweepResult) const
{
	SCOPE_CYCLE_COUNTER(STAT_CharFindFloor);

	// No collision, no floor...
	if (!HasValidData() || !UpdatedComponent->IsQueryCollisionEnabled())
	{
		OutFloorResult.Clear();
		return;
	}

	//UE_LOG(LogCharacterMovement, VeryVerbose, TEXT("[Role:%d] FindFloor: %s at location %s"), (int32)CharacterOwner->GetLocalRole(), *GetNameSafe(CharacterOwner), *CapsuleLocation.ToString());
	check(CharacterOwner->GetCapsuleComponent());

	// Increase height check slightly if walking, to prevent floor height adjustment from later invalidating the floor result.
	const float HeightCheckAdjust = (IsMovingOnGround() ? MAX_FLOOR_DIST + UE_KINDA_SMALL_NUMBER : -MAX_FLOOR_DIST);

	float FloorSweepTraceDist = FMath::Max(MAX_FLOOR_DIST, MaxFindFloorStepHeight + HeightCheckAdjust);
	float FloorLineTraceDist = FloorSweepTraceDist;
	bool bNeedToValidateFloor = true;

	// Sweep floor
	if (FloorLineTraceDist > 0.f || FloorSweepTraceDist > 0.f)
	{
		UCharacterMovementComponent* MutableThis = const_cast<UHiCharacterMovementComponent*>(this);

		if (bAlwaysCheckFloor || !bCanUseCachedLocation || bForceNextFloorCheck || bJustTeleported)
		{
			MutableThis->bForceNextFloorCheck = false;
			ComputeFloorDist(CapsuleLocation, FloorLineTraceDist, FloorSweepTraceDist, OutFloorResult, CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleRadius(), DownwardSweepResult);
		}
		else
		{
			// Force floor check if base has collision disabled or if it does not block us.
			UPrimitiveComponent* MovementBase = CharacterOwner->GetMovementBase();
			const AActor* BaseActor = MovementBase ? MovementBase->GetOwner() : NULL;
			const ECollisionChannel CollisionChannel = UpdatedComponent->GetCollisionObjectType();

			if (MovementBase != NULL)
			{
				MutableThis->bForceNextFloorCheck = !MovementBase->IsQueryCollisionEnabled()
					|| MovementBase->GetCollisionResponseToChannel(CollisionChannel) != ECR_Block
					|| MovementBaseUtility::IsDynamicBase(MovementBase);
			}

			const bool IsActorBasePendingKill = BaseActor && !IsValid(BaseActor);

			if (!bForceNextFloorCheck && !IsActorBasePendingKill && MovementBase)
			{
				//UE_LOG(LogCharacterMovement, Log, TEXT("%s SKIP check for floor"), *CharacterOwner->GetName());
				OutFloorResult = CurrentFloor;
				bNeedToValidateFloor = false;
			}
			else
			{
				MutableThis->bForceNextFloorCheck = false;
				ComputeFloorDist(CapsuleLocation, FloorLineTraceDist, FloorSweepTraceDist, OutFloorResult, CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleRadius(), DownwardSweepResult);
			}
		}
	}

	// OutFloorResult.HitResult is now the result of the vertical floor check.
	// See if we should try to "perch" at this location.
	if (bNeedToValidateFloor && OutFloorResult.bBlockingHit && !OutFloorResult.bLineTrace)
	{
		const bool bCheckRadius = true;
		if (ShouldComputePerchResult(OutFloorResult.HitResult, bCheckRadius))
		{
			float MaxPerchFloorDist = FMath::Max(MAX_FLOOR_DIST, MaxStepHeight + HeightCheckAdjust);
			if (IsMovingOnGround())
			{
				MaxPerchFloorDist += FMath::Max(0.f, PerchAdditionalHeight);
			}

			FFindFloorResult PerchFloorResult;
			if (ComputePerchResult(GetValidPerchRadius(), OutFloorResult.HitResult, MaxPerchFloorDist, PerchFloorResult))
			{
				// Don't allow the floor distance adjustment to push us up too high, or we will move beyond the perch distance and fall next time.
				const float AvgFloorDist = (MIN_FLOOR_DIST + MAX_FLOOR_DIST) * 0.5f;
				const float MoveUpDist = (AvgFloorDist - OutFloorResult.FloorDist);
				if (MoveUpDist + PerchFloorResult.FloorDist >= MaxPerchFloorDist)
				{
					OutFloorResult.FloorDist = AvgFloorDist;
				}

				// If the regular capsule is on an unwalkable surface but the perched one would allow us to stand, override the normal to be one that is walkable.
				if (!OutFloorResult.bWalkableFloor)
				{
					// Floor distances are used as the distance of the regular capsule to the point of collision, to make sure AdjustFloorHeight() behaves correctly.
					OutFloorResult.SetFromLineTrace(PerchFloorResult.HitResult, OutFloorResult.FloorDist, FMath::Max(OutFloorResult.FloorDist, MIN_FLOOR_DIST), true);
				}
			}
			else
			{
				// We had no floor (or an invalid one because it was unwalkable), and couldn't perch here, so invalidate floor (which will cause us to start falling).
				OutFloorResult.bWalkableFloor = false;
			}
		}
	}
}

float UHiCharacterMovementComponent::GetMappedSpeed() const
{
	// Map the character's current speed to the configured movement speeds with a range of 0-3,
	// with 0 = stopped, 1 = the Walk Speed, 2 = the Run Speed, and 3 = the Sprint Speed.
	// This allows us to vary the movement speeds but still use the mapped range in calculations for consistent results

	const float Speed = Velocity.Size2D();
	const float LocWalkSpeed = CurrentMovementSettings.WalkSpeed * SpeedScale;
	const float LocRunSpeed = CurrentMovementSettings.RunSpeed * SpeedScale;
	const float LocSprintSpeed = CurrentMovementSettings.SprintSpeed * SpeedScale;

	if (Speed > LocRunSpeed)
	{
		return FMath::GetMappedRangeValueClamped<float, float>({LocRunSpeed, LocSprintSpeed}, {2.0f, 3.0f}, Speed);
	}

	if (Speed > LocWalkSpeed)
	{
		return FMath::GetMappedRangeValueClamped<float, float>({LocWalkSpeed, LocRunSpeed}, {1.0f, 2.0f}, Speed);
	}

	return FMath::GetMappedRangeValueClamped<float, float>({0.0f, LocWalkSpeed}, {0.0f, 1.0f}, Speed);
}

bool UHiCharacterMovementComponent::IsInAir() const
{
	return (MovementMode == MOVE_Falling || MovementMode == MOVE_Flying || MovementMode == MOVE_Custom) && UpdatedComponent;
}

void UHiCharacterMovementComponent::SetMovementSettings(FHiMovementSettings NewMovementSettings)
{
	// Set the current movement settings from the owner
	CurrentMovementSettings = NewMovementSettings;
	OnMovementSettingsChanged();
}

void UHiCharacterMovementComponent::SetSpeedScale(float speedScale)
{
	SpeedScale = speedScale;
	OnMovementSettingsChanged();
}

float UHiCharacterMovementComponent::GetSpeedScale() const
{
	return SpeedScale;
}

void UHiCharacterMovementComponent::SetAllowedGait(EHiGait NewAllowedGait)
{
	if (AllowedGait != NewAllowedGait)
	{
		AllowedGait = NewAllowedGait;
		OnMovementSettingsChanged();

		if (PawnOwner->IsLocallyControlled())
		{
			if (GetCharacterOwner()->GetLocalRole() == ROLE_AutonomousProxy)
			{
				Server_SetAllowedGait(NewAllowedGait);
			}
			// bRequestMovementSettingsChange = true;
			return;
		}
		if (!PawnOwner->HasAuthority())
		{
			const float UpdateMaxWalkSpeed = CurrentMovementSettings.GetSpeedForGait(AllowedGait) * SpeedScale;
			// UE_LOG(LogTemp, Warning, TEXT("UHiCharacterMovementComponent::SetAllowedGait %f"), UpdateMaxWalkSpeed);
			MaxWalkSpeed = UpdateMaxWalkSpeed;
			MaxWalkSpeedCrouched = UpdateMaxWalkSpeed;
		}
	}
}

float UHiCharacterMovementComponent::GetGaitSpeedInSettings(const EHiGait InGait)
{
	switch (InGait)
	{
	case EHiGait::Idle:
		return 0.0f;
	case EHiGait::Walking:
		return CurrentMovementSettings.WalkSpeed;
	case EHiGait::Running:
		return CurrentMovementSettings.RunSpeed;
	case EHiGait::Sprinting:
		return CurrentMovementSettings.SprintSpeed;
	}
	return 0.0f;
}

void UHiCharacterMovementComponent::SetForceNoCombine(bool value)
{
	bForceNoCombine = value;
}

bool UHiCharacterMovementComponent::GetForceNoCombine() const
{
	return bForceNoCombine;
}

FVector UHiCharacterMovementComponent::GetFallingLateralAcceleration(float DeltaTime)
{
	// No acceleration in Z
	FVector FallAcceleration(Acceleration.X, Acceleration.Y, 0.f);

	FRotator HorizontalRotator(0, UpdatedComponent->GetComponentRotation().Yaw, 0);
	FVector LocalFallAcceleration = HorizontalRotator.UnrotateVector(FallAcceleration);

	FallAcceleration = LocalFallAcceleration.X * UpdatedComponent->GetForwardVector();

	// bound acceleration, falling object has minimal ability to impact acceleration
	if (!HasAnimRootMotion() && FallAcceleration.SizeSquared2D() > 0.f)
	{
		FallAcceleration = GetAirControl(DeltaTime, AirControl, FallAcceleration);
		FallAcceleration = FallAcceleration.GetClampedToMaxSize(GetMaxAcceleration());
	}
	return FallAcceleration;
}

void UHiCharacterMovementComponent::CalcVelocity(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	switch (MovementMode)
	{
	case MOVE_Walking:
		CalcVelocityForWalking(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	case MOVE_Falling:
		CalcVelocityForFalling(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	default:
		Super::CalcVelocity(DeltaTime, Friction, bFluid, BrakingDeceleration);
		break;
	}
	return;
}

FVector UHiCharacterMovementComponent::NewFallVelocity(const FVector& InitialVelocity, const FVector& Gravity, float DeltaTime) const
{

	FVector Result = InitialVelocity;

	if (DeltaTime > 0.f)
	{
		// Apply gravity.
		Result += Gravity * DeltaTime;

		Result += GetBufferAcceleratedVelocity() * DeltaTime;


		// Don't exceed terminal velocity.
		const float TerminalLimit = FMath::Abs(GetPhysicsVolume()->TerminalVelocity);
		if (Result.SizeSquared() > FMath::Square(TerminalLimit))
		{
			const FVector GravityDir = Gravity.GetSafeNormal();
			if ((Result | GravityDir) > TerminalLimit)
			{
				Result = FVector::PointPlaneProject(Result, FVector::ZeroVector, GravityDir) + GravityDir * TerminalLimit;
			}
		}
	}

	return Result;
}

void UHiCharacterMovementComponent::CalcVelocityForGliding(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	// Do not update velocity when using root motion or when SimulatedProxy and not simulating root motion - SimulatedProxy are repped their Velocity
	if (!HasValidData() || HasAnimRootMotion() || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bWasSimulatingRootMotion))
	{
		return;
	}

	Friction = FMath::Max(0.f, Friction);
	const float MaxAccel = GetMaxAcceleration();
	float MaxSpeed = GetMaxSpeed();
	const FVector OldVelocity = Velocity;

	// Check if path following requested movement
	bool bZeroRequestedAcceleration = true;
	FVector RequestedAcceleration = FVector::ZeroVector;
	float RequestedSpeed = 0.0f;
	if (ApplyRequestedMove(DeltaTime, MaxAccel, MaxSpeed, Friction, BrakingDeceleration, RequestedAcceleration, RequestedSpeed))
	{
		bZeroRequestedAcceleration = false;
	}

	if (bForceMaxAccel)
	{
		// Force acceleration at full speed.
		// In consideration order for direction: Acceleration, then Velocity, then Pawn's rotation.
		if (Acceleration.SizeSquared() > SMALL_NUMBER)
		{
			Acceleration = Acceleration.GetSafeNormal() * MaxAccel;
		}
		else
		{
			Acceleration = MaxAccel * (Velocity.SizeSquared() < SMALL_NUMBER ? UpdatedComponent->GetForwardVector() : Velocity.GetSafeNormal());
		}

		AnalogInputModifier = 1.f;
	}

	// Path following above didn't care about the analog modifier, but we do for everything else below, so get the fully modified value.
	// Use max of requested speed and max speed if we modified the speed in ApplyRequestedMove above.

	// Zale: The analoginputmodifier adjusts due to acceleration, but after adjusting the upper speed limit, the overall speed will be unstable
	const float MaxInputSpeed = FMath::Max(MaxSpeed * AnalogInputModifier, GetMinAnalogSpeed());
	MaxSpeed = FMath::Max(RequestedSpeed, MaxInputSpeed);

	// Apply braking or deceleration
	const bool bZeroAcceleration = Acceleration.IsZero();
	const bool bVelocityOverMax = IsExceedingMaxSpeed(MaxSpeed);
	const float ActualBrakingFriction = (bUseSeparateBrakingFriction ? BrakingFriction : Friction);

	if (bZeroAcceleration && bZeroRequestedAcceleration)
	{
		Velocity = FVector(0, 0, 0);
	}
	else if (!bZeroAcceleration)
	{
		// Friction affects our ability to change direction. This is only done for input acceleration, not path following.
		const FVector AccelDir = Acceleration.GetSafeNormal();
		const float VelSize = Velocity.Size();
		Velocity = Velocity - (Velocity - AccelDir * VelSize) * FMath::Min(DeltaTime * Friction, 1.f);
	}

	// Only apply braking if there is no acceleration, or we are over our max speed and need to slow down to it.
	if (bVelocityOverMax)
	{
		Velocity = OldVelocity.GetSafeNormal() * MaxSpeed;
	}

	// Apply fluid friction
	if (bFluid)
	{
		Velocity = Velocity * (1.f - FMath::Min(Friction * DeltaTime, 1.f));
	}

	// Apply input acceleration
	if (!bZeroAcceleration)
	{
		const float NewMaxInputSpeed = IsExceedingMaxSpeed(MaxInputSpeed) ? Velocity.Size() : MaxInputSpeed;
		Velocity += Acceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxInputSpeed);
	}

	// Apply additional requested acceleration
	if (!bZeroRequestedAcceleration)
	{
		const float NewMaxRequestedSpeed = IsExceedingMaxSpeed(RequestedSpeed) ? Velocity.Size() : RequestedSpeed;
		Velocity += RequestedAcceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxRequestedSpeed);
	}

	if (bUseRVOAvoidance)
	{
		CalcAvoidanceVelocity(DeltaTime);
	}
}

void UHiCharacterMovementComponent::CalcVelocityForWalking(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	// Do not update velocity when using root motion or when SimulatedProxy and not simulating root motion - SimulatedProxy are repped their Velocity
	if (!HasValidData() || HasAnimRootMotion() || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bWasSimulatingRootMotion))
	{
		return;
	}

	Friction = FMath::Max(0.f, Friction);
	const float MaxAccel = GetMaxAcceleration();
	float MaxSpeed = GetMaxSpeed();
	const FVector OldVelocity = Velocity;

	// Check if path following requested movement
	bool bZeroRequestedAcceleration = true;
	FVector RequestedAcceleration = FVector::ZeroVector;
	float RequestedSpeed = 0.0f;
	if (ApplyRequestedMove(DeltaTime, MaxAccel, MaxSpeed, Friction, BrakingDeceleration, RequestedAcceleration, RequestedSpeed))
	{
		bZeroRequestedAcceleration = false;
	}

	if (bForceMaxAccel)
	{
		// Force acceleration at full speed.
		// In consideration order for direction: Acceleration, then Velocity, then Pawn's rotation.
		if (Acceleration.SizeSquared() > SMALL_NUMBER)
		{
			Acceleration = Acceleration.GetSafeNormal() * MaxAccel;
		}
		else
		{
			Acceleration = MaxAccel * (Velocity.SizeSquared() < SMALL_NUMBER ? UpdatedComponent->GetForwardVector() : Velocity.GetSafeNormal());
		}

		AnalogInputModifier = 1.f;
	}

	// Path following above didn't care about the analog modifier, but we do for everything else below, so get the fully modified value.
	// Use max of requested speed and max speed if we modified the speed in ApplyRequestedMove above.

	// Zale: The analoginputmodifier adjusts due to acceleration, but after adjusting the upper speed limit, the overall speed will be unstable
	const float MaxInputSpeed = FMath::Max(MaxSpeed * AnalogInputModifier, GetMinAnalogSpeed());
	MaxSpeed = FMath::Max(RequestedSpeed, MaxInputSpeed);

	// Apply braking or deceleration
	const bool bZeroAcceleration = Acceleration.IsZero();
	const bool bVelocityOverMax = IsExceedingMaxSpeed(MaxSpeed);
	const float ActualBrakingFriction = (bUseSeparateBrakingFriction ? BrakingFriction : Friction);

	if (bZeroAcceleration && bZeroRequestedAcceleration)
	{
		Velocity = FVector(0, 0, 0);
	}
	else if (!bZeroAcceleration)
	{
		Velocity = Acceleration.GetSafeNormal() * Velocity.Size();
	}

	// Only apply braking if there is no acceleration, or we are over our max speed and need to slow down to it.
	if (bVelocityOverMax)
	{
		Velocity = OldVelocity.GetSafeNormal() * MaxSpeed;
	}

	// Apply fluid friction
	if (bFluid)
	{
		Velocity = Velocity * (1.f - FMath::Min(Friction * DeltaTime, 1.f));
	}

	// Apply input acceleration
	if (!bZeroAcceleration)
	{
		const float NewMaxInputSpeed = IsExceedingMaxSpeed(MaxInputSpeed) ? Velocity.Size() : MaxInputSpeed;
		Velocity += Acceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxInputSpeed);
	}

	// Apply additional requested acceleration
	if (!bZeroRequestedAcceleration)
	{
		const float NewMaxRequestedSpeed = IsExceedingMaxSpeed(RequestedSpeed) ? Velocity.Size() : RequestedSpeed;
		Velocity += RequestedAcceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxRequestedSpeed);
	}
	Velocity += BufferVelocity;
	Velocity += BufferVelocityOnlyOnce;
	BufferVelocityOnlyOnce = FVector::ZeroVector;
	if (bUseRVOAvoidance)
	{
		CalcAvoidanceVelocity(DeltaTime);
	}
}


void UHiCharacterMovementComponent::CalcVelocityForFalling(float DeltaTime, float Friction, bool bFluid, float BrakingDeceleration)
{
	// Do not update velocity when using root motion or when SimulatedProxy and not simulating root motion - SimulatedProxy are repped their Velocity
	if (!HasValidData()/* || HasAnimRootMotion()*/ || DeltaTime < MIN_TICK_TIME || (CharacterOwner && CharacterOwner->GetLocalRole() == ROLE_SimulatedProxy && !bWasSimulatingRootMotion))
	{
		return;
	}

	Friction = FMath::Max(0.f, Friction);
	const float MaxAccel = GetMaxAcceleration();
	float MaxSpeed = GetMaxSpeed();
	const FVector OldVelocity = Velocity;

	// Check if path following requested movement
	bool bZeroRequestedAcceleration = true;
	FVector RequestedAcceleration = FVector::ZeroVector;
	float RequestedSpeed = 0.0f;
	if (ApplyRequestedMove(DeltaTime, MaxAccel, MaxSpeed, Friction, BrakingDeceleration, RequestedAcceleration, RequestedSpeed))
	{
		bZeroRequestedAcceleration = false;
	}

	// Path following above didn't care about the analog modifier, but we do for everything else below, so get the fully modified value.
	// Use max of requested speed and max speed if we modified the speed in ApplyRequestedMove above.

	// Zale: The analoginputmodifier adjusts due to acceleration, but after adjusting the upper speed limit, the overall speed will be unstable
	const float MaxInputSpeed = FMath::Max(MaxSpeed, GetMinAnalogSpeed());
	MaxSpeed = FMath::Max(RequestedSpeed, MaxInputSpeed);

	// Apply braking or deceleration
	const bool bZeroAcceleration = Acceleration.IsZero();
	const bool bVelocityOverMax = IsExceedingMaxSpeed(MaxSpeed);
	const float ActualBrakingFriction = (bUseSeparateBrakingFriction ? BrakingFriction : Friction);

	// Only apply braking if there is no acceleration, or we are over our max speed and need to slow down to it.

	if (bVelocityOverMax)
	{
		Velocity = OldVelocity.GetSafeNormal() * MaxSpeed;
	}

	// Apply fluid friction
	if (bFluid)
	{
		Velocity = Velocity * (1.f - FMath::Min(Friction * DeltaTime, 1.f));
	}

	// Apply input acceleration
	if (!bZeroAcceleration)
	{
		const float NewMaxInputSpeed = IsExceedingMaxSpeed(MaxInputSpeed) ? Velocity.Size() : MaxInputSpeed;
		Velocity += Acceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxInputSpeed);
	}

	// Apply additional requested acceleration
	if (!bZeroRequestedAcceleration)
	{
		const float NewMaxRequestedSpeed = IsExceedingMaxSpeed(RequestedSpeed) ? Velocity.Size() : RequestedSpeed;
		Velocity += RequestedAcceleration * DeltaTime;
		Velocity = Velocity.GetClampedToMaxSize(NewMaxRequestedSpeed);
	}

	if (FVector::DotProduct(Velocity, UpdatedComponent->GetForwardVector()) < 0.0f)
	{
		Velocity = FVector(0, 0, OldVelocity.Z);
	}
	//Velocity += BufferVelocity;

	if (bUseRVOAvoidance)
	{
		CalcAvoidanceVelocity(DeltaTime);
	}
}

void UHiCharacterMovementComponent::ApplyVelocityBraking(float DeltaTime, float Friction, float BrakingDeceleration)
{
	if (!HasValidData() || HasAnimRootMotion() || DeltaTime < MIN_TICK_TIME)
	{
		return;
	}

	const float FrictionFactor = FMath::Max(0.f, BrakingFrictionFactor);
	Friction = FMath::Max(0.f, Friction * FrictionFactor);
	BrakingDeceleration = FMath::Max(0.f, BrakingDeceleration);
	const bool bZeroFriction = (Friction == 0.f);
	const bool bZeroBraking = (BrakingDeceleration == 0.f);

	if (bZeroFriction && bZeroBraking)
	{
		return;
	}

	const FVector OldVel = Velocity;

	const FVector RevAccel = (bZeroBraking ? FVector::ZeroVector : (-BrakingDeceleration * Velocity.GetSafeNormal()));
	// apply friction and braking
	Velocity = Velocity + ((-Friction) * Velocity + RevAccel) * DeltaTime;

	// Don't reverse direction
	if ((Velocity | OldVel) <= 0.f)
	{
		Velocity = FVector::ZeroVector;
		return;
	}

	// Clamp to zero if nearly zero, or if below min threshold and braking.
	const float VSizeSq = Velocity.SizeSquared();
	if (VSizeSq <= KINDA_SMALL_NUMBER || (!bZeroBraking && VSizeSq <= FMath::Square(BRAKE_TO_STOP_VELOCITY)))
	{
		Velocity = FVector::ZeroVector;
	}
}

bool UHiCharacterMovementComponent::BP_CanStepUp(const FHitResult& Hit) const
{
	return this->CanStepUp(Hit);
}

void UHiCharacterMovementComponent::BP_HandleImpact(const FHitResult& Hit, float TimeSlice, const FVector& MoveDelta)
{
	this->HandleImpact(Hit, TimeSlice, MoveDelta);
}

float UHiCharacterMovementComponent::BP_SlideAlongSurface(const FVector& Delta, float Time, const FVector& Normal, FHitResult& Hit, bool bHandleImpact)
{
	return this->SlideAlongSurface(Delta, Time, Normal, Hit, bHandleImpact);
}

bool UHiCharacterMovementComponent::BP_StepUp(const FVector& GravDir, const FVector& Delta, const FHitResult& Hit, bool& bComputedFloor, FFindFloorResult& FloorResult)
{
	FStepDownResult StepDownResult;
	bool bStepUp = this->StepUp(GravDir, Delta, Hit, &StepDownResult);
	bComputedFloor = StepDownResult.bComputedFloor;
	FloorResult = StepDownResult.FloorResult;
	return bStepUp;
}

FVector UHiCharacterMovementComponent::BP_ComputeGroundMovementDelta(const FVector& Delta, const FHitResult& RampHit, const bool bHitFromLineTrace) const
{
	return ComputeGroundMovementDelta(Delta, RampHit, bHitFromLineTrace);
}

void UHiCharacterMovementComponent::UpdateWalkSpeed()
{
	const float UpdateMaxWalkSpeed = CurrentMovementSettings.GetSpeedForGait(AllowedGait) * SpeedScale;
	UE_LOG(LogTemp, Warning, TEXT("UHiCharacterMovementComponent::UpdateWalkSpeed %f %s %d"), UpdateMaxWalkSpeed, *GetName(), GetNetMode());
	MaxWalkSpeed = UpdateMaxWalkSpeed;
	MaxWalkSpeedCrouched = UpdateMaxWalkSpeed;
}


/*void UHiCharacterMovementComponent::SetMovementMode(EMovementMode NewMovementMode, uint8 NewCustomMode)
{
	if (NewMovementMode == MOVE_Custom || MovementMode == MOVE_Custom || NewCustomMode != CustomMovementMode)
	{
		char GStackTrace[65536];
		FPlatformStackWalk::StackWalkAndDump(GStackTrace, 65535, 1);
		FString OutCallstack = ANSI_TO_TCHAR(GStackTrace);

		UE_LOG(LogNetPlayerMovement, Error, TEXT("%s"), *OutCallstack);
	}
	Super::SetMovementMode(NewMovementMode, NewCustomMode);
}*/

void UHiCharacterMovementComponent::ChangeRootMotionOverrideType(UObject* OwnerObject, EHiRootMotionOverrideType NewRootMotionOverrideType)
{
	RootMotionOverrideType = NewRootMotionOverrideType;
	RootMotionOverrideTypePendingList.Add(TPair<UObject*, EHiRootMotionOverrideType>(OwnerObject, NewRootMotionOverrideType));
}

void UHiCharacterMovementComponent::ResetRootMotionOverrideTypeToDefault(UObject* OwnerObject)
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

bool UHiCharacterMovementComponent::ServerCanAcceptClientPosition()
{
#if WITH_EDITOR
	AHiWorldSettings* WorldSettings= Cast<AHiWorldSettings>(CharacterOwner->GetWorldSettings());
	if (WorldSettings)
	{
		return WorldSettings->bForceServerAcceptClientPosition || bServerAcceptClientAuthoritativePosition || ServerDealClientPosition == EHiServerDealClientPosition::Accept;
	}
#endif
	
	return bServerAcceptClientAuthoritativePosition || ServerDealClientPosition == EHiServerDealClientPosition::Accept;
}

/** Special Tick for Simulated Proxies */
void UHiCharacterMovementComponent::SimulatedTick(float DeltaSeconds)
{
	checkSlow(CharacterOwner != nullptr);

	// If we are playing a RootMotion AnimMontage.
	if (CharacterOwner->IsPlayingNetworkedRootMotionMontage())
	{
		bWasSimulatingRootMotion = true;
		UE_LOG(LogRootMotion, Verbose, TEXT("UCharacterMovementComponent::SimulatedTick"));

		// Tick animations before physics.
		if (CharacterOwner && CharacterOwner->GetMesh())
		{
			TickCharacterPose(DeltaSeconds);

			// Make sure animation didn't trigger an event that destroyed us
			if (!HasValidData())
			{
				return;
			}
		}

		const FQuat OldRotationQuat = UpdatedComponent->GetComponentQuat();
		const FVector OldLocation = UpdatedComponent->GetComponentLocation();

		USkeletalMeshComponent* Mesh = CharacterOwner->GetMesh();
		const FVector SavedMeshRelativeLocation = Mesh ? Mesh->GetRelativeLocation() : FVector::ZeroVector;

		if (RootMotionParams.bHasRootMotion)
		{
			SimulateRootMotion(DeltaSeconds, RootMotionParams.GetRootMotionTransform());

#if WITH_EDITOR /*!(UE_BUILD_SHIPPING) */
			// debug
			if (CharacterOwner && bDebugDrawSimulate)
			{
				const FRotator OldRotation = OldRotationQuat.Rotator();
				const FRotator NewRotation = UpdatedComponent->GetComponentRotation();
				const FVector NewLocation = UpdatedComponent->GetComponentLocation();
				DrawDebugCoordinateSystem(GetWorld(), CharacterOwner->GetMesh()->GetComponentLocation() + FVector(0, 0, 1), NewRotation, 50.f, false);
				DrawDebugLine(GetWorld(), OldLocation, NewLocation, FColor::Red, false, 10.f);

				UE_LOG(LogRootMotion, Log, TEXT("UCharacterMovementComponent::SimulatedTick DeltaMovement Owner: %s, Role: %s, DeltaTranslation: %s, DeltaRotation: %s, MovementBase: %s, OldLocation: %s, NewLocation: %s"),
					*CharacterOwner->GetName(), *UEnum::GetValueAsString(TEXT("Engine.ENetRole"), CharacterOwner->GetLocalRole()), *(NewLocation - OldLocation).ToCompactString(), *(NewRotation - OldRotation).GetNormalized().ToCompactString(), *GetNameSafe(CharacterOwner->GetMovementBase()), *OldLocation.ToCompactString(), *NewLocation.ToCompactString());
			}
#endif // WITH_EDITOR
		}

		// then, once our position is up to date with our animation, 
		// handle position correction if we have any pending updates received from the server.
		if (CharacterOwner && (CharacterOwner->RootMotionRepMoves.Num() > 0))
		{
			CharacterOwner->SimulatedRootMotionPositionFixup(DeltaSeconds);
		}

		if (!bNetworkSmoothingComplete && (NetworkSmoothingMode == ENetworkSmoothingMode::Linear))
		{
			// Same mesh with different rotation?
			const FQuat NewCapsuleRotation = UpdatedComponent->GetComponentQuat();
			if (Mesh == CharacterOwner->GetMesh() && !NewCapsuleRotation.Equals(OldRotationQuat, 1e-6f) && ClientPredictionData)
			{
				// Smoothing should lerp toward this new rotation target, otherwise it will just try to go back toward the old rotation.
				ClientPredictionData->MeshRotationTarget = NewCapsuleRotation;
				Mesh->SetRelativeLocationAndRotation(SavedMeshRelativeLocation, CharacterOwner->GetBaseRotationOffset());
			}
		}
	}
	else if (CurrentRootMotion.HasActiveRootMotionSources())
	{
		// We have root motion sources and possibly animated root motion
		bWasSimulatingRootMotion = true;
		UE_LOG(LogRootMotion, Verbose, TEXT("UCharacterMovementComponent::SimulatedTick"));

		// If we have RootMotionRepMoves, find the most recent important one and set position/rotation to it
		bool bCorrectedToServer = false;
		const FVector OldLocation = UpdatedComponent->GetComponentLocation();
		const FQuat OldRotation = UpdatedComponent->GetComponentQuat();
		if (CharacterOwner->RootMotionRepMoves.Num() > 0)
		{
			// Move Actor back to position of that buffered move. (server replicated position).
			FSimulatedRootMotionReplicatedMove& RootMotionRepMove = CharacterOwner->RootMotionRepMoves.Last();
			if (CharacterOwner->RestoreReplicatedMove(RootMotionRepMove))
			{
				bCorrectedToServer = true;
			}
			Acceleration = RootMotionRepMove.RootMotion.Acceleration;

			CharacterOwner->PostNetReceiveVelocity(RootMotionRepMove.RootMotion.LinearVelocity);
			LastUpdateVelocity = RootMotionRepMove.RootMotion.LinearVelocity;

			// Convert RootMotionSource Server IDs -> Local IDs in AuthoritativeRootMotion and cull invalid
			// so that when we use this root motion it has the correct IDs
			ConvertRootMotionServerIDsToLocalIDs(CurrentRootMotion, RootMotionRepMove.RootMotion.AuthoritativeRootMotion, RootMotionRepMove.Time);
			RootMotionRepMove.RootMotion.AuthoritativeRootMotion.CullInvalidSources();

			// Set root motion states to that of repped in state
			CurrentRootMotion.UpdateStateFrom(RootMotionRepMove.RootMotion.AuthoritativeRootMotion, true);

			// Clear out existing RootMotionRepMoves since we've consumed the most recent
			UE_LOG(LogRootMotion, Log, TEXT("\tClearing old moves in SimulatedTick (%d)"), CharacterOwner->RootMotionRepMoves.Num());
			CharacterOwner->RootMotionRepMoves.Reset();
		}

		// Update replicated gravity direction
		if (bNetworkGravityDirectionChanged)
		{
			SetGravityDirection(CharacterOwner->GetReplicatedGravityDirection());
			bNetworkGravityDirectionChanged = false;
		}

		// Update replicated movement mode.
		if (bNetworkMovementModeChanged)
		{
			ApplyNetworkMovementMode(CharacterOwner->GetReplicatedMovementMode());
			bNetworkMovementModeChanged = false;
		}

		// Perform movement
		PerformMovement(DeltaSeconds);

		// After movement correction, smooth out error in position if any.
		if (bCorrectedToServer || CurrentRootMotion.NeedsSimulatedSmoothing())
		{
			SmoothCorrection(OldLocation, OldRotation, UpdatedComponent->GetComponentLocation(), UpdatedComponent->GetComponentQuat());
		}
	}
	// Not playing RootMotion AnimMontage
	else
	{
		// if we were simulating root motion, we've been ignoring regular ReplicatedMovement updates.
		// If we're not simulating root motion anymore, force us to sync our movement properties.
		// (Root Motion could leave Velocity out of sync w/ ReplicatedMovement)
		if (bWasSimulatingRootMotion)
		{
			CharacterOwner->RootMotionRepMoves.Empty();
			CharacterOwner->OnRep_ReplicatedMovement();
			CharacterOwner->OnRep_ReplicatedBasedMovement();
			SetGravityDirection(CharacterOwner->GetReplicatedGravityDirection());
			ApplyNetworkMovementMode(GetCharacterOwner()->GetReplicatedMovementMode());
		}

		if (CharacterOwner->IsReplicatingMovement() && UpdatedComponent)
		{
			USkeletalMeshComponent* Mesh = CharacterOwner->GetMesh();
			const FVector SavedMeshRelativeLocation = Mesh ? Mesh->GetRelativeLocation() : FVector::ZeroVector;
			const FQuat SavedCapsuleRotation = UpdatedComponent->GetComponentQuat();
			const bool bPreventMeshMovement = !bNetworkSmoothingComplete;

			// Avoid moving the mesh during movement if SmoothClientPosition will take care of it.
			{
				const FScopedPreventAttachedComponentMove PreventMeshMovement(bPreventMeshMovement ? Mesh : nullptr);
				if (Mesh && Mesh->IsPlayingNetworkedRootMotionMontage())
				{
					// Update replicated gravity direction
					if (bNetworkGravityDirectionChanged)
					{
						SetGravityDirection(CharacterOwner->GetReplicatedGravityDirection());
						bNetworkGravityDirectionChanged = false;
					}

					// Update replicated movement mode.
					if (bNetworkMovementModeChanged)
					{
						ApplyNetworkMovementMode(CharacterOwner->GetReplicatedMovementMode());
						bNetworkMovementModeChanged = false;
					}

					PerformMovement(DeltaSeconds);
				}
				else
				{
					SimulateMovement(DeltaSeconds);
				}
			}

			// With Linear smoothing we need to know if the rotation changes, since the mesh should follow along with that (if it was prevented above).
			// This should be rare that rotation changes during simulation, but it can happen when ShouldRemainVertical() changes, or standing on a moving base.
			const bool bValidateRotation = bPreventMeshMovement && (NetworkSmoothingMode == ENetworkSmoothingMode::Linear);
			if (bValidateRotation && UpdatedComponent)
			{
				// Same mesh with different rotation?
				const FQuat NewCapsuleRotation = UpdatedComponent->GetComponentQuat();
				if (Mesh == CharacterOwner->GetMesh() && !NewCapsuleRotation.Equals(SavedCapsuleRotation, 1e-6f) && ClientPredictionData)
				{
					// Smoothing should lerp toward this new rotation target, otherwise it will just try to go back toward the old rotation.
					ClientPredictionData->MeshRotationTarget = NewCapsuleRotation;
					Mesh->SetRelativeLocationAndRotation(SavedMeshRelativeLocation, CharacterOwner->GetBaseRotationOffset());
				}
			}
		}

		if (bWasSimulatingRootMotion)
		{
			bWasSimulatingRootMotion = false;
		}
	}

	// Smooth mesh location after moving the capsule above.
	if (!bNetworkSmoothingComplete)
	{
		SmoothClientPosition(DeltaSeconds);
	}
	else
	{
		UE_LOG(LogHiCharacterMovement, Verbose, TEXT("Skipping network smoothing for %s."), *GetNameSafe(CharacterOwner));
	}
}
