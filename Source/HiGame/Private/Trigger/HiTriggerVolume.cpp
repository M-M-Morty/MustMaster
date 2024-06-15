// Fill out your copyright notice in the Description page of Project Settings.


#include "Trigger/HiTriggerVolume.h"

#if WITH_EDITOR
#include "BSPOps.h"
#include "Components/BrushComponent.h"
#include "Builders/CubeBuilder.h"
#include "UnrealEd.h"
#include "Editor/UnrealEd/Public/Editor.h"
#include "Component/HiTriggerComponent.h"

#endif





AHiTriggerVolume::AHiTriggerVolume(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}


void AHiTriggerVolume::NotifyActorBeginOverlap(AActor* OtherActor)
{
	if (IsTargetActorValidToNotify(OtherActor))
	{
		Super::NotifyActorBeginOverlap(OtherActor);	
	}	
}

void AHiTriggerVolume::NotifyActorEndOverlap(AActor* OtherActor)
{
	if (IsTargetActorValidToNotify(OtherActor))
	{
		Super::NotifyActorEndOverlap(OtherActor);	
	}	
}


void AHiTriggerVolume::PostSpawnActor()
{
#if WITH_EDITOR
	BrushBuilder = NewObject<UCubeBuilder>();
	PreEditChange(nullptr);

	// Use the same object flags as the owner volume
	EObjectFlags Flags = GetFlags() & (RF_Transient | RF_Transactional);

	PolyFlags = 0;
	Brush = NewObject<UModel>(this, NAME_None, Flags);
	if (Brush)
	{
		Brush->Initialize(nullptr, true);
		Brush->Polys = NewObject<UPolys>(Brush, NAME_None, Flags);	
	}
	GetBrushComponent()->Brush = Brush;
	if(BrushBuilder != nullptr)
	{
		BrushBuilder = DuplicateObject<UBrushBuilder>(BrushBuilder, this);
		BrushBuilder->Build( GetWorld(), this );
	}
	
	FBSPOps::csgPrepMovingBrush( this );

	// Set the texture on all polys to nullptr.  This stops invisible textures
	// dependencies from being formed on volumes.
	if ( Brush )
	{
		for ( int32 poly = 0 ; poly < Brush->Polys->Element.Num() ; ++poly )
		{
			FPoly* Poly = &(Brush->Polys->Element[poly]);
			Poly->Material = nullptr;
		}
	}

	PostEditChange();
#endif
	
}


bool AHiTriggerVolume::IsTargetActorValidToNotify(AActor* OtherActor) const
{
	if (IsValid(OtherActor))
	{
		if (OtherActor->GetClass()->IsChildOf(ValidParentClass))
		{
			return true;
		}
		return false;
	}
	return false;
}


#if WITH_EDITOR

void AHiTriggerVolume::CheckForErrors()
{
	ABrush::CheckForErrors();
}

void AHiTriggerVolume::CreateBrushSubComponent()
{
	
}


/*
void AHiTriggerVolume::CreateBrushSubComponent()
{
	if (!InnerTriggerClass->IsValidLowLevelFast())
	{
		return;
	}
	
	UHiTriggerComponent* TriggerComponent = NewObject<UHiTriggerComponent>(this, InnerTriggerClass);
	TriggerComponent->RegisterComponent();
	TriggerComponent->SetMobility(EComponentMobility::Movable);
	TriggerComponent->bSelectable = true;
	TriggerComponent->SetVisibility(true);
	
	UStaticMesh* StaticMesh = GEditor->ConvertStaticMeshFromBrush(TriggerComponent, "", nullptr, GetBrushComponent()->Brush);
	StaticMesh->SetBodySetup(GetBrushComponent()->GetBodySetup());
	TriggerComponent->SetStaticMesh(StaticMesh);
	TriggerComponent->SetWorldTransform(GetBrushComponent()->GetComponentTransform());
	TriggerComponent->UpdateRelativeScale();

	//InnerTriggers.Emplace(TriggerComponent);
	AddInstanceComponent(TriggerComponent);
	TriggerComponent->AttachToComponent(GetRootComponent(), FAttachmentTransformRules::KeepWorldTransform);

	PostEditChange();
}
*/

#endif