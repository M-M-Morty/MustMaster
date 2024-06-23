// Fill out your copyright notice in the Description page of Project Settings.


#include "EditorUtilityActorComponents/GenerateTriggerUtilityComponent.h"
#include "Components/ShapeComponent.h"
#include "Trigger/HiTriggerBox.h"
#include "Kismet/GameplayStatics.h"

UGenerateTriggerUtilityComponent::UGenerateTriggerUtilityComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = true;
	PrimaryComponentTick.bCanEverTick = true;
	
	bIsEditorOnly = true;
}

#if WITH_EDITOR
void UGenerateTriggerUtilityComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{	
	const FName PropertyName = PropertyChangedEvent.MemberProperty ? PropertyChangedEvent.MemberProperty->GetFName() : NAME_None;
	if (PropertyName == TEXT("bAutoGenerateTrigger"))
	{
		if (bAutoGenerateTrigger)
		{
			GenerateTrigger();
		}
		else
		{
			DeleteTrigger();
		}	
	}
	Super::PostEditChangeProperty(PropertyChangedEvent);
}


void UGenerateTriggerUtilityComponent::OnComponentDestroyed(bool bDestroyingHierarchy)
{
	Super::OnComponentDestroyed(bDestroyingHierarchy);
	if (bDestroyingHierarchy)
	{
		DeleteTrigger();	
	}	
}


void UGenerateTriggerUtilityComponent::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	AActor* Owner = GetOwner();
	UpdateTriggerActorTransform(false);
}


void UGenerateTriggerUtilityComponent::GenerateTrigger()
{
	UWorld* World = GetWorld();
	AActor* Owner = GetOwner();
	if (bAutoGenerateTrigger && World && Owner)
	{
		if (!IsValid(TriggerActor))
		{
			if(!IsValid(TriggerActorClass))
			{				
				TriggerActorClass = AHiTriggerBox::StaticClass();		
			}
			const FVector Location = Owner->GetActorLocation();
			const FRotator Rotation = Owner->GetActorRotation();

			FActorSpawnParameters SpawnParameters;
			SpawnParameters.bAllowDuringConstructionScript = true;			
			TriggerActor = Cast<AHiTriggerBox>(World->SpawnActor(*TriggerActorClass, &Location, &Rotation, SpawnParameters));					
		}
		if (IsValid(TriggerActor))
		{
			UpdateTriggerActorTransform(true);
			TriggerActor->SetFolderPath(TEXT("AUTO_GEN_DO_NOT_REMOVE"));		
			TriggerActor->ReferenceActors.Empty();
			TriggerActor->ReferenceActors.Add(Owner);			
		}
	}
}

void UGenerateTriggerUtilityComponent::DeleteTrigger()
{
	if (IsValid(TriggerActor))
	{
		TriggerActor->ReferenceActors.Empty();
		TriggerActor->Destroy();	
	}
}

void UGenerateTriggerUtilityComponent::UpdateTriggerActorTransform(bool Force)
{
	AActor* Owner = GetOwner();
	if (Owner && IsValid(TriggerActor))
	{
		FVector Origin, BoxExtent;			
		Owner->GetActorBounds(false, Origin, BoxExtent);
		
		if (Force || (TriggerFollowType == ETriggerFollowType::Transform) || ( TriggerFollowType == ETriggerFollowType::Rotation ))//scale
		{
			const FVector Scale = BoxExtent * 2 * 0.01;			
			TriggerActor->SetActorScale3D(FVector(Scale.X, Scale.Y, Scale.Z));	
		}		

		if (Force || (TriggerFollowType == ETriggerFollowType::Transform) || ( TriggerFollowType == ETriggerFollowType::Translate ))//translate
		{
			FVector Location = Owner->GetActorLocation();
			Location.Z += BoxExtent.Z/2.0;
			TriggerActor->SetActorLocation(Location);	
		}		
	}
}
#endif