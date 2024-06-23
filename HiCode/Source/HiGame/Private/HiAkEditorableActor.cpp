// Fill out your copyright notice in the Description page of Project Settings.
#include "HiAkEditorableActor.h"
#include "AkComponent.h"
#include "AkGameplayStatics.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetMathLibrary.h"


AHiAkEditorableActor::AHiAkEditorableActor(const FObjectInitializer& ObjectInitializer):
				Super(ObjectInitializer)
{
#if WITH_EDITOR
	OnToggleSelectDelegateHandle = FEditorDelegates::OnViewportEditorShowToggled.AddUObject(this, &AHiAkEditorableActor::OnToggleSelectWireSwitch);
	Tags.Add("ShowDebugWire");
#endif

	static const FName ComponentName = TEXT("AkComponent");
	AkComponent = ObjectInitializer.CreateDefaultSubobject<UAkComponent>(this, ComponentName);
	AkComponent->StopWhenOwnerDestroyed = true;
	AkComponent->AttachToComponent(GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform);
}


void AHiAkEditorableActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	DoDistanceCulling();
}

void AHiAkEditorableActor::BeginPlay()
{
	Super::BeginPlay();
	bPlaying = false;
	if (CenterLocation.IsZero())
	{
		CenterLocation = GetActorLocation();	
	}	
}

void AHiAkEditorableActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	bPlaying = false;
}

void AHiAkEditorableActor::DoDistanceCulling_Implementation()
{
	APlayerController* pPlayerController = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	if (pPlayerController != nullptr)
	{
		
		FVector ListenerLoc, Front, Right;
		pPlayerController->GetAudioListenerPosition(ListenerLoc, Front, Right);
		float distance_squard = UKismetMathLibrary::Vector_DistanceSquared(CenterLocation, ListenerLoc);
		if (distance_squard > (CullingDistance * CullingDistance))
		{
			if (bPlaying)
			{
				bPlaying = false;
				RecieveOutsideCullingRange();
			}			
		}
		else
		{
			if (!bPlaying)
			{
				bPlaying = true;
				// play akevent
				RecieveInsideCullingRange();
			}
		}			
	}	
}



#if WITH_EDITOR
void AHiAkEditorableActor::EditorTick(float DeltaTime)
{
	Super::EditorTick(DeltaTime);
	if (bDebugDraw)
	{
		DebugDrawSourcePoints();	
	}	
}


void AHiAkEditorableActor::DebugDrawSourcePoints()
{
	UWorld* World = GetWorld();
	if ((World) && AkComponent)
	{
		for(int32 i = 0; i < SourcePositions.Num(); ++i)
		{				
			FVector Location = SourcePositions[i].GetLocation();
			DrawDebugSphere(World, Location, AkComponent->GetAttenuationRadius(), 12, FColor::Green, false, GetActorTickInterval() );					
		}
		DrawDebugSphere(World, CenterLocation, CullingDistance, 12, FColor::Orange, false, GetActorTickInterval() );
	}	
}

void AHiAkEditorableActor::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	static FName NAME_SourcePositions = GET_MEMBER_NAME_CHECKED(AHiAkEditorableActor, SourcePositions);	
	if (PropertyChangedEvent.Property)
	{
		if(PropertyChangedEvent.Property->GetFName() == NAME_SourcePositions)
		{
			CenterLocation = GetActorLocation();
			TArray<FVector> VectorArray;
			if (SourcePositions.Num() > 0)
			{
				for (int i = 0; i < SourcePositions.Num(); ++i)
				{
					VectorArray.Add(SourcePositions[i].GetLocation());
				}
				CenterLocation = UKismetMathLibrary::GetVectorArrayAverage(VectorArray);
			}
		}
	}
}



void AHiAkEditorableActor::OnToggleSelectWireSwitch(const FString& InClassName, bool bToggle)
{	
	FString ClassName = GetClass()->GetName();
	ClassName.RemoveFromEnd(TEXT("_C"));
	//UE_LOG(LogTemp, Error,TEXT("OnToggleSelectWireSwitch_Implementation %s  %s"),*ClassName,  *InClassName);
	if ((ClassName == InClassName) && bDebugDraw != bToggle)
	{
		bDebugDraw = bToggle;		
	}
}
FBox AHiAkEditorableActor::GetStreamingBounds() const
{
	FBox Box = Super::GetStreamingBounds();
	FBoxSphereBounds NewBounds;
	NewBounds.Origin = GetTransform().GetLocation();
	NewBounds.BoxExtent = FVector::One() * CullingDistance;
	NewBounds.SphereRadius = CullingDistance;
	Box += NewBounds.GetBox();
	return Box;
}
#endif