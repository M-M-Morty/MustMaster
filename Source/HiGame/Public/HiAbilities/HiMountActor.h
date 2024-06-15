// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "AbilitySystemInterface.h"
#include "HiAbilities/HiGASLibrary.h"
#include "Component/HiAbilitySystemComponent.h"
#include "HiMountActor.generated.h"

/**
 *
 *	Mount actor spawned by TargetActor.
 *
 */
UCLASS()
class HIGAME_API AHiMountActor : public AActor, public IAbilitySystemInterface
{
	GENERATED_BODY()

public:	
	// Sets default values for this actor's properties
	// TODO Attention: constructor always run before FinishSpawningActor, that's weired.
	AHiMountActor();

	UFUNCTION(BlueprintCallable, Category = "AI")
	virtual UAbilitySystemComponent* GetAbilitySystemComponent()const override;

	UFUNCTION(BlueprintCallable, Category="AI")
	UHiAbilitySystemComponent* GetHiAbilitySystemComponent() const { return AbilitySystemComponent; }
	
	UFUNCTION(BlueprintCallable)
	FGameplayAbilitySpecHandle GiveAbility(TSubclassOf<UGameplayAbility> AbilityType, int32 InputID, UGameplayAbilityUserData* UserData = nullptr);

	UFUNCTION(BlueprintCallable, Category="AI")
	void Server_SetActorLocation(FVector NewLocation, bool bSweep, bool bTeleport);

	UFUNCTION(NetMulticast, Reliable, Category = "AI")
	void Multicast_SetActorLocation(FVector NewLocation, bool bSweep, bool bTeleport);

	UFUNCTION(BlueprintCallable, Category="AI")
	void Server_SetActorRotation(FRotator NewRotation, ETeleportType Teleport);

	UFUNCTION(NetMulticast, Reliable, Category = "AI")
	void Multicast_SetActorRotation(FRotator NewRotation, ETeleportType Teleport);
	
	UFUNCTION(BlueprintImplementableEvent, Category = "AI")
	void OnAttributeChanged(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec);

	UFUNCTION(NetMulticast, Reliable)
	void Multicast_OnAttributeChanged(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec);

	UFUNCTION(BlueprintImplementableEvent)
	void OnDamaged(float DamageAmount, const FHitResult& HitInfo, AActor* InstigatorCharacter, AActor* DamageCauser);
	
	UFUNCTION(BlueprintImplementableEvent, Category = "AI")
	void OnOwnerGamePlayTagNewOrRemove(const FGameplayTag Tag, int32 NewCount);

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:
	virtual void Tick(float DeltaTime) override;
	virtual void Destroyed() override;
	
public:
	// UPROPERTY(Replicated, EditAnywhere, BlueprintReadOnly, Category="AI", Meta = (AllowPrivateAccess = "true"))
	// ECharIdentity Identity = ECharIdentity::Player;

	UPROPERTY(Replicated, EditAnywhere, BlueprintReadWrite, Category = "AI")
	AActor* SourceActor;

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "AI", meta = (AllowPrivateAccess = "true"))
	UHiAbilitySystemComponent* AbilitySystemComponent;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AI")
	class UHiAttributeSet* AttributeSet;
};
