// Fill out your copyright notice in the Description page of Project Settings.


#include "HiPushOverlapActorComponet.h"
#include "Component/HiCharacterMovementComponent.h"

// Sets default values for this component's properties
UHiPushOverlapActorComponet::UHiPushOverlapActorComponet()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;

	// ...
}


// Called when the game starts
void UHiPushOverlapActorComponet::BeginPlay()
{
	Super::BeginPlay();
	if (GetOwner())
	{
		LastPos = GetOwner()->GetTransform().GetLocation();

	}
	// ...
	
}


// Called every frame
void UHiPushOverlapActorComponet::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	if (GetOwner())
	{
		for (auto Player : ActorArray)
		{
			if (Player)
			{
				FVector PlayerPos = Player->GetActorTransform().GetLocation();
				FVector OwnerPos = GetOwner()->GetTransform().GetLocation();

				FVector Velocity = ((OwnerPos-LastPos) / DeltaTime);
				Velocity.Z = 0;
				float speed = Velocity.Length();

				FVector Dir = PlayerPos - OwnerPos;
				Dir.Z = 0;
				double PlayerToTrigger = Dir.Length();
				Dir = Dir.GetSafeNormal2D();
			
				

				FVector PlayerVelocity = Dir.GetSafeNormal2D() * speed* SpeedScale;
				if (Dir == Velocity.GetSafeNormal2D())
				{
					FVector Dir2(Velocity.Y, -Velocity.X, 0);
					Dir2 = Dir2.GetSafeNormal2D();
					PlayerVelocity += Dir2 * speed * 0.5* SpeedScale;
				}
				if (IsStandOn)
				{
					if (PlayerPos.Z > OwnerPos.Z)
					{
						PlayerVelocity = FVector::ZeroVector;
					}
				}

				Player->AddBufferVelocityOnlyOnce(PlayerVelocity);

			}
		}
		LastPos = GetOwner()->GetTransform().GetLocation();
	}
	

	// ...
}

void UHiPushOverlapActorComponet::AddOverlapActor(UHiCharacterMovementComponent* Actor)
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
			UE_LOG(LogController, Warning, TEXT("UHiPushOverlapActorComponet Acotr is in Array"));
		}
	}
}

void UHiPushOverlapActorComponet::DelOverlapActor(UHiCharacterMovementComponent* Actor)
{
	if (Actor != nullptr)
	{
		if (ActorArray.Find(Actor) != -1)
		{
			//UE_LOG(LogController, Warning, TEXT("UHiAcceleratedVelocityBAComponent DelVelocityBufferActor Remove Actor Acotr"));
			ActorArray.Remove(Actor);
		}
		else
		{
			UE_LOG(LogController, Warning, TEXT("UHiPushOverlapActorComponet Acotr is not in Array"));
		}

	}
}

