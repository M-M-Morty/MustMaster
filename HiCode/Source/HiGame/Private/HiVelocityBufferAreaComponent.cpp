// Fill out your copyright notice in the Description page of Project Settings.


#include "HiVelocityBufferAreaComponent.h"
#include "Component/HiCharacterMovementComponent.h"

// Sets default values for this component's properties
UHiVelocityBufferAreaComponent::UHiVelocityBufferAreaComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	AreaVelocity = FVector::ZeroVector;
	ActorArray.Reset();
	// ...
}


// Called when the game starts
void UHiVelocityBufferAreaComponent::BeginPlay()
{
	Super::BeginPlay();
	ActorArray.Reset();
	if (GetOwner())
	{
		auto Owner = GetOwner();
		auto Rot = Owner->GetTransform().GetRotation();
		Rot = FVector::ForwardVector.ToOrientationQuat() * Rot;
		FVector Dir = Rot.Vector();
		//UE_LOG(LogController, Warning, TEXT("UHiVelocityBufferAreaComponent BeginPlay Dir=%s Rot=%s"),*Dir.ToString(), *Owner->GetTransform().GetRotation().ToString());
		Dir.Normalize();
		AreaVelocity = Dir * BufferSpeed;
	}
	// ...
	
}


// Called every frame
void UHiVelocityBufferAreaComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	
	// ...
}

void UHiVelocityBufferAreaComponent::AddVelocityBufferActor(UHiCharacterMovementComponent* Actor)
{
	if (Actor!=nullptr)
	{
		if (ActorArray.Find(Actor) == -1)
		{
			ActorArray.Add(Actor);
			Actor->AddBufferVelocity(AreaVelocity);
			Actor->Velocity += AreaVelocity;
			//UE_LOG(LogController, Warning, TEXT("UHiVelocityBufferAreaComponent AddVelocityBufferActor Add Actor Acotr"));
		}
		else
		{
			UE_LOG(LogController, Warning, TEXT("UHiVelocityBufferAreaComponent Acotr is in Array"));
		}
	}
	
}

void UHiVelocityBufferAreaComponent::DelVelocityBufferActor(UHiCharacterMovementComponent* Actor)
{
	if (Actor != nullptr)
	{
		if (ActorArray.Find(Actor) != -1)
		{
			//UE_LOG(LogController, Warning, TEXT("UHiVelocityBufferAreaComponent DelVelocityBufferActor Remove Actor Acotr"));
			ActorArray.Remove(Actor);
			Actor->AddBufferVelocity(-AreaVelocity);
		}
		else
		{
			UE_LOG(LogController, Warning, TEXT("UHiVelocityBufferAreaComponent Acotr is not in Array"));
		}

	}
	
}



