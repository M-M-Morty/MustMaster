// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiTargetActorSpec.h"
#include "Abilities/GameplayAbilityTargetDataFilter.h"
#include "Component/HiCharacterDebugComponent.h"
#include "HiCollisionLibrary.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiCollisionLibrary : public UBlueprintFunctionLibrary
{
public:
	GENERATED_BODY()
	
	UHiCollisionLibrary();
	~UHiCollisionLibrary();

	/** 
	 * PerformOverlapActors.HitActors(TArray<TWeakObjectPtr<AActor>>) is not supported by blueprint.
	 * TArray<AActor*> is supported.
	*/
	UFUNCTION(BlueprintCallable)
	static void PerformOverlapActorsBP(UObject* WorldContextObject, const FHiTargetActorSpec& TargetActorSpec, const FVector& Origin, const FVector& ForwardVector, FGameplayTargetDataFilterHandle Filter, TArray<AActor*>& HitActors, bool& NeedDestroy, bool bDebug=false);

	/** Perform overlap and get hit actors according TargetActorSpec
	 *
	 * @param World UWorld object.
	 * @param TargetActorSpec
	 * @param ForwardVector 
	 * @param Filter TargetData filter
	 * @param HitActors Output hit actors.
	 * @param NeedDestroy Whether need destroy the source actor. for example when projectile collision with scene, should destroy the projectile.
	 */
	static void PerformOverlapActors(UObject* WorldContextObject, const FHiTargetActorSpec& TargetActorSpec, const FVector& Origin, const FVector& ForwardVector, FGameplayTargetDataFilterHandle Filter, TArray<TWeakObjectPtr<AActor>>& HitActors, bool& NeedDestroy, bool bDebug=false, float LifeTime=2.0f);

	UFUNCTION(BlueprintCallable)
	static bool SphereOverlapComponents(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, float Radius, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<UPrimitiveComponent*>& OutComponents, bool bDebug=false, float LifeTime=2.0f);

	UFUNCTION(BlueprintCallable)
	static bool SphereOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, float Radius, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<AActor*>& OutActors, bool bDebug=false, float LifeTime=2.0f);
	
	UFUNCTION(BlueprintCallable)
	static bool SectionOverlapComponents(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Radius, float Angle, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class UPrimitiveComponent*>& OutComponents, bool bDebug=false, float LifeTime = 2.0f);

	UFUNCTION(BlueprintCallable)
	static bool SectionOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Radius, float Angle, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class AActor*>& OutActors, bool bDebug=false, float LifeTime=2.0f);

	/**
	 * @param KeepOrigin whether auto change box origin to ensure box only location in front. Otherwise box will center at given origin. 
	 */
	UFUNCTION(BlueprintCallable)
	static bool BoxOverlapComponents(const UObject* WorldContextObject,const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Length, float HalfWidth, float UpHeight, float DownHeight, UClass* ComponentClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class UPrimitiveComponent*>& OutComponents, bool KeepOrigin=false, bool bDebug=false, float LifeTime=2.0f);

	UFUNCTION(BlueprintCallable)
	static bool BoxOverlapActors(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>> & ObjectTypes, const FVector& Origin, const FVector& ForwardVector, float Length, float HalfWidth, float UpHeight, float DownHeight, UClass* ActorClassFilter, const TArray<AActor*>& ActorsToIgnore, TArray<class AActor*>& OutActors, bool KeepOrigin=false, bool bDebug=false, float LifeTime=2.0f);

	/** Check target in section from origin forward
	 *
	 * @param TargetPos
	 * @param Origin 
	 * @param ForwardVector TargetForward
	 * @param Radians
	 * @return true in section, otherwise false
	 */
	UFUNCTION(BlueprintCallable)
	static bool CheckInSection(const FVector& TargetPos, const FVector& Origin, const FVector& ForwardVector, float Radians);
	
	/** 为数不多的中文注释，且看且珍惜
	 * 判断Target相较于Origin的方位是否在给定的范围内（以Origin正前方右侧朝向为初始，逆时针旋转）
	 *
	 * @param TargetPos - 目标点
	 * @param Origin - 原点
	 * @param ForwardVector - 一般为Target朝向 
	 * @param StartAngle - 范围初始值（角度）
	 * @param EndAngle - 范围结束值（角度）
	 * @return true - 在范围内，false - 在范围外
	 */
	UFUNCTION(BlueprintCallable)
	static bool CheckInDirectionBySection(const FVector& TargetPos, const FVector& Origin, const FVector& ForwardVector, int StartAngle, int EndAngle);
	
	UFUNCTION(BlueprintCallable)
	static bool CheckInHeight(const FVector& TargetPos, const FVector& Origin, float UpHeight, float DownHeight);

	UFUNCTION(BlueprintCallable)
	static bool CheckInHeightZ(float OriginZ, float MaxZ, float MinZ, float UpHeight, float DownHeight);

	/**
	 * Sweep component along a line.
	 * TODO: support FCollisionObjectQueryParams
	 *
	 */
	UFUNCTION(BlueprintCallable)
	static bool ComponentTraceMulti(const UObject* WorldContextObject, const TArray<TEnumAsByte<EObjectTypeQuery>>& ObjectTypes, const FVector Start, const FVector End, const FRotator Rotation, UPrimitiveComponent* PrimComp, TArray<FHitResult>& OutHits);

	/**
	 * @brief Sweep capsule support rotation.
	 * @param WorldContextObject 
	 * @param Start 
	 * @param End 
	 * @param Orientation 
	 * @param Radius 
	 * @param HalfHeight 
	 * @param ObjectTypes 
	 * @param bTraceComplex 
	 * @param ActorsToIgnore 
	 * @param DrawDebugType 
	 * @param OutHits 
	 * @param bIgnoreSelf 
	 * @param TraceColor 
	 * @param TraceHitColor 
	 * @param DrawTime 
	 * @return 
	 */
	UFUNCTION(BlueprintCallable)
	static bool CapsuleTraceMultiForObjects(const UObject* WorldContextObject, const FVector Start, const FVector End, const FRotator Orientation, float Radius, float HalfHeight, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, bool bTraceComplex, const TArray<AActor*>& ActorsToIgnore, EDrawDebugTrace::Type DrawDebugType, TArray<FHitResult>& OutHits, bool bIgnoreSelf, FLinearColor TraceColor = FLinearColor::Red, FLinearColor TraceHitColor = FLinearColor::Green, float DrawTime = 5.0f);

	UFUNCTION(BlueprintCallable)
	static bool CapsuleTraceSingleForObjects(const UObject* WorldContextObject, const FVector Start, const FVector End, const FRotator Orientation, float Radius, float HalfHeight, const TArray<TEnumAsByte<EObjectTypeQuery> > & ObjectTypes, bool bTraceComplex, const TArray<AActor*>& ActorsToIgnore, EDrawDebugTrace::Type DrawDebugType, FHitResult& OutHit, bool bIgnoreSelf, FLinearColor TraceColor = FLinearColor::Red, FLinearColor TraceHitColor = FLinearColor::Green, float DrawTime = 5.0f);

	/**
	 * Perform trace hit objects, return HitResults.
	 * @param WorldContextObject
	 * @param  
	 *
	 */
	// static void PerformTrace(UObject* WorldContextObject, const FHiTargetActorSpec& TargetActorSpec, const FVector& Origin, const FVector& ForwardVector, FGameplayTargetDataFilterHandle Filter, TArray<FHitResult>& HitResults, EDrawDebugTrace::Type DrawDebugType=EDrawDebugTrace::Type::None);


	UFUNCTION(BlueprintCallable)
	static void GetComponentPhysicsMaterial(UPrimitiveComponent* PrimComp, bool bSimpleCollision, TArray<class UPhysicalMaterial*> &OutPhysMaterials);
};
