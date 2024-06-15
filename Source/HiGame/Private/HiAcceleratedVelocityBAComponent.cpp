// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAcceleratedVelocityBAComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include <cstdlib> 

// Sets default values for this component's properties
UHiAcceleratedVelocityBAComponent::UHiAcceleratedVelocityBAComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	MaxBufferAcceleratedSpeed = 0;
	MaxAreaAcceleratedVelocity = FVector::ZeroVector;
	BoxCenter = FVector::ZeroVector;
	BoxMinZ = 0;
	BoxLen = 0;
	ActorArray.Reset();
	
	// ...
}


// Called when the game starts
void UHiAcceleratedVelocityBAComponent::BeginPlay()
{
	Super::BeginPlay();
	if (GetOwner())
	{
		auto Owner = GetOwner();
		auto Rot = Owner->GetTransform().GetRotation();
		auto Box = Owner->GetComponentsBoundingBox();
		auto BoxSize = Box.GetSize();
		
		BoxMinZ = Box.Min.Z;
		BoxLen = abs(BoxSize.Z);
		BoxCenter = Box.GetCenter();


		
		Rot = FVector::ForwardVector.ToOrientationQuat() * Rot;
		FVector Dir = Rot.Vector();
		//UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent BeginPlay Dir=%s Rot=%s"), *Dir.ToString(), *Owner->GetTransform().GetRotation().ToString());
		Dir.Normalize();
		MaxAreaAcceleratedVelocity = Dir * MaxBufferAcceleratedSpeed;
		CurAreaAcceleratedVelocity = Dir*0;
	}
	// ...
	
}


// Called every frame
void UHiAcceleratedVelocityBAComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	for (auto& Actor : ActorArray)
	{
		auto ActorToBox = Actor->GetActorTransform().GetLocation()-(BoxCenter - MaxAreaAcceleratedVelocity.GetSafeNormal()*BoxLen*0.5);
		double Angle = FMath::Acos(FVector::DotProduct(ActorToBox.GetSafeNormal(), MaxAreaAcceleratedVelocity.GetSafeNormal()));
		FVector CrossProduct = ActorToBox.GetSafeNormal() ^ MaxAreaAcceleratedVelocity.GetSafeNormal();
		if (CrossProduct.Z<0)
		{
			Angle = -Angle;
		}
		double ActorLen = ActorToBox.Length() * FMath::Cos(Angle);



		double lerpSize = (BoxLen - ActorLen) / BoxLen;
		if (lerpSize<0)
		{
			lerpSize = 0;
		}
		

		Actor->AddBufferAcceleratedVelocity(-CurAreaAcceleratedVelocity);
		CurAreaAcceleratedVelocity = MaxAreaAcceleratedVelocity * lerpSize;
		Actor->AddBufferAcceleratedVelocity(CurAreaAcceleratedVelocity);
		//UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent TickComponent ActorLen=%f BoxLen=%f lerpSize=%f CurAreaAcceleratedVelocity=%s"), ActorLen, BoxLen, lerpSize, *CurAreaAcceleratedVelocity.ToString());
		if (MaxAreaAcceleratedVelocity.Z > 0&& Actor->IsWalking())
		{
			Actor->SetMovementMode(MOVE_Falling);
		}
	}
	// ...
}

void UHiAcceleratedVelocityBAComponent::AddVelocityBufferActor(UHiCharacterMovementComponent* Actor)
{
	if (Actor != nullptr)
	{
		if (ActorArray.Find(Actor) == -1)
		{
			ActorArray.Add(Actor);
			//UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent AddVelocityBufferActor Add Actor Acotr"));
		}
		else
		{
			UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent Acotr is in Array"));
		}
	}
}

void UHiAcceleratedVelocityBAComponent::DelVelocityBufferActor(UHiCharacterMovementComponent* Actor)
{
	if (Actor != nullptr)
	{
		if (ActorArray.Find(Actor) != -1)
		{
			//UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent DelVelocityBufferActor Remove Actor Acotr"));
			ActorArray.Remove(Actor);
			Actor->AddBufferAcceleratedVelocity(-CurAreaAcceleratedVelocity);
			CurAreaAcceleratedVelocity = FVector::ZeroVector;
		}
		else
		{
			UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent Acotr is not in Array"));
		}

	}
}

