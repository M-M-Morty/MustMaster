// Fill out your copyright notice in the Description page of Project Settings.


#include "BlastSimpleBuildingActor.h"
#include "NiagaraComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Actions/AsyncAction_CreateAssetAsync.h"
#include "Materials/MaterialInstanceConstant.h"
#include "Materials/MaterialInstanceDynamic.h"
const FString DebrisMeshNamePrefix = TEXT("Debris_");
const FString FringeMeshNamePrefix = TEXT("Fringe_");
const FString ExtraCollisionesBeforeBlastPrefix = TEXT("ExtraCollisionBeforeBlast_");
// Sets default values
ABlastSimpleBuildingActor::ABlastSimpleBuildingActor()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("RootComponent"));
	RootComponent->SetWorldTransform(FTransform::Identity);
	RootComponent->Mobility = EComponentMobility::Static;

	MainBuilding = CreateDefaultSubobject<UStaticMeshComponent>("MainBuilding");
	MainBuilding->Mobility = EComponentMobility::Static;
	MainBuilding->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
	
	BaseBrokenBuilding = CreateDefaultSubobject<UStaticMeshComponent>("BaseBrokenBuilding");
	BaseBrokenBuilding->Mobility = EComponentMobility::Static;
	BaseBrokenBuilding->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);

	TopBlastBuilding = CreateDefaultSubobject<UStaticMeshComponent>("TopBlastBuilding");
	TopBlastBuilding->Mobility = EComponentMobility::Static;
	TopBlastBuilding->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);


	BaseCollision = CreateDefaultSubobject<UStaticMeshComponent>("BaseCollision");
	BaseCollision->Mobility = EComponentMobility::Static;
	BaseCollision->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
	
	TopCollision = CreateDefaultSubobject<UStaticMeshComponent>("TopCollision");
	TopCollision->Mobility = EComponentMobility::Static;
	TopCollision->AttachToComponent(RootComponent, FAttachmentTransformRules::KeepRelativeTransform);
	
}

void ABlastSimpleBuildingActor::StartBlasting(const FString& PartName)
{
	if(PartName == BaseCollision->GetName())
	{
		return;
	}

	if(bHasBlasted)
	{
		return;
	}
	bHasBlasted = true;
	
	MainBuilding->SetVisibility(false);
	MainBuilding->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	TopCollision->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BaseCollision->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	BaseBrokenBuilding->SetVisibility(true);
	BaseBrokenBuilding->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	TopBlastBuilding->SetVisibility(true);
	TopBlastBuilding->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
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

		if (Row->TotalBlastPlayTime > 0)
		{
			InfoInBlasting.TotalBlastTime = Row->TotalBlastPlayTime;
			InfoInBlasting.bInBlasting = false;
			InfoInBlasting.TotalShowTime = FMath::Max(InfoInBlasting.TotalShowTime, InfoInBlasting.TotalBlastTime + 0.01);
		}
		else
		{
			for (FBlastMaterialParamInfo& Info : Row->MaterialInfos)
            {
            	InfoInBlasting.ParamStartChangeTimeInSeconds.Add(Info.StartTimeInSeconds);
            	InfoInBlasting.ParamEndChangeTimeInSeconds.Add(Info.EndTimeInSeconds);
            	InfoInBlasting.ParamStartValues.Add(Info.StartValue);
            	InfoInBlasting.ParamEndValues.Add(Info.EndValue);
            	InfoInBlasting.NowValues.Add(Info.StartValue);
				BlastEndTime = FMath::Max(BlastEndTime, Info.EndTimeInSeconds);
            }
		}
	}

	StartSkeletonBlastingAnimation();
	ShowSceneCompByName(FringeMeshNamePrefix, true, true);
	ShowSceneCompByName(ExtraCollisionesBeforeBlastPrefix, false, false);
	
	if(UKismetSystemLibrary::IsDedicatedServer(this))
	{
		InfoInBlasting.bInBlasting = false;
	
		GetWorld()->GetTimerManager().SetTimer(HandleEndPlayForServer, [&]()
		{
			HandleEndPlayForServer.Invalidate();
			OnBlastPlayEnd();
		}, BlastEndTime, false);
		return;
	}
	
	if (InfoInBlasting.TotalBlastTime > 0)
	{
		StartMaterialBlast();
	}
	StartEffect();

	if (StartBlastDelegate.IsBound())
	{
		StartBlastDelegate.Broadcast();
	}
}

void ABlastSimpleBuildingActor::SetMaterialAutoPlay(bool bAutoPlay)
{
	bool bChanged = false;
	int MtlIdx = 0;
    for (auto Mtl : TopBlastBuilding->GetMaterials())
    {
    	if (bAutoPlay)
    	{
    		UMaterialInstanceDynamic* MID = UMaterialInstanceDynamic::Create(Mtl, this);
            TopBlastBuilding->SetMaterial(MtlIdx++, MID);
            MID->SetScalarParameterValue( TEXT("Auto Playback"), 1.0);
    	}
	   
    }
	TopBlastBuilding->MarkRenderInstancesDirty();
}

void ABlastSimpleBuildingActor::StartMaterialBlast()
{
	SetMaterialAutoPlay(true);
	
	float T = InfoInBlasting.TotalShowTime - InfoInBlasting.TotalBlastTime;
	GetWorld()->GetTimerManager().SetTimer(TimerHandleEndMaterialBlast, [=]()
	{
		TimerHandleEndMaterialBlast.Invalidate();
		OnBlastPlayEnd();
		GetWorld()->GetTimerManager().SetTimer(TimerHandleEndPlay, [=]()
		{
			TimerHandleEndPlay.Invalidate();
			//SetMaterialAutoPlay(false);
			TopBlastBuilding->SetVisibility(false);
			
		},  InfoInBlasting.TotalShowTime - InfoInBlasting.TotalBlastTime, false);
		
	}, InfoInBlasting.TotalBlastTime, false);
}

void ABlastSimpleBuildingActor::StartSkeletonBlastingAnimation() const
{
	FString ClassName = GetClass()->GetName();
	ClassName = ClassName.Mid(0,ClassName.Len() - 2); 
	const FString ContextString;
	const FBuildingTopBlastInfo* Row = BuildingPartInfo->FindRow<FBuildingTopBlastInfo>(*ClassName, ContextString);
	if (!Row)
	{
		return;
	}
	
	TArray<UActorComponent*> SkeletonComponents;
	GetComponents(USkeletalMeshComponent::StaticClass(), SkeletonComponents);

	for (UActorComponent* Comp : SkeletonComponents)
	{
		USkeletalMeshComponent* SkeletalMeshComp = Cast<USkeletalMeshComponent>(Comp);
		const FString& Name = Comp->GetName();
		for (const FSkeletonAnimInfo& Info : Row->SkeletonAnimInfos)
		{
			if (Info.SkeletonCompName == Name && !Info.SkeletonDieAnimPath.IsEmpty())
			{
				UAsyncAction_CreateAssetAsync * CreateAssetAsyncAction = UAsyncAction_CreateAssetAsync::CreateAssetAsyncUsePath(GetWorld(), Info.SkeletonDieAnimPath);
                		
                CreateAssetAsyncAction->OnComplete2.BindLambda([=](UObject* Asset)
                {
                	if (UAnimSequence* Sequence = Cast<UAnimSequence> (Asset))
                	{
                		SkeletalMeshComp->PlayAnimation(Sequence, false);
                	}
                });
        
                CreateAssetAsyncAction->Activate();
			}
		}
		
	}
}

void ABlastSimpleBuildingActor::StartEffect()
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
				GetWorld()->GetTimerManager().SetTimer(EffectHandleStartPlay, [&, CompPtr]()
				{
					EffectHandleStartPlay.Invalidate();
					if (CompPtr.IsValid())
					{
						CompPtr->SetVisibility(true);
						CompPtr->Activate();
					}
					
					GetWorld()->GetTimerManager().SetTimer(EffectHandleEndPlay, [&, CompPtr]()
					{
						EffectHandleEndPlay.Invalidate();
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

void ABlastSimpleBuildingActor::InitBuildingState()
{
	MainBuilding->SetVisibility(true);
	MainBuilding->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	TopCollision->SetVisibility(false);
	TopCollision->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	BaseCollision->SetVisibility(false);
	BaseCollision->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	
	BaseBrokenBuilding->SetVisibility(false);
	BaseBrokenBuilding->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	TopBlastBuilding->SetVisibility(false);
	TopBlastBuilding->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	ShowSceneCompByName(DebrisMeshNamePrefix, false, false);
	ShowSceneCompByName(FringeMeshNamePrefix, false, false);
	ShowSceneCompByName(ExtraCollisionesBeforeBlastPrefix, false, true);
}

// Called when the game starts or when spawned
void ABlastSimpleBuildingActor::BeginPlay()
{
	Super::BeginPlay();
	InitBuildingState();
}

void ABlastSimpleBuildingActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	if (InfoInBlasting.TotalBlastTime > 0)
	{
		SetMaterialAutoPlay(false);
	}
	
	if(HandleEndPlayForServer.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(HandleEndPlayForServer);
	}
	if(TimerHandleEndMaterialBlast.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(TimerHandleEndMaterialBlast);
	}
	if(TimerHandleEndPlay.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(TimerHandleEndPlay);
	}
	if(EffectHandleStartPlay.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(EffectHandleStartPlay);
	}
	if(EffectHandleEndPlay.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(EffectHandleEndPlay);
	}
}
// Called every frame
void ABlastSimpleBuildingActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	UpdateBlasting();
	
}

void ABlastSimpleBuildingActor::ShowSceneCompByName(const FString& PrefixesName, bool bShown, bool bUseCollision)
{
	TArray<UActorComponent*> SceneComponents;
	GetComponents(USceneComponent::StaticClass(), SceneComponents, true);
			
	for (UActorComponent* Comp : SceneComponents)
	{
		if (Comp->GetName().StartsWith(PrefixesName))
		{
			(Cast<USceneComponent>(Comp))->SetVisibility(bShown);
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

void ABlastSimpleBuildingActor::OnBlastPlayEnd()
{
	ShowSceneCompByName(DebrisMeshNamePrefix, true, true);
}

void ABlastSimpleBuildingActor::UpdateBlasting()
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
		/*
		TArray<UActorComponent*> StaticMeshComponents;
		GetComponents(UStaticMeshComponent::StaticClass(), StaticMeshComponents);
		for (UActorComponent* Comp : StaticMeshComponents)
		{
			if (Comp->GetName().StartsWith(DebrisMeshNamePrefix))
			{
				(Cast<UStaticMeshComponent>(Comp))->SetVisibility(false);
			}
		}*/
		
		TopBlastBuilding->SetVisibility(false);
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
		TopBlastBuilding->SetScalarParameterValueOnMaterials(*InfoInBlasting.MaterialParamName, InfoInBlasting.NowValues);
		
	}
	else
	{
		if (!InfoInBlasting.bOnBlastPlayEnd)
		{
			OnBlastPlayEnd();
			InfoInBlasting.bOnBlastPlayEnd = true;
		}
		if (InfoInBlasting.TotalShowTime < 0)
		{
			InfoInBlasting.bInBlasting = false;
		}
	}
}
