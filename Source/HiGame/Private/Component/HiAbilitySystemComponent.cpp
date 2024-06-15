// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiAbilitySystemComponent.h"
#include "AbilitySystemGlobals.h"
#include "AbilitySystemLog.h"
#include "AbilitySystemStats.h"
#include "Characters/HiCharacter.h"
#include "Sequence/HiLevelSequencePlayer.h"
#include "Animation/AnimInstance.h"
#include "Attributies/HiAttributeSet.h"


UHiAbilitySystemComponent* GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent)
{
	return Cast<UHiAbilitySystemComponent>(UAbilitySystemGlobals::GetAbilitySystemComponentFromActor(Actor, LookForComponent));
}



UHiAbilitySystemComponent::UHiAbilitySystemComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{

}

void UHiAbilitySystemComponent::OnRegister()
{
	Super::OnRegister();
	
	this->GameplayEffectRemovedHandle = OnAnyGameplayEffectRemovedDelegate().AddUObject(this, &UHiAbilitySystemComponent::OnAnyGameplayEffectRemoved);
	this->GameplayEffectTagCountChangedHandle = RegisterGenericGameplayTagEvent().AddUObject(this, &UHiAbilitySystemComponent::OnGameplayEffectTagCountChangedCallback);
}

void UHiAbilitySystemComponent::OnUnregister()
{
	Super::OnUnregister();
	
	OnAnyGameplayEffectRemovedDelegate().Remove(this->GameplayEffectRemovedHandle);
	RegisterGenericGameplayTagEvent().Remove(this->GameplayEffectTagCountChangedHandle);
}

void UHiAbilitySystemComponent::OnComponentDestroyed(bool bDestroyingHierarchy) {
	//if (GetOwnerActor()) {
	//	UE_LOG(LogAbilitySystem, Error, TEXT("OnComponentDestroyed, owner: %s, role: %s"),
	//		*GetOwnerActor()->GetName(), *UEnum::GetValueAsString(TEXT("Engine.ENetRole"), GetOwnerActor()->GetLocalRole()));
	//	FDebug::DumpStackTraceToLog(ELogVerbosity::Error);
	//}

	DestroyActiveState();

	// The MarkPendingKill on these attribute sets used to be done in UninitializeComponent,
	// but it was moved here instead since it's possible for the component to be uninitialized,
	// and later re-initialized, without being destroyed - and the attribute sets need to be preserved
	// in this case. This can happen when the owning actor's level is removed and later re-added
	// to the world, since EndPlay (and therefore UninitializeComponents) will be called on
	// the owning actor when its level is removed.
	for (UAttributeSet* Set : GetSpawnedAttributes())
	{
		// Common Attribute not destroy by single ASC.
		UHiAttributeSet* HiSet = Cast<UHiAttributeSet>(Set);
		if (HiSet && HiSet->bCommonAttribute) {
			continue;
		}

		if (Set)
		{
			Set->MarkAsGarbage();
		}
	}

	// Call the super at the end, after we've done what we needed to do
	Super::UActorComponent::OnComponentDestroyed(bDestroyingHierarchy);
}

bool UHiAbilitySystemComponent::TryActivateAbilityByClassParam(TSubclassOf<UGameplayAbility> InAbilityToActivate, UAnimMontage* InMontageToPlay, bool bAllowRemoteActivation)
{
	return true;
}


bool UHiAbilitySystemComponent::TryActivateAbilityFromGameplayEvent(TSubclassOf<UGameplayAbility> InAbilityToActivate, FGameplayTag EventTag,  struct FGameplayEventData Payload )
{  
	bool bSuccess = false;
		
	const UGameplayAbility* const InAbilityCDO = InAbilityToActivate.GetDefaultObject();
	FGameplayAbilityActorInfo* ActorInfo = AbilityActorInfo.Get();
	for (const FGameplayAbilitySpec& Spec : ActivatableAbilities.Items)
	{
		if (Spec.Ability == InAbilityCDO)
		{
			bSuccess |= TriggerAbilityFromGameplayEvent(Spec.Handle, ActorInfo, EventTag, &Payload, *this);
			break;
		}
	}
	
	return bSuccess;	
}

void UHiAbilitySystemComponent::BP_CancelAbilityHandle(const FGameplayAbilitySpecHandle& AbilityHandle)
{
	CancelAbilityHandle(AbilityHandle);
}

bool UHiAbilitySystemComponent::BP_TryActivateAbilityByHandle(FGameplayAbilitySpecHandle AbilityToActivate,
	bool bAllowRemoteActivation)
{
	return TryActivateAbility(AbilityToActivate, bAllowRemoteActivation);
}

FGameplayAbilitySpecHandle UHiAbilitySystemComponent::FindAbilitySpecHandleFromInputID(int32 InputID)
{
	FGameplayAbilitySpec* AbilitySpec = FindAbilitySpecFromInputID(InputID);
	if (AbilitySpec)
	{
		return AbilitySpec->Handle;
	}
	return FGameplayAbilitySpecHandle();
}

FGameplayAbilitySpecHandle UHiAbilitySystemComponent::FindAbilitySpecHandleFromClass(TSubclassOf<UGameplayAbility> InAbilityClass)
{
	auto Spec = FindAbilitySpecFromClass(InAbilityClass);
	if (Spec)
	{
		return Spec->Handle;
	}
	return FGameplayAbilitySpecHandle();
}

void UHiAbilitySystemComponent::BP_CancelAbilities(UGameplayAbility* Ignore)
{
	Super::CancelAllAbilities(Ignore);
}

bool UHiAbilitySystemComponent::CanApplyGE(const UGameplayEffect* GameplayEffect, float Level, const FGameplayEffectContextHandle& EffectContext)
{
	return CanApplyAttributeModifiers(GameplayEffect, Level, EffectContext);
}

bool UHiAbilitySystemComponent::SetGameplayEffectDurationHandle(FActiveGameplayEffectHandle Handle, float NewDuration)
{
	if (!Handle.IsValid())
	{
		return false;
	}
		
	const FActiveGameplayEffect* cActiveGameplayEffect = GetActiveGameplayEffect(Handle);
	if (!cActiveGameplayEffect)
	{
		return false;
	}

	FActiveGameplayEffect* ActiveGameplayEffect = const_cast<FActiveGameplayEffect*>(cActiveGameplayEffect);
	if (NewDuration > 0)
	{
		ActiveGameplayEffect->Spec.Duration = NewDuration;
	}
	else
	{
		ActiveGameplayEffect->Spec.Duration = 0.0f;
	}

	ActiveGameplayEffect->StartServerWorldTime = ActiveGameplayEffects.GetServerWorldTime();
	ActiveGameplayEffect->CachedStartServerWorldTime = ActiveGameplayEffect->StartServerWorldTime;
	ActiveGameplayEffect->StartWorldTime = ActiveGameplayEffects.GetWorldTime();

	ActiveGameplayEffects.MarkItemDirty(*ActiveGameplayEffect);
	ActiveGameplayEffects.CheckDuration(Handle);

	ActiveGameplayEffect->EventSet.OnTimeChanged.Broadcast(ActiveGameplayEffect->Handle, ActiveGameplayEffect->StartWorldTime, ActiveGameplayEffect->GetDuration());
	OnGameplayEffectDurationChange(*ActiveGameplayEffect);
	return true;
}

bool UHiAbilitySystemComponent::RestartActiveGameplayEffectDuration(FActiveGameplayEffectHandle Handle)
{
	const FActiveGameplayEffect* cActiveGameplayEffect = GetActiveGameplayEffect(Handle);
	if (!cActiveGameplayEffect)
	{
		return false;
	}
	
	FActiveGameplayEffect* ActiveGameplayEffect = const_cast<FActiveGameplayEffect*>(cActiveGameplayEffect);
	ActiveGameplayEffect->StartServerWorldTime = ActiveGameplayEffects.GetServerWorldTime();
	ActiveGameplayEffect->CachedStartServerWorldTime = ActiveGameplayEffect->StartServerWorldTime;
	ActiveGameplayEffect->StartWorldTime = ActiveGameplayEffects.GetWorldTime();
	ActiveGameplayEffects.MarkItemDirty(*ActiveGameplayEffect);

	ActiveGameplayEffect->EventSet.OnTimeChanged.Broadcast(ActiveGameplayEffect->Handle, ActiveGameplayEffect->StartWorldTime, ActiveGameplayEffect->GetDuration());
	OnGameplayEffectDurationChange(*ActiveGameplayEffect);
	return true;
}

void UHiAbilitySystemComponent::GetActiveGameplayEffectRemainingAndDuration(FActiveGameplayEffectHandle Handle, float& Remaining, float& Duration) const
{
	if (!Handle.IsValid())
	{
		return;
	}
	
	float StartEffectTime = 0.0f;
	ActiveGameplayEffects.GetGameplayEffectStartTimeAndDuration(Handle, StartEffectTime, Duration);
	Remaining = FMath::Clamp(Duration - (ActiveGameplayEffects.GetWorldTime() - StartEffectTime), 0, Duration);
}

void UHiAbilitySystemComponent::OnAnyGameplayEffectRemoved(const FActiveGameplayEffect& Effect) const
{
	OnGameplayEffectRemoved.Broadcast(Effect);
}

void UHiAbilitySystemComponent::OnGameplayEffectTagCountChangedCallback(const FGameplayTag Tag, int32 NewCount) {
	OnGameplayEffectTagCountChanged.Broadcast(Tag, NewCount);
}

FTimerManager& UHiAbilitySystemComponent::GetTimerManager() const
{
	AHiCharacter *Character = Cast<AHiCharacter>(GetOwnerActor());

	if (Character)
	{
		return Character->GetTimerManager();
	}

	return Super::GetTimerManager();
}

bool UHiAbilitySystemComponent::HasGameplayTag(FGameplayTag Tag) const
{
	return Super::HasMatchingGameplayTag(Tag);
}

void UHiAbilitySystemComponent::SetGameplayTag(FGameplayTag Tag, int32 Count)
{
	SetTagMapCount(Tag, Count);
}

void UHiAbilitySystemComponent::OnRep_ActivateAbilities()
{
	Super::OnRep_ActivateAbilities();
	if (IsOwnerActorAuthoritative())
	{
		ABILITY_LOG(Error, TEXT("OnRep_ActivateAbilities called on Server"));
	}
	else
	{		
		AHiCharacter* CharacterAbility = Cast<AHiCharacter>(GetAvatarActor());
		if (IsValid(CharacterAbility))
		{
			CharacterAbility->ClientOnRep_ActivateAbilities();
		}
	}
}

void UHiAbilitySystemComponent::OnGiveAbility(FGameplayAbilitySpec& AbilitySpec)
{
	BP_OnGiveAbility(AbilitySpec.Handle);

	UHiGameplayAbility* Ability = Cast<UHiGameplayAbility>(AbilitySpec.GetPrimaryInstance());
	if (Ability)
	{
		Ability->OnGive();
	}

	Super::OnGiveAbility(AbilitySpec);
}

void UHiAbilitySystemComponent::OnRemoveAbility(FGameplayAbilitySpec& AbilitySpec)
{
	BP_OnRemoveAbility(AbilitySpec.Handle);

	UHiGameplayAbility* Ability = Cast<UHiGameplayAbility>(AbilitySpec.GetPrimaryInstance());
	if (Ability)
	{
		Ability->OnRemove();
	}

	Super::OnRemoveAbility(AbilitySpec);
}

void UHiAbilitySystemComponent::InitAbilityActorInfo(AActor* InOwnerActor, AActor* InAvatarActor)
{
	Super::InitAbilityActorInfo(InOwnerActor, InAvatarActor);
}

void UHiAbilitySystemComponent::OnImmunityBlockGameplayEffect(const FGameplayEffectSpec& Spec, const FActiveGameplayEffect* ImmunityGE)
{
	Super::OnImmunityBlockGameplayEffect(Spec, ImmunityGE);

	this->BP_OnImmunityBlockGameplayEffect(Spec, *ImmunityGE);
}

FGameplayAbilityActorInfo UHiAbilitySystemComponent::GetAbilityActorInfo()
{
	if (!ensure(AbilityActorInfo))
	{
		return FGameplayAbilityActorInfo();
	}
	return *AbilityActorInfo;
}

void UHiAbilitySystemComponent::BP_RefreshAbilityActorInfo()
{
	RefreshAbilityActorInfo();
}

void UHiAbilitySystemComponent::SetReplicationMode(EGameplayEffectReplicationMode NewReplicationMode)
{
	Super::SetReplicationMode(NewReplicationMode);
}

bool UHiAbilitySystemComponent::CanClientPredict() const
{
	return CanPredict();
}

float UHiAbilitySystemComponent::GetCurrentMontagePosition() const
{
	UAnimInstance* AnimInstance = AbilityActorInfo.IsValid() ? AbilityActorInfo->GetAnimInstance() : nullptr;
	UAnimMontage* CurrentAnimMontage = GetCurrentMontage();
	if (CurrentAnimMontage && AnimInstance && AnimInstance->Montage_IsActive(CurrentAnimMontage))
	{
		return AnimInstance->Montage_GetPosition(CurrentAnimMontage);
	}
	
	return -1.f;
}

const UAnimSequenceBase* UHiAbilitySystemComponent::GetCurrentAnimSequence() const
{
	auto SectionID = GetCurrentMontageSectionID();
	if (SectionID < 0)
	{
		return nullptr;
	}
	
	UAnimMontage* CurrentAnimMontage = GetCurrentMontage();
	auto CompositeSequence = CurrentAnimMontage->GetAnimCompositeSection(SectionID);
	return CompositeSequence.GetLinkedSequence();
}

void UHiAbilitySystemComponent::GetCurrentAnimSequenceStartAndEndTime(float& OutStartTime, float& OutEndTime) const
{
	auto SectionID = GetCurrentMontageSectionID();
	UAnimMontage* CurrentAnimMontage = GetCurrentMontage();
	CurrentAnimMontage->GetSectionStartAndEndTime(SectionID, OutStartTime, OutEndTime);
}

UAnimMontage* UHiAbilitySystemComponent::BP_GetCurrentMontage() const
{
	return Super::GetCurrentMontage();
}

void UHiAbilitySystemComponent::SetAttributeBaseValue(const FGameplayAttribute& Attribute, float NewBaseValue)
{
	this->SetNumericAttributeBase(Attribute, NewBaseValue);
}

float UHiAbilitySystemComponent::GetAttributeBaseValue(const FGameplayAttribute &Attribute)
{
	return GetNumericAttributeBase(Attribute);
}

void UHiAbilitySystemComponent::SetAttributeCurrentValue(const FGameplayAttribute& Attribute, float NewValue) {
	SetNumericAttribute_Internal(Attribute, NewValue);
}

float UHiAbilitySystemComponent::GetAttributeCurrentValue(const FGameplayAttribute &Attribute)
{
	return GetNumericAttribute(Attribute);
}

FGameplayAttribute UHiAbilitySystemComponent::FindAttributeByName(FName Name)
{
	TArray<FGameplayAttribute> Attributes;
	this->GetAllAttributes(Attributes);

	for (FGameplayAttribute Attr : Attributes)
	{
		if (Attr.AttributeName == Name.ToString()) return Attr;
	}

	return FGameplayAttribute();
}

void UHiAbilitySystemComponent::MulticastOther_PlaySequence_Implementation(ULevelSequence* SequenceToPlay, const FMovieSceneSequencePlaybackSettings& Settings, const TArray<FAbilityTaskSequenceBindings>& Bindings)
{
	if (GetAvatarActor()->GetLocalRole() != ROLE_SimulatedProxy)
	{
		return;
	}
	
	// ABILITY_LOG(Warning, TEXT("MulticastOther_PlaySequence: %s"), *SequenceToPlay->GetDisplayName().ToString());
	StopSequence();

	ALevelSequenceActor* SequenceActor;
	ULevelSequencePlayer* SequencePlayer = UHiLevelSequencePlayer::CreateHiLevelSequencePlayer(this, SequenceToPlay, Settings, SequenceActor);
	if (SequenceActor && SequencePlayer)
	{
		this->LevelSequenceActor = SequenceActor;
		this->LevelSequencePlayer = SequencePlayer;
		this->CurrentSequenceInPlay = SequenceToPlay;
		
		// Set level sequence actor bindings.
		for (const FAbilityTaskSequenceBindings& Binding : Bindings)
		{
			TArray<AActor*> CompBindingActors;

			for (int Ind = 0; Ind < Binding.Actors.Num(); Ind ++)
			{
				if (Binding.Actors[Ind] == nullptr)
				{
					if (Ind < Binding.BindingClasses.Num() && IsValid(Binding.BindingClasses[Ind]))
					{
						UWorld* CurWorld = GetWorld();
						if (CurWorld)
						{
							AActor* CreatedActor = CurWorld->SpawnActor(Binding.BindingClasses[Ind], &Binding.BindingTransforms[Ind]);
							if (CreatedActor)
							{
								CompBindingActors.Add(CreatedActor);
								ActorsSpawnedInSequence.Add(CreatedActor);
							}
						}
					}
				}
				else
				{
					CompBindingActors.Add(Binding.Actors[Ind]);
				}
			}
			
			LevelSequenceActor->SetBindingByTag(Binding.BindingTag, CompBindingActors, Binding.bAllowBindingsFromAsset);
		}

		LevelSequencePlayer->Play();
		LevelSequencePlayer->OnStop.AddDynamic(this, &UHiAbilitySystemComponent::StopSequence);
		LevelSequencePlayer->OnFinished.AddDynamic(this, &UHiAbilitySystemComponent::UHiAbilitySystemComponent::OnFinishedSequence);
	}
}

void UHiAbilitySystemComponent::MulticastOther_StopSequence_Implementation(ULevelSequence* SequenceToPlay)
{
	if (GetAvatarActor()->GetLocalRole() != ROLE_SimulatedProxy)
	{
		return;
	}
	
	if (SequenceToPlay && SequenceToPlay != CurrentSequenceInPlay)
	{
		return;
	}

	this->StopSequence();
}

void UHiAbilitySystemComponent::StopSequence()
{
	if (!CurrentSequenceInPlay)
	{
		return;
	}

	if (IsValid(LevelSequencePlayer))
	{
		LevelSequencePlayer->OnStop.RemoveDynamic(this, &UHiAbilitySystemComponent::StopSequence);
		// LevelSequencePlayer->OnFinished.RemoveDynamic(this, &UHiAbilitySystemComponent::UHiAbilitySystemComponent::OnFinishedSequence);
		
		// ABILITY_LOG(Warning, TEXT("UHiAbilitySystemComponent stop sequence: %s, %d"), *CurrentSequenceInPlay->GetDisplayName().ToString(), GetAvatarActor()->GetLocalRole());
		// FDebug::DumpStackTraceToLog(ELogVerbosity::Error);
		LevelSequencePlayer->Stop();
	}

	// if (IsValid(LevelSequenceActor))
	// {
	// 	LevelSequenceActor->Destroy();
	// 	LevelSequenceActor = nullptr;
	// }

	CurrentSequenceInPlay = nullptr;
	ClearSequenceSpawnedActors();
}

void UHiAbilitySystemComponent::ClearSequenceSpawnedActors()
{
	for (auto SActor : ActorsSpawnedInSequence)
	{
		if (IsValid(SActor))
		{
			SActor->Destroy();
		}
	}
	
	ActorsSpawnedInSequence.Empty();
}

void UHiAbilitySystemComponent::OnStopSequence()
{
	ClearSequenceSpawnedActors();
}

void UHiAbilitySystemComponent::OnFinishedSequence()
{
	if (IsValid(LevelSequenceActor))
	{
		LevelSequenceActor->Destroy();
		LevelSequenceActor = nullptr;
	}
	
	ClearSequenceSpawnedActors();
}

void UHiAbilitySystemComponent::AddAttributeSet(UAttributeSet* AttrSet)
{
	this->AddSpawnedAttribute(AttrSet);
	this->ForceReplication();
}

void UHiAbilitySystemComponent::RemoveAttributeSet(UAttributeSet* AttrSet)
{
	this->RemoveSpawnedAttribute(AttrSet);
	this->ForceReplication();
}

bool UHiAbilitySystemComponent::HasActivateAbilities() const
{	
	for (const FGameplayAbilitySpec& Spec : ActivatableAbilities.Items)
	{
		if (Spec.IsActive())
		{
			return true;
		}
	}
	return false;
}

bool UHiAbilitySystemComponent::HasActivateAbilityByClass(TSubclassOf<UGameplayAbility> InAbilityClass)
{
	const auto SpecHandle = FindAbilitySpecFromClass(InAbilityClass);
	if (SpecHandle && SpecHandle->IsActive())
	{
		return true;
	}		
	return false;
}
