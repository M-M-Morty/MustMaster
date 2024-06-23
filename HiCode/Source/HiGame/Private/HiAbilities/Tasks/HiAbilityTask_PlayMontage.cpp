// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/Tasks/HiAbilityTask_PlayMontage.h"
#include "GameFramework/Character.h"
#include "AbilitySystemComponent.h"
#include "AbilitySystemGlobals.h"
#include "AbilitySystemLog.h"
#include "Component/HiAbilitySystemComponent.h"
#include "HiAbilities/HiGameplayAbility.h"

DEFINE_REPLICATED_ABILITY_TASK_TYPE(UHiAbilityTask_PlayMontage)

UHiAbilityTask_PlayMontage::UHiAbilityTask_PlayMontage(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	Rate = 1.f;
	bStopWhenAbilityEnds = true;
}

void UHiAbilityTask_PlayMontage::OnMontageBlendingOut(UAnimMontage* Montage, bool bInterrupted)
{
	if (Ability && Ability->GetCurrentMontage() == MontageToPlay)
	{
		if (Montage == MontageToPlay)
		{
			AbilitySystemComponent->ClearAnimatingAbility(Ability);

			// Reset AnimRootMotionTranslationScale
			ACharacter* Character = Cast<ACharacter>(GetAvatarActor());
			if (Character && (Character->GetLocalRole() == ROLE_Authority ||
							  (Character->GetLocalRole() == ROLE_AutonomousProxy && Ability->GetNetExecutionPolicy() == EGameplayAbilityNetExecutionPolicy::LocalPredicted)))
			{
				Character->SetAnimRootMotionTranslationScale(1.f);
			}

		}
	}

	if (bInterrupted)
	{
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnInterrupted.Broadcast();
		}
	}
	else
	{
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnBlendOut.Broadcast();
		}
	}
}

void UHiAbilityTask_PlayMontage::OnMontageInterrupted()
{
	if (StopPlayingMontage())
	{
		// Let the BP handle the interrupt as well
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnInterrupted.Broadcast();
		}
	}
}

void UHiAbilityTask_PlayMontage::OnMontageEnded(UAnimMontage* Montage, bool bInterrupted)
{
	if (!bInterrupted)
	{
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnCompleted.Broadcast();
		}
	}

	EndTask();
}

UHiAbilityTask_PlayMontage* UHiAbilityTask_PlayMontage::CreatePlayMontageAndWaitProxy(UGameplayAbility* OwningAbility,
	FName TaskInstanceName, UAnimMontage *MontageToPlay, const FAlphaBlendArgs& BlendIn, float Rate, FName StartSection, bool bStopWhenAbilityEnds, float AnimRootMotionTranslationScale, float StartTimeSeconds)
{

	UAbilitySystemGlobals::NonShipping_ApplyGlobalAbilityScaler_Rate(Rate);

	UHiAbilityTask_PlayMontage* MyObj = NewAbilityTask<UHiAbilityTask_PlayMontage>(OwningAbility, TaskInstanceName);
	MyObj->MontageToPlay = MontageToPlay;
	MyObj->BlendIn = BlendIn;
	MyObj->Rate = Rate;
	MyObj->StartSection = StartSection;
	MyObj->AnimRootMotionTranslationScale = AnimRootMotionTranslationScale;
	MyObj->bStopWhenAbilityEnds = bStopWhenAbilityEnds;
	MyObj->StartTimeSeconds = StartTimeSeconds;
	
	return MyObj;
}

void UHiAbilityTask_PlayMontage::Activate()
{
	if (Ability == nullptr)
	{
		return;
	}

	bool bPlayedMontage = false;

	if (AbilitySystemComponent.IsValid())
	{
		const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
		if (ActorInfo)
		{
			UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();
			if (AnimInstance != nullptr)
			{
				if (AbilitySystemComponent->PlayMontageWithBlendIn(Ability, Ability->GetCurrentActivationInfo(), MontageToPlay, BlendIn, Rate, StartSection, StartTimeSeconds) > 0.f)
				{
					// Playing a montage could potentially fire off a callback into game code which could kill this ability! Early out if we are  pending kill.
					if (ShouldBroadcastAbilityTaskDelegates() == false)
					{
						return;
					}

					InterruptedHandle = Ability->OnGameplayAbilityCancelled.AddUObject(this, &UHiAbilityTask_PlayMontage::OnMontageInterrupted);

					BlendingOutDelegate.BindUObject(this, &UHiAbilityTask_PlayMontage::OnMontageBlendingOut);
					AnimInstance->Montage_SetBlendingOutDelegate(BlendingOutDelegate, MontageToPlay);

					MontageEndedDelegate.BindUObject(this, &UHiAbilityTask_PlayMontage::OnMontageEnded);
					AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, MontageToPlay);

					ACharacter* Character = Cast<ACharacter>(GetAvatarActor());
					if (Character && (Character->GetLocalRole() == ROLE_Authority ||
									  (Character->GetLocalRole() == ROLE_AutonomousProxy && Ability->GetNetExecutionPolicy() == EGameplayAbilityNetExecutionPolicy::LocalPredicted)))
					{
						Character->SetAnimRootMotionTranslationScale(AnimRootMotionTranslationScale);
					}

					bPlayedMontage = true;
				}
			}
		}
		else
		{
			ABILITY_LOG(Warning, TEXT("UHiAbilityTask_PlayMontage call to PlayMontage failed!"));
		}
	}
	else
	{
		ABILITY_LOG(Warning, TEXT("UHiAbilityTask_PlayMontage called on invalid AbilitySystemComponent"));
	}

	if (!bPlayedMontage)
	{
		ABILITY_LOG(Warning, TEXT("UHiAbilityTask_PlayMontage called in Ability %s failed to play montage %s; Task Instance Name %s."), *Ability->GetName(), *GetNameSafe(MontageToPlay),*InstanceName.ToString());
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnCancelled.Broadcast();
		}
	}

	SetWaitingOnAvatar();
}

void UHiAbilityTask_PlayMontage::ExternalCancel()
{
	check(AbilitySystemComponent.IsValid());

	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnCancelled.Broadcast();
	}
	Super::ExternalCancel();
}

void UHiAbilityTask_PlayMontage::OnDestroy(bool AbilityEnded)
{
	// Note: Clearing montage end delegate isn't necessary since its not a multicast and will be cleared when the next montage plays.
	// (If we are destroyed, it will detect this and not do anything)

	// This delegate, however, should be cleared as it is a multicast
	if (Ability)
	{
		Ability->OnGameplayAbilityCancelled.Remove(InterruptedHandle);
		if (AbilityEnded && bStopWhenAbilityEnds)
		{
			StopPlayingMontage();
		}
	}

	Super::OnDestroy(AbilityEnded);

}

bool UHiAbilityTask_PlayMontage::StopPlayingMontage()
{
	if (!Ability)
	{
		return false;
	}
	
	const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
	if (!ActorInfo)
	{
		return false;
	}

	UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();
	if (AnimInstance == nullptr)
	{
		return false;
	}

	// Check if the montage is still playing
	// The ability would have been interrupted, in which case we should automatically stop the montage
	if (AbilitySystemComponent.IsValid() && Ability)
	{
		if (AbilitySystemComponent->GetAnimatingAbility() == Ability
			&& AbilitySystemComponent->GetCurrentMontage() == MontageToPlay)
		{
			// Unbind delegates so they don't get called as well
			FAnimMontageInstance* MontageInstance = AnimInstance->GetActiveInstanceForMontage(MontageToPlay);
			if (MontageInstance)
			{
				MontageInstance->OnMontageBlendingOutStarted.Unbind();
				MontageInstance->OnMontageEnded.Unbind();
			}

			AbilitySystemComponent->CurrentMontageStop();
			return true;
		}
	}

	return false;
}

FString UHiAbilityTask_PlayMontage::GetDebugString() const
{
	UAnimMontage* PlayingMontage = nullptr;
	if (Ability)
	{
		const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
		if (ActorInfo)
		{
			UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();

			if (AnimInstance != nullptr)
			{
				PlayingMontage = AnimInstance->Montage_IsActive(MontageToPlay) ? MontageToPlay : AnimInstance->GetCurrentActiveMontage();
			}
		}
	}

	return FString::Printf(TEXT("PlayMontageAndWait. MontageToPlay: %s  (Currently Playing): %s"), *GetNameSafe(MontageToPlay), *GetNameSafe(PlayingMontage));
}

#if LQT_DISTRIBUTED_DS
void UHiAbilityTask_PlayMontage::SerializeTransferPrivateData(FArchive& Ar, UPackageMap* PackageMap)
{
	Ar << MontageToPlay;

	Ar << Rate;

	Ar << StartSection;

	Ar << AnimRootMotionTranslationScale;

	Ar << StartTimeSeconds;

	Ar << bStopWhenAbilityEnds;
	
	//FAbilityDelegateSerializeHelper::SerializeMultiDelegate(Ar, &OnCompleted, Ability);
	//FAbilityDelegateSerializeHelper::SerializeMultiDelegate(Ar, &OnBlendOut, Ability);
	//FAbilityDelegateSerializeHelper::SerializeMultiDelegate(Ar, &OnInterrupted, Ability);
	//FAbilityDelegateSerializeHelper::SerializeMultiDelegate(Ar, &OnCancelled, Ability);

	if (Ar.IsLoading())
	{
		UHiGameplayAbility *HiAbility = Cast<UHiGameplayAbility>(Ability);
		OnCompleted.AddDynamic(HiAbility, &UHiGameplayAbility::OnCompleted);
		OnBlendOut.AddDynamic(HiAbility, &UHiGameplayAbility::OnBlendOut);
		OnInterrupted.AddDynamic(HiAbility, &UHiGameplayAbility::OnInterrupted);
		OnCancelled.AddDynamic(HiAbility, &UHiGameplayAbility::OnCancelled);
		
		const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
		UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();
		if (AnimInstance != nullptr)
		{
			InterruptedHandle = Ability->OnGameplayAbilityCancelled.AddUObject(this, &UHiAbilityTask_PlayMontage::OnMontageInterrupted);

			BlendingOutDelegate.BindUObject(this, &UHiAbilityTask_PlayMontage::OnMontageBlendingOut);
			AnimInstance->Montage_SetBlendingOutDelegate(BlendingOutDelegate, MontageToPlay);

			MontageEndedDelegate.BindUObject(this, &UHiAbilityTask_PlayMontage::OnMontageEnded);
			AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, MontageToPlay);
		}
	}
}
#endif
