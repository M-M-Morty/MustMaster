
#include "HiAbilities/HiGameplayAbility.h"

#include "Component/HiAbilitySystemComponent.h"
#include "GameplayAbilities/Public/AbilitySystemLog.h"
#include "Abilities/Tasks/AbilityTask_PlayMontageAndWait.h"
#include "HiAbilities/HiAbilityDataBase.h"


UHiGameplayAbility::UHiGameplayAbility(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer)
{
	auto ImplementedInBlueprint = [](const UFunction* Func) -> bool
	{
		return Func && ensure(Func->GetOuter())
			&& (Func->GetOuter()->IsA(UBlueprintGeneratedClass::StaticClass()) || Func->GetOuter()->IsA(UDynamicClass::StaticClass()));
	};

	{
		static FName FuncName = FName(TEXT("K2_ActivateAbilityParams"));
		UFunction* ActivateFunction = GetClass()->FindFunctionByName(FuncName);
		bHasBlueprintActivateParams = ImplementedInBlueprint(ActivateFunction);
	}	
}

void UHiGameplayAbility::PreTransfer()
{
	
}

void UHiGameplayAbility::SerializeTransferPrivateData(FArchive& Ar, UPackageMap* PackageMap)
{
	Super::SerializeTransferPrivateData(Ar, PackageMap);
	Ar << MontageToPlay;
	Ar << SequenceToPlay;
	Ar << CameraSequenceToPlay;
	
	Ar << ActivateOnGranted;
	
	//Ar << CooldownDuration;

}

void UHiGameplayAbility::PostTransfer()
{
	K2_PostTransfer();
}

void UHiGameplayAbility::OnGiveAbility(const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilitySpec& Spec)
{
	Super::OnGiveAbility(ActorInfo, Spec);

	K2_OnGiveAbility();
}

void UHiGameplayAbility::OnRemoveAbility(const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilitySpec& Spec)
{
	Super::OnRemoveAbility(ActorInfo, Spec);

	K2_OnRemoveAbility();
}

bool UHiGameplayAbility::ShouldActivateAbility(ENetRole Role) const
{
	return (Role == ROLE_Authority || (NetSecurityPolicy != EGameplayAbilityNetSecurityPolicy::ServerOnly && NetSecurityPolicy != EGameplayAbilityNetSecurityPolicy::ServerOnlyExecution));	// Don't violate security policy if we're not the server
}

// ��д��Ĭ��ʵ�֣�K2_ActivateAbilityFromEvent ���ȼ����� K2_ActivateAbility
void UHiGameplayAbility::ActivateAbility(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo, const FGameplayEventData* TriggerEventData)
{
	if (bHasBlueprintActivateFromEvent)
	{
		if (TriggerEventData)
		{
			// A Blueprinted ActivateAbility function must call CommitAbility somewhere in its execution chain.
			K2_ActivateAbilityFromEvent(*TriggerEventData);
		}
		else
		{
			UE_LOG(LogAbilitySystem, Warning, TEXT("Ability %s expects event data but none is being supplied. Use Activate Ability instead of Activate Ability From Event."), *GetName());
			bool bReplicateEndAbility = false;
			bool bWasCancelled = true;
			EndAbility(Handle, ActorInfo, ActivationInfo, bReplicateEndAbility, bWasCancelled);
		}
	}
	else if (bHasBlueprintActivate)
	{
		// A Blueprinted ActivateAbility function must call CommitAbility somewhere in its execution chain.
		K2_ActivateAbility();
	}
	else
	{
		// Native child classes may want to override ActivateAbility and do something like this:

		// Do stuff...

		if (CommitAbility(Handle, ActorInfo, ActivationInfo))		// ..then commit the ability...
		{
			//	Then do more stuff...
		}
	}
}

void UHiGameplayAbility::OnCompleted()
{
	K2_OnCompleted();
}

void UHiGameplayAbility::OnBlendOut()
{
	K2_OnBlendOut();
}

void UHiGameplayAbility::OnInterrupted()
{
	K2_OnInterrupted();
}

void UHiGameplayAbility::OnCancelled()
{
	K2_OnCancelled();
}

UAbilityTask_PlayMontageAndWait* UHiGameplayAbility::CreatePlayMontageAndWaitProxy(FName TaskInstanceName,
	UAnimMontage* InMontageToPlay, float Rate, FName StartSection, bool bStopWhenAbilityEnds,
	float AnimRootMotionTranslationScale, float StartTimeSeconds)
{
	if (UAbilityTask_PlayMontageAndWait* InWait = UAbilityTask_PlayMontageAndWait::CreatePlayMontageAndWaitProxy(
		this, TaskInstanceName, InMontageToPlay, Rate, StartSection,
		bStopWhenAbilityEnds, AnimRootMotionTranslationScale, StartTimeSeconds))
	{
		InWait->OnBlendOut.AddDynamic(this, &UHiGameplayAbility::OnBlendOut);
		InWait->OnCompleted.AddDynamic(this, &UHiGameplayAbility::OnCompleted);
		InWait->OnInterrupted.AddDynamic(this, &UHiGameplayAbility::OnInterrupted);
		InWait->OnCancelled.AddDynamic(this, &UHiGameplayAbility::OnCancelled);

		InWait->Activate();
		return InWait;
	}
	return nullptr;
}

UAbilityTask_PlayMontageAndWait* UHiGameplayAbility::PlayMontage(FName StartSection)
{
	return CreatePlayMontageAndWaitProxy(NAME_None, MontageToPlay, 1.0f, StartSection);
}

int32 UHiGameplayAbility::GetCompositeSectionsNumber() const
{
	if (MontageToPlay)
	{
		return MontageToPlay->CompositeSections.Num();
	}
	return 0;
}

bool UHiGameplayAbility::MakeEffectContainerSpecByTag(FGameplayTag ContainerTag, int32 Level, FHiGameplayEffectContainer& EffectContainer, TArray<FGameplayEffectSpecHandle>& Specs)
{
	FHiGameplayEffectContainer* FoundContainer = EffectContainerMap.Find(ContainerTag);
	if (! FoundContainer)
	{
		return false;
	}

	if (Level == INDEX_NONE)
	{
		Level = this->GetAbilityLevel();
	}
	
	EffectContainer = *FoundContainer;
	for (const TSubclassOf<UGameplayEffect>& EffectClass : FoundContainer->TargetGameplayEffectClasses)
	{
		Specs.Add(MakeOutgoingGameplayEffectSpec(EffectClass, Level));
	}

	return true;
}


bool UHiGameplayAbility::MakeEffectContainerSpecByTagOfSelf(FGameplayTag ContainerTag, int32 Level, FHiGameplayEffectContainer& EffectContainer, TArray<FGameplayEffectSpecHandle>& Specs)
{
	FHiGameplayEffectContainer* FoundContainer = EffectContainerMap.Find(ContainerTag);
	if (!FoundContainer)
	{
		return false;
	}

	if (Level == INDEX_NONE)
	{
		Level = this->GetAbilityLevel();
	}

	EffectContainer = *FoundContainer;
	for (const TSubclassOf<UGameplayEffect>& EffectClass : FoundContainer->SelfGameplayEffectClasses)
	{
		Specs.Add(MakeOutgoingGameplayEffectSpec(EffectClass, Level));
	}

	return true;
}

TArray<FActiveGameplayEffectHandle> UHiGameplayAbility::ApplyEffectContainerSpec(const TArray<FGameplayEffectSpecHandle>& Specs, const FGameplayAbilityTargetDataHandle& TargetData)
{
	TArray<FActiveGameplayEffectHandle> AllEffects;

	for (const FGameplayEffectSpecHandle& EffectSpec : Specs)
	{
		AllEffects.Append(K2_ApplyGameplayEffectSpecToTarget(EffectSpec, TargetData));
	}

	return AllEffects;
}

void UHiGameplayAbility::OnAvatarSet(const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilitySpec& Spec)
{
	Super::OnAvatarSet(ActorInfo, Spec);

	if (ActivateOnGranted)
	{
		ABILITY_LOG(Display, TEXT("Auto active ability: %s"), *Spec.Ability->GetName());
		ActorInfo->AbilitySystemComponent->TryActivateAbility(Spec.Handle, true);
	}
}

const FGameplayTagContainer* UHiGameplayAbility::GetCooldownTags() const
{
	FGameplayTagContainer* MutableTags = const_cast<FGameplayTagContainer*>(&TempCooldownTags);
	MutableTags->Reset(); // MutableTags writes to the TempCooldownTags on the CDO so clear it in case the ability cooldown tags change (moved to a different slot)
	const FGameplayTagContainer* ParentTags = Super::GetCooldownTags();
	if (ParentTags)
	{
		MutableTags->AppendTags(*ParentTags);
	}
	MutableTags->AppendTags(CooldownTags);
	return MutableTags;
}



void UHiGameplayAbility::ApplyCooldown(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo* ActorInfo, const FGameplayAbilityActivationInfo ActivationInfo) const
{
	UGameplayEffect* CooldownGE = GetCooldownGameplayEffect();
	if (CooldownGE)
	{		
		FGameplayEffectSpecHandle SpecHandle = MakeOutgoingGameplayEffectSpec(CooldownGE->GetClass(), GetAbilityLevel());
		SpecHandle.Data.Get()->DynamicGrantedTags.AppendTags(CooldownTags);
		ApplyGameplayEffectSpecToOwner(Handle, ActorInfo, ActivationInfo, SpecHandle);
	}
}

bool UHiGameplayAbility::CanActivateAbilityWithHandle(const FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo ActorInfo, FGameplayTagContainer& OptionalRelevantTags) const
{
	return Super::CanActivateAbility(Handle, &ActorInfo, nullptr, nullptr, &OptionalRelevantTags);
}

void UHiGameplayAbility::GetCooldownRemainingAndDuration(FGameplayAbilitySpecHandle Handle, const FGameplayAbilityActorInfo ActorInfo, float& TimeRemaining, float& CD) const
{
	Super::GetCooldownTimeRemainingAndDuration(Handle, &ActorInfo, TimeRemaining, CD);
}

FGameplayAbilitySpecHandle UHiGameplayAbility::GetCurrentSpecHandle() const
{
	return this->GetCurrentAbilitySpecHandle();
}

void UHiGameplayAbility::ResetAbilityCD()
{
	//多段攻击需要重置CD
	if(!CooldownTags.IsEmpty() && CurrentActorInfo && CurrentActorInfo->AbilitySystemComponent.IsValid())
	{
		FGameplayEffectQuery const Query = FGameplayEffectQuery::MakeQuery_MatchAnyOwningTags(CooldownTags);
		TArray<FActiveGameplayEffectHandle> Effects = CurrentActorInfo->AbilitySystemComponent->GetActiveEffects(Query);
		for(auto ItemEffect : Effects)
		{
			float TimeRemaining(0.f);
			float CD(0.f);
			GetCooldownRemainingAndDuration(CurrentSpecHandle, *CurrentActorInfo, TimeRemaining, CD);
			CurrentActorInfo->AbilitySystemComponent->ModifyActiveEffectStartTime(ItemEffect, CD - TimeRemaining);
		}
	}
}

UGameplayEffect* UHiGameplayAbility::GetCostGameplayEffect() const
{
	return K2_GetCostGameplayEffect();
}

UGameplayEffect* UHiGameplayAbility::K2_GetCostGameplayEffect_Implementation() const
{
	return UGameplayAbility::GetCostGameplayEffect();
}

void UHiGameplayAbility::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);

	// Enable replicate of fields in blueprint subclass.
	UBlueprintGeneratedClass* BPClass = Cast<UBlueprintGeneratedClass>(GetClass());
	if (BPClass)
	{
		BPClass->GetLifetimeBlueprintReplicationList(OutLifetimeProps);
	}
}

UHiAbilityDataBase* UHiGameplayAbility::FindAbilityDataByClass(
	const TSubclassOf<UHiAbilityDataBase> AbilityDataClass) const
{
	for(auto& Item: AbilityData)
	{
		if(IsValid(Item))
		{
			if(Item->IsA(AbilityDataClass))
			{
				return Item;
			}
		}
	}

	return nullptr;
}