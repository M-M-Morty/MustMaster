// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiProjectileActorBase.h"
#include "Abilities/GameplayAbilityTargetActor.h"
#include "Component/HiCharacterDebugComponent.h"
#include "HiTargetActorBase.generated.h"

/**
 * HiGame TargetActor base class
 */

UCLASS()
class HIGAME_API AHiTargetActorBase : public AGameplayAbilityTargetActor
{
	GENERATED_BODY()

public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category=Targeting)
	TSubclassOf<AHiProjectileActorBase> ProjectileClass;

	/** GameplayEffects to apply to TargetData */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ExposeOnSpawn = true), Category = Calculation)
	TArray<FGameplayEffectSpecHandle> GameplayEffectsHandle;

	/** GameplayEffects to apply to self when hit target */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ExposeOnSpawn = true), Category = Calculation)
	TArray<FGameplayEffectSpecHandle> SelfGameplayEffectsHandle;

	/** Custom knock info */
	UPROPERTY(BlueprintReadWrite, meta = (ExposeOnSpawn = true), Category = Calculation, Replicated)
	UObject* KnockInfo;
	
	/** Debug trace type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Debug)
	TEnumAsByte<EDrawDebugTrace::Type> DebugType;

	/** Debug draw time */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Debug)
	float DebugTime;

public:
	AHiTargetActorBase(const FObjectInitializer& ObjectInitializer);
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UFUNCTION(BlueprintNativeEvent)
	void OnTick();

	UFUNCTION(BlueprintCallable)
	virtual bool ShouldProduceTargetData() const override;
	
	virtual void StartTargeting(UGameplayAbility* Ability) override;

	UFUNCTION(BlueprintNativeEvent)
	void OnStartTargeting(UGameplayAbility* Ability);

	virtual void ConfirmTargetingAndContinue() override;

	UFUNCTION(BlueprintNativeEvent)
	void OnConfirmTargetingAndContinue();

	/** Create reticle actor. */
	UFUNCTION(BlueprintCallable)
	AGameplayAbilityWorldReticle* CreateReticleActor();

	/** Client replicate TargetData to server in LocalPredicted mode, check data valid in here.*/
	virtual bool OnReplicatedTargetDataReceived(FGameplayAbilityTargetDataHandle& Data) const override;

	UFUNCTION(BlueprintNativeEvent)
	bool OnTargetDataReceived(FGameplayAbilityTargetDataHandle& Data) const;

	UFUNCTION(BlueprintCallable)
	void BroadcastTargetDataHandleWithActors(const TArray<AActor*>& Actors);

	UFUNCTION(BlueprintCallable)
	void BroadcastTargetDataHandleWithHitResults(const TArray<FHitResult>& HitResults);

	UFUNCTION(BlueprintCallable)
	void BroadcastTargetDataHandle(const FGameplayAbilityTargetDataHandle& Handle);

	UFUNCTION(BlueprintCallable)
	bool IsShouldProduceTargetDataOnServer();

	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	virtual void Destroyed();
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, meta = (ExposeOnSpawn = true), Category = Calculation)
	AGameplayAbilityWorldReticle* ReticleActor;
};
