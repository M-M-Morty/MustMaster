// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiVehicleMantleComponent.h"
#include "Component/HiVehicleMovementComponent.h"

UHiVehicleMantleComponent::UHiVehicleMantleComponent(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer)
{
}

void UHiVehicleMantleComponent::InitializeComponent()
{
	Super::InitializeComponent();
	if(AActor * Owner = GetOwner())
	{
		AHiCharacter *VehicleOwner = Cast<AHiCharacter>(Owner);

		if (!ensureMsgf(VehicleOwner, TEXT("Invalid HiMantleComponent owner type: %s"), *Owner->GetFName().ToString()))
		{
			return;
		}
		VehicleMovementComponent = Cast<UHiVehicleMovementComponent>(VehicleOwner->GetMovementComponent());
	}
	
	
}

void UHiVehicleMantleComponent::PhysMantle_Implementation(float DeltaTime)
{
}

void UHiVehicleMantleComponent::CheckClimbType(float DeltaTime)
{
	if( OwnerVehicle == nullptr || OwnerVehicle->GetWorld() == nullptr)
	{
		return;
	}
	if (OwnerVehicle->GetWorld()->GetNetMode() == ENetMode::NM_Client || OwnerVehicle->GetWorld()->GetNetMode() == NM_Standalone)
	{
		if(VehicleMovementComponent && VehicleMovementComponent->IsAccelerating())
		{
			switch (ClimbType)
			{
			case EHiClimbType::WallRun:
				if (WallRunType == EHiWallRunType::Sprint)
				{
					ReachRoofCheck(SprintClimbTraceSettings, EDrawDebugTrace::Type::ForDuration);
				}
				else if (WallRunType == EHiWallRunType::Climb)
				{
					ReachRoofCheck(ClimbTraceSettings, EDrawDebugTrace::Type::ForDuration);
				}
				break;
			case EHiClimbType::Mantle:
				if (CanBreakMantle())
				{
					MantleCheck(MantleTraceSettings, EDrawDebugTrace::Type::ForDuration);
				}
				break;
			case EHiClimbType::None:
				if (IsBlockedByWallThisFrame() && (!VehicleMovementComponent || VehicleMovementComponent->VehicleState == EHiVehicleState::OnGrounded))
				{
					GroundCheck(GroundedTraceSettings, EDrawDebugTrace::Type::ForDuration, true);
				}
			default:
				break;
			}
		}
	}
}

void UHiVehicleMantleComponent::BeginPlay()
{
	Super::BeginPlay();
	
	if (GetOwner())
	{
		OwnerVehicle = Cast<AHiCharacter>(GetOwner());
	}
}

void UHiVehicleMantleComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
}
