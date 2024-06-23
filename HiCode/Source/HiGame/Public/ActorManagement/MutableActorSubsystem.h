#pragma once

#include "CoreMinimal.h"
#include "GameplayEntitySubsystem.h"
#include "JsonObjectWrapper.h"
#include "EdRuntime/HiEdRuntimeStruct.h"
#include "MutableActorSubsystem.generated.h"

DECLARE_LOG_CATEGORY_EXTERN(LogMutableActor, Log, All);

UCLASS(Blueprintable, BlueprintType, Abstract)
class UMutableActorSubsystem: public UTickableWorldSubsystem
{
	GENERATED_BODY()

public:

	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void PostInitialize() override;
	virtual void Deinitialize() override;

	virtual void OnWorldBeginPlay(UWorld& InWorld) override;

	void OnWorldBeginPlayDelegate();

	virtual ETickableTickType GetTickableTickType() const override { return ETickableTickType::Always; }
	virtual TStatId GetStatId() const override { RETURN_QUICK_DECLARE_CYCLE_STAT(UMutableActorSubsystem, STATGROUP_Tickables); }
	void Tick(float DeltaTime) override;

	UFUNCTION(BlueprintImplementableEvent)
	void OnGlobalActorRegister(FName GlobalActorName);

	UFUNCTION(BlueprintCallable)
	UWorld* GetWorldScript();

	UFUNCTION(BlueprintImplementableEvent)
	void OnSyncLevelActorScript(const FString& ActorID, int32 ActorCreateType);

	UFUNCTION(BlueprintImplementableEvent)
	void InitializeScript();

	UFUNCTION(BlueprintImplementableEvent)
	void PostInitializeScript();

	UFUNCTION(BlueprintImplementableEvent)
	void OnWorldBeginPlayScript();

	UFUNCTION(BlueprintImplementableEvent)
	void OnMutableActorManagerReadyScript();

	UFUNCTION(BlueprintImplementableEvent)
	void DeinitializeScript();

	UFUNCTION(BlueprintImplementableEvent, meta=(DisplayName = "Tick"))
	void ReceiveTick(float DeltaSeconds);
	
	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void LoadFileToJsonWrapper(const FString EditorId, const FString& FilePath);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void DecodeStringToJson(const FString EditorId, const FString& JsonString);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	const FJsonObjectWrapper& GetJsonObjectWrapper(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void ClearJsonObjectWrapperDatas();

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void AddToJsonObjectWrapperDatas(const FString EditorId, const FJsonObjectWrapper JsonData);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void RemoveFromJsonObjectWrapperDatas(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	bool ContainsInJsonObjectWrapperDatas(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void ClearSpawnedActors();

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void AddToSpawnedActors(const FString EditorId, const AActor* Actor);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void RemoveFromSpawnedActors(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	bool ContainsInSpawnedActors(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	const AActor* GetSpawnedActor(const FString EditorId);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void ClearOctree();

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void AddElementToOctree(const FString EditorId, const FVector Location);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	void UpdateElementInOctree(const FString EditorId, const FVector Location);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	TArray<FString> FindElementsFromOctree(const FVector Location, const double Radius);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	TArray<FString> FindAllElementsFromOctree();

	UFUNCTION(BlueprintCallable)
	bool IsFilterByLandscapeEnabled() const;

	UFUNCTION(BlueprintCallable)
	void GetLandscapeBoundingBoxList(TArray<FBox>& BoxList) const;
	
private:
	/* Editor group_id.suite_id -> Actor maybe should make static for share in multiworlds*/
	TMap<const FString, const FJsonObjectWrapper> JsonObjectWrapperDatas;
	
	/* Editor group_id.suite_id -> Actor*/
	UPROPERTY()
	TMap<FString, const AActor*> SpawnedActors;
	
	/* Editor group_id.suite_id -> Location*/
	TOctree2<struct FObjectInfo, FEdOctreeSemantics> Octree;

	FJsonObjectWrapper DefaultJson;
};