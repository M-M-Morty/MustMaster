// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiCollisionLibrary.h"

#include "AbilitySystemLog.h"
#include "DrawDebugHelpers.h"
#include "Kismet/KismetSystemLibrary.h"
#include "HiAbilities/HiMountActor.h"
#include "PhysicsEngine/BodyInstance.h"
#include "PhysicalMaterials/PhysicalMaterial.h"
#include "HiAbilities/HiTraceUtils.h"

UHiCollisionLibrary::UHiCollisionLibrary()
{
}

UHiCollisionLibrary::~UHiCollisionLibrary()
{
}

void UHiCollisionLibrary::PerformOverlapActorsBP(UObject* WorldContextObject, const FHiTargetActorSpec& TargetActorSpec, const FVector& Origin, const FVector& ForwardVector, FGameplayTargetDataFilterHandle Filter, TArray<AActor*>& HitActors, bool& NeedDestroy, bool bDebug)
{
	TArray<TWeakObjectPtr<AActor>> WOutActors;
	UHiCollisionLibrary::PerformOverlapActors(WorldContextObject, TargetActorSpec, Origin, ForwardVector, Filter, WOutActors, NeedDestroy, bDebug);
	
	for (auto OutActor : WOutActors)
	{
		AActor* Actor = OutActor.Get();
		HitActors.Add(Actor);
	}
}

void UHiCollisionLibrary::PerformOverlapActors(UObject* WorldContextObject, const FHiTargetActorSpec& TargetActorSpec, const FVector& Origin, const FVector& ForwardVector, FGameplayTargetDataFilterHandle Filter, TArray<TWeakObjectPtr<AActor>>& HitActors, bool& NeedDestroy, bool bDebug, float LifeTime)
{
	TArray<AActor*> OutActors;
	TArray<AActor*> ActorsToIgnore;
	TArray<TEnumAsByte<EObjectTypeQuery>> ObjectTypes;
	// TODO default to Pawn and MountActor.
	ObjectTypes.Add(EObjectTypeQuery::ObjectTypeQuery3);
	ObjectTypes.Add(EObjectTypeQuery::ObjectTypeQuery7);
	const float AngleRad = FMath::DegreesToRadians(TargetActorSpec.Angle);

	switch(TargetActorSpec.CalcRangeType)
	{
	case Circle:
		SphereOverlapActors(WorldContextObject, ObjectTypes, Origin, TargetActorSpec.Radius, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nullptr, ActorsToIgnore, OutActors, bDebug, LifeTime);
		break;
		
	case Section:
		SectionOverlapActors(WorldContextObject, ObjectTypes, Origin, ForwardVector, TargetActorSpec.Radius, AngleRad, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nullptr, ActorsToIgnore, OutActors, bDebug, LifeTime);
		break;

	case CalcRangeTypeRect:
		BoxOverlapActors(WorldContextObject, ObjectTypes, Origin, ForwardVector, TargetActorSpec.Length, TargetActorSpec.HalfWidth, TargetActorSpec.UpHeight, TargetActorSpec.DownHeight, nullptr, ActorsToIgnore, OutActors, false, bDebug, LifeTime);
		break;

	default:
		break;
	}

	for (int32 i = 0; i < OutActors.Num(); ++i)
	{
		// TODO consider hit crushable box.
		AActor* Actor = OutActors[i];
		APawn* PawnActor = Cast<APawn>(OutActors[i]);
		AHiMountActor* HiMountActor = Cast<AHiMountActor>(OutActors[i]);
		if (!PawnActor && !HiMountActor)
		{
			// Collision with scene.
			NeedDestroy = true;
			continue;
		}
		
		if (!HitActors.Contains(Actor) && Filter.FilterPassesForActor(Actor))
		{
			// Limit one calculation target limit.
			// TODO priority.
			if (HitActors.Num() >= TargetActorSpec.CalcTargetLimit)
			{
				return;
			}
			
			HitActors.Add(Actor);
		}
	}
}

bool UHiCollisionLibrary::SphereOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, float Radius, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<AActor*>& OutActors, bool bDebug, float LifeTime)
{
	OutActors.Empty();

	TArray<UPrimitiveComponent*> OverlapComponents;
	bool bOverlapped = SphereOverlapComponents(WorldContextObject, ObjectTypes, Origin, Radius, UpHeight, DownHeight, NULL, ActorsToIgnore, OverlapComponents, bDebug, LifeTime);
	if (bOverlapped)
	{
		UKismetSystemLibrary::GetActorListFromComponentList(OverlapComponents, ActorClassFilter, OutActors);
	}

	return (OutActors.Num() > 0);
}


bool UHiCollisionLibrary::SphereOverlapComponents(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, float Radius, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<UPrimitiveComponent*>& OutComponents, bool bDebug, float LifeTime)
{
	UKismetSystemLibrary::SphereOverlapComponents(WorldContextObject, Origin, Radius, ObjectTypes, ComponentClassFilter, ActorsToIgnore, OutComponents);

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
#if ENABLE_DRAW_DEBUG
		if (bDebug)
		{
			DrawDebugSphere(World, Origin, Radius, 16, FColor::Red, false, LifeTime);
		}
#endif // ENABLE_DRAW_DEBUG
	}

	// Check in up and down height.
	for (auto It = OutComponents.CreateIterator(); It; ++ It)
	{
		auto const& CurComponent = *It;
		if ((UpHeight > 0 || DownHeight > 0) && !CheckInHeightZ(Origin.Z, CurComponent->Bounds.Origin.Z + CurComponent->Bounds.BoxExtent.Z, CurComponent->Bounds.Origin.Z - CurComponent->Bounds.BoxExtent.Z, UpHeight, DownHeight))
		{
			It.RemoveCurrent();
		}
	}

	return (OutComponents.Num() > 0);
}

bool UHiCollisionLibrary::SectionOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Radius, float Angle, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<AActor*>& OutActors, bool bDebug, float LifeTime)
{
	OutActors.Empty();

	TArray<UPrimitiveComponent*> OverlapComponents;
	bool bOverlapped = SectionOverlapComponents(WorldContextObject, ObjectTypes, Origin, ForwardVector, Radius, Angle, UpHeight, DownHeight, NULL, ActorsToIgnore, OverlapComponents, bDebug, LifeTime);
	if (bOverlapped)
	{
		UKismetSystemLibrary::GetActorListFromComponentList(OverlapComponents, ActorClassFilter, OutActors);
	}

	return (OutActors.Num() > 0);
}

bool UHiCollisionLibrary::SectionOverlapComponents(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Radius, float Angle, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<UPrimitiveComponent*>& OutComponents, bool bDebug, float LifeTime)
{
	SphereOverlapComponents(WorldContextObject, ObjectTypes, Origin, Radius, UpHeight, DownHeight, ComponentClassFilter, ActorsToIgnore, OutComponents);

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
#if ENABLE_DRAW_DEBUG
		if (bDebug)
		{
			DrawDebugPoint(World, Origin, 10, FColor::Green, false, LifeTime);
			DrawDebugLine(World, Origin, Origin + ForwardVector * Radius, FColor::Yellow, false, LifeTime);
			DrawDebugCircleArc(World, Origin, Radius, ForwardVector, Angle/2, 8, FColor::Green, false, LifeTime);
			DrawDebugSphere(World, Origin, Radius, 16, FColor::Red, false, LifeTime);
		}
#endif // ENABLE_DRAW_DEBUG
	}

	// After sphere overlap, check angle in section.
	for (auto It = OutComponents.CreateIterator(); It; ++ It)
	{
		const UPrimitiveComponent* CurComp = (*It);
		if (!CheckInSection(CurComp->GetComponentLocation(), Origin, ForwardVector, Angle))
		{
			const auto CurComponent = *It;
			It.RemoveCurrent();
		}
	}
	
	return (OutComponents.Num() > 0);
}

bool UHiCollisionLibrary::BoxOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Length, float HalfWidth, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<AActor*>& OutActors, bool bKeepOrigin, bool bDebug, float LifeTime)
{
	OutActors.Empty();

	TArray<UPrimitiveComponent*> OverlapComponents;
	bool bOverlapped = BoxOverlapComponents(WorldContextObject, ObjectTypes, Origin, ForwardVector, Length, HalfWidth, UpHeight, DownHeight, NULL, ActorsToIgnore, OverlapComponents, bKeepOrigin, bDebug, LifeTime);
	if (bOverlapped)
	{
		UKismetSystemLibrary::GetActorListFromComponentList(OverlapComponents, ActorClassFilter, OutActors);
	}

	return (OutActors.Num() > 0);
}

bool UHiCollisionLibrary::BoxOverlapComponents(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Length, float HalfWidth, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<UPrimitiveComponent*>& OutComponents, bool bKeepOrigin, bool bDebug, float LifeTime)
{
	OutComponents.Empty();

	const FQuat& Rot = ForwardVector.Rotation().Quaternion();
	const FVector BoxExtent = FVector( Length / 2, HalfWidth, FMath::Max(UpHeight, DownHeight));
	FVector NewOrigin = Origin;
	if (!bKeepOrigin)
	{
		NewOrigin = Origin + ForwardVector * Length / 2;
	}

	FCollisionQueryParams Params(SCENE_QUERY_STAT(BoxOverlapComponents), false);
	Params.AddIgnoredActors(ActorsToIgnore);

	TArray<FOverlapResult> Overlaps;
	FCollisionObjectQueryParams ObjectParams;
	for (auto Iter = ObjectTypes.CreateConstIterator(); Iter; ++Iter)
	{
		const ECollisionChannel & Channel = UCollisionProfile::Get()->ConvertToCollisionChannel(false, *Iter);
		ObjectParams.AddObjectTypesToQuery(Channel);
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	if (World != nullptr)
	{
		World->OverlapMultiByObjectType(Overlaps, NewOrigin, Rot, ObjectParams, FCollisionShape::MakeBox(BoxExtent), Params);

#if ENABLE_DRAW_DEBUG
		if (bDebug)
		{
			DrawDebugPoint(World, NewOrigin, 10, FColor::Green, false, LifeTime);
			DrawDebugLine(World, NewOrigin, NewOrigin + ForwardVector * Length, FColor::Yellow, false, LifeTime);
			if (!bKeepOrigin)
			{
				DrawDebugPoint(World, NewOrigin, 10, FColor::Red, false, LifeTime);
			}
			DrawDebugBox(World, NewOrigin, BoxExtent, Rot, FColor::Red, false, LifeTime);
		}
#endif // ENABLE_DRAW_DEBUG
	}

	for (int32 OverlapIdx=0; OverlapIdx<Overlaps.Num(); ++OverlapIdx)
	{
		FOverlapResult const& O = Overlaps[OverlapIdx];
		auto OverlapComp = O.Component;

		if (! OverlapComp.IsValid())
		{
			continue;
		}
		
		if (! CheckInHeightZ(NewOrigin.Z, OverlapComp->Bounds.Origin.Z + OverlapComp->Bounds.BoxExtent.Z, OverlapComp->Bounds.Origin.Z - OverlapComp->Bounds.BoxExtent.Z, UpHeight, DownHeight))
		{
			continue;
		}
		
		if ( !ComponentClassFilter || OverlapComp.Get()->IsA(ComponentClassFilter) )
		{
			OutComponents.Add(OverlapComp.Get());
		}
	}

	return (OutComponents.Num() > 0);
}

bool UHiCollisionLibrary::CheckInHeight(const FVector& TargetPos, const FVector& Origin, float UpHeight, float DownHeight)
{
	float HeightDelta = TargetPos.Z - Origin.Z;
	if ((DownHeight > 0 && HeightDelta < -DownHeight) || (UpHeight > 0 && HeightDelta > UpHeight))
	{
		return false;
	}
	
	return true;
}

bool UHiCollisionLibrary::CheckInHeightZ(float OriginZ, float MaxZ, float MinZ, float UpHeight, float DownHeight)
{
	if ((UpHeight > 0 && MaxZ < OriginZ - DownHeight) || (DownHeight > 0 && MinZ > OriginZ + UpHeight))
	{
		return false;
	}

	return true;
}

bool UHiCollisionLibrary::CheckInSection(const FVector& TargetPos, const FVector& Origin, const FVector& ForwardVector, float Radians)
{
	FVector TargetPosWithoutZ = FVector(TargetPos.X, TargetPos.Y, 0);
	FVector OriginPosWithoutZ = FVector(Origin.X, Origin.Y, 0);
	const FVector OriginToTarget = TargetPosWithoutZ - OriginPosWithoutZ;
	const float CosHalfAngle = FMath::Cos(FMath::Clamp(Radians/2, 0.f, PI));
	if(FVector::DotProduct(OriginToTarget.GetUnsafeNormal(), ForwardVector) > CosHalfAngle)
	{
		return true;
	}

	return false;
}

bool UHiCollisionLibrary::CheckInDirectionBySection(const FVector& TargetPos, const FVector& Origin, const FVector& ForwardVector, int StartAngle, int EndAngle)
{
	StartAngle = FMath::Clamp(StartAngle, 0, 360);
	EndAngle = FMath::Clamp(EndAngle, 0, 360);
	StartAngle = FMath::Min(StartAngle, EndAngle);

	if (StartAngle < 180 && EndAngle > 180)
	{
		// 跨越180度得分开判断
		return CheckInDirectionBySection(TargetPos, Origin, ForwardVector, StartAngle, 180) || CheckInDirectionBySection(TargetPos, Origin, ForwardVector, 180, EndAngle);
	}
	
	const FVector TargetPosWithoutZ = FVector(TargetPos.X, TargetPos.Y, 0);
	const FVector OriginPosWithoutZ = FVector(Origin.X, Origin.Y, 0);
	const FVector OriginToTarget = TargetPosWithoutZ - OriginPosWithoutZ;

	auto const DotForward = FVector::DotProduct(OriginToTarget.GetUnsafeNormal(), ForwardVector.GetUnsafeNormal());
	if (DotForward < 0.0f && EndAngle <= 180)
	{
		// DotForward < 0说明Target在Origin的后方
		return false;
	}
	else if (DotForward > 0.0f && EndAngle > 180)
	{
		// DotForward > 0 说明Target在Origin的前方
		return false;
	}
	
	const FVector ZNormal(0, 0, 1);
	const FVector RightForwardVector = FVector::CrossProduct(ZNormal, ForwardVector);
	auto const DotRightForward = FVector::DotProduct(OriginToTarget.GetUnsafeNormal(), RightForwardVector.GetUnsafeNormal());

	auto const StartRadians = FMath::DegreesToRadians(StartAngle);
	auto const EndRadians = FMath::DegreesToRadians(EndAngle);
	
	auto const StartCos = FMath::Cos(StartRadians);
	auto const EndCos = FMath::Cos(EndRadians);
	
	bool ret = false;
	if (EndAngle <= 180)
	{
		// EndAngle <= 180时，Angle越大，cos越小
		ret = (DotRightForward < StartCos || FMath::Abs(DotRightForward - StartCos) < 0.00001f) && // DotRightForward <= StartCos
			(DotRightForward > EndCos || FMath::Abs(DotRightForward - EndCos) < 0.00001f); // DotRightForward >= EndCos
	}
	else
	{
		// EndAngle > 180时，Angle越大，cos越大
		ret = (DotRightForward > StartCos || FMath::Abs(DotRightForward - StartCos) < 0.00001f) && // DotRightForward >= StartCos
			(DotRightForward < EndCos || FMath::Abs(DotRightForward - EndCos) < 0.00001f); // DotRightForward <= EndCos
	}
	
	return ret;
}

bool UHiCollisionLibrary::ComponentTraceMulti(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector Start, const FVector End, const FRotator Rotation, UPrimitiveComponent* PrimComp, TArray<FHitResult>& OutHits)
{
	if (!WorldContextObject || !PrimComp)
	{
		return false;
	}
	
	AActor* const Actor = PrimComp->GetOwner();
	static const FName TraceTagName = TEXT("HiCollisionLibrary");
	FComponentQueryParams Params(SCENE_QUERY_STAT(MoveComponent), Actor);
	FCollisionResponseParams ResponseParam;
	PrimComp->InitSweepCollisionParams(Params, ResponseParam);
	Params.bIgnoreTouches |= !(PrimComp->GetGenerateOverlapEvents());
	Params.TraceTag = TraceTagName;
	UWorld* MyWorld = WorldContextObject->GetWorld();

	FCollisionObjectQueryParams ObjectParams;
	for (auto Iter = ObjectTypes.CreateConstIterator(); Iter; ++Iter)
	{
		const ECollisionChannel & Channel = UCollisionProfile::Get()->ConvertToCollisionChannel(false, *Iter);
		ObjectParams.AddObjectTypesToQuery(Channel);
	}
	
	return MyWorld ? MyWorld->ComponentSweepMulti(OutHits, PrimComp, Start, End, Rotation, Params, ObjectParams) : false;
}

bool UHiCollisionLibrary::CapsuleTraceMultiForObjects(const UObject* WorldContextObject, const FVector Start, const FVector End, const FRotator Orientation, float Radius, float HalfHeight, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, bool bTraceComplex, const TArray<AActor*>& ActorsToIgnore, EDrawDebugTrace::Type DrawDebugType, TArray<FHitResult>& OutHits, bool bIgnoreSelf, FLinearColor TraceColor, FLinearColor TraceHitColor, float DrawTime)
{
	static const FName CapsuleTraceMultiName(TEXT("CapsuleTraceMultiForObjects"));
	FCollisionQueryParams Params = HiConfigureCollisionParams(CapsuleTraceMultiName, bTraceComplex, ActorsToIgnore, bIgnoreSelf, WorldContextObject);

	FCollisionObjectQueryParams ObjectParams = HiConfigureCollisionObjectParams(ObjectTypes);
	if (ObjectParams.IsValid() == false)
	{
		UE_LOG(LogBlueprintUserMessages, Warning, TEXT("Invalid object types"));
		return false;
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	bool const bHit = World ? World->SweepMultiByObjectType(OutHits, Start, End, Orientation.Quaternion(), ObjectParams, FCollisionShape::MakeCapsule(Radius, HalfHeight), Params) : false;

#if ENABLE_DRAW_DEBUG
	HiDrawDebugCapsuleTraceMulti(World, Start, End, Orientation, Radius, HalfHeight, DrawDebugType, bHit, OutHits, TraceColor, TraceHitColor, DrawTime);
#endif

	return bHit;
}

void UHiCollisionLibrary::GetComponentPhysicsMaterial(UPrimitiveComponent* PrimComp, bool bSimpleCollision, TArray<UPhysicalMaterial*> &OutPhysMaterials)
{	
	if(PrimComp)
	{
		if (bSimpleCollision)
		{
			UPhysicalMaterial* PhysMat = PrimComp->BodyInstance.GetSimplePhysicalMaterial();
			if (PhysMat)
			{
				OutPhysMaterials.Add(PhysMat);	
			}			
		}
		else
		{
			PrimComp->BodyInstance.GetComplexPhysicalMaterials(OutPhysMaterials);
		}
	}	
}
