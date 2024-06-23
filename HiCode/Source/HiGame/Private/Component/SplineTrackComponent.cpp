// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/SplineTrackComponent.h"



USplineMeshComponent * USplineTrackComponent::CreateSplineMesh()
{
	
	USplineMeshComponent * SplineMesh = CreateComponent<USplineMeshComponent>();
	if (!SplineMesh)
		return nullptr;
	SplineMesh->ComponentTags.Add(FName("Rail"));
	SplineMesh->SetStaticMesh(StaticMesh);
	SplineMesh->SetForwardAxis(ForwardAxis);
	SplineMesh->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
	SplineMesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	SplineMesh->SetCollisionResponseToChannel(ECC_Camera, ECR_Ignore);
	if(Material)
		SplineMesh->SetMaterial(0, Material);
	return SplineMesh;
}

USplineTrackComponent::~USplineTrackComponent()
{
	HeadTrigger = nullptr;
	TailTrigger = nullptr;
	TransferSpline = nullptr;
}

void USplineTrackComponent::BeginPlay()
{
	Super::BeginPlay();
	CreateStartTrigger();
	UpdateCollision();
}
void USplineTrackComponent::JumpToSplineTrack(AEdActor* trigger)
{
	if (!trigger)
		return;
	OnJumpToTrack(Cast<AActor>(trigger) == HeadTrigger);
}


UChildActorComponent* USplineTrackComponent::CreateChildComponent(const FTransform& RelativeTransform)
{
	if(!GetOwner())
	{
		return nullptr;
	}
	UChildActorComponent* ChildActorComp = CreateComponent<UChildActorComponent>(GetOwner()->GetRootComponent(), RelativeTransform);
	if (!ChildActorComp)
		return nullptr;
	ChildActorComp->bAutoRegister = true;
	ChildActorComp->bEditableWhenInherited = true;
	ChildActorComp->bHiddenInGame = false;
	ChildActorComp->SetChildActorClass(StartTriggerClass);
	ChildActorComp->bEditableWhenInherited = true;
	ChildActorComp->CreateChildActor();
	return ChildActorComp;
}

AActor* USplineTrackComponent::CreateTriggerActor(const FTransform& RelativeTransform)
{
	if(!GetWorld())
	{
		return nullptr;
	}
	if(!GetOwner())
	{
		return nullptr;
	}
	const FTransform WorldTransform = RelativeTransform * GetOwner()->GetActorTransform();
	AActor* Actor = GetWorld()->SpawnActor(StartTriggerClass, &WorldTransform);
	if(Actor)
	{
		OnTriggerCreated.Broadcast(Actor);
	}
	return Actor;
}

void USplineTrackComponent::CreateStartTrigger()
{
	AActor * Owner = GetOwner();
	if(!Owner)
	{
		return;
	}
	if(Owner->GetLocalRole() != ROLE_Authority)
	{
		return;
	}
	int num = this->GetNumberOfSplinePoints();
	UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::CreateStartTrigger SplinePoints: %d"), num);
	if (num > 1 && StartTriggerClass)
	{
		if (!HeadTrigger)
		{
			FVector Location = GetLocationAtSplinePoint(0, ESplineCoordinateSpace::Local);
			UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::HeadTrigger Location: %f,%f,%f,"), Location.X, Location.Y, Location.Z);
			FTransform Transform(FRotator::ZeroRotator,Location + HeadTriggerOffset, FVector(HeadTriggerScale));
			HeadTrigger = CreateTriggerActor(Transform);
		}
		if (!TailTrigger)
		{
			FVector Location = GetLocationAtSplinePoint(num-1, ESplineCoordinateSpace::Local);
			UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::TailTrigger Location: %f,%f,%f,"), Location.X, Location.Y, Location.Z);
			FTransform Transform(FRotator::ZeroRotator,Location + TailTriggerOffset, FVector(TailTriggerScale));
			TailTrigger = CreateTriggerActor(Transform);
		}
	}
}

void USplineTrackComponent::UpdateCollision()
{
	//int num = this->GetNumberOfSplinePoints();
	//UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::UpdateCollision SplinePoints: %d"), num);
}

USplineComponent * USplineTrackComponent::GetParabolaSplineTrack(bool ToHead, FVector StartLocation, float& totle_time)
{
	if (!TransferSpline)
	{
		TransferSpline = CreateComponent<USplineComponent>(nullptr);
		if (!TransferSpline)
			return nullptr;
	}
	auto TargetLocation = this->GetWorldLocationAtSplinePoint( ToHead ? 0 : (this->GetNumberOfSplinePoints() -1));
	TransferSpline = GetParabolaSplineTrackToLocation(StartLocation, TargetLocation, totle_time);
	return TransferSpline;
}

USplineComponent* USplineTrackComponent::GetParabolaSplineTrackToLocation(FVector StartLocation, FVector TargetLocation,
	float& totle_time)
{
	auto TTransferSpline = CreateComponent<USplineComponent>(nullptr);
	if (!TTransferSpline)
		return nullptr;
	TArray<FVector> points;
	auto w = (StartLocation - TargetLocation).Size2D();
	auto height_diff = FMath::Abs( TargetLocation.Z - StartLocation.Z);
	auto t0 = FMath::Sqrt( height_diff * 2/1000.0);
	auto t1 = FMath::Sqrt( 100 * 2/1000.0);
	auto t = t1 *2 + t0;
	if (totle_time > t)
	{
		t1 = 0.5* (totle_time - t0);
	}
	else
	{
		totle_time = t;
	}
	auto top_height_diff = 0.5 * 1000 * t1 * t1;
	FVector Mid;
	if (TargetLocation.Z > StartLocation.Z)
	{
		auto percent = (t0 + t1)/totle_time;
		Mid = StartLocation + percent * (TargetLocation - StartLocation);
		Mid.Z = TargetLocation.Z + top_height_diff;
	}
	else
	{
		auto percent = t1/totle_time;
		Mid = StartLocation + percent * (TargetLocation - StartLocation);
		Mid.Z = StartLocation.Z + top_height_diff;
	}
	points.Add(StartLocation);
	points.Add(Mid);
	points.Add(TargetLocation);
	//UE_LOG(LogTemp, Log, TEXT("totle_time: %f, StartLocation : (%f, %f, %f)"), totle_time, Mid.Z, Mid.Y, Mid.Z);
	//UE_LOG(LogTemp, Log, TEXT("                  TopLocation : (%f, %f, %f)"), Mid.Z, Mid.Y, Mid.Z);
	//UE_LOG(LogTemp, Log, TEXT("               TargetLocation : (%f, %f, %f)"), TargetLocation.Z, TargetLocation.Y, TargetLocation.Z);
	TTransferSpline->SetSplinePoints(points, ESplineCoordinateSpace::World);
	FVector Tangent0(
		0.5*(Mid.X - StartLocation.X),
		0.5*(Mid.Y - StartLocation.Y),
		2*(Mid.Z - StartLocation.Z)
		);
	FVector Tangent2(
	-0.5*(Mid.X - TargetLocation.X),
	-0.5*(Mid.Y - TargetLocation.Y),
	-2*(Mid.Z - TargetLocation.Z)
		);
	FVector Tangent01((Mid.X - StartLocation.X), (Mid.Y - StartLocation.Y), 0);
	FVector Tangent12((TargetLocation.X - Mid.X), (TargetLocation.Y - Mid.Y), 0);
	//UE_LOG(LogTemp, Log, TEXT("Tangent-- Start : (%f, %f, %f)"), Tangent0.Z, Tangent0.Y, Tangent0.Z);
	//UE_LOG(LogTemp, Log, TEXT("            Top : (%f, %f, %f), (%f, %f, %f)"), Tangent01.Z, Tangent01.Y, Tangent01.Z, Tangent12.Z, Tangent12.Y, Tangent12.Z);
    //UE_LOG(LogTemp, Log, TEXT("         Target : (%f, %f, %f)"), Tangent2.Z, Tangent2.Y, Tangent2.Z);
    	
	TTransferSpline->SetTangentAtSplinePoint(0, Tangent0, ESplineCoordinateSpace::World);
	TTransferSpline->SetTangentsAtSplinePoint(1,Tangent01, Tangent12, ESplineCoordinateSpace::World);
	TTransferSpline->SetTangentAtSplinePoint(2, Tangent2, ESplineCoordinateSpace::World);
	TTransferSpline->bEditableWhenInherited = true;
	return TTransferSpline;
}

void USplineTrackComponent::UpdateSplineMeshByPoint(int PointIndex)
{
#if WITH_EDITOR
	USplineMeshComponent * SplineMesh = CreateSplineMesh();
	if (SplineMesh)
	{
		FVector StartLocation, StartTangent, EndLocation, EndTangent;
		this->GetLocalLocationAndTangentAtSplinePoint(PointIndex, StartLocation, StartTangent);
		this->GetLocalLocationAndTangentAtSplinePoint(PointIndex+1, EndLocation, EndTangent);
		FRotator StartRotator = this->GetRotationAtSplinePoint(PointIndex,ESplineCoordinateSpace::Local);
		FRotator EndRotator = this->GetRotationAtSplinePoint(PointIndex+1,ESplineCoordinateSpace::Local);
		
		SplineMesh->SetRelativeLocation(this->GetRelativeLocation());
		SplineMesh->SetRelativeRotation(this->GetRelativeRotation());
		SplineMesh->SetStartRoll(StartRotator.Roll);
		SplineMesh->SetEndRoll(EndRotator.Roll);
		SplineMesh->SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent);
	}
#endif
}


void USplineTrackComponent::OnConstructor_Implementation()
{
#if WITH_EDITOR
	int num = this->GetNumberOfSplinePoints();
	//UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::OnConstructor SplinePoints: %d"), num);
	if (num>1 && StaticMesh)
	{
		for (int i = 0; i < num-1; i++)
		{
			UpdateSplineMeshByPoint(i);
		}
	}
#endif
}


void USplineTrackComponent::DestroyComponent(bool bPromoteChildren)
{
	//UE_LOG(LogTemp, Log, TEXT("USplineTrackComponent::DestroyComponent bPromoteChildren: %d"), bPromoteChildren);
	if(GetWorld())
	{
		if(HeadTrigger)
		{
			GetWorld()->DestroyActor(HeadTrigger);
			HeadTrigger = nullptr;
		}
		if(TailTrigger)
		{
			GetWorld()->DestroyActor(TailTrigger);
			TailTrigger = nullptr;
		}
	}
	Super::DestroyComponent(bPromoteChildren);
	
}
