// Copyright Epic Games, Inc. All Rights Reserved.

#include "AsyncAction_CreateActorAsync.h"

#include "LevelSequence.h"
#include "LevelSequenceActor.h"
#include "Animation/SkeletalMeshActor.h"
#include "Engine/AssetManager.h"
#include "Engine/StreamableManager.h"
#include "Blueprint/WidgetBlueprintLibrary.h"
#include "Engine/Engine.h"
#include "Engine/GameInstance.h"
#include "Engine/LocalPlayer.h"

UAsyncAction_CreateActorAsync::UAsyncAction_CreateActorAsync(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

UAsyncAction_CreateActorAsync* UAsyncAction_CreateActorAsync::CreateActorAsync(UObject* WorldContextObject, TSoftObjectPtr<UObject> Asset)
{
	if (Asset.IsNull())
	{
		FFrame::KismetExecutionMessage(TEXT("CreateActorAsync was passed a null aset"), ELogVerbosity::Error);
		return nullptr;
	}

	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::LogAndReturnNull);
	UAsyncAction_CreateActorAsync* Action = NewObject<UAsyncAction_CreateActorAsync>();
	Action->SoftObjectPath = Asset.ToSoftObjectPath();
	Action->World = World;
	Action->RegisterWithGameInstance(World);

	return Action;
}

UAsyncAction_CreateActorAsync* UAsyncAction_CreateActorAsync::CreateActorAsyncInLua(UWorld* World, const FString& AssetPath)
{
	//const FAssetRegistryModule& AssetRegistryModule = FModuleManager::GetModuleChecked<FAssetRegistryModule>("AssetRegistry");
	//const IAssetRegistry& AssetRegistry = AssetRegistryModule.Get();
	//const FAssetData AssetData = AssetRegistry.GetAssetByObjectPath(FSoftObjectPath(*AssetPath));
	
	UAsyncAction_CreateActorAsync* Action = NewObject<UAsyncAction_CreateActorAsync>();
	Action->SoftObjectPath = FSoftObjectPath(*AssetPath);
	Action->World = World;
	Action->RegisterWithGameInstance(World);
	//UE_LOG(LogTemp, Warning, TEXT("call CreateActorAsyncInLua[%s][%s]"), *AssetPath, *(Action->SoftObjectPath.ToString()));
	return Action;
}

UAsyncAction_CreateActorAsync* UAsyncAction_CreateActorAsync::CreateActorWithObjectPathAsync(UWorld* World, const FSoftObjectPath& SoftObjectPath)
{
	UAsyncAction_CreateActorAsync* Action = NewObject<UAsyncAction_CreateActorAsync>();
	Action->SoftObjectPath = SoftObjectPath;
	Action->World = World;
	Action->RegisterWithGameInstance(World);
	return Action;
}

void UAsyncAction_CreateActorAsync::Activate()
{
	TWeakObjectPtr<UAsyncAction_CreateActorAsync> LocalWeakThis(this);
	StreamingHandle = UAssetManager::Get().GetStreamableManager().RequestAsyncLoad(
		SoftObjectPath,
		FStreamableDelegate::CreateUObject(this, &ThisClass::OnAssetLoaded),
		FStreamableManager::AsyncLoadHighPriority
	);
	
}

void UAsyncAction_CreateActorAsync::Cancel()
{
	Super::Cancel();

	if (StreamingHandle.IsValid())
	{
		StreamingHandle->CancelHandle();
		StreamingHandle.Reset();
	}
}

void UAsyncAction_CreateActorAsync::OnAssetLoaded()
{
	// If the load as successful, create it, otherwise don't complete this.
	// create actor
	AActor* RetActor = nullptr;
	UObject* Asset = StreamingHandle->GetLoadedAsset();
	if(IsValid(Asset))
	{
		if (Asset->GetClass()->IsChildOf(UStaticMesh::StaticClass()))
        {
        	AStaticMeshActor *StaticMeshActor = World->SpawnActor<AStaticMeshActor>();
        	UStaticMesh* StaticMesh = Cast<UStaticMesh>(Asset);
        	StaticMeshActor->GetStaticMeshComponent()->SetMobility(EComponentMobility::Movable);
        	StaticMeshActor->GetStaticMeshComponent()->SetStaticMesh(StaticMesh);
        	StaticMeshActor->MarkComponentsRenderStateDirty();
        	RetActor = StaticMeshActor;
        }
        else if (Asset->GetClass()->IsChildOf(USkeletalMesh::StaticClass()))
        {
        	USkeletalMesh* SkeletalMesh = Cast<USkeletalMesh>(Asset);
        	ASkeletalMeshActor* SkeletalMeshActor = World->SpawnActor<ASkeletalMeshActor>();
        	SkeletalMeshActor->GetSkeletalMeshComponent()->SetMobility(EComponentMobility::Movable);
        	SkeletalMeshActor->GetSkeletalMeshComponent()->SetSkeletalMesh(SkeletalMesh);
        	RetActor = SkeletalMeshActor;
        }
        else if (Asset->GetClass()->IsChildOf(UBlueprint::StaticClass()))
        {
        	const UBlueprint* Blueprint = Cast<UBlueprint>(Asset);
        	AActor* BlueprintActor = World->SpawnActor<AActor>(Blueprint->GeneratedClass);
        	RetActor = BlueprintActor;
        }
        else if (Asset->GetClass()->IsChildOf(ULevelSequence::StaticClass()))
        {
        	ULevelSequence* LevelSequence = Cast<ULevelSequence>(Asset);
        	ALevelSequenceActor* LevelSequenceActor = World->SpawnActor<ALevelSequenceActor>();
        	LevelSequenceActor->SetSequence(LevelSequence);
        
        	// Always initialize the player so that the playback settings/range can be initialized from editor.
        	LevelSequenceActor->InitializePlayer();
        	//if (LevelSequenceActor->SequencePlayer)
        	//{
        	//	LevelSequenceActor->SequencePlayer->SetPlaybackPosition(FMovieSceneSequencePlaybackParams(LevelSequenceActor->SequencePlayer->GetEndTime().AsSeconds(), EUpdatePositionMethod::Jump));
        	//}
        	
        	RetActor = LevelSequenceActor;
        }
        else
        {
        	UE_LOG(LogTemp, Warning, TEXT("CreateActorAsync : %s not support!)"), *(Asset->GetClass()->GetName()));
        }
	}
	
	OnComplete.Broadcast(RetActor);
	
	if (OnComplete2.IsBound())
	{
		OnComplete2.Execute(RetActor);
	}
	
	StreamingHandle.Reset();
	SetReadyToDestroy();
}