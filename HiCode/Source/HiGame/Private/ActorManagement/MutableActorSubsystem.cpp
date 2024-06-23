#include "ActorManagement/MutableActorSubsystem.h"

#include "GlobalActorsSubsystem.h"
#include "LandscapeStreamingProxy.h"
#include "EdRuntime/HiEdRuntime.h"
#include "WorldPartition/WorldPartition.h"
#include "EngineUtils.h"
#include "GameplayEntitySubsystem.h"
#include "Kismet/KismetSystemLibrary.h"
#if WITH_EDITOR && LQT_DISTRIBUTED_DS
#include "DistributedDSUtils.h"
#endif
DEFINE_LOG_CATEGORY(LogMutableActor);

void UMutableActorSubsystem::Initialize(FSubsystemCollectionBase& Collection)
{
	Super::Initialize(Collection);
	InitializeScript();
}


void UMutableActorSubsystem::PostInitialize()
{
	UE_LOG(LogTemp, Log, TEXT("UMutableActorSubsystem::PostInitialize %s"), *GetName());
	Super::PostInitialize();
	UWorld* World = GetWorld();
	auto GlobalActorSubsystem = World->GetSubsystem<UGlobalActorsSubsystem>();
	if (GlobalActorSubsystem)
	{
		GlobalActorSubsystem->OnGlobalActorRegister.AddUObject(this, &UMutableActorSubsystem::OnGlobalActorRegister);
	}
	auto GameplayEntitySubsystem = World->GetSubsystem<UGameplayEntitySubsystem>();
	if (GameplayEntitySubsystem)
	{
		GameplayEntitySubsystem->GetOnSyncLevelActorDelegate().AddUObject(this, &UMutableActorSubsystem::OnSyncLevelActorScript);
	}
	World->OnWorldBeginPlay.AddUObject(this, &UMutableActorSubsystem::OnWorldBeginPlayDelegate);
#if WITH_EDITOR && LQT_DISTRIBUTED_DS
	if(!UKismetSystemLibrary::IsServer(World))
	{
		if (FDistributedDSUtils::IsUseLoadRange())
		{
			GetWorld()->SetUseDistributedRegion(true);
			GetWorld()->SetDistributedRegionList(FDistributedDSUtils::GetLoadRange());
			GEngine->Exec(World, TEXT("wp.Runtime.HLOD 0"));
		}
		else
		{
			GEngine->Exec(World, TEXT("wp.Runtime.HLOD 1"));
		}
		
	}
#endif
	PostInitializeScript();
}

void UMutableActorSubsystem::Deinitialize()
{
	UE_LOG(LogTemp, Log, TEXT("UMutableActorSubsystem::Deinitialize %s"), *GetName());
	DeinitializeScript();
}

UWorld* UMutableActorSubsystem::GetWorldScript()
{
	return GetWorld();
}

void UMutableActorSubsystem::OnWorldBeginPlay(UWorld& InWorld)
{
	
}

void UMutableActorSubsystem::OnWorldBeginPlayDelegate()
{
	OnWorldBeginPlayScript();
}

void UMutableActorSubsystem::Tick(float DeltaTime)
{
	ReceiveTick(DeltaTime);
}



void UMutableActorSubsystem::LoadFileToJsonWrapper(const FString EditorId, const FString& FilePath)
{
	const FString FileContents = UHiEdRuntime::LoadFileToString(FilePath);
	DecodeStringToJson(EditorId, FileContents);
}

void UMutableActorSubsystem::DecodeStringToJson(const FString EditorId, const FString& JsonString)
{
	FJsonObjectWrapper JsonWrapper;
	if (JsonWrapper.JsonObjectFromString(JsonString))
	{
		JsonObjectWrapperDatas.Add(EditorId, JsonWrapper);
	}
}

const FJsonObjectWrapper& UMutableActorSubsystem::GetJsonObjectWrapper(const FString EditorId)
{
	if (ContainsInJsonObjectWrapperDatas(EditorId))
	{
		return JsonObjectWrapperDatas[EditorId];
	}
	return DefaultJson;
}

void UMutableActorSubsystem::ClearJsonObjectWrapperDatas()
{
	JsonObjectWrapperDatas.Reset();
}

void UMutableActorSubsystem::AddToJsonObjectWrapperDatas(const FString EditorId, const FJsonObjectWrapper JsonData)
{
	JsonObjectWrapperDatas.Add(EditorId, JsonData);
}

void UMutableActorSubsystem::RemoveFromJsonObjectWrapperDatas(const FString EditorId)
{
	if (ContainsInJsonObjectWrapperDatas(EditorId))
	{
		JsonObjectWrapperDatas.Remove(EditorId);
	}
}

bool UMutableActorSubsystem::ContainsInJsonObjectWrapperDatas(const FString EditorId)
{
	return JsonObjectWrapperDatas.Contains(EditorId);
}

void UMutableActorSubsystem::ClearSpawnedActors()
{
	SpawnedActors.Reset();
}

void UMutableActorSubsystem::AddToSpawnedActors(const FString EditorId, const AActor* Actor)
{
	SpawnedActors.Add(EditorId, Actor);
}

void UMutableActorSubsystem::RemoveFromSpawnedActors(const FString EditorId)
{
	if (ContainsInSpawnedActors(EditorId))
	{
		SpawnedActors.Remove(EditorId);
	}
}

bool UMutableActorSubsystem::ContainsInSpawnedActors(const FString EditorId)
{
	return SpawnedActors.Contains(EditorId);
}

const AActor* UMutableActorSubsystem::GetSpawnedActor(const FString EditorId)
{
	if (ContainsInSpawnedActors(EditorId))
	{
		return SpawnedActors[EditorId];
	}
	return nullptr;
}

void UMutableActorSubsystem::ClearOctree()
{
	Octree.Destroy();
}

void UMutableActorSubsystem::AddElementToOctree(const FString EditorId, const FVector Location)
{
	Octree.AddElement(FObjectInfo(EditorId, Location));
}

void UMutableActorSubsystem::UpdateElementInOctree(const FString EditorId, const FVector Location)
{
	// todo(dougzhang):
}

TArray<FString> UMutableActorSubsystem::FindElementsFromOctree(const FVector Location, const double Radius)
{
	TArray<FString> Result;
	Octree.FindElementsWithBoundsTest(FBoxCenterAndExtent(Location, FVector(Radius, Radius, Radius)), [&Result](const FObjectInfo& Info)
	{
		Result.Add(Info.EditorID);	
	});
	return Result;	
}

TArray<FString> UMutableActorSubsystem::FindAllElementsFromOctree()
{
	TArray<FString> Result;
	Octree.FindAllElements([&Result](const FObjectInfo& Info)
	{
		Result.Add(Info.EditorID);	
	});
	return Result;
}

bool UMutableActorSubsystem::IsFilterByLandscapeEnabled() const
{
	UWorld* World = GetWorld();
	if (World->WorldType == EWorldType::PIE && World->GetWorldPartition())
	{
		// enabled only in pie and in the map with world partition
		return true;
	}
	return false;
}


void UMutableActorSubsystem::GetLandscapeBoundingBoxList(TArray<FBox>& BoxList) const
{
	UWorld* World = GetWorld();
	TActorIterator<ALandscapeStreamingProxy> LandscapeItr = TActorIterator<ALandscapeStreamingProxy>(World);
	for (; LandscapeItr; ++LandscapeItr)
	{
		ALandscapeStreamingProxy* LandscapeStreamingProxy = (*LandscapeItr);
		FVector Origin, Extent;
		LandscapeStreamingProxy->GetActorBounds(false, Origin, Extent);
		BoxList.Emplace(FBox(Origin - Extent, Origin + Extent));
	}
}



