// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiTriggerComponent.h"

#include "Components/BrushComponent.h"
#include "Components/StaticMeshComponent.h"

#if WITH_EDITOR
#include "Materials/MaterialInstanceDynamic.h"
#include "Editor/UnrealEd/Public/Editor.h"
#endif

UHiTriggerComponent::UHiTriggerComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
#if WITH_EDITOR
	,WireFrameMaterialBase(FSoftObjectPath(TEXT("/Engine/EngineDebugMaterials/WireframeMaterial.WireframeMaterial")))
#endif
{
}

void UHiTriggerComponent::BeginPlay()
{
	Super::BeginPlay();
	UWorld* World = GEngine->GetWorldFromContextObject(GetOwner(), EGetWorldErrorMode::LogAndReturnNull);
	if ( World && ((World->GetNetMode() == NM_Client) || (World->GetNetMode() == NM_Standalone)))
	{
		if (!OnComponentBeginOverlap.IsAlreadyBound(this, &UHiTriggerComponent::ReviceComponentBeginOverlap))
		{
			OnComponentBeginOverlap.AddDynamic(this, &UHiTriggerComponent::ReviceComponentBeginOverlap);
		}
		if (!OnComponentEndOverlap.IsAlreadyBound(this, &UHiTriggerComponent::ReviceComponentEndOverlap))
		{
			OnComponentEndOverlap.AddDynamic(this, &UHiTriggerComponent::ReviceComponentEndOverlap);
		}	
	}	
}

void UHiTriggerComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	UWorld* World = GEngine->GetWorldFromContextObject(GetOwner(), EGetWorldErrorMode::LogAndReturnNull);
	if ( World && ((World->GetNetMode() == NM_Client) || (World->GetNetMode() == NM_Standalone)))
	{
		OnComponentBeginOverlap.RemoveDynamic(this, &UHiTriggerComponent::ReviceComponentBeginOverlap);
		OnComponentEndOverlap.RemoveDynamic(this, &UHiTriggerComponent::ReviceComponentEndOverlap);	
	}	
}

#if WITH_EDITOR
bool UHiTriggerComponent::SetStaticMesh(UStaticMesh* NewMesh)
{
	const bool Result = Super::SetStaticMesh(NewMesh);
	if (GetStaticMesh())
	{			
		GetStaticMesh()->SetMaterial(0, GetActiveWireFrameMID());
	}
	return Result;
}

void UHiTriggerComponent::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	
	static FName NAME_WireFrameColor = GET_MEMBER_NAME_CHECKED(UHiTriggerComponent, WireFrameColor);
	static FName NAME_TriggerScale = GET_MEMBER_NAME_CHECKED(UHiTriggerComponent, TriggerScale);
	
	if (PropertyChangedEvent.Property)
	{
		if(PropertyChangedEvent.Property->GetFName() == NAME_WireFrameColor)
		{
			UMaterialInstanceDynamic* MI =  Cast<UMaterialInstanceDynamic>(GetMaterial(0));
			MI->SetVectorParameterValue(FName(TEXT("Color")), WireFrameColor);
		}

		if(PropertyChangedEvent.Property->GetFName() == NAME_TriggerScale)
		{
			UpdateRelativeScale();
		}
	}	
}

UMaterial* UHiTriggerComponent::GetActiveWireFrameMaterial()
{
	return WireFrameMaterialBase.LoadSynchronous();
}

UMaterialInstanceDynamic* UHiTriggerComponent::GetActiveWireFrameMID()
{
	UMaterial* BaseWireFrameMat = GetActiveWireFrameMaterial();
	if (!WireFrameMaterialInst || WireFrameMaterialInst->Parent != BaseWireFrameMat)
	{
		WireFrameMaterialInst = UMaterialInstanceDynamic::Create(BaseWireFrameMat, nullptr);	
	}
	return WireFrameMaterialInst;
}

void UHiTriggerComponent::UpdateRelativeScale()
{
	FVector ScaleParam = FVector(TriggerScale, TriggerScale, 0.99);
	SetRelativeScale3D(ScaleParam);
}

void UHiTriggerComponent::CreateTriggerMesh()
{
	if (AActor* Owner = GetOwner())
	{
		if (UBrushComponent* BrushComponent = Cast<UBrushComponent>(Owner->GetRootComponent()))
		{				
			SetStaticMesh(nullptr);			
			//create mesh trigger from bursh mesh
			UStaticMesh* NewStaticMesh = GEditor->ConvertStaticMeshFromBrush(this, "", nullptr, BrushComponent->Brush);		
			NewStaticMesh->ClearFlags(NewStaticMesh->GetFlags());			
			NewStaticMesh->SetFlags(RF_Transactional);
			NewStaticMesh->SetBodySetup(BrushComponent->GetBodySetup());
			SetStaticMesh(NewStaticMesh);
			SetWorldTransform(BrushComponent->GetComponentTransform());
			//set random color
			WireFrameColor = FLinearColor::MakeRandomColor();
			UMaterialInstanceDynamic* MI =  Cast<UMaterialInstanceDynamic>(GetMaterial(0));
			MI->SetVectorParameterValue(FName(TEXT("Color")), WireFrameColor);
			//set relative scale
			UpdateRelativeScale();
		}	
	}
}

void UHiTriggerComponent::OnRegister()
{
	Super::OnRegister();
	if (GetStaticMesh())
	{
		UMaterialInstanceDynamic* MI =  GetActiveWireFrameMID();
		GetStaticMesh()->SetMaterial(0, MI);		
		MI->SetVectorParameterValue(FName(TEXT("Color")), WireFrameColor);
	}
}

#endif
