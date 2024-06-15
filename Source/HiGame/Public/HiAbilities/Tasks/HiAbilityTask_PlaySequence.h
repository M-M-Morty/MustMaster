// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "LevelSequence.h"
#include "LevelSequenceActor.h"
#include "MovieSceneSequencePlayer.h"
#include "Abilities/Tasks/AbilityTask.h"
#include "HiAbilityTask_PlaySequence.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE(FSequnceWaitSimpleDelegate);

USTRUCT(BlueprintType)
struct FAbilityTaskSequenceBindings
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadWrite)
	FName BindingTag;

	UPROPERTY(BlueprintReadWrite)
	TArray<AActor*> Actors;

	UPROPERTY(BlueprintReadWrite)
	TArray<UClass*> BindingClasses;

	UPROPERTY(BlueprintReadWrite)
	TArray<FTransform> BindingTransforms;
	
	UPROPERTY(BlueprintReadWrite)
	bool bAllowBindingsFromAsset;
};

/**
 * Ability task to simply play sequence.
 */
UCLASS()
class HIGAME_API UHiAbilityTask_PlaySequence : public UAbilityTask
{
	GENERATED_BODY()

	/** Event triggered when the level sequence is played */
	UPROPERTY(BlueprintAssignable)
	FSequnceWaitSimpleDelegate OnPlay;

	/** Event triggered when the level sequence is stopped */
	UPROPERTY(BlueprintAssignable)
	FSequnceWaitSimpleDelegate OnStop;

	/** Event triggered when the level sequence is paused */
	UPROPERTY(BlueprintAssignable)
	FSequnceWaitSimpleDelegate OnPause;

	/** Event triggered when the level sequence finishes naturally (without explicitly calling stop) */
	UPROPERTY(BlueprintAssignable)
	FSequnceWaitSimpleDelegate OnFinished;

	FDelegateHandle InterruptedHandle;

	UFUNCTION()
	void OnPlayCallback();

	UFUNCTION()
	void OnStopCallback();

	UFUNCTION()
	void OnPauseCallback();

	UFUNCTION()
	void OnFinishedCallback();

	UFUNCTION()
	void OnAbilityCanceled();

	virtual void OnDestroy(bool bAbilityEnded) override;

	bool StopPlayingSequence();
	void SetRootMotionTranslationScale(float RootMotionTranslationScale);

	void SyncStopSequence();

public:
	/** 
	 * Start playing an level sequence and wait for it complete.
	 * If StopWhenAbilityEnds is true, this sequence will be aborted if the ability ends normally. It is always stopped when the ability is explicitly cancelled.
	 * On normal execution, OnFinished is called.
	 *
	 * @param TaskInstanceName Set to override the name of this task, for later querying
	 * @param SequenceToPlay Level sequence to play.
	 * @param Settings Settings for play level sequence.
	 * @param Bindings Bindings for level sequence actors.
	 * @param bStopWhenAbilityEnds If true, this montage will be aborted if the ability ends normally. It is always stopped when the ability is explicitly cancelled
	 * @param AnimRootMotionTranslationScale Change to modify size of root motion or set to 0 to block it entirely
	 * @param SequenceToPlayOnSimulated Level sequence to play on simulated, if is null will use SequenceToPlay.
	 * Attention Two sequence use same binding settings right now!
	 */
	UFUNCTION(BlueprintCallable, Category="Ability|Tasks", meta = (DisplayName="PlaySequenceAndWait",
		HidePin = "OwningAbility", DefaultToSelf = "OwningAbility", BlueprintInternalUseOnly = "TRUE"))
	static UHiAbilityTask_PlaySequence* CreatePlaySequenceAndWaitProxy(UGameplayAbility* OwningAbility, FName TaskInstanceName,
		ULevelSequence* SequenceToPlay, FMovieSceneSequencePlaybackSettings Settings, TArray<FAbilityTaskSequenceBindings> Bindings, 
		bool bStopWhenAbilityEnds=true, float AnimRootMotionTranslationScale=1.0,
		ULevelSequence* SequenceToPlayOnSimulated=nullptr);

	UFUNCTION(BlueprintPure, Category="Ability|Tasks")
	ALevelSequenceActor* GetLevelSequenceActor() const;

	UFUNCTION(BlueprintPure, Category="Ability|Tasks")
	ULevelSequencePlayer* GetLevelSequencePlayer() const;

	virtual void Activate() override;

	virtual void ExternalCancel() override;

protected:
	UPROPERTY()
	ULevelSequence* SequenceToPlay;

	UPROPERTY()
	ULevelSequence* SequenceToPlayOnSimulated;

	UPROPERTY()
	FMovieSceneSequencePlaybackSettings Settings;

	UPROPERTY()
	TArray<FAbilityTaskSequenceBindings> Bindings;

	UPROPERTY()
	float AnimRootMotionTranslationScale;
	
	UPROPERTY()
	bool bStopWhenAbilityEnds;
	
	UPROPERTY()
	bool bStopWhenAbilityCanceled;

private:
	ALevelSequenceActor* LevelSequenceActor;
	ULevelSequencePlayer* LevelSequencePlayer;
};
