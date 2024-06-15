// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiSkillComponent.h"
#include "GameplayTagsManager.h"
#include "Characters/HiCharacter.h"
#include "Component/HiAbilitySystemComponent.h"

UHiSkillComponent::UHiSkillComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	PrimaryComponentTick.bStartWithTickEnabled = false;
	PrimaryComponentTick.bCanEverTick = false;
	SetIsReplicatedByDefault(true);
	AbilitySystemComponent = nullptr;
	bPawnReadyToInitialize = false;
}

void UHiSkillComponent::InitializeAbilitySystem(UHiAbilitySystemComponent* InASC, AActor* InOwnerActor)
{
	check(InASC);
	check(InOwnerActor);
	
	if (AbilitySystemComponent == InASC)
	{
		// the ability system hasn`t changed
		return;
	}

	if (AbilitySystemComponent)
	{
		// clean up the old ability system compoent
		UninitializeAbilitySystem();
	}

	APawn* Pawn = GetPawnChecked<APawn>();
	AActor* ExistingAvatar = InASC->GetAvatarActor();

	if ((ExistingAvatar != nullptr) && (ExistingAvatar != Pawn))
	{
		// There is already a pawn acting as the ASC's avatar, so we need to kick it out
		// This can happen on clients if they're lagged: their new pawn is spawned + possessed before the dead one is removed
		//ensure(!ExistingAvatar->HasAuthority());
		if (UHiSkillComponent* OtherSkillComponent = FindSkillComponent(ExistingAvatar))
		{
			OtherSkillComponent->UninitializeAbilitySystem();
		}
	}

	AbilitySystemComponent = InASC;
	AbilitySystemComponent->InitAbilityActorInfo(InOwnerActor, Pawn);
	this->RegisterASCCallback();

	AHiCharacter* Owner = Cast<AHiCharacter>(Pawn);
	if(Owner)
	{
		Owner->OnAbilitySystemInitialized();
	}
	
	OnAbilitySystemInitialized.Broadcast();
}

void UHiSkillComponent::UninitializeAbilitySystem()
{
	if (!AbilitySystemComponent)
	{
		return ;
	}

	// Uninitialize the ASC if we're still the avatar actor (otherwise another pawn already did it when they became the avatar actor)
	if (AbilitySystemComponent->GetAvatarActor() == GetOwner())
	{
		AbilitySystemComponent->CancelAbilities(nullptr, nullptr);
		//AbilitySystemComponent->ClearAbilityInput();
		AbilitySystemComponent->RemoveAllGameplayCues();

		if (AbilitySystemComponent->GetOwnerActor() != nullptr)
		{
			AbilitySystemComponent->SetAvatarActor(nullptr);
		}
		else
		{
			// If the ASC doesn't have a valid owner, we need to clear *all* actor info, not just the avatar pairing
			AbilitySystemComponent->ClearActorInfo();
		}

		this->UnRegisterASCCallback();

		APawn* Pawn = GetPawnChecked<APawn>();
		AHiCharacter* Owner = Cast<AHiCharacter>(Pawn);
		if(Owner)
		{
			Owner->OnAbilitySystemUninitialized();
		}
		
		OnAbilitySystemUninitialized.Broadcast();
	}
	AbilitySystemComponent = nullptr;
}

void UHiSkillComponent::HandleControllerChanged()
{
	if (AbilitySystemComponent && (AbilitySystemComponent->GetAvatarActor() == GetPawnChecked<APawn>()))
	{
		ensure(AbilitySystemComponent->AbilityActorInfo->OwnerActor == AbilitySystemComponent->GetOwnerActor());
		if (AbilitySystemComponent->GetOwnerActor() == nullptr)
		{
			UninitializeAbilitySystem();
		}
		else
		{
			AbilitySystemComponent->RefreshAbilityActorInfo();
		}
	}
	CheckPawnReadyToInitialize();
}

void UHiSkillComponent::HandlePlayerStateReplicated()
{
	CheckPawnReadyToInitialize();
}

void UHiSkillComponent::SetupPlayerInputComponent()
{
	CheckPawnReadyToInitialize();
}

bool UHiSkillComponent::CheckPawnReadyToInitialize()
{
	if (bPawnReadyToInitialize)
	{
		return true;
	}

	APawn* Pawn = GetPawnChecked<APawn>();

	const bool bHasAuthority = Pawn->HasAuthority();
	const bool bIsLocallyControlled = Pawn->IsLocallyControlled();

	if (bHasAuthority || bIsLocallyControlled)
	{
		// Check for being possessed by a controller.
		if (!GetController<AController>())
		{
			return false;
		}
	}

	// Allow pawn components to have requirements.
	TArray<UActorComponent*> InteractableComponents = Pawn->GetComponentsByInterface(UHiReadyInterface::StaticClass());

	for (UActorComponent* InteractableComponent : InteractableComponents)
	{
		const IHiReadyInterface* Ready = CastChecked<IHiReadyInterface>(InteractableComponent);
		if (!Ready->IsPawnComponentReadyToInitialize())
		{
			return false;
		}
	}

	// Pawn is ready to initialize.
	bPawnReadyToInitialize = true;
	OnPawnReadyToInitialize.Broadcast();
	BP_OnPawnReadyToInitialize.Broadcast();
	
	return true;
}

void UHiSkillComponent::OnRegister()
{
	Super::OnRegister();

	const APawn* Pawn = GetPawn<APawn>();
	ensureAlwaysMsgf((Pawn != nullptr), TEXT("HiSkillComponent on [%s] can only be added to Pawn Actors."), *GetNameSafe(GetOwner()));

	TArray<UActorComponent*> SkillComponents;
	Pawn->GetComponents(UHiSkillComponent::StaticClass(), SkillComponents);
	// LevelSequence convert to spawnable will created another trash component
	ensureAlwaysMsgf(
		SkillComponents.Num() == 1 ||
		(SkillComponents.Num() == 2 && SkillComponents[0]->GetName().Find(TEXT("TRASH_")) != INDEX_NONE),
		TEXT("Only one HiSkillComponent should exist on [%s]."), *GetNameSafe(GetOwner())
	);
}

void UHiSkillComponent::OnPawnReadyToInitialize_RegisterAndCall(FSimpleMulticastDelegate::FDelegate Delegate)
{
	if (!OnPawnReadyToInitialize.IsBoundToObject(Delegate.GetUObject()))
	{
		OnPawnReadyToInitialize.Add(Delegate);
	}

	if (bPawnReadyToInitialize)
	{
		Delegate.Execute();
	}
}

FGameplayAbilitySpecHandle UHiSkillComponent::GiveAbility(TSubclassOf<UGameplayAbility> AbilityType, int32 InputID, UGameplayAbilityUserData* UserData, int32 SkillLevel)
{
	if (HasAuthority() && IsValid(AbilityType) && IsValid(AbilitySystemComponent))
	{
		return AbilitySystemComponent->GiveAbility(FGameplayAbilitySpec(AbilityType, SkillLevel, InputID, nullptr, UserData));
	}
	else
	{
		return FGameplayAbilitySpecHandle();
	}
}

void UHiSkillComponent::SetAbilityLevel(TSubclassOf<UGameplayAbility> AbilityType, int32 NewLevel)
{
	if (HasAuthority() && IsValid(AbilityType) && IsValid(AbilitySystemComponent))
	{
		for(auto& Item :  AbilitySystemComponent->GetActivatableAbilities())
		{
			if(Item.Ability == AbilityType.GetDefaultObject())
			{
				Item.Level = NewLevel;
				break;
			}
		}
	}	
}

void UHiSkillComponent::SetRemoveAbilityOnEnd(FGameplayAbilitySpecHandle AbilitySpecHandle)
{
	if (HasAuthority() && IsValid(AbilitySystemComponent))
	{
		return AbilitySystemComponent->SetRemoveAbilityOnEnd(AbilitySpecHandle);
	}
}

void UHiSkillComponent::RegisterASCCallback()
{
	ImmunityCallbackHandle = this->AbilitySystemComponent->OnImmunityBlockGameplayEffectDelegate.AddUObject(this, &UHiSkillComponent::ImmunityCallback);
}

void UHiSkillComponent::ImmunityCallback(const FGameplayEffectSpec& BlockedSpec, const FActiveGameplayEffect* ImmunityGE)
{
	this->OnImmunityBlockGameplayEffect(BlockedSpec, *ImmunityGE);
}

void UHiSkillComponent::UnRegisterASCCallback()
{
	if (ImmunityCallbackHandle.IsValid())
	{
		this->AbilitySystemComponent->OnImmunityBlockGameplayEffectDelegate.Remove(ImmunityCallbackHandle);
	}
}