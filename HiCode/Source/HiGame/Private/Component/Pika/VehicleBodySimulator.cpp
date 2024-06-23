// Fill out your copyright notice in the Description page of Project Settings.
#include "Component/Pika/VehicleBodySimulator.h"

#include "GameFramework/CharacterMovementComponent.h"
#include "Kismet/KismetMathLibrary.h"
#include "Kismet/KismetSystemLibrary.h"


// 质量参数模拟，不需要动态数值
constexpr float ConstBodyMass = 1.0f;
constexpr float ConstBodyMassInv = 1.0f;
static const FVector ConstLocalInertiaTensor = FVector(1666.667, 1666.667, 1666.667);	// ref: FBodyInstance::GetBodyInertiaTensor
static const FVector ConstLocalInvInertiaTensor = FVector(1.0 / ConstLocalInertiaTensor.X, 1.0 / ConstLocalInertiaTensor.Y, 1.0 / ConstLocalInertiaTensor.Z);

// Sets default values for this component's properties
UVehicleBodySimulator::UVehicleBodySimulator()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.TickGroup = TickGroup;
	bWantsInitializeComponent = true;
	bAutoActivate = true;

	// Defaults
	SpringHookean = 35.0f;
	SpringLinearDamping = 30.0f;
	SpringAngularDamping = 60.0f;
	SpringLength = 30.0f;
	MinLocalOffsetZLimit = -100.0f;
	MaxLocalOffsetZLimit = 100.0f;
	RotationLimit = FVector(50.0, 50.0, 50.0);
	SimPhysicsGravity = -980.0f;
	MaxSimPhysicsTimeInterval = 1.0f / 30;
	TraceFloorComplex = false;
	TraceFloorRangeEx = FVector2D(0, 300);
	DrawDebugPoints = false;
	UnderFloorDebugColor = FLinearColor(0, 0.2, 0.7, 0.8);
	OverFloorDebugColor = FLinearColor(0.8, 0.7, 0.2, 0.8);
	SimulateAllowed = true;
}

// Called when the game starts
void UVehicleBodySimulator::BeginPlay()
{
	Super::BeginPlay();

	AActor* pOwnerActor = GetOwner();
	if (!Cast<APawn>(pOwnerActor))
	{
		SetComponentTickEnabled(false);
		m_bSimulateBody = false;
		return;
	}
	
	m_bSimulateBody = UKismetSystemLibrary::IsStandalone(this) || !pOwnerActor->HasAuthority();
	if (!m_bSimulateBody)
	{
		SetComponentTickEnabled(false);
		return;
	}
	
	SpringLength = FMath::Abs(SpringLength);
	USceneComponent* AttachedComponent = GetAttachParent();
	RigidComponent = Cast<UPrimitiveComponent>(AttachedComponent);

	if (RigidComponent)
	{
		m_BaseLinearDamping = RigidComponent->GetLinearDamping();
		m_BaseAngularDamping = RigidComponent->GetAngularDamping();

		FName AttachSocket = GetAttachSocketName();
		USkeletalMeshComponent* pSkeletalMeshComponent = Cast<USkeletalMeshComponent>(RigidComponent);
		if (pSkeletalMeshComponent && !AttachSocket.IsNone())
		{
			m_bUsingBoneUpdate = true;
			m_OriginVisibilityBasedAnimTickOption = pSkeletalMeshComponent->VisibilityBasedAnimTickOption;
			pSkeletalMeshComponent->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
		}
		else
		{
			m_bUsingBoneUpdate = false;
		}
		OwnerMovementComponent = pOwnerActor->FindComponentByClass<UCharacterMovementComponent>();
	}

	m_ExternalForces = FVector::ZeroVector;
	m_ExternalTorques = FVector::ZeroVector;
	m_FakeLinearVelocity = FVector::ZeroVector;
	m_FakeAngularVelocity = FVector::ZeroVector;
}

void UVehicleBodySimulator::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (m_bSimulateBody && SimulateAllowed)
	{
		SimulateTick(DeltaTime);
	}
}

FVector UVehicleBodySimulator::MatrixMulVector3(const FMatrix& matrix, const FVector& vector)
{
	FVector4 Vec4 = UKismetMathLibrary::Matrix_TransformVector(matrix, vector);
	return FVector(Vec4.X, Vec4.Y, Vec4.Z);
}

FMatrix UVehicleBodySimulator::CalculateWorldInertiaTensorInverse(const FMatrix& orientation, const FVector& inverseInertiaTensorLocal)
{
	FMatrix outInverseInertiaTensorWorld;
	outInverseInertiaTensorWorld.M[0][0] = orientation.M[0][0] * inverseInertiaTensorLocal.X;
	outInverseInertiaTensorWorld.M[0][1] = orientation.M[1][0] * inverseInertiaTensorLocal.X;
	outInverseInertiaTensorWorld.M[0][2] = orientation.M[2][0] * inverseInertiaTensorLocal.X;
	outInverseInertiaTensorWorld.M[0][3] = 0;

	outInverseInertiaTensorWorld.M[1][0] = orientation.M[0][1] * inverseInertiaTensorLocal.Y;
	outInverseInertiaTensorWorld.M[1][1] = orientation.M[1][1] * inverseInertiaTensorLocal.Y;
	outInverseInertiaTensorWorld.M[1][2] = orientation.M[2][1] * inverseInertiaTensorLocal.Y;
	outInverseInertiaTensorWorld.M[1][3] = 0;

	outInverseInertiaTensorWorld.M[2][0] = orientation.M[0][2] * inverseInertiaTensorLocal.Z;
	outInverseInertiaTensorWorld.M[2][1] = orientation.M[1][2] * inverseInertiaTensorLocal.Z;
	outInverseInertiaTensorWorld.M[2][2] = orientation.M[2][2] * inverseInertiaTensorLocal.Z;
	outInverseInertiaTensorWorld.M[2][3] = 0;

	outInverseInertiaTensorWorld.M[3][0] = 0;
	outInverseInertiaTensorWorld.M[3][1] = 0;
	outInverseInertiaTensorWorld.M[3][2] = 0;
	outInverseInertiaTensorWorld.M[3][3] = 1;

	return UKismetMathLibrary::Multiply_MatrixMatrix(orientation, outInverseInertiaTensorWorld);
}

void UVehicleBodySimulator::SimulateBody(float DeltaTime)
{
	FTransform MyWorldTransform = GetComponentToWorld();
	float SignOfGravity = FMath::Sign(SimPhysicsGravity);
	int pointNum = WheelPoints.Num();
	
	PointsUnderFloor = 0;
	for (int pointIndex = 0; pointIndex < pointNum; pointIndex++)
	{
		bool isUnderFloor = false;
		FVector pointV3 = WheelPoints[pointIndex];
		FVector worldPointV3 = MyWorldTransform.TransformPosition(pointV3);
		float FlootHeight = GetFloorHeight(worldPointV3);

		float SignedRadius = SignOfGravity * SpringLength;
		if (FlootHeight > (worldPointV3.Z + SignedRadius))
		{
			PointsUnderFloor++;
			isUnderFloor = true;

			float LengthMultiplier = (FlootHeight - (worldPointV3.Z + SignedRadius)) / (SpringLength * 2);
			LengthMultiplier = FMath::Clamp(LengthMultiplier, 0.f, 2.f);

			// force formula: (Volume(Mass) * SpringHookean * -Gravity) / Total Points * LengthMultiplier
			float ForceZ = ConstBodyMass * SpringHookean * - SimPhysicsGravity / pointNum * LengthMultiplier;

			// Add force for this point
			ApplyForceAtPosition(FVector(0, 0, ForceZ), worldPointV3);
		}

		if (DrawDebugPoints)
		{
			FLinearColor DebugColor = isUnderFloor ? UnderFloorDebugColor : OverFloorDebugColor;
			UKismetSystemLibrary::DrawDebugSphere(GetWorld(), worldPointV3, SpringLength, 8, DebugColor);
		}
	}

	UpdateFakePhysicsVelocity(DeltaTime);

	const float linDampingFactor = m_BaseLinearDamping + SpringLinearDamping * PointsUnderFloor / pointNum;
	const float angDampingFactor = m_BaseAngularDamping + SpringAngularDamping * PointsUnderFloor / pointNum;
	// Apply the velocity damping
	// Damping force : F_c = -c' * v (c=damping factor)
	// Differential Equation      : m * dv/dt = -c' * v
	//                              => dv/dt = -c * v (with c=c'/m)
	//                              => dv/dt + c * v = 0
	// Solution      : v(t) = v0 * e^(-c * t)
	//                 => v(t + dt) = v0 * e^(-c(t + dt))
	//                              = v0 * e^(-c * t) * e^(-c * dt)
	//                              = v(t) * e^(-c * dt)
	//                 => v2 = v1 * e^(-c * dt)
	// Using Padé's approximation of the exponential function:
	// Reference: https://mathworld.wolfram.com/PadeApproximant.html
	//                   e^x ~ 1 / (1 - x)
	//                      => e^(-c * dt) ~ 1 / (1 + c * dt)
	//                      => v2 = v1 * 1 / (1 + c * dt)
	// Update damping based on number of underfloor test points
	const float linearDamping = 1.0f / (1.0f + linDampingFactor * DeltaTime);
	const float angularDamping = 1.0f / (1.0f + angDampingFactor * DeltaTime);

	m_FakeLinearVelocity = m_FakeLinearVelocity * linearDamping;
	m_FakeAngularVelocity = m_FakeAngularVelocity * angularDamping;

	if (m_bUsingBoneUpdate)
	{
		UpdateFakePhysicsBody_Bone(DeltaTime);
	}
	else
	{
		UpdateFakePhysicsBody_Component(DeltaTime);
	}
}

void UVehicleBodySimulator::UpdateFakePhysicsVelocity(float DeltaTime)
{
	FQuat Quaternion = RigidComponent->GetComponentQuat();

	FMatrix QuatMatrix = Quaternion.ToMatrix();
	FMatrix WorldInvInertiaTensor = CalculateWorldInertiaTensorInverse(QuatMatrix, ConstLocalInvInertiaTensor);

	FVector LinearLockAxisFactors = FVector::OneVector;
	FVector AngularLockAxisFactors = FVector::OneVector;

	// Integrate the external force to get the new velocity of the body
	m_FakeLinearVelocity = m_FakeLinearVelocity + DeltaTime * ConstBodyMassInv * LinearLockAxisFactors * m_ExternalForces;
	m_FakeAngularVelocity = m_FakeAngularVelocity + DeltaTime * AngularLockAxisFactors * MatrixMulVector3(WorldInvInertiaTensor, m_ExternalTorques);

	// Apply gravity force
	if (RigidComponent->IsGravityEnabled())
	{
		int32 pointNum = WheelPoints.Num();
		int32 GravityScale = pointNum - PointsUnderFloor;
		GravityScale = FMath::Clamp(GravityScale, 1, pointNum);

		m_FakeLinearVelocity = m_FakeLinearVelocity + FVector(0, 0, GravityScale * SimPhysicsGravity) * DeltaTime;
	}

	m_ExternalForces = FVector::ZeroVector;
	m_ExternalTorques = FVector::ZeroVector;
}

void UVehicleBodySimulator::UpdateFakePhysicsBody_Component(float DeltaTime)
{
	// Get current position and orientation of the body
	FTransform ownerTransform = GetOwner()->GetActorTransform();
	FTransform worldTransform = RigidComponent->GetComponentToWorld();
	FQuat currentOrientation = worldTransform.GetRotation();
	FVector currentLocation = worldTransform.GetTranslation();

	// Update the new constrained position and orientation of the body
	FVector deltaLocation = m_FakeLinearVelocity * DeltaTime;
	FVector destLocation = currentLocation + deltaLocation;
	FVector localDestLocation = ownerTransform.InverseTransformPosition(destLocation);
	localDestLocation.X = 0;
	localDestLocation.Y = 0;
	localDestLocation.Z = FMath::Clamp(localDestLocation.Z, MinLocalOffsetZLimit, MaxLocalOffsetZLimit);
	destLocation = ownerTransform.TransformPosition(localDestLocation);

	FQuat newOrientation = currentOrientation + FQuat(m_FakeAngularVelocity.X, m_FakeAngularVelocity.Y, m_FakeAngularVelocity.Z, 0) * currentOrientation * 0.5 * DeltaTime;
	FQuat localOrientation = ownerTransform.InverseTransformRotation(newOrientation);
	FRotator localRot = localOrientation.Rotator();
	localRot.Yaw = RigidComponent->GetRelativeRotation().Yaw;
	localRot.Pitch = FMath::Clamp(localRot.Pitch, -RotationLimit.X, RotationLimit.X);
	localRot.Roll = FMath::Clamp(localRot.Roll, -RotationLimit.Z, RotationLimit.Z);

	FRotator destOrientation = UKismetMathLibrary::TransformRotation(ownerTransform, localRot);
	RigidComponent->SetWorldLocationAndRotation(destLocation, destOrientation);
}

// 在CS模式下变更Component的坐标会导致移动时模型抖动
// 使用在ABP中修改RootBoneIK的方式解决此问题
void UVehicleBodySimulator::UpdateFakePhysicsBody_Bone(float DeltaTime)
{
	FName BoneName = GetAttachSocketName();
	// Get current position and orientation of the body root bone
	FTransform worldTransform = RigidComponent->GetComponentToWorld();
	FTransform boneWorldTransform = RigidComponent->GetSocketTransform(BoneName);

	FQuat currentOrientation = boneWorldTransform.GetRotation();
	FVector currentLocation = boneWorldTransform.GetLocation();

	// Update the new constrained position and orientation of the body
	FVector deltaLocation = m_FakeLinearVelocity * DeltaTime;
	FVector destLocation = currentLocation + deltaLocation;
	FVector localDestLocation = worldTransform.InverseTransformPosition(destLocation);
	localDestLocation.X = 0;
	localDestLocation.Y = 0;
	localDestLocation.Z = FMath::Clamp(localDestLocation.Z, MinLocalOffsetZLimit, MaxLocalOffsetZLimit);
	
	RootBoneLocation = localDestLocation;

	FQuat newOrientation = currentOrientation + FQuat(m_FakeAngularVelocity.X, m_FakeAngularVelocity.Y, m_FakeAngularVelocity.Z, 0) * currentOrientation * 0.5 * DeltaTime;
	FQuat localOrientation = worldTransform.InverseTransformRotation(newOrientation);
	FRotator localRot = localOrientation.Rotator();
	localRot.Yaw = 0;
	localRot.Pitch = FMath::Clamp(localRot.Pitch, -RotationLimit.X, RotationLimit.X);
	localRot.Roll = FMath::Clamp(localRot.Roll, -RotationLimit.Z, RotationLimit.Z);
	RootBoneRotation = localRot;
}

float UVehicleBodySimulator::GetFloorHeight(const FVector& WorldLocation)
{
	APawn* pOwnerPawn = Cast<APawn>(GetOwner());
	FVector OwnerActorLocation = pOwnerPawn->GetActorLocation();
	FVector TraceStart = WorldLocation;
	FVector TraceEnd = WorldLocation;
	if (WorldLocation.Z > OwnerActorLocation.Z)
	{
		TraceStart.Z = WorldLocation.Z + TraceFloorRangeEx.X;
		TraceEnd.Z = OwnerActorLocation.Z - TraceFloorRangeEx.Y;
	}
	else
	{
		TraceStart.Z = OwnerActorLocation.Z + TraceFloorRangeEx.X;
		TraceEnd.Z = WorldLocation.Z - TraceFloorRangeEx.Y;
	}

	FHitResult Hit;
	if (TraceFloorProfileName.IsNone())
	{
		FCollisionQueryParams QueryParams;
		FCollisionResponseParams ResponseParam;
		OwnerMovementComponent->UpdatedPrimitive->InitSweepCollisionParams(QueryParams, ResponseParam);

		QueryParams.bIgnoreTouches = true;
		QueryParams.bTraceComplex = TraceFloorComplex;
		QueryParams.AddIgnoredActor(pOwnerPawn);

		const ECollisionChannel CollisionChannel = OwnerMovementComponent->UpdatedPrimitive->GetCollisionObjectType();
		GetWorld()->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, CollisionChannel, QueryParams, ResponseParam);
	}
	else
	{
		UKismetSystemLibrary::LineTraceSingleByProfile(pOwnerPawn, TraceStart, TraceEnd, TraceFloorProfileName, TraceFloorComplex, {}, EDrawDebugTrace::Type::None, Hit, true);
	}

	if (Hit.bBlockingHit && Hit.Component.IsValid() && Hit.Component->CanCharacterStepUp(pOwnerPawn))
	{
		return Hit.Location.Z;
	}
	return FLT_MIN;
}

void UVehicleBodySimulator::ClearForcesAndVelocity()
{
	m_ExternalForces = FVector::ZeroVector;
	m_ExternalTorques = FVector::ZeroVector;
	m_FakeLinearVelocity = FVector::ZeroVector;
	m_FakeAngularVelocity = FVector::ZeroVector;

	if (m_bUsingBoneUpdate)
	{
		USkeletalMeshComponent* pSkeletalMeshComponent = Cast<USkeletalMeshComponent>(RigidComponent);
		if (pSkeletalMeshComponent)
		{
			pSkeletalMeshComponent->VisibilityBasedAnimTickOption = m_OriginVisibilityBasedAnimTickOption;
		}
	}
}

void UVehicleBodySimulator::ApplyForceAtPosition(const FVector& WorldForce, const FVector& WorldPosition)
{
	// Add the force
	m_ExternalForces += WorldForce;

	// Add the torque
	FVector worldCompLocation = RigidComponent->GetComponentLocation();
	m_ExternalTorques += ((WorldPosition - worldCompLocation) ^ WorldForce);
}

void UVehicleBodySimulator::SimulateTick(float DeltaTime)
{
	if (
		!IsActive() || !m_bSimulateBody ||
		!RigidComponent || RigidComponent->IsAnySimulatingPhysics() || !RigidComponent->IsGravityEnabled() ||
		!OwnerMovementComponent || !OwnerMovementComponent->UpdatedPrimitive
		)
	{
		ClearForcesAndVelocity();
		return;
	}

	if (!OwnerMovementComponent->IsWalking())
	{
		ClearForcesAndVelocity();
		FVector OwnerVelocity = GetOwner()->GetVelocity();
		m_FakeLinearVelocity = FVector(0,0,OwnerVelocity.Z);
		return;
	}

	if (WheelPoints.Num() > 0)
	{
		float ClampedDeltaTime = FMath::Clamp(DeltaTime, 0, MaxSimPhysicsTimeInterval);
		SimulateBody(ClampedDeltaTime);
	}
}

void UVehicleBodySimulator::InitializeComponent()
{
	Super::InitializeComponent();
}

