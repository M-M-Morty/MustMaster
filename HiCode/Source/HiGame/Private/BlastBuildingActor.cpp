// Fill out your copyright notice in the Description page of Project Settings.


#include "BlastBuildingActor.h"

#include "NiagaraComponent.h"
#include "Components/StaticMeshComponent.h"

// Sets default values
ABlastBuildingActor::ABlastBuildingActor()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void ABlastBuildingActor::BeginPlay()
{
	Super::BeginPlay();
	
	InitializePartSustainRelations();

	TArray<UActorComponent*> CollisionComp = GetComponentsByTag(UStaticMeshComponent::StaticClass(), TEXT("Collision"));
	for (UActorComponent* Comp : CollisionComp)
	{
		NameToCollision.Add(Comp->GetName(), Cast<UStaticMeshComponent>(Comp));
	}
}

void ABlastBuildingActor::InitializePartSustainRelations()
{
	if (IsValid(BuildingPartInfo))
	{
		TArray<FName> RowNames = BuildingPartInfo->GetRowNames();
		for (const FName& Name : RowNames)
		{
			FString ContextString;
			FCBlastBuildingPartInfo* Row = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(Name, ContextString);
			if (Row)
			{
				TArray<FString> SeparatedStrings;
				const int32 nArraySize = Row->SustainPartName.ParseIntoArray(SeparatedStrings, TEXT("#"), false);
				PartSustainRelations.Add(Name.ToString(), SeparatedStrings);
			}
		}
	}
}

// Called every frame
void ABlastBuildingActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	if (!IsValid(BuildingPartInfo))
	{
		return;
	}
	if (bUpdateState)
	{
		bUpdateState = false;
		
		CollisionMeshState.Empty();
		TArray<UActorComponent*> CollisionComp = GetComponentsByTag(UStaticMeshComponent::StaticClass(), TEXT("Collision"));
		for (UActorComponent* Comp : CollisionComp)
		{
			const UStaticMeshComponent* StaticMeshComponent = Cast<UStaticMeshComponent>(Comp);
			const ECollisionEnabled::Type CollisionEnabledType = StaticMeshComponent->GetCollisionEnabled();
			if (CollisionEnabledType == ECollisionEnabled::NoCollision)
			{
				CollisionMeshState.Add(StaticMeshComponent->GetName(), EBuildingPartState::Hide);
			}
			
		}

		// update new quality and center.
		{
			TotalQuality = 0;
			TotalCenterOfGravity = FVector::ZeroVector;
			
			TArray<FName> RowNames = BuildingPartInfo->GetRowNames();
			for (const FName& Name : RowNames)
			{
				if (CollisionMeshState.Contains(Name.ToString()))
				{
					continue;
				}
				FString ContextString;
				if (FCBlastBuildingPartInfo* Row = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(Name, ContextString))
				{
					float Quality = Row->BoundingBox.GetVolume() * 0.01* 0.01 * 0.01 * Row->Density;
					TotalQuality += Quality;
					TotalCenterOfGravity += Row->BoundingBox.GetCenter() * Quality;
				}
			}
			if (TotalQuality > 0)
			{
				TotalCenterOfGravity /= TotalQuality;
			}
				
			
		}
		TArray<FName> RowNames = BuildingPartInfo->GetRowNames();
		bool bNewPartUpdated = false;
		do
		{
			bNewPartUpdated = false;
			for (TMap<FString, TArray<FString>>::TIterator Iter = PartSustainRelations.CreateIterator();  Iter; ++Iter)
			{
				FString RowName = Iter->Key;
			
				if (!CollisionMeshState.Contains(RowName))
				{
					if (!Iter->Value.Num())
					{
						continue;
					}
					bool bSustainPartHasStand = false;
					for (FString& SustainPartName: Iter->Value)
					{
						if (!CollisionMeshState.Contains(SustainPartName))
						{
							bSustainPartHasStand = true;
							break;
						}
					}
					if (!bSustainPartHasStand)
					{
						CollisionMeshState.Add(RowName, EBuildingPartState::Falling);
						SFallingPartInfo NewFallingInfo = GetInitializedFallingPartInfo();
						if (FallingPartInfos.Contains(RowName))
						{
							NewFallingInfo.MovedDistance = FallingPartInfos[RowName].MovedDistance;
							NewFallingInfo.FallingStartVelocity  =  (FallingPartInfos[RowName].FallingLastTime * Gravity + FallingPartInfos[RowName].FallingStartVelocity) * 0.8;
							FallingPartInfos[RowName] = NewFallingInfo;
						}
						FallingPartInfos.Add(RowName, NewFallingInfo);
						bNewPartUpdated = true;
					}
				}
			}
				
		}while (bNewPartUpdated);

		for (TMap<FString, TArray<FString>>::TIterator Iter = PartSustainRelations.CreateIterator();  Iter; ++Iter)
		{
			FString RowName = Iter->Key;
			if (CollisionMeshState.Contains(RowName) && CollisionMeshState[RowName] == EBuildingPartState::Hide&&  FallingPartInfos.Contains(RowName))
			{
				FallingPartInfos.Remove(RowName);
			}
		}
		
	}

	// update falling part
	{
		TArray<UActorComponent*> MainBuildingComp = GetComponentsByTag(UStaticMeshComponent::StaticClass(), TEXT("MainBuilding"));
		
		for (TMap<FString, SFallingPartInfo>::TIterator Iter = FallingPartInfos.CreateIterator();  Iter; ++Iter)
		{
			const UWorld* World = GetWorld();
			
			const float FallingTime = World->GetTimeSeconds() - Iter->Value.FallingStartTime;
			const float DetlaMovingDistance = Iter->Value.FallingStartVelocity * FallingTime + 0.5 * Gravity * FallingTime * FallingTime - (Iter->Value.FallingStartVelocity * Iter->Value.FallingLastTime + 0.5 * Gravity* Iter->Value.FallingLastTime* Iter->Value.FallingLastTime);
			Iter->Value.MovedDistance += DetlaMovingDistance;
			const float TotalMoveDistance = Iter->Value.MovedDistance;
			
			Iter->Value.FallingLastTime = FallingTime;
			FVector Location = NameToCollision[Iter->Key]->GetComponentTransform().GetLocation();
			Location.Z -= 100 * DetlaMovingDistance;
			NameToCollision[Iter->Key]->SetWorldLocation(Location);

			FString ContextString;
			const FCBlastBuildingPartInfo* BuildingPartInfoRow = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(*Iter->Key, ContextString);
			
			for (UActorComponent* Comp : MainBuildingComp)
			{
				UStaticMeshComponent* StaticMeshComponent = Cast<UStaticMeshComponent>(Comp);
				StaticMeshComponent->SetVectorParameterValueOnMaterials(*BuildingPartInfoRow->MaterialTagName, FVector(0, 0, -100 * TotalMoveDistance));
			}

			if (BuildingPartInfoRow->bCrashImmediatelyWithoutSustain || CheckFallingPartCollapse(Iter->Key, Iter.Value()))
			{
				CollapseInC(NameToCollision[Iter->Key].Get());
			}
		}
	}

	UpdateBlasting();
}


void ABlastBuildingActor::UpdateBlasting()
{
	TArray<FString> EndBlastingParts;
	const UWorld* World = GetWorld();
	const float NowTime = World ? World->GetTimeSeconds() : 0.f;
	
	
	for (TMap<FString, SBlastingPartInfo>::TIterator It = BlastingPartInfos.CreateIterator(); It; ++It)
	{
		SBlastingPartInfo& Info = It->Value;
		const float TimePassed = NowTime - Info.StartTime;
		float NewHeight = TimePassed * Info.MoveBackVelocity + Info.BlastStartHeight;
		if (NewHeight > Info.OriginHeight)
		{
			NewHeight = Info.OriginHeight;
		}
		FVector Location = Info.BlastingComp->GetComponentTransform().GetLocation();
		Location.Z = NewHeight;
		Info.BlastingComp->SetWorldLocation(Location);
		
		bool InInterpolation = false;
		
		for (int Index = 0; Index < Info.StartFrameValues.Num(); ++Index)
		{
			if ((Info.NowFrameValues[Index] - Info.EndFrameValues[Index]) * (Info.StartFrameValues[Index] - Info.EndFrameValues[Index]) > 0)
			{
				InInterpolation = true;
				Info.NowFrameValues[Index] = Info.StartFrameValues[Index] + (Info.EndFrameValues[Index] - Info.StartFrameValues[Index]) *TimePassed /Info.LastTimes[Index] ;
			}
			
			if ((Info.StartFrameValues[Index] < Info.EndFrameValues[Index] && Info.NowFrameValues[Index] > Info.EndFrameValues[Index])
				|| (Info.StartFrameValues[Index] > Info.EndFrameValues[Index] && Info.NowFrameValues[Index] < Info.EndFrameValues[Index]))
			{
				Info.NowFrameValues[Index] = Info.EndFrameValues[Index];
			}
			
		}
		if (InInterpolation)
		{
			Info.BlastingComp->SetScalarParameterValueOnMaterials(*Info.MaterialParamName, Info.NowFrameValues);
		}
		else
		{
			if (Info.bInBlasting)
			{
				ShowDebrisInC(It.Key());
			}
			Info.bInBlasting = false;
			if (TimePassed > Info.TotalShowTime)
			{
				if (Info.TotalShowTime > 0)
				{
					Info.BlastingComp->SetVisibility(false);
				}
				
				EndBlastingParts.Add(It.Key());
			}
			
		}
	}

	for (FString& EndPart : EndBlastingParts)
	{
		BlastingPartInfos.Remove(EndPart);
	}
}

void ABlastBuildingActor::StartBlasting(const FString& PartName)
{
	if (BlastingPartInfos.Contains(PartName))
	{
		return;
	}
	if (!IsValid(BuildingPartInfo))
	{
		return;
	}
	const FString ContextString;
	FCBlastBuildingPartInfo* Row = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(*PartName, ContextString);
	if (!Row)
	{
		return;
	}
	if (Row->BlastMeshName.IsEmpty() || Row->BlastMaterialInfos.Num() == 0)
	{
		return;
	}
	SBlastingPartInfo BlastingPartInfo;
	const UWorld* World = GetWorld();
	BlastingPartInfo.bInBlasting = true;
	BlastingPartInfo.StartTime = World ? World->GetTimeSeconds() : 0.f;
	BlastingPartInfo.MaterialParamName = Row->BlastMaterialInfos[0].MaterialParamName;
	BlastingPartInfo.TotalShowTime = Row->BlastTotalShowTime;
	
	float MinBlastTime = FLT_MAX;
	for (FBlastMaterialInfo& Info : Row->BlastMaterialInfos)
	{
		BlastingPartInfo.LastTimes.Add(Info.LastTimeInSeconds);
		BlastingPartInfo.StartFrameValues.Add(Info.StartFrameValue);
		BlastingPartInfo.EndFrameValues.Add(Info.EndFrameValue);
		BlastingPartInfo.NowFrameValues.Add(Info.StartFrameValue);
		if (Info.LastTimeInSeconds < MinBlastTime)
		{
			MinBlastTime = Info.LastTimeInSeconds;
		}
	}
	UStaticMeshComponent * BlastComp = nullptr;
	const FTransform Trans = NameToCollision[PartName]->GetComponentTransform();
	for (UActorComponent* Comp : GetComponents())
	{
		if (Comp->GetName() == Row->BlastMeshName)
		{
			BlastComp = Cast<UStaticMeshComponent>(Comp);
			break;
		}
	}
	if (BlastComp)
	{
		BlastingPartInfo.OriginHeight = BlastComp->GetComponentTransform().GetLocation().Z;
		BlastingPartInfo.BlastStartHeight = Trans.GetLocation().Z;
		BlastingPartInfo.MoveBackVelocity = (BlastingPartInfo.OriginHeight - Trans.GetLocation().Z) / (MinBlastTime * BlastingPartInfo.MoveBackUsedTimeRate);
		BlastComp->SetVisibility(true);
		BlastComp->SetWorldTransform(Trans);
		BlastComp->SetScalarParameterValueOnMaterials(*BlastingPartInfo.MaterialParamName, BlastingPartInfo.NowFrameValues);
		BlastingPartInfo.BlastingComp = BlastComp;
		BlastingPartInfos.Add(PartName, BlastingPartInfo);
	}
}
void ABlastBuildingActor::StartEffect(const FString& PartName)
{
	if(!IsValid(BuildingPartInfo))
	{
		return;
	}
	const FString ContextString;
	const FCBlastBuildingPartInfo* Row = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(*PartName, ContextString);
	if (!Row)
	{
		return;
	}

	if(Row->BlastEffectInfos.IsEmpty())
	{
		return;
	}
	
	for (UActorComponent* Comp : K2_GetComponentsByClass(UNiagaraComponent::StaticClass()))
	{
		const UNiagaraComponent *NiagaraComponent = Cast<UNiagaraComponent>(Comp);
		for (const FBlastEffectsInfo& BlastEffectsInfo : Row->BlastEffectInfos)
		{
			if (Comp->GetName() == BlastEffectsInfo.EffectName)
			{
				TSoftObjectPtr<UNiagaraComponent> CompPtr(NiagaraComponent);
				FTimerHandle TimerHandleStartPlay;
				GetWorld()->GetTimerManager().SetTimer(TimerHandleStartPlay, [&, CompPtr]()
				{
					if (CompPtr.IsValid())
					{
						CompPtr->SetVisibility(true);
						CompPtr->Activate();
					}

					FTimerHandle TimerHandleEndPlay;
					GetWorld()->GetTimerManager().SetTimer(TimerHandleEndPlay, [CompPtr]()
					{
						if (CompPtr.IsValid())
						{
							CompPtr->Deactivate();
							CompPtr->SetVisibility(false);
						}
					}, BlastEffectsInfo.EndTime, false);
					
				}, BlastEffectsInfo.StartTime, false);
			}
		}
	}
}

bool ABlastBuildingActor::CheckFallingPartCollapse(const FString& PartName, const SFallingPartInfo& FallingPart)
{
	if (IsValid(BuildingPartInfo))
	{
		FString ContextString;
		const FCBlastBuildingPartInfo* BuildingPartInfoRow = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(*PartName, ContextString);
		const FBox Bounding = BuildingPartInfoRow->BoundingBox.ShiftBy(FVector(0, 0, -FallingPart.MovedDistance * 100));
		
		FBox GroundBox = FBox(FVector(-100000, -10000, -10), FVector(100000, 10000, 10));
		if (Bounding.Intersect(GroundBox))
		{
			return true;
		}
		TArray<FName> RowNames = BuildingPartInfo->GetRowNames();
		for (const FName& Name : RowNames)
		{
			if (CollisionMeshState.Contains(Name.ToString())) // Hide or Falling
			{
				continue;
			}
			const FCBlastBuildingPartInfo* StaticBuildingPartInfoRow = BuildingPartInfo->FindRow<FCBlastBuildingPartInfo>(*Name.ToString(), ContextString);

			if (Bounding.Intersect(StaticBuildingPartInfoRow->BoundingBox))
			{
				return true;
			}
		}
	}
	return false;
}

SFallingPartInfo ABlastBuildingActor::GetInitializedFallingPartInfo()const
{
	SFallingPartInfo FallingPartInfo;
	const UWorld* World = GetWorld();
	FallingPartInfo.FallingStartTime = World ? World->GetTimeSeconds() : 0.f;
	FallingPartInfo.FallingLastTime = 0;
	FallingPartInfo.MovedDistance = 0;

	return FallingPartInfo;
}
