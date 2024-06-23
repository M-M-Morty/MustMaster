// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/MaterialGroupComponent.h"

#include "Component/HiSkeletalMeshComponent.h"

static FName DissolveAmountName(TEXT("Dissolve"));
static FName Fresnel_StrengthName(TEXT("Fresnel_Strength"));
static FName Fresnel_PowerName(TEXT("Fresnel_Power"));
static FName Emissive_StrengthName(TEXT("Emissive_Strength"));

#define UPDATE_PARAMETER_VALUE(Param) \
	UpdateParameterValue(Param##Name, Param); \
	Previous##Param = Param; \
	for (TWeakObjectPtr<UMaterialGroupComponent> Child : Children) \
	{\
		if (Child.IsValid())\
			Child->Set##Param(Param);\
	}

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
	bPreviousUseMaskedMaterials = false;
	PreviousDissolveAmount = 0.0f;
	PreviousFresnel_Strength = 0.0f;
	PreviousFresnel_Power = 0.0f;
	PreviousEmissive_Strength = 0.0f;
	ExtractComponentIfNeeded();
	for (TWeakObjectPtr<UPrimitiveComponent>& TargetComponentReference : TargetComponentReferences)
	{
		if (TargetComponentReference.IsValid())
		{
			if (UHiSkeletalMeshComponent* Component = Cast<UHiSkeletalMeshComponent>(TargetComponentReference.Get()))
			{
				Component->OnChildAttachment.AddDynamic(this, &UMaterialGroupComponent::OnChildAttachment);
			}
		}
	}
}

void UMaterialGroupComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);

	Children.Empty();
	
	for (TWeakObjectPtr<UPrimitiveComponent>& TargetComponentReference : TargetComponentReferences)
	{
		if (TargetComponentReference.IsValid())
		{
			if (UHiSkeletalMeshComponent* Component = Cast<UHiSkeletalMeshComponent>(TargetComponentReference.Get()))
			{
				Component->OnChildAttachment.RemoveDynamic(this, &UMaterialGroupComponent::OnChildAttachment);
			}
		}
	}
}

void UMaterialGroupComponent::SetUseMaskedMaterials(bool bInUseMaskedMaterials)
{
	if (bUseMaskedMaterials == bInUseMaskedMaterials)
		return;
	bUseMaskedMaterials = bInUseMaskedMaterials;	
	SwitchDissolveMaterials();
	bPreviousUseMaskedMaterials = bUseMaskedMaterials;
	UpdateAllParameterValues();
}

void UMaterialGroupComponent::SetDissolveAmount(float InDissolveAmount)
{
	if (DissolveAmount == InDissolveAmount)
		return;
	DissolveAmount = InDissolveAmount;
	UPDATE_PARAMETER_VALUE(DissolveAmount);
}

void UMaterialGroupComponent::SetFresnel_Strength(float InFresnel_Strength)
{
	if (Fresnel_Strength == InFresnel_Strength)
		return;
	Fresnel_Strength = InFresnel_Strength;
	UPDATE_PARAMETER_VALUE(Fresnel_Strength);
}

void UMaterialGroupComponent::SetFresnel_Power(float InFresnel_Power)
{
	if (Fresnel_Power == InFresnel_Power)
		return;
	Fresnel_Power = InFresnel_Power;
	UPDATE_PARAMETER_VALUE(Fresnel_Power);
}

void UMaterialGroupComponent::SetEmissive_Strength(float InEmissive_Strength)
{
	if (Emissive_Strength == InEmissive_Strength)
		return;
	Emissive_Strength = InEmissive_Strength;
	UPDATE_PARAMETER_VALUE(Emissive_Strength);
}

void UMaterialGroupComponent::AddChild(UMaterialGroupComponent* Child)
{
	if (!Child)
		return;
	if (Children.Contains(Child))
		return;
	Children.Add(Child);
	Child->SetUseMaskedMaterials(bPreviousUseMaskedMaterials);
	Child->SetDissolveAmount(PreviousDissolveAmount);
	Child->SetFresnel_Strength(PreviousFresnel_Strength);
	Child->SetFresnel_Power(PreviousFresnel_Power);
	Child->SetEmissive_Strength(PreviousEmissive_Strength);
	
}

void UMaterialGroupComponent::RemoveChild(UMaterialGroupComponent* Child)
{
	if (!Child)
		return;
	if (!Children.Contains(Child))
		return;
	Children.Remove(Child);
}

void UMaterialGroupComponent::OnChildAttachment(USceneComponent* InSceneComponent, bool bIsAttached)
{
	if (InSceneComponent && InSceneComponent->GetOwner())
	{
		if (UMaterialGroupComponent* ChildComponent = Cast<UMaterialGroupComponent>(InSceneComponent->GetOwner()->GetComponentByClass(UMaterialGroupComponent::StaticClass())))
		{
			if (ChildComponent == this)
				return;
			if (GetOwner() == ChildComponent->GetOwner())
				return;
			if (bIsAttached)
			{
				AddChild(ChildComponent);
			}
			else
			{
				RemoveChild(ChildComponent);
			}
		}
	}
}

#if WITH_EDITOR
void UMaterialGroupComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	static FName NAME_bUseMaskedMaterials = GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, bUseMaskedMaterials);
	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == NAME_bUseMaskedMaterials)
	{
		SwitchDissolveMaterials();
		bPreviousUseMaskedMaterials = bUseMaskedMaterials;
		UpdateAllParameterValues();
	}

	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, DissolveAmount))
	{
		UPDATE_PARAMETER_VALUE(DissolveAmount);
	}
	
	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, Fresnel_Strength))
	{
		UPDATE_PARAMETER_VALUE(Fresnel_Strength);
	}
	
	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, Fresnel_Power))
	{
		UPDATE_PARAMETER_VALUE(Fresnel_Power);
	}

	if (PropertyChangedEvent.Property && PropertyChangedEvent.Property->GetFName() == GET_MEMBER_NAME_CHECKED(UMaterialGroupComponent, Emissive_Strength))
	{
		UPDATE_PARAMETER_VALUE(Emissive_Strength);
	}
}
#endif

void UMaterialGroupComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	if (bPreviousUseMaskedMaterials != bUseMaskedMaterials)
	{
		SwitchDissolveMaterials();
		bPreviousUseMaskedMaterials = bUseMaskedMaterials;
		UpdateAllParameterValues();
	}
	if (PreviousDissolveAmount != DissolveAmount)
	{
		UPDATE_PARAMETER_VALUE(DissolveAmount);
	}
	if (PreviousFresnel_Strength != Fresnel_Strength)
	{
		UPDATE_PARAMETER_VALUE(Fresnel_Strength);
	}
	if (PreviousFresnel_Power != Fresnel_Power)
	{
		UPDATE_PARAMETER_VALUE(Fresnel_Power);
	}
	if (PreviousEmissive_Strength != Emissive_Strength)
	{
		UPDATE_PARAMETER_VALUE(Emissive_Strength);
	}
}

void UMaterialGroupComponent::ExtractComponentIfNeeded()
{
	if (TargetComponentReferences.Num() != TargetComponentNames.Num())
	{
		TargetComponentReferences.SetNumZeroed(TargetComponentNames.Num());
	}
	
	AActor* Owner = GetOwner();
	if (!Owner)
		return;
	
	for (int i = 0; i < TargetComponentNames.Num(); i++)
	{
		if (TargetComponentReferences[i].IsValid())
			continue;
		const FName& TargetComponentName = TargetComponentNames[i];
		if (TargetComponentName != NAME_None)
		{
			TArray<UPrimitiveComponent*> PrimitiveComponents;
			Owner->GetComponents<UPrimitiveComponent>(PrimitiveComponents);
			for (UPrimitiveComponent* PrimitiveComponent : PrimitiveComponents)
			{
				if (PrimitiveComponent->GetFName() == TargetComponentName)
				{
					TargetComponentReferences[i] = PrimitiveComponent;
					break;
				}
			}
		}
	}
}

void UMaterialGroupComponent::SwitchDissolveMaterials()
{
	ExtractComponentIfNeeded();

	if (bUseMaskedMaterials)
	{
		for (int32 GroupIndex = 0; GroupIndex < TargetComponentReferences.Num(); GroupIndex++)
		{
			TWeakObjectPtr<UPrimitiveComponent>& TargetComponentReference = TargetComponentReferences[GroupIndex];
			if (TargetComponentReference.IsValid())
			{
				TArray<UMaterialInterface*>& Materials = MaskedMaterials[GroupIndex].Materials;
				int32 NumMaterials = FMath::Min(Materials.Num(), TargetComponentReference->GetNumMaterials());
				for (int32 MaterialIndex = 0; MaterialIndex < NumMaterials; MaterialIndex++)
				{
					TargetComponentReference->SetMaterial(MaterialIndex, Materials[MaterialIndex]);
				}
			}
		}
	}
	else
	{
		for (int32 GroupIndex = 0; GroupIndex < TargetComponentReferences.Num(); GroupIndex++)
		{
			TWeakObjectPtr<UPrimitiveComponent>& TargetComponentReference = TargetComponentReferences[GroupIndex];
			if (TargetComponentReference.IsValid())
			{
				TArray<UMaterialInterface*>& Materials = OriginalMaterials[GroupIndex].Materials;
				int32 NumMaterials = FMath::Min(Materials.Num(), TargetComponentReference->GetNumMaterials());
				for (int32 MaterialIndex = 0; MaterialIndex < NumMaterials; MaterialIndex++)
				{
					TargetComponentReference->SetMaterial(MaterialIndex, Materials[MaterialIndex]);
				}
			}
		}
	}

	for (TWeakObjectPtr<UMaterialGroupComponent> Child : Children)
	{
		if (Child.IsValid())
		{
			Child->SetUseMaskedMaterials(bUseMaskedMaterials);
		}
			
	}
}

void UMaterialGroupComponent::UpdateParameterValue(const FName& ParameterName, float Value)
{
	ExtractComponentIfNeeded();

	for (int GroupIndex = 0; GroupIndex < TargetComponentReferences.Num(); GroupIndex++)
	{
		TWeakObjectPtr<UPrimitiveComponent>& TargetComponentReference = TargetComponentReferences[GroupIndex];
		if (TargetComponentReference.IsValid())
		{
			for (int32 i = 0; i < TargetComponentReference->GetNumMaterials(); i++)
			{
				UMaterialInstanceDynamic* MID = TargetComponentReference->CreateAndSetMaterialInstanceDynamic(i);
				if (MID)
				{
					MID->SetScalarParameterValue(ParameterName, Value);
				}
			}
		}
	}
}

void UMaterialGroupComponent::UpdateAllParameterValues()
{
	UPDATE_PARAMETER_VALUE(DissolveAmount);
	UPDATE_PARAMETER_VALUE(Fresnel_Strength);
	UPDATE_PARAMETER_VALUE(Fresnel_Power);
	UPDATE_PARAMETER_VALUE(Emissive_Strength);
}
