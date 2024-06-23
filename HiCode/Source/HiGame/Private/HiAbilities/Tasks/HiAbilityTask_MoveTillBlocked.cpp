// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/Tasks/HiAbilityTask_MoveTillBlocked.h"

#include "AbilitySystemComponent.h"
#include "PlayMontageCallbackProxy.h"
#include "Abilities/Tasks/AbilityTask_PlayMontageAndWait.h"
#include "GameFramework/CharacterMovementComponent.h"

UHiAbilityTask_MoveTillBlocked* UHiAbilityTask_MoveTillBlocked::CreateMoveTillBlockedTask(UGameplayAbility* OwningAbility, FName TaskInstanceName, UAnimMontage* Montage, const FMoveTillBlockedParams& Params)
{
	UHiAbilityTask_MoveTillBlocked* MyObj = NewAbilityTask<UHiAbilityTask_MoveTillBlocked>(OwningAbility, TaskInstanceName);
	MyObj->MontageToPlay = Montage;
	MyObj->InitSpeed = Params.InitSpeed;
	MyObj->InitAcc = Params.InitAcc;
	MyObj->MoveDir = Params.MoveDir;
	MyObj->AccCurve = Params.AccCurve;
	MyObj->bTickingTask = true;
	return MyObj;
}

void UHiAbilityTask_MoveTillBlocked::Activate()
{
	AActor* OwnerActor = this->GetOwnerActor();
	ACharacter* OwnerCharacter = this->GetOwnerCharacter();
	if(!IsValid(OwnerCharacter))
	{
		this->EndTask();
		return;
	}
	UCharacterMovementComponent* MovementComponent = OwnerCharacter->GetCharacterMovement();
	if (!IsValid(OwnerActor) || !IsValid(MovementComponent))
	{
		this->EndTask();
		return;
	}

	if(MontageToPlay && AbilitySystemComponent.IsValid())
	{
		const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
		if(ActorInfo)
		{
			UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();
			if (AnimInstance != nullptr)
			{
				// TODO may need listen montage events for end task.
				AbilitySystemComponent->PlayMontage(Ability, Ability->GetCurrentActivationInfo(), MontageToPlay, 1.0);
			}
		}
	}

	this->Velocity = this->InitSpeed * this->MoveDir.GetSafeNormal();
	this->ElapsedTime = 0;
	this->OnStarted.Broadcast();
}

void UHiAbilityTask_MoveTillBlocked::TickTask(float DeltaTime)
{
	AActor* OwnerActor = this->GetOwnerActor();
	const ACharacter* OwnerCharacter = GetOwnerCharacter();
	if(!IsValid(OwnerCharacter))
	{
		this->EndTask();
		return;
	}	
	UCharacterMovementComponent* MovementComponent = OwnerCharacter->GetCharacterMovement();
	if (!IsValid(OwnerActor) || !IsValid(MovementComponent))
	{
		this->EndTask();
		return;
	}

	FVector MoveDelta = Velocity * DeltaTime;
	FHitResult Hit;
	bool bMoveSuccess = MovementComponent->SafeMoveUpdatedComponent(MoveDelta, OwnerActor->GetActorQuat(), true, Hit);
	if (!bMoveSuccess || Hit.IsValidBlockingHit())
	{
		this->EndTask();
		return;
	}
	
	float acc = InitAcc;
	if (AccCurve)
	{
		acc = AccCurve->GetFloatValue(this->ElapsedTime);
	}
	this->ElapsedTime += DeltaTime;
	this->Velocity = this->Velocity + this->Velocity.GetSafeNormal() * acc * DeltaTime;
}

ACharacter* UHiAbilityTask_MoveTillBlocked::GetOwnerCharacter() const
{
	AActor* OwnerActor = this->GetOwnerActor();
	if (!IsValid(OwnerActor))
	{
		return nullptr;
	}

	ACharacter* OwnerCharacter = Cast<ACharacter>(OwnerActor);
	if (!IsValid(OwnerCharacter))
	{
		return nullptr;
	}

	return OwnerCharacter;
}

USkeletalMeshComponent* UHiAbilityTask_MoveTillBlocked::GetOwnerMesh() const
{
	const ACharacter* OwnerCharacter = GetOwnerCharacter();
	if (!IsValid(OwnerCharacter))
	{
		return nullptr;
	}
	
	return OwnerCharacter->GetMesh();
}

void UHiAbilityTask_MoveTillBlocked::OnDestroy(bool bInOwnerFinished)
{
	Super::OnDestroy(bInOwnerFinished);

	if (MontageToPlay && AbilitySystemComponent.IsValid())
	{
		AbilitySystemComponent->StopMontageIfCurrent(*MontageToPlay);
	}

	this->OnCompleted.Broadcast();
}
