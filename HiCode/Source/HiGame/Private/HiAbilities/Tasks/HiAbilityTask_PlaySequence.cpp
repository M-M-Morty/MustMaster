// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/Tasks/HiAbilityTask_PlaySequence.h"

#include "AbilitySystemComponent.h"
#include "AbilitySystemLog.h"
#include "GameFramework/Character.h"

#include "Sequence/HiLevelSequencePlayer.h"
#include "Component/HiAbilitySystemComponent.h"

UHiAbilityTask_PlaySequence* UHiAbilityTask_PlaySequence::CreatePlaySequenceAndWaitProxy(UGameplayAbility* OwningAbility, FName TaskInstanceName, 
	ULevelSequence* SequenceToPlay, FMovieSceneSequencePlaybackSettings Settings, TArray<FAbilityTaskSequenceBindings> Bindings, bool bStopWhenAbilityEnds, 
	float AnimRootMotionTranslationScale, ULevelSequence* SequenceToPlayOnSimulated)
{
	UHiAbilityTask_PlaySequence* Task = NewAbilityTask<UHiAbilityTask_PlaySequence>(OwningAbility, TaskInstanceName);
	Task->SequenceToPlay = SequenceToPlay;
	Task->SequenceToPlayOnSimulated = SequenceToPlayOnSimulated;
	if (Task->SequenceToPlayOnSimulated == nullptr) {
		Task->SequenceToPlayOnSimulated = SequenceToPlay;
	}
	Task->Settings = Settings;
	Task->bStopWhenAbilityEnds = bStopWhenAbilityEnds;
	Task->AnimRootMotionTranslationScale = AnimRootMotionTranslationScale;

	// TODO: As actor may not replicated to client before rpc, so here sync actor's class and transform too.
	for (FAbilityTaskSequenceBindings& Binding : Bindings)
	{
		for (const auto BindingActor : Binding.Actors)
		{
			if (BindingActor)
			{
				Binding.BindingClasses.Add(BindingActor->GetClass());
				Binding.BindingTransforms.Add(BindingActor->GetTransform());
			}
		}
	}

	Task->Bindings = Bindings;

	Task->bStopWhenAbilityCanceled = true;

	return Task;
}

void UHiAbilityTask_PlaySequence::Activate()
{
	if (Ability == nullptr)
	{
		return;
	}

	bool bPlayedSequence = false;
	UHiAbilitySystemComponent* ASC = Cast<UHiAbilitySystemComponent>(AbilitySystemComponent);
	if (ASC)
	{
		LevelSequencePlayer = UHiLevelSequencePlayer::CreateHiLevelSequencePlayer(this, SequenceToPlay, Settings, LevelSequenceActor);
		if (LevelSequenceActor && LevelSequencePlayer)
		{
			// Set level sequence actor bindings.
			for (const FAbilityTaskSequenceBindings& Binding : Bindings)
			{
				LevelSequenceActor->SetBindingByTag(Binding.BindingTag, Binding.Actors, Binding.bAllowBindingsFromAsset);
			}

			InterruptedHandle = Ability->OnGameplayAbilityCancelled.AddUObject(this, &UHiAbilityTask_PlaySequence::OnAbilityCanceled);
			
			LevelSequencePlayer->OnPlay.AddDynamic(this, &UHiAbilityTask_PlaySequence::OnPlayCallback);
			LevelSequencePlayer->OnPause.AddDynamic(this, &UHiAbilityTask_PlaySequence::OnPauseCallback);
			LevelSequencePlayer->OnFinished.AddDynamic(this, &UHiAbilityTask_PlaySequence::OnFinishedCallback);
			LevelSequencePlayer->OnStop.AddDynamic(this, &UHiAbilityTask_PlaySequence::OnStopCallback);

			LevelSequencePlayer->Play();
			bPlayedSequence = true;

			SetRootMotionTranslationScale(AnimRootMotionTranslationScale);

			// TODO: Bindings actor may not replicated before rpc received by receiver.
			// DependsOn console variable net.DelayUnmappedRPCs to ensure replicate actors in params before rpc.
			if (ASC->GetAvatarActor()->GetLocalRole() == ROLE_Authority)
			{
#if WITH_EDITOR
				ABILITY_LOG(Verbose, TEXT("Invoke MulticastOther_PlaySequence with sequence: %s"), *this->SequenceToPlayOnSimulated->GetDisplayName().ToString())
#endif
				ASC->MulticastOther_PlaySequence(this->SequenceToPlayOnSimulated, Settings, Bindings);
			}
		}
	}
	else
	{
		ABILITY_LOG(Warning, TEXT("UHiAbilityTask_PlaySequence called on invalid AbilitySystemComponent"));
	}

	if (!bPlayedSequence)
	{
		ABILITY_LOG(Warning, TEXT("UHiAbilityTask_PlaySequence called in Ability %s failed to play sequence %s; Task Instance Name %s."), *Ability->GetName(), *GetNameSafe(SequenceToPlay),*InstanceName.ToString());
		if (ShouldBroadcastAbilityTaskDelegates())
		{
			OnStop.Broadcast();
		}
	}

	SetWaitingOnAvatar();
}

void UHiAbilityTask_PlaySequence::OnAbilityCanceled()
{
	if (bStopWhenAbilityCanceled && StopPlayingSequence())
	{
		OnStop.Broadcast();
	}
}

void UHiAbilityTask_PlaySequence::OnPlayCallback()
{
	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnPlay.Broadcast();
	}
}

void UHiAbilityTask_PlaySequence::OnPauseCallback()
{
	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnPause.Broadcast();
	}
}

void UHiAbilityTask_PlaySequence::OnStopCallback()
{
	SetRootMotionTranslationScale(1.0f);

	SyncStopSequence();

	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnStop.Broadcast();
	}
}

void UHiAbilityTask_PlaySequence::OnFinishedCallback()
{
	SetRootMotionTranslationScale(1.0f);

	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnFinished.Broadcast();
	}
}

void UHiAbilityTask_PlaySequence::ExternalCancel()
{
	check(AbilitySystemComponent.IsValid());

	if (ShouldBroadcastAbilityTaskDelegates())
	{
		OnStop.Broadcast();
	}
	Super::ExternalCancel();
}

bool UHiAbilityTask_PlaySequence::StopPlayingSequence()
{
	const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
	if (!ActorInfo)
	{
		return false;
	}

	UHiAbilitySystemComponent* ASC = Cast<UHiAbilitySystemComponent>(AbilitySystemComponent);
	if (ASC)
	{
		
		Ability->OnGameplayAbilityCancelled.Remove(InterruptedHandle);
		if (IsValid(LevelSequencePlayer) && LevelSequencePlayer->IsPlaying())
		{
			LevelSequencePlayer->OnPlay.RemoveDynamic(this, &UHiAbilityTask_PlaySequence::OnPlayCallback);
			LevelSequencePlayer->OnPause.RemoveDynamic(this, &UHiAbilityTask_PlaySequence::OnPauseCallback);
			LevelSequencePlayer->OnFinished.RemoveDynamic(this, &UHiAbilityTask_PlaySequence::OnFinishedCallback);
			LevelSequencePlayer->OnStop.RemoveDynamic(this, &UHiAbilityTask_PlaySequence::OnStopCallback);

			LevelSequencePlayer->Stop();

			// Replicate stop sequence to simulated client.
			SyncStopSequence();
		}

		return true;
	}

	return false;
}

void UHiAbilityTask_PlaySequence::SetRootMotionTranslationScale(float RootMotionTranslationScale)
{
	ACharacter* Character = Cast<ACharacter>(GetAvatarActor());
	if (Character && (Character->GetLocalRole() == ROLE_Authority ||
					  (Character->GetLocalRole() == ROLE_AutonomousProxy && Ability->GetNetExecutionPolicy() == EGameplayAbilityNetExecutionPolicy::LocalPredicted)))
	{
		Character->SetAnimRootMotionTranslationScale(RootMotionTranslationScale);
	}
}

void UHiAbilityTask_PlaySequence::SyncStopSequence()
{
	const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
	if (!ActorInfo)
	{
		return;
	}

	UHiAbilitySystemComponent* ASC = Cast<UHiAbilitySystemComponent>(AbilitySystemComponent);
	if (ASC)
	{
		// Replicate stop sequence to simulated client.
		if (ASC->GetAvatarActor()->GetLocalRole() == ROLE_Authority)
		{
#if WITH_EDITOR
			ABILITY_LOG(Verbose, TEXT("Invoke MulticastOther_StopSequence with sequence: %s"), *SequenceToPlay->GetDisplayName().ToString())
#endif
			ASC->MulticastOther_StopSequence(this->SequenceToPlayOnSimulated);
		}
	}
}

ALevelSequenceActor* UHiAbilityTask_PlaySequence::GetLevelSequenceActor() const
{
	return LevelSequenceActor;
}

ULevelSequencePlayer* UHiAbilityTask_PlaySequence::GetLevelSequencePlayer() const
{
	return LevelSequencePlayer;
}

void UHiAbilityTask_PlaySequence::OnDestroy(bool bAbilityEnded)
{
	if (Ability)
	{
		if (bAbilityEnded && bStopWhenAbilityEnds)
		{
			StopPlayingSequence();
		}
	}

	Super::OnDestroy(bAbilityEnded);
}
