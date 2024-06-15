// Fill out your copyright notice in the Description page of Project Settings.


#include "HiPlayerState.h"

#include "GameplayEntitySubsystem.h"
#include "Characters/HiPlayerController.h"
#include "Components/CapsuleComponent.h"
#include "NetCommon/DistributedDSConnectionBase.h"

static FName PawnUnique_ProfileName = FName(TEXT("PawnUnique"));

AHiPlayerState::AHiPlayerState()
{
	this->OnPawnSet.AddDynamic(this, &AHiPlayerState::OnPawnSetCallback);

	auto CapsuleComponent = CreateDefaultSubobject<UCapsuleComponent>(ACharacter::CapsuleComponentName);
	CapsuleComponent->InitCapsuleSize(34.0f, 88.0f);
	CapsuleComponent->SetCollisionProfileName(PawnUnique_ProfileName);

	CapsuleComponent->CanCharacterStepUpOn = ECB_No;
	CapsuleComponent->SetShouldUpdatePhysicsVolume(false);
	CapsuleComponent->SetCanEverAffectNavigation(false);
	CapsuleComponent->bDynamicObstacle = true;
	RootComponent = CapsuleComponent;
}

void AHiPlayerState::PreInitializeComponents()
{
	Super::PreInitializeComponents();
	if (Aether::GetSSInstanceType() == ESSInstanceType::Game)
	{
		AHiPlayerController* PlayerController = Cast<AHiPlayerController>(GetPlayerController());
		if (PlayerController)
		{
			SetPlayerProxyID(PlayerController->GetPlayerProxyID());
		}
	}
	K2_PreInitializeComponents();
}

FString AHiPlayerState::GenerateActorID()
{
	UGameplayEntitySubsystem* GameplayEntitySubsystem = GetWorld()->GetSubsystem<UGameplayEntitySubsystem>();
	if (GameplayEntitySubsystem == nullptr)
	{
		return "";
	}
	return GameplayEntitySubsystem->GetPlayerActorID(PlayerProxyID);
}

void AHiPlayerState::PostTransfer()
{
	Super::PostTransfer();
	OnTransferToSpace(GetSpaceID());
}

void AHiPlayerState::OnTransferToSpace_Implementation(int32 InSpaceID)
{
	K2_OnTransferToSpace(InSpaceID);
}

void AHiPlayerState::BeginPlay()
{
	Super::BeginPlay();
}


void AHiPlayerState::AddAttributeSet(UHiAttributeSet* InAttributeSet)
{
	if (!IsValid(InAttributeSet)) {
		return;
	}
	
	if (AttributeSets.Find(InAttributeSet) == INDEX_NONE) {
		AttributeSets.Add(InAttributeSet);

		MARK_PROPERTY_DIRTY_FROM_NAME(AHiPlayerState, AttributeSets, this);
	}
}

void AHiPlayerState::GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const
{
	// Fast Arrays don't use push model, but there's no harm in marking them with it.
	// The flag will just be ignored.
	FDoRepLifetimeParams Params;
	Params.bIsPushBased = true;

	DOREPLIFETIME_WITH_PARAMS_FAST(AHiPlayerState, AttributeSets, Params);

	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
}
