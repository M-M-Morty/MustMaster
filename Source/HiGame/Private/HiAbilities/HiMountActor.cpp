// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiMountActor.h"
#include "Component/HiAIComponent.h"
#include "HiUtilsFunctionLibrary.h"
#include "Kismet/KismetSystemLibrary.h"
#include "AbilitySystemComponent.h"

// PRAGMA_DISABLE_OPTIMIZATION

DEFINE_LOG_CATEGORY_STATIC(LogMountActor, Log, All)

// Sets default values
AHiMountActor::AHiMountActor()
{
	PrimaryActorTick.bCanEverTick = true;

	AbilitySystemComponent = CreateDefaultSubobject<UHiAbilitySystemComponent>(TEXT("gas"));
	AbilitySystemComponent->SetIsReplicated(true);
}

UAbilitySystemComponent* AHiMountActor::GetAbilitySystemComponent() const
{
	return AbilitySystemComponent;
}

void AHiMountActor::BeginPlay()
{
	Super::BeginPlay();
}

void AHiMountActor::GetLifetimeReplicatedProps(TArray< FLifetimeProperty > & OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	
	// DOREPLIFETIME(AHiMountActor, Identity);
	DOREPLIFETIME(AHiMountActor, SourceActor);
}

void AHiMountActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);
	
	// if (UHiUtilsFunctionLibrary::IsServer(this))
	// {
	// 	UE_LOG(LogMountActor, Warning, TEXT("AHiMountActor at server"));
	// }
	//
	// if (UHiUtilsFunctionLibrary::IsClient(this))
	// {
	// 	UE_LOG(LogMountActor, Warning, TEXT("AHiMountActor at client"));
	// }
}

FGameplayAbilitySpecHandle AHiMountActor::GiveAbility(TSubclassOf<UGameplayAbility> AbilityType, int32 InputID, UGameplayAbilityUserData* UserData)
{
	if (HasAuthority() && IsValid(AbilityType) && IsValid(AbilitySystemComponent))
	{
		return AbilitySystemComponent->GiveAbility(FGameplayAbilitySpec(AbilityType, 1, InputID, nullptr, UserData));
	}
	else
	{
		return FGameplayAbilitySpecHandle();
	}
}

void AHiMountActor::Server_SetActorLocation(FVector NewLocation, bool bSweep, bool bTeleport)
{
	Multicast_SetActorLocation(NewLocation, bSweep, bTeleport);
}

void AHiMountActor::Multicast_SetActorLocation_Implementation(FVector NewLocation, bool bSweep, bool bTeleport)
{
	SetActorLocation(NewLocation, bSweep, nullptr, TeleportFlagToEnum(bTeleport));
}

void AHiMountActor::Server_SetActorRotation(FRotator NewRotation, ETeleportType Teleport)
{
	Multicast_SetActorRotation(NewRotation, Teleport);
}

void AHiMountActor::Multicast_SetActorRotation_Implementation(FRotator NewRotation, ETeleportType Teleport)
{
	SetActorRotation(NewRotation, Teleport);
}

void AHiMountActor::Multicast_OnAttributeChanged_Implementation(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec) {
	this->OnAttributeChanged(Attribute, NewValue, OldValue, Spec);
}

void AHiMountActor::Destroyed()
{
	Super::Destroyed();
	
	if (SourceActor)
	{
		auto const AIComponent = UHiAIComponent::FindAIComponent(SourceActor);
		AIComponent->OnMountActorDestroyed(this);
	}
}
