// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiProjectileActorBase.h"

#include "Net/UnrealNetwork.h"

// Sets default values
AHiProjectileActorBase::AHiProjectileActorBase()
{
	PrimaryActorTick.bCanEverTick = true;
}

void AHiProjectileActorBase::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	DOREPLIFETIME(AHiProjectileActorBase, bDebug);
}