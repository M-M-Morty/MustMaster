// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiAvatarSkeletalMeshComponent.h"

#include "Animation/SkeletonRemapping.h"
#include "Animation/SkeletonRemappingRegistry.h"
#include "Async/Async.h"
#include "Characters/HiCharacter.h"


DEFINE_LOG_CATEGORY_STATIC(HiAvatarSkeletalMeshComponent, Log, All);

void UHiAvatarSkeletalMeshComponent::BeginPlay()
{
	Super::BeginPlay();
	if(AHiCharacter* Character = GetOwner<AHiCharacter>())
	{
		Character->ReceiveControllerChangedDelegate.AddUniqueDynamic(this, &UHiAvatarSkeletalMeshComponent::OnReceiveControllerChanged);
	}
}

void UHiAvatarSkeletalMeshComponent::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	
	if(AHiCharacter* Character = GetOwner<AHiCharacter>())
	{
		Character->ReceiveControllerChangedDelegate.RemoveDynamic(this, &UHiAvatarSkeletalMeshComponent::OnReceiveControllerChanged);
	}
	Super::EndPlay(EndPlayReason);
}

void UHiAvatarSkeletalMeshComponent::OnReceiveControllerChanged(APawn* InPawn, AController* OldController,
	AController* NewController)
{
	if(APawn* Owner = GetOwner<APawn>())
	{
		if (Owner != InPawn)
		{
			return;
		}
		if (NewController)
		{
			UpdateAnimNodeSyncedAnimSequence();
		}
	}
}


void UHiAvatarSkeletalMeshComponent::InitializeBaseSkeletonAnimSequence()
{
	USkeleton* Skeleton = GetSkeleton();
	if(!Skeleton)
    {
    	return;
    }
    if(!AnimSequencePathMap.IsEmpty())
    {
    	return;
    }
	const FString SkeletonName = Skeleton->GetName();
	if(AnimNamePrefixTag.IsEmpty())
	{
		AnimNamePrefixTag = SkeletonName.Mid(3, SkeletonName.Find("_", ESearchCase::IgnoreCase, ESearchDir::FromStart,3)-3) + "_P_";
	}
	Super::InitializeBaseSkeletonAnimSequence();

	
	if(VehicleAnimationMappingDataTable)
	{
		VehicleAnimationMappingDataTable->ForeachRow<FHiAnimSequencePath>(TEXT("UHiSkeletalMeshComponent::InitializeComponent Initialize AnimSequencePathMap"),
			[this](const FName& Key, const FHiAnimSequencePath& Value)
			{
				BaseAnimSequencePathMap.Add(Key.ToString(), Value.AnimPath);
			}
		);
	}
}

void UHiAvatarSkeletalMeshComponent::GetSkeletonAnimationByTargetAnimation(UAnimSequenceBase* Anim)
{
	if(!Anim)
	{
		return;
	}
	const USkeleton * AnimSkeleton = Anim->GetSkeleton();
	const USkeleton * Skeleton = GetSkeleton();
	if (!AnimSkeleton || !Skeleton)
	{
		return;
	}
	const FString AnimName = Anim->GetName();
	if (AnimSkeleton == Skeleton)
	{
		return;
	}
	
	TArray<UAnimSequence*> Anims;
	do
	{
		const FSkeletonRemapping& Remapping = UE::Anim::FSkeletonRemappingRegistry::Get().GetRemapping(AnimSkeleton, Skeleton);
		if(Remapping.IsValid())
		{
			if (UAnimSequence* TargetAnim = GetSkeletonAnimation(AnimName))
			{
				Anims.Emplace(TargetAnim);
			}
			break;
		}

		if (BaseAnimSequencePathMap.Contains(AnimName))
		{
			//base body
			if (UAnimSequence* BaseAnim = GetBaseSkeletonAnimation(AnimName))
			{
				Anims.Emplace(BaseAnim);
				//clothes
				if (UAnimSequence* TargetAnim = GetSkeletonAnimation(AnimName))
				{
					Anims.Emplace(TargetAnim);
				}
				break;
			}
		}
		break;
	}
	while (false);
	
	if(const AHiCharacter* Character= Cast<AHiCharacter>(GetOwner()))
	{
		if(!Character->Controller)
		{
			return;
		}
	}
	for(UAnimSequence* TargetAnim : Anims)
	{
		Anim->AddAnimSequenceForFillTargetSkeleton(TargetAnim);
	}
}

bool UHiAvatarSkeletalMeshComponent::NeedFillTargetSkeletonPose()
{
	return bFillTargetSkeletonPose;
}

UAnimSequence* UHiAvatarSkeletalMeshComponent::GetBaseSkeletonAnimation(const FString& AnimName)
{
	if(AnimName.IsEmpty())
	{
		return nullptr;
	}
	if(TObjectPtr<UAnimSequence>* AnimSequence = BaseSkeletonAnimations.Find(AnimName))
	{
		return *AnimSequence;
	}
	const USkeleton * Skeleton = GetSkeleton();
	if (!Skeleton)
	{
		return nullptr;
	}
	const FString SkeletonName = Skeleton->GetName();
	if(FString * res = BaseAnimSequencePathMap.Find(AnimName))
	{
		FString AnimPath = *res;
		if(!IsInGameThread())
		{
			AsyncTask(ENamedThreads::GameThread, [this,AnimName, AnimPath]() mutable {
				LoadBaseSkeletonAnimation(AnimName, AnimPath);
			});
			UE_LOG(HiAvatarSkeletalMeshComponent, Log, TEXT("GetSkeletonAnimation  %s is not in IsInGameThread, run AsyncTask"), *AnimName);
			return nullptr;
		}
		
		UAnimSequence* Anim = LoadBaseSkeletonAnimation(AnimName, AnimPath);
		if(Anim)
		{
			UE_LOG(HiAvatarSkeletalMeshComponent, Log, TEXT("GetSkeletonAnimation [%s]: %s Created successfully"), *SkeletonName, *AnimName);
			return Anim;
		}
	}
	UE_LOG(HiAvatarSkeletalMeshComponent, Warning, TEXT("GetSkeletonAnimation [%s]: %s Does not exist"), *SkeletonName, *AnimName);
	return nullptr;	
}

UAnimSequence* UHiAvatarSkeletalMeshComponent::LoadBaseSkeletonAnimation(const FString& AnimName,
                                                                         const FString& AnimPath)
{
	UAnimSequence* Anim = LoadObject<UAnimSequence>(nullptr,  *AnimPath);
	if(Anim)
	{
		BaseSkeletonAnimations.Emplace(AnimName, Anim);
		return Anim;
	}
	return nullptr;
}

void UHiAvatarSkeletalMeshComponent::SyncAnimSequence(UAnimSequenceBase* AnimationSequence)
{
	Super::SyncAnimSequence(AnimationSequence);
}
