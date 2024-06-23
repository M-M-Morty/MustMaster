// Fill out your copyright notice in the Description page of Project Settings.


#include "BlastMultiplePiecesBuildingActor.h"
#include "NiagaraComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Actions/AsyncAction_CreateAssetAsync.h"
#include "Materials/MaterialInstanceConstant.h"

const FString DebrisesMeshNamePrefix = TEXT("Debris");
const FString FringesMeshNamePrefix = TEXT("Fringe");
const FString MainBuildingsMeshNamePrefix = TEXT("MainBuilding");
const FString TopCollisionsMeshNamePrefix = TEXT("TopCollision");
const FString BaseCollisionsMeshNamePrefix = TEXT("BaseCollision");
const FString BaseBrokenBuildingsMeshNamePrefix = TEXT("BaseBrokenBuilding");
const FString TopBlastBuildingsMeshNamePrefix = TEXT("TopBlastBuilding");
const FString ExtraCollisionBeforeBlastPrefix = TEXT("ExtraCollisionBeforeBlast");

// Sets default values
ABlastMultiplePiecesBuildingActor::ABlastMultiplePiecesBuildingActor()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}
void ABlastMultiplePiecesBuildingActor::InitComp()
{
	TArray<UActorComponent*> SceneComponents;
	GetComponents(USceneComponent::StaticClass(), SceneComponents, true);
	for (UActorComponent* Comp: SceneComponents)
	{
		USceneComponent* SceneComp = Cast<USceneComponent>(Comp);
		FString Name = SceneComp->GetName();
		if (Name.Contains(TEXT("_")))
		{
			int Loc;
			Name.FindChar('_', Loc);
			FString Prefix = Name.Mid(0, Loc);
			if (!BuildingComp.Contains(Prefix))
			{
				BuildingComp.Add(Prefix, TSet<USceneComponent*>());
			}
			BuildingComp[Prefix].Add(SceneComp);
		}
	}

	ShowSceneCompByName(MainBuildingsMeshNamePrefix, true, false);
	ShowSceneCompByName(TopCollisionsMeshNamePrefix, false, true);
	ShowSceneCompByName(BaseCollisionsMeshNamePrefix, false, true);

	ShowSceneCompByName(BaseBrokenBuildingsMeshNamePrefix, false, false);
	ShowSceneCompByName(TopBlastBuildingsMeshNamePrefix, false, false);

	ShowSceneCompByName(FringesMeshNamePrefix, false, false);
	ShowSceneCompByName(DebrisesMeshNamePrefix, false, false);

	ShowSceneCompByName(ExtraCollisionBeforeBlastPrefix, false, true);
}
// Called when the game starts or when spawned
void ABlastMultiplePiecesBuildingActor::BeginPlay()
{
	Super::BeginPlay();
	InitComp();
	
}

void ABlastMultiplePiecesBuildingActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	
	if(HandleEndPlayForServer.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(HandleEndPlayForServer);
	}
	if(HandleStartPlayForEffect.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(HandleStartPlayForEffect);
	}
	if(HandleEndPlayForEffect.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(HandleEndPlayForEffect);
	}
}

void ABlastMultiplePiecesBuildingActor::ShowSceneCompByName(const FString& PrefixesName, bool bShown, bool bUseCollision)
{
	
	if (BuildingComp.Contains(PrefixesName))
	{
		for (auto Comp: BuildingComp[PrefixesName])
		{
			Comp->SetVisibility(bShown);
			
			if (UStaticMeshComponent* StaticMeshComp = Cast<UStaticMeshComponent>(Comp))
			{
				if (bUseCollision)
				{
					StaticMeshComp->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
				}
				else
				{
					StaticMeshComp->SetCollisionEnabled(ECollisionEnabled::NoCollision);

				}
			}
		}
	}
}

void ABlastMultiplePiecesBuildingActor::StartBlasting(const FString& PartName)
{
	if(bHasBlasted)
	{
		return;
	}
	bHasBlasted = true;

	ShowSceneCompByName(MainBuildingsMeshNamePrefix, false, false);
	ShowSceneCompByName(TopCollisionsMeshNamePrefix, false, false);
	ShowSceneCompByName(BaseCollisionsMeshNamePrefix, false, false);

	ShowSceneCompByName(BaseBrokenBuildingsMeshNamePrefix, true, true);
	ShowSceneCompByName(TopBlastBuildingsMeshNamePrefix, true, false);

	ShowSceneCompByName(ExtraCollisionBeforeBlastPrefix, false, false);


	FString ClassName = GetClass()->GetName();
	ClassName = ClassName.Mid(0,ClassName.Len() - 2); // remove "_C"
	const FString ContextString;
	FBuildingTopBlastInfo* Row = BuildingPartInfo->FindRow<FBuildingTopBlastInfo>(*ClassName, ContextString);
	if (!Row|| (Row->MaterialInfos.Num() == 0 && Row->TotalBlastPlayTime < 0))
	{
		return;
	}
	
	// init info in blasting
	float BlastEndTime = 0;
	{
		const UWorld* World = GetWorld();
		InfoInBlasting.bInBlasting = true;
		InfoInBlasting.BlastingStartTime = World ? World->GetTimeSeconds() : 0.f;
		InfoInBlasting.TotalShowTime = Row->TotalShowTime;
		InfoInBlasting.MaterialParamName = Row->MaterialParamName;
		
		for (FBlastMaterialParamInfo& Info : Row->MaterialInfos)
		{
			InfoInBlasting.ParamStartChangeTimeInSeconds.Add(Info.StartTimeInSeconds);
			InfoInBlasting.ParamEndChangeTimeInSeconds.Add(Info.EndTimeInSeconds);
			InfoInBlasting.ParamStartValues.Add(Info.StartValue);
			InfoInBlasting.ParamEndValues.Add(Info.EndValue);
			InfoInBlasting.NowValues.Add(Info.StartValue);
			InfoInBlasting.MaterialOwnedCompNames.Add(Info.MaterialOwnedCompName);
			BlastEndTime = FMath::Max(BlastEndTime, Info.EndTimeInSeconds);
		}
	}

	ShowSceneCompByName(FringesMeshNamePrefix, true, true);
	if(UKismetSystemLibrary::IsDedicatedServer(this))
	{
		InfoInBlasting.bInBlasting = false;
		GetWorld()->GetTimerManager().SetTimer(HandleEndPlayForServer, [&]()
		{
			HandleEndPlayForServer.Invalidate();
			ShowSceneCompByName(TopBlastBuildingsMeshNamePrefix, false, false);
		}, BlastEndTime, false);
		return;
	}
	

	StartEffect();

	if (StartBlastDelegate.IsBound())
	{
		StartBlastDelegate.Broadcast();
	}
}

void ABlastMultiplePiecesBuildingActor::StartEffect()
{
	FString ClassName = GetClass()->GetName();
	ClassName = ClassName.Mid(0,ClassName.Len() - 2); 
	const FString ContextString;
	const FBuildingTopBlastInfo* Row = BuildingPartInfo->FindRow<FBuildingTopBlastInfo>(*ClassName, ContextString);
	if (!Row)
	{
		return;
	}

	if(Row->EffectInfos.IsEmpty())
	{
		return;
	}

	TArray<UActorComponent*> NiagaComponents;
	GetComponents(UNiagaraComponent::StaticClass(), NiagaComponents);
	for (UActorComponent* Comp : NiagaComponents)
	{
		const UNiagaraComponent *NiagaraComponent = Cast<UNiagaraComponent>(Comp);
		for (const FEffectInfo& BlastEffectsInfo : Row->EffectInfos)
		{
			if (Comp->GetName() == BlastEffectsInfo.EffectName)
			{
				TSoftObjectPtr<UNiagaraComponent> CompPtr(NiagaraComponent);
				
				GetWorld()->GetTimerManager().SetTimer(HandleStartPlayForEffect, [&, CompPtr]()
				{
					HandleStartPlayForEffect.Invalidate();
					if (CompPtr.IsValid())
					{
						CompPtr->SetVisibility(true);
						CompPtr->Activate(true);
					}

					
					GetWorld()->GetTimerManager().SetTimer(HandleEndPlayForEffect, [&, CompPtr]()
					{
						HandleEndPlayForEffect.Invalidate();
						if (CompPtr.IsValid())
						{
							CompPtr->Deactivate();
							CompPtr->SetVisibility(false);
						}
					}, BlastEffectsInfo.EndTime, false);
					
				}, BlastEffectsInfo.StartTime != 0? BlastEffectsInfo.StartTime: 0.01, false);
			}
		}
	}
}

// Called every frame
void ABlastMultiplePiecesBuildingActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	UpdateBlasting();
	
}

void ABlastMultiplePiecesBuildingActor::UpdateBlasting()
{
	if(!InfoInBlasting.bInBlasting)
	{
		return;
	}
	
	const UWorld* World = GetWorld();
	const float NowTime = World ? World->GetTimeSeconds() : 0.f;

	const float TimePassed = NowTime - InfoInBlasting.BlastingStartTime;

	if (InfoInBlasting.TotalShowTime > 0 && TimePassed > InfoInBlasting.TotalShowTime)
	{
		ShowSceneCompByName(TopBlastBuildingsMeshNamePrefix, false, false);
		InfoInBlasting.bInBlasting = false;
		return;
	}

	bool InInterpolation = false;
	for (int Index = 0; Index < InfoInBlasting.ParamStartValues.Num(); ++Index)
	{
		if(InfoInBlasting.ParamStartChangeTimeInSeconds[Index] > TimePassed)
		{
			InInterpolation = true;
			InfoInBlasting.NowValues[Index] = InfoInBlasting.ParamStartValues[Index];
		}
		else if (InfoInBlasting.ParamEndChangeTimeInSeconds[Index] < TimePassed)
		{
			if (InfoInBlasting.NowValues[Index] != InfoInBlasting.ParamEndValues[Index])
			{
				InInterpolation = true;
			}
			InfoInBlasting.NowValues[Index] = InfoInBlasting.ParamEndValues[Index];
		}
		else
		{
			InInterpolation = true;
			InfoInBlasting.NowValues[Index] = InfoInBlasting.ParamStartValues[Index] +
				(TimePassed - InfoInBlasting.ParamStartChangeTimeInSeconds[Index]) * (InfoInBlasting.ParamEndValues[Index] - InfoInBlasting.ParamStartValues[Index])
			/(InfoInBlasting.ParamEndChangeTimeInSeconds[Index] - InfoInBlasting.ParamStartChangeTimeInSeconds[Index]);
		}
	}

	if (InInterpolation)
	{
		TMap<FString, TArray<float>> Values;
		for (int Index = 0; Index < InfoInBlasting.ParamStartValues.Num(); ++Index)
		{
			if (!Values.Contains(InfoInBlasting.MaterialOwnedCompNames[Index]))
			{
				Values.Add(InfoInBlasting.MaterialOwnedCompNames[Index], TArray<float>());
			}
			Values[InfoInBlasting.MaterialOwnedCompNames[Index]].Add(InfoInBlasting.NowValues[Index]);
		}
		for (auto Comp: BuildingComp.FindOrAdd(TopBlastBuildingsMeshNamePrefix))
		{
			if (Values.Contains(Comp->GetName()))
			{
				if (UMeshComponent* MeshComp = Cast<UMeshComponent>(Comp))
				{
					MeshComp->SetScalarParameterValueOnMaterials(*InfoInBlasting.MaterialParamName,Values[Comp->GetName()]);
				}
			}
		}
		
		
	}
	else
	{
		if (!InfoInBlasting.bOnBlastPlayEnd)
		{
			ShowSceneCompByName(DebrisesMeshNamePrefix, true, true);
			InfoInBlasting.bOnBlastPlayEnd = true;
		}
		if (InfoInBlasting.TotalShowTime < 0)
		{
			InfoInBlasting.bInBlasting = false;
		}
	}
}