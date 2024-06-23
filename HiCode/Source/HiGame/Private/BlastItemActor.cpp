// Fill out your copyright notice in the Description page of Project Settings.


#include "BlastItemActor.h"

#include "Field/FieldSystemNoiseAlgo.h"
#if WITH_EDITOR
#include "Selection.h"
const FString AnchorBoundingBoxNamePrefix = TEXT("Pivot_box");
#endif

bool ABlastItemActor::Init()
{
#if WITH_EDITOR
	PrimaryActorTick.bCanEverTick = true;
	AnchorBoxTransform = FTransform::Identity;
	
#endif
	
	DummyRoot = CreateDefaultSubobject<USceneComponent>(TEXT("RootComponent"));

    GeometryCollectionComponent = CreateDefaultSubobject<UGeometryCollectionComponent>(TEXT("GeometryCollectionComponent"));
	GeometryCollectionComponent->SetupAttachment(DummyRoot);

	RootComponent = DummyRoot;
	return true;
}
// Sets default values
ABlastItemActor::ABlastItemActor():
Super()
{
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	Init();
}

ABlastItemActor::ABlastItemActor(const FObjectInitializer& ObjectInitializer):
Super(ObjectInitializer)
{
 	Init();
}

// Called when the game starts or when spawned
void ABlastItemActor::BeginPlay()
{
	Super::BeginPlay();
}
void ABlastItemActor::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);
	if(TimerHandleDelayInit.IsValid())
	{
		GetWorld()->GetTimerManager().ClearTimer(TimerHandleDelayInit);
	}
}

// Called every frame
void ABlastItemActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

#if WITH_EDITOR
	//放这里等component全部初始化好后初始化
	if (!bUseAnchorBox)
	{
		TArray<UActorComponent*> Components;
		GetComponents(UStaticMeshComponent::StaticClass(), Components);
		for (UActorComponent* Comp : Components)
		{
			if (Comp->GetName().StartsWith(AnchorBoundingBoxNamePrefix))
			{
				const USceneComponent* SceneComp = Cast<USceneComponent>(Comp);
				AnchorBoxTransform = SceneComp->GetRelativeTransform();
				bUseAnchorBox = true;
				break;
			}
		}
	}
	// 这里放tick里去主动更新的原因是
	// 1.像end贴地操作更改坐标并不能在OnPropertyChanged中获取.
	// 2.PropertyChange中只有在移动后才会触发，不能实时改动。
	if(IsValid(FieldSystemActor))
	{
		if (bUseAnchorBox )
		{
			const FTransform NewTrans = AnchorBoxTransform * GetRootComponent()->GetComponentTransform();
			if (!NewTrans.Equals(FieldSystemActor->GetTransform()))
			{
				FieldSystemActor->SetActorTransform(NewTrans);
			}
		}
		else
		{
			FVector Origin(FVector::ZeroVector);
			if (GeometryCollectionComponent)
			{
				const FBoxSphereBounds Bounds = GeometryCollectionComponent->GetLocalBounds();
				Origin = Bounds.GetBox().GetCenter();
				Origin.Z = 0;
			}
			FTransform BoxTrans;
			BoxTrans.SetLocation(Origin);
			const FTransform FieldSystemActorTransform = BoxTrans * GetActorTransform();
			const FVector Location = FieldSystemActorTransform.GetLocation();
			const FRotator Rotation = FieldSystemActorTransform.GetRotation().Rotator();
			
			if (!(FieldSystemActor->GetActorLocation().Equals(Location) && FieldSystemActor->GetActorRotation().Equals(Rotation)))
            {
				//FieldSystemActor->SetActorTransform(GetActorTransform());
            	FieldSystemActor->SetActorLocation(Location);
            	FieldSystemActor->SetActorRotation(Rotation);
            }
		}
		
	}
#endif
	
}

#if WITH_EDITOR
void ABlastItemActor::DeleteAnchor()
{
	if(!GIsEditor)
	{
		return;
	}
	
	if (IsValid(FieldSystemActor))
	{
		GeometryCollectionComponent->InitializationFields.Empty();
		FieldSystemActor->Destroy();
	}
}

void ABlastItemActor::PostActorCreated()
{
	Super::PostActorCreated();
	
	if(!GIsEditor)
    {
    	return;
    }
	GetWorld()->GetTimerManager().SetTimer(TimerHandleDelayInit, [&]()
	{
		TimerHandleDelayInit.Invalidate();
		// for copy actor
		FieldSystemActor = nullptr;
		if (IsValid(GeometryCollectionComponent))
		GeometryCollectionComponent->InitializationFields.Empty();
		InitFieldsForGeometryCollection();
	}, 1, false);
}

void ABlastItemActor::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
	if(!GIsEditor)
	{
		return;
	}
	const FName PropertyName = PropertyChangedEvent.MemberProperty ? PropertyChangedEvent.MemberProperty->GetFName() : NAME_None;

	if (PropertyName == FName(TEXT("GeometryCollectionComponent")))
	{
		GeometryCollectionComponent->InitializationFields.Empty();
		InitFieldsForGeometryCollection();
	}
	else if (PropertyName == TEXT("bAutoGenerateAnchor"))
	{
		if (bAutoGenerateAnchor)
		{
			InitFieldsForGeometryCollection();
		}
		else
		{
			DeleteAnchor();
		}
	}
}

void ABlastItemActor::InitFieldsForGeometryCollection()
{
	if (!bAutoGenerateAnchor)
	{
		return;
	}
	if(!GIsEditor)
	{
		return;
	}
	// 用自带类
	if(IsValid(GeometryCollectionComponent) && GetWorld() &&
	(GeometryCollectionComponent->InitializationFields.IsEmpty() || !IsValid(GeometryCollectionComponent->InitializationFields[0])))
	{
		if (!IsValid(FieldSystemActor))
		{
			if (IsValid(FieldSystemActorClass))
			{
				auto const Location = GetActorLocation();
				auto const Rotation = GetActorRotation();
				FieldSystemActor = Cast<AFieldSystemActor>(GetWorld()->SpawnActor(*FieldSystemActorClass, &Location, &Rotation));
				FieldSystemActor->SetFolderPath(TEXT("AUTO_GEN_DO_NOT_REMOVE"));
			}
		}
		if (IsValid(FieldSystemActor))
		{
			const FBoxSphereBounds Bounds = GeometryCollectionComponent->GetLocalBounds();
			const FVector FieldBox = Bounds.BoxExtent * 2 * 0.01;
			FieldSystemActor->SetActorScale3D(FVector(FieldBox.X, FieldBox.Y, FieldBox.Z * 0.2));
			//FieldSystemActor->SetActorRelativeLocation(FVector(0, 0, Bounds.BoxExtent.Z* -0.2));
			GeometryCollectionComponent->InitializationFields.Empty();
			GeometryCollectionComponent->InitializationFields.Add(FieldSystemActor);

			if (bUseAnchorBox )
			{
				const FTransform NewTrans = AnchorBoxTransform * GetRootComponent()->GetComponentTransform();
				FieldSystemActor->SetActorTransform(NewTrans);
			}
			else
			{
				FieldSystemActor->SetActorLocation(GetActorLocation());
				FieldSystemActor->SetActorRotation(GetActorRotation());
			}
			
		}
		return;
	}
}
#endif

