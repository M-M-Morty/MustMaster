// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiTargetActorBase.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "Characters/HiCharacter.h"
#include "Abilities/GameplayAbility.h"
#include "Kismet/GameplayStatics.h"
#include "HiGame/Public/HiUtilsFunctionLibrary.h"
#include "DistributedDSComponent.h"
#include "DistributedEntityType.h"

AHiTargetActorBase::AHiTargetActorBase(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	PrimaryActorTick.bCanEverTick = true;
	ShouldProduceTargetDataOnServer = true;
}

void AHiTargetActorBase::BeginPlay()
{
	Super::BeginPlay();
}

void AHiTargetActorBase::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	OnTick();
}

void AHiTargetActorBase::OnTick_Implementation()
{
	
}

bool AHiTargetActorBase::ShouldProduceTargetData() const
{
	return Super::ShouldProduceTargetData();
}

void AHiTargetActorBase::StartTargeting(UGameplayAbility* Ability)
{
	Super::StartTargeting(Ability);

	OnStartTargeting(Ability);

	if (SourceActor)
	{
		SET_ASSOCIATED_LEADER(this, SourceActor, EEntityAssociateSource::Geo, EEntityAssociateType::Private);
	}
}

void AHiTargetActorBase::OnStartTargeting_Implementation(UGameplayAbility* Ability)
{
	
}

void AHiTargetActorBase::ConfirmTargetingAndContinue()
{
	check(ShouldProduceTargetData());
	OnConfirmTargetingAndContinue();
}

void AHiTargetActorBase::OnConfirmTargetingAndContinue_Implementation()
{
	
}

bool AHiTargetActorBase::OnReplicatedTargetDataReceived(FGameplayAbilityTargetDataHandle& Data) const
{
	Super::OnReplicatedTargetDataReceived(Data);

	return OnTargetDataReceived(Data);
}

bool AHiTargetActorBase::OnTargetDataReceived_Implementation(FGameplayAbilityTargetDataHandle& Data) const
{
	return true;
}

void AHiTargetActorBase::BroadcastTargetDataHandleWithActors(const TArray<AActor*>& Actors)
{
	FGameplayAbilityTargetDataHandle Handle;
	if (OwningAbility)
	{		
		Handle = UAbilitySystemBlueprintLibrary::AbilityTargetDataFromActorArray(Actors, false);	
		TargetDataReadyDelegate.Broadcast(Handle);	
	}
}

void AHiTargetActorBase::BroadcastTargetDataHandleWithHitResults(const TArray<FHitResult>& HitResults)
{
	if (OwningAbility)
	{
		FGameplayAbilityTargetDataHandle ReturnDataHandle;

		for (int32 i = 0; i < HitResults.Num(); i++)
		{
			FGameplayAbilityTargetData_SingleTargetHit* ReturnData = new FGameplayAbilityTargetData_SingleTargetHit();
			ReturnData->HitResult = HitResults[i];
			ReturnDataHandle.Add(ReturnData);
		}

		TargetDataReadyDelegate.Broadcast(ReturnDataHandle);
	}
}

void AHiTargetActorBase::BroadcastTargetDataHandle(const FGameplayAbilityTargetDataHandle& Handle)
{
	TargetDataReadyDelegate.Broadcast(Handle);
}

bool AHiTargetActorBase::IsShouldProduceTargetDataOnServer()
{
	return ShouldProduceTargetDataOnServer;
}

 AGameplayAbilityWorldReticle* AHiTargetActorBase::CreateReticleActor()
 {
 	if (ReticleClass && GetWorld())
 	{
 		AGameplayAbilityWorldReticle* SpawnedReticleActor = GetWorld()->SpawnActor<AGameplayAbilityWorldReticle>(ReticleClass, GetActorLocation(), GetActorRotation());
 		if (SpawnedReticleActor)
 		{
 			SpawnedReticleActor->InitializeReticle(this, PrimaryPC, ReticleParams);
 			ReticleActor = SpawnedReticleActor;
			return ReticleActor;
 		}
 	}

	return nullptr;
 }

void AHiTargetActorBase::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME_CONDITION(AHiTargetActorBase, KnockInfo, COND_None);
}

void AHiTargetActorBase::Destroyed() {
	Super::Destroyed();
}
