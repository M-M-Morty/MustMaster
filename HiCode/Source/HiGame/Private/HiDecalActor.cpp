// Fill out your copyright notice in the Description page of Project Settings.


#include "HiDecalActor.h"
#include "Components/BoxComponent.h"
#include "Components/DecalComponent.h"

AHiDecalActor::AHiDecalActor(const FObjectInitializer& ObjectInitializer):
			Super(ObjectInitializer)
{
#if WITH_EDITOR
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;
#endif
	
	BoxComponent = CreateDefaultSubobject<UBoxComponent>(TEXT("BoxComponent"));
	BoxComponent->SetupAttachment(GetRootComponent());
	BoxComponent->Mobility = EComponentMobility::Movable;	
	BoxComponent->SetCanEverAffectNavigation(false);
	BoxComponent->bDrawOnlyIfSelected = true;
	BoxComponent->bUseAttachParentBound = false;
	BoxComponent->bUseEditorCompositing = true;
	BoxComponent->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);

#if WITH_EDITOR
	UpdateBoxBounds();
#endif
}

#if WITH_EDITOR

void AHiDecalActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	UpdateBoxBounds();	
}

void AHiDecalActor::UpdateBoxBounds()
{
	{		
		if (const UDecalComponent* DecalComponent = GetDecal())
		{
			//BoxComponent->SetWorldLocation(GetActorLocation());
			const FVector DecalSize = DecalComponent->DecalSize;
			BoxComponent->SetBoxExtent(DecalSize);			
		}
	}
}

#endif