// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/MaterialGroupComponent.h"


// Sets default values for this component's properties
UMaterialGroupComponent::UMaterialGroupComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bAllowTickOnDedicatedServer = false;
}

// Called when the game starts
void UMaterialGroupComponent::BeginPlay()
{
	Super::BeginPlay();

}

void UMaterialGroupComponent::SetUseMaskedMaterials(bool bInUseMaskedMaterials)
{
	if (bUseMaskedMaterials == bInUseMaskedMaterials)
		return;
	bUseMaskedMaterials = bInUseMaskedMaterials;	
	UpdateTargetComponentMaterials();
	bPreviousUseMaskedMaterials = bUseMaskedMaterials;
}

#if WITH_EDITOR
void UMaterialGroupComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	static FName NAME_bUseMaskedMaterials = GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, bUseMaskedMaterials);
	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == NAME_bUseMaskedMaterials)
	{
		UpdateTargetComponentMaterials();
		bPreviousUseMaskedMaterials = bUseMaskedMaterials;
	}
}
#endif

void UMaterialGroupComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (bPreviousUseMaskedMaterials != bUseMaskedMaterials)
	{
		UpdateTargetComponentMaterials();
		bPreviousUseMaskedMaterials = bUseMaskedMaterials;
	}
}

void UMaterialGroupComponent::UpdateTargetComponentMaterials()
{
	AActor* Owner = GetOwner();
	if (!Owner)
		return;

	UPrimitiveComponent* TargetComponent = nullptr;
	if (TargetComponentName != NAME_None)
	{
		TArray<UPrimitiveComponent*> PrimitiveComponents;
		Owner->GetComponents<UPrimitiveComponent>(PrimitiveComponents);
		for (UPrimitiveComponent* PrimitiveComponent : PrimitiveComponents)
		{
			if (PrimitiveComponent->GetFName() == TargetComponentName)
			{
				TargetComponent = PrimitiveComponent;
				break;
			}
		}
	}
	if (!TargetComponent)
		return;

	if (bUseMaskedMaterials)
	{
		int32 NumMaterials = FMath::Min(MaskedMaterials.Num(), TargetComponent->GetNumMaterials());
		for (int32 i = 0; i < NumMaterials; i++)
		{
			TargetComponent->SetMaterial(i, MaskedMaterials[i]);
		}
	}
	else
	{
		int32 NumMaterials = FMath::Min(OriginalMaterials.Num(), TargetComponent->GetNumMaterials());
		for (int32 i = 0; i < NumMaterials; i++)
		{
			TargetComponent->SetMaterial(i, OriginalMaterials[i]);
		}
	}
}
