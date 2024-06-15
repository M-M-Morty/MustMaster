// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "LevelSequencePlayer.h"
#include "SequencerTrackInstanceBP.h"
#include "Abilities/GameplayAbilityTargetDataFilter.h"
#include "Abilities/GameplayAbilityTargetTypes.h"
#include "HiAbilities/HiGameplayEffectContext.h"
#include "GameServerSettings.h"
#include "LuaEnv.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "Engine/PostProcessVolume.h"
#include "HiUtilsFunctionLibrary.generated.h"

class AHiPlayerController;
class UNiagaraComponent;
class UTimelineComponent;
class USkeleton;
class UAnimMontage;

USTRUCT()
struct FInt
{
	GENERATED_BODY()
};

USTRUCT()
struct FFloat
{
	GENERATED_BODY()
};

/**
 * 
 */
UCLASS()
class UHiUtilsFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
public:
	UFUNCTION(BlueprintCallable)
    static UClass* FindObjectFromName(const FName& InName);

	UFUNCTION(BlueprintCallable)
	static FString GetEnumPathFromName(const FName& InName);

	UFUNCTION(BlueprintCallable)
	static FString GetStructPathFromName(const FName& InName);

	UFUNCTION(BlueprintCallable)
	static bool FilterPassesForActor(FGameplayTargetDataFilterHandle FilterHandle, const AActor* ActorToBeFiltered);

	UFUNCTION(BlueprintCallable, Category = "HiAbility|TargetData")
	static FGameplayAbilityTargetDataHandle	AbilityTargetDataFromHitResults(const TArray<FHitResult>& HitResults);

	/**
	 * @brief Construct GameplayAbilityTargetData from hits and knock info, FHiGameplayAbilityTargetData_SingleHit.
	 * @param HitResults 
	 * @param KnockInfo 
	 * @return 
	 */
	UFUNCTION(BlueprintCallable, Category = "HiAbility|TargetData")
	static FGameplayAbilityTargetDataHandle	AbilityTargetDataFromHitResultsWithKnockInfo(const TArray<FHitResult>& HitResults, UObject* KnockInfo);

	/**
	 * @brief Construct GameplayAbilityTargetData from hits and knock info, for AOE skills with many hits, FHiGameplayAbilityTargetData_HitArray.
	 * @param HitResults
	 * @param KnockInfo
	 * @param LocationInfo
	 * @return 
	 */
	UFUNCTION(BlueprintCallable, Category = "HiAbility|TargetData")
	static FGameplayAbilityTargetDataHandle	AbilityAOETargetDataFromHitResultsWithKnockInfo(const TArray<FHitResult>& HitResults, UObject* KnockInfo, const FGameplayAbilityTargetingLocationInfo& LocationInfo);
	
	UFUNCTION(BlueprintCallable, Category = "HiAbility|TargetData")
	static FGameplayAbilityTargetDataHandle	AbilityTargetDataArrayFromActors(const TArray<AActor*> Actors , UObject* KnockInfo, const FGameplayAbilityTargetingLocationInfo& LocationInfo);
	
	/** Get KnockInfo from TargetData */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static UObject* GetKnockInfoFromTargetData(const FGameplayAbilityTargetDataHandle& Data, int32 Index);

	/** Get hits of AOE TargetData */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static void GetHitsFromTargetData(const FGameplayAbilityTargetDataHandle& Data, int32 Index, TArray<FHitResult>& Hits);

	/** Get SourceLocation of AOE TargetData */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static void GetSourceLocationFromTargetData(const FGameplayAbilityTargetDataHandle& Data, int32 Index, FGameplayAbilityTargetingLocationInfo& SourceLocation);

	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static void UpdateKnockInfoOfTargetData(const FGameplayAbilityTargetDataHandle& Data, UObject* KnockInfo);

	/** Check specified index target data type. */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static bool IsTargetActorArray(const FGameplayAbilityTargetDataHandle& Data, int32 Index);

	/** Check specified index target data type. */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static bool IsTargetHitArray(const FGameplayAbilityTargetDataHandle& Data, int32 Index);

	/** Check specified index target data type. */
	UFUNCTION(BlueprintPure, Category = "Ability|TargetData")
	static bool IsSingleHitResult(const FGameplayAbilityTargetDataHandle& Data, int32 Index);
	
	UFUNCTION(BlueprintCallable)
	static void FindAllMeshCompsFromBlueprintClass(UClass* Class, TArray<UStaticMeshComponent*>& Comps);

	// UFUNCTION(BlueprintPure, Category = "Ability|EffectContext", Meta = (DisplayName = "SetUserData"))
	// static UObject* EffectContextSetUserData(FGameplayEffectContextHandle EffectContext, UObject* Data);
	//
	// UFUNCTION(BlueprintPure, Category = "Ability|EffectContext", Meta = (DisplayName = "GetUserData"))
	// static UObject* EffectContextGetUserData(FGameplayEffectContextHandle EffectContext);

	UFUNCTION(BlueprintCallable)
	static void RegisterComponent(UActorComponent* Component);
	
	UFUNCTION(BlueprintCallable, Category = "HiAbility|TargetData")
	static float CheckLoadingProgress(const FString& MapName);
	
	UFUNCTION(BlueprintCallable)
	static void DestroyComponent(UActorComponent* Component);
	
	UFUNCTION(BlueprintCallable)
	static bool IsServer(const UObject* WorldContextObject);
	
	UFUNCTION(BlueprintCallable)
	static bool IsClient(const UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable)
	static UObject* GetGWorld();

	UFUNCTION(BlueprintCallable)
	static UGameInstance* GetGGameInstance();

	UFUNCTION(BlueprintCallable)
	static bool IsServerWorld();

	UFUNCTION(BlueprintCallable)
	static bool IsClientWorld();
	
	UFUNCTION(BlueprintCallable)
	static int64 GetNowTimestamp();
	
	UFUNCTION(BlueprintCallable)
	static int64 GetNowTimestampMs();
	
	UFUNCTION(BlueprintCallable)
	static float GetMontagePlayLength(UAnimMontage* Montage);
	
	UFUNCTION(BlueprintCallable)
	static FRotator Rotator_Normalized(const FRotator& Rotation);

	UFUNCTION(BlueprintCallable)
	static void SetMontageBlendInTime(UAnimMontage* Montage, float BlendTime);

	UFUNCTION(BlueprintCallable)
	static void SetMontageBlendOutTime(UAnimMontage* Montage, float BlendTime);

	UFUNCTION(BlueprintCallable)
	static void RegisterLuaConsoleCmd(const FString& CmdName, const FString& CmdHelp);

	UFUNCTION(BlueprintCallable)
	static TSet<FString>& ObjectGetAllCallableFunctionNames(UObject* Object);

	UFUNCTION(BlueprintCallable)
	static void SetMontagePlayRate(USkeletalMeshComponent *Component, UAnimMontage *Montage, float PlayRate);

	UFUNCTION(BlueprintCallable)
	static float GetNiagaraSystemInstanceAge(UNiagaraComponent* NiagaraComponent);

	UFUNCTION(BlueprintCallable)
	static void GetTimelineValueRange(UTimelineComponent* TimelineComponent, float& MinValue, float& MaxValue);

	UFUNCTION(BlueprintCallable)
	static void FindNavPath(AController* Controller, const FVector& GoalLocation, TArray<FVector>& OutPath);

	UFUNCTION(BlueprintCallable)
	static bool GetRandomReachablePointInRadius(AController* Controller, const FVector& Origin, float Radius, FVector& ResultLocation);

	UFUNCTION(BlueprintCallable)
	static bool GetRandomPointInNavigableRadius(AController* Controller, const FVector& Origin, float Radius, FVector& ResultLocation);

	UFUNCTION(BlueprintCallable)
	static bool IsWorldStartup(UObject* WorldContextObject);

	UFUNCTION(BlueprintPure)
	static ULevelSequencePlayer* GetSequencePlayer(UMovieSceneTrackInstance* TrackInstance, const FSequencerTrackInstanceInput& Input);

	UFUNCTION(BlueprintPure)
	static void GetMontageSectionStartAndEndTime(UAnimMontage* Montage, FName SectionName, float& OutStartTime, float& OutEndTime);

	/** Get nearest distance from point to actor's all components. */
	UFUNCTION(BlueprintCallable)
	static float GetNearestDistanceToActor(const FVector& Point, const AActor* Target, ECollisionChannel TraceChannel, FVector& ClosestPointOnCollision, UPrimitiveComponent*& OutPrimitiveComponent);

	/** Get nearest distance from point to component. */
	UFUNCTION(BlueprintCallable)
	static float GetNearestDistanceToComponent(const FVector& Point, const UPrimitiveComponent* TargetComp, FVector& ClosestPointOnCollision);

	UFUNCTION(BlueprintPure)
	static bool WasRecentlyRenderedWithoutShadow(UPrimitiveComponent *Comp, float Tolerance = 0.2);

	UFUNCTION(BlueprintCallable)
	static TArray<UObject*> GetAkAudioTypeUserDatas(const class UAkAudioType* Instance, const UClass* Type);

	UFUNCTION(BlueprintCallable)
	static void SetGameQualityLevel(int32 Level);
	
	UFUNCTION(BlueprintCallable)
	static bool AddBlueprintTypeToCache(FString Path, UObject* LoadedObject);

	UFUNCTION(BlueprintCallable)
	static bool RemoveBlueprintTypeToCache(FString Path);

	UFUNCTION(BlueprintCallable)
	static UObject* GetCachedBlueprintType(FString Path);
	
	static TMap<FString, UObject*> BlueprintTypeCache;

	UFUNCTION(BlueprintCallable)
	static FVector2D ClampScreenPositionInEllipse(double EllipseAxisX, double EllipseAxisY, const FVector2D& ScreenPosition, bool bForceToEdge);

	UFUNCTION(BlueprintCallable)
	static bool IsAssetSkeletonCompatible(USkeleton* Skeleton, UAnimMontage* AnimMontage);

	UFUNCTION(BlueprintCallable)
	static bool MarkActorDirty(AActor* InActor);

	UFUNCTION(BlueprintCallable)
	static bool AIRegisterPerceptionSource(AActor* SourceActor);

	UFUNCTION(BlueprintCallable)
	static bool AIUnregisterPerceptionSource(AActor* SourceActor);

	UFUNCTION(BlueprintCallable)
	static void CreateHiGameplayDebuggerCategoryReplicator(AHiPlayerController* OwnerPC);

	UFUNCTION(BlueprintCallable)
	static TArray<class AHiTriggerVolume*> GetActorInWhichHiTriggerVolumes(AActor* InActor);

	UFUNCTION(BlueprintCallable)
	static void RemovePostProcessBlendable(APostProcessVolume* PPV, TScriptInterface<IBlendableInterface> InBlendableObject);

	UFUNCTION(BlueprintCallable)
	static bool IsLocalAdapter();

	UFUNCTION(BlueprintCallable)
	static ESSInstanceType GetSSInstanceType();

	UFUNCTION(BlueprintCallable)
	static bool IsSSInstanceGame();

	UFUNCTION(BlueprintCallable)
	static bool IsSSInstanceClient();

	UFUNCTION(BlueprintCallable)
	static bool IsSSInstanceGate();

	UFUNCTION(BlueprintCallable)
	static const UGameServerSettings* GetGameServerSettings();

	UFUNCTION(BlueprintCallable)
	static FString GetDefaultLoginHost();

	UFUNCTION(BlueprintCallable)
	static bool IsInPIE();

	UFUNCTION(BlueprintCallable)
	static bool IsWithEditor();

	UFUNCTION(BlueprintCallable)
	static int32 GetClientEnterSpaceID();

	UFUNCTION(BlueprintCallable)
	static int32 GetClientPlayMode();

	UFUNCTION(BlueprintCallable)
	static TArray<UAssetUserData*> GetAnimationAssetUserData(const class UAnimationAsset* AnimationAsset, const UClass* Type);

	UFUNCTION(BlueprintCallable)
	static TArray<UAssetUserData*> GetAssetUserData(const class UObject* Asset, const UClass* Type);

	UFUNCTION(BlueprintCallable)
	static UAssetUserData* AddAssetUserData(UObject* AssetObject, TSubclassOf<UAssetUserData> ClassType);

	UFUNCTION(BlueprintCallable)
	static FGameplayTag GetDirectParentGameplayTag(FGameplayTag InGameplayTag);

	UFUNCTION(BlueprintCallable)
	static bool WithEditor();

};

#if defined(USING_LUAJIT)
extern "C"
{
	__declspec(dllexport) bool FFI_GetStaticBool();
	__declspec(dllexport) double FFI_GetStaticNumber();
	__declspec(dllexport) const char* FFI_GetStaticString();
	
	__declspec(dllexport) const char* FFI_GetObjName(lua_Integer Obj_Addr);
	__declspec(dllexport) const char* FFI_GetDisplayName(lua_Integer Obj_Addr);
	__declspec(dllexport) int64_t FFI_GetFrameCount();
	__declspec(dllexport) int64_t FFI_GetNowTimestampMs();
	__declspec(dllexport) int64_t FFI_GetGameplayAbilityFromSpecHandle(lua_Integer AbilitySystem_Addr, lua_Integer SpecHandle_Addr);
	__declspec(dllexport) int64_t FFI_GetHiAbilitySystemComponent(lua_Integer Obj_Addr);
	__declspec(dllexport) int64_t FFI_GetPlayerCharacter(lua_Integer Context_Addr, int32_t PlayerIndex);
}
#endif
