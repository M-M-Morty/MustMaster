// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiSkeletalMeshComponent.h"

#include "FurComponent.h"
#include "SkeletalMergingLibrary.h"
#include "Characters/HiCharacterStructLibrary.h"
#include "Characters/Animation/HiAnimInstance.h"
#include "Component/HiAvatarLocomotionAppearance.h"
#include "Async/Async.h"
#include "Characters/HiCharacter.h"
#include "Rendering/SkeletalMeshRenderData.h"

DEFINE_LOG_CATEGORY_STATIC(HiSkeletalMeshComponent, Log, All);

TMap<FString,FString> UHiSkeletalMeshComponent::SkeletonAnimPrefixTags;

UHiSkeletalMeshComponent::UHiSkeletalMeshComponent(const FObjectInitializer& ObjectInitializer /*= FObjectInitializer::Get()*/)
	: Super(ObjectInitializer)
{
}

UHiSkeletalMeshComponent::~UHiSkeletalMeshComponent()
{
	SkeletonAnimations.Empty();
	AnimSequencePathMap.Empty();
}

void UHiSkeletalMeshComponent::OnChildAttached(USceneComponent* ChildComponent)
{
	Super::OnChildAttached(ChildComponent);
	OnChildAttachment.Broadcast(ChildComponent, true);
}

void UHiSkeletalMeshComponent::OnChildDetached(USceneComponent* ChildComponent)
{
	Super::OnChildDetached(ChildComponent);
	OnChildAttachment.Broadcast(ChildComponent, false);
}

void UHiSkeletalMeshComponent::OnRegister()
{
	InitializeBaseSkeletonAnimSequence();
	Super::OnRegister();
}


void UHiSkeletalMeshComponent::InitializeBaseSkeletonAnimSequence()
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
	if( AnimSequencePathDataTable)
	{
		AnimSequencePathDataTable->ForeachRow<FHiAnimSequencePath>(TEXT("UHiSkeletalMeshComponent::InitializeComponent Initialize AnimSequencePathMap"),
			[this](const FName& Key, const FHiAnimSequencePath& Value)
			{
				AnimSequencePathMap.Add(Key.ToString(), Value.AnimPath);
			}
		);
	}
	const FString SkeletonName = Skeleton->GetName();
	if(AnimNamePrefixTag.IsEmpty())
	{
		AnimNamePrefixTag = SkeletonName.Mid(0, 1+ SkeletonName.Find("_", ESearchCase::IgnoreCase, ESearchDir::FromStart,3));
	}
	SkeletonAnimPrefixTags.Add(SkeletonName, AnimNamePrefixTag);
	
}

bool UHiSkeletalMeshComponent::NeedFillTargetSkeletonPose()
{
	if(AActor* Actor = GetOwner())
	{
		if ( Actor->GetRemoteRole() == ROLE_Authority && Actor->GetLocalRole() == ROLE_SimulatedProxy)
		{
			return false;
		}
	}
	return bFillTargetSkeletonPose;

}

UAnimSequence* UHiSkeletalMeshComponent::GetSkeletonAnimation(const FString& AnimName)
{
	if(AnimName.IsEmpty())
	{
		return nullptr;
	}
	if(TObjectPtr<UAnimSequence>* AnimSequence = SkeletonAnimations.Find(AnimName))
	{
		return *AnimSequence;
	}
	const USkeleton * Skeleton = GetSkeleton();
	if (!Skeleton)
	{
		return nullptr;
	}
	const FString SkeletonName = Skeleton->GetName();
	if(FString * res = AnimSequencePathMap.Find(AnimName))
	{
		FString AnimPath = *res;
		if(!IsInGameThread())
		{
			AsyncTask(ENamedThreads::GameThread, [this,AnimName, AnimPath]() mutable {
				LoadSkeletonAnimation(AnimName, AnimPath);
			});
			UE_LOG(HiSkeletalMeshComponent, Log, TEXT("GetSkeletonAnimation  %s is not in IsInGameThread, run AsyncTask"), *AnimName);
			return nullptr;
		}
		
		UAnimSequence* Anim = LoadSkeletonAnimation(AnimName, AnimPath);
		if(Anim)
		{
			
			UE_LOG(HiSkeletalMeshComponent, Log, TEXT("GetSkeletonAnimation [%s]: %s Created successfully"), *SkeletonName, *AnimName);
			return Anim;
		}
	}
	UE_LOG(HiSkeletalMeshComponent, Warning, TEXT("GetSkeletonAnimation [%s]: %s Does not exist"), *SkeletonName, *AnimName);
	return nullptr;	
}

void UHiSkeletalMeshComponent::GetSkeletonAnimationByTargetAnimation(UAnimSequenceBase* Anim)
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
	if (AnimSkeleton == Skeleton)
	{
		return;
	}
	UAnimSequence* TargetAnim = GetSkeletonAnimation(GetMatchingAnimationName(Anim));
	Anim->AddAnimSequenceForFillTargetSkeleton(TargetAnim);
}

FString UHiSkeletalMeshComponent::GetMatchingAnimationName(const UAnimSequenceBase * Anim)
{
	FString AnimName =  Anim->GetName();
	FString SourceAnimPath = Anim->GetPathName();
	if (AnimSequencePathMap.Contains(AnimName))
	{
		return AnimName;
	}
	const FString NoPrefixName = GetNoPrefixAnimationName(Anim);
	if(!NoPrefixName.IsEmpty())
	{
		return AnimNamePrefixTag + NoPrefixName;
	}
	return AnimName;
}

FString UHiSkeletalMeshComponent::GetNoPrefixAnimationName(const UAnimSequenceBase* Anim)
{
	if(!Anim || !Anim->GetSkeleton())
	{
		return "";
	}
	const FString AnimName =  Anim->GetName();
	const FString AnimSkeletonName = Anim->GetSkeleton()->GetName();
	////SK_Prop_Skateboard_01
	const FString SkeletonName = AnimSkeletonName.EndsWith("_Skeleton") ? AnimSkeletonName.Mid(0, AnimSkeletonName.Len()-9) : AnimSkeletonName;
	if(const FString *Tag = SkeletonAnimPrefixTags.Find(AnimSkeletonName))
	{
		if(AnimName.StartsWith(*Tag))
		{
			//SK_Prop_
			const int TagSize= Tag->Len();
			//Skateboard_01_Run_Start_Back
			FString NoPrefixName = AnimName.Mid(TagSize, AnimName.Len()-TagSize);
			if (AnimName.StartsWith(SkeletonName))
			{
				//_Run_Start_Back
				FString Name = AnimName.Mid(SkeletonName.Len(), AnimName.Len()-SkeletonName.Len());
				return NoPrefixName.Mid(0, NoPrefixName.Find("_")) + Name;
			}
			return NoPrefixName;
		}
	}
	return "";
}

UAnimSequence* UHiSkeletalMeshComponent::LoadSkeletonAnimation(const FString& AnimName, const FString& AnimPath)
{
	UAnimSequence* Anim = LoadObject<UAnimSequence>(nullptr,  *AnimPath);
	if(Anim)
	{
		SkeletonAnimations.Emplace(AnimName, Anim);
		return Anim;
	}
	return nullptr;
}

void UHiSkeletalMeshComponent::AddSyncedMeshComponents(UHiSkeletalMeshComponent* Mesh, EMergeSkeletonFlag MergeSkeletonFlag, FString Prefix ,bool HiddenInGame)
{
	if (!Mesh)
	{
		return;
	}
	if(!Mesh->GetSkeletalMeshAsset())
	{
		return;
	}
	SyncedMeshComponents.Emplace(Mesh);
	SyncedMeshMergeFlags.Emplace(Mesh->GetSkeleton(), MergeSkeletonFlag, Prefix);
	UpdateSkeletonForSyncAnimations();
	if(HiddenInGame)
	{
		Mesh->SetHiddenInGame(true);
		TArray<USceneComponent*> Children;
		Mesh->GetChildrenComponents(false, Children);
		if (Prefix.IsEmpty())
		{
			for (USceneComponent* Comp : Children)
			{
				if(UGFurComponent* GFur = Cast<UGFurComponent>(Comp))
				{
					FDetachmentTransformRules DetachmentRules(EDetachmentRule::KeepRelative, true);
					GFur->DetachFromComponent(DetachmentRules);
					FAttachmentTransformRules AttachmentRules(EAttachmentRule::KeepRelative, true);
					GFur->AttachToComponent(this, AttachmentRules);
					gFurs.Add(Mesh, GFur);
					GFur->RegenerateFur();
				}
			}
		}
	}
}

void UHiSkeletalMeshComponent::RemoveSyncedMeshComponents(UHiSkeletalMeshComponent* Mesh)
{
	if(UGFurComponent ** gFur = gFurs.Find(Mesh))
	{
		UGFurComponent *GFurComp = *gFur;
		FDetachmentTransformRules DetachmentRules(EDetachmentRule::KeepRelative, true);
        GFurComp->DetachFromComponent(DetachmentRules);
        FAttachmentTransformRules AttachmentRules(EAttachmentRule::KeepRelative, true);
        GFurComp->AttachToComponent(Mesh, AttachmentRules);
		GFurComp->RegenerateFur();
        gFurs.Remove(Mesh);
		Mesh->SetHiddenInGame(false);
	}
	if(SyncedMeshComponents.Contains(Mesh))
	{
		SyncedMeshComponents.Remove(Mesh);
	}
	SyncedMeshMergeFlags.RemoveAll([&Mesh](FSkeletalMergeFlag& E) { return E.SkeletonToMerge == Mesh->GetSkeleton(); });
	UpdateSkeletonForSyncAnimations();
}

void UHiSkeletalMeshComponent::UpdateAnimNodeSyncedAnimSequence()
{
	if(UHiAnimInstance* AnimInstance = Cast<UHiAnimInstance>(GetAnimInstance()))
    {
    	AnimInstance->UpdateAnimNodeAnimSequence();
    }
    for (const UAnimInstance* LinkedInstance : const_cast<const UHiSkeletalMeshComponent*>(this)->GetLinkedAnimInstances())
    {
    	if(UHiAnimInstance* AnimInstance = Cast<UHiAnimInstance>(const_cast<UAnimInstance*>(LinkedInstance)))
    	{
    		AnimInstance->UpdateAnimNodeAnimSequence();
    	}
    }
}

void UHiSkeletalMeshComponent::OnMontageStartToPlay(UHiAnimInstance* AnimInstance, UAnimMontage* Montage)
{
	UE_LOG(HiSkeletalMeshComponent, Log, TEXT("OnMontageStartToPlay %s"), *Montage->GetPathName());
	OnMontageStarted.Broadcast(AnimInstance, Montage);
	if (NeedFillTargetSkeletonPose())
	{
		for (const FSlotAnimationTrack& Track :Montage->SlotAnimTracks)
		{
			for (const FAnimSegment& Seg:Track.AnimTrack.AnimSegments)
			{
				if (UAnimSequenceBase* Anim = Seg.GetAnimReference())
				{
					SyncAnimSequence(Anim);
				}
			}
		}
	}
}

void UHiSkeletalMeshComponent::OnMontageEnd(UHiAnimInstance* AnimInstance, UAnimMontage* Montage, bool bInterrupted)
{
	UE_LOG(HiSkeletalMeshComponent, Log, TEXT("OnMontageEnd %s"), *Montage->GetPathName());
	OnMontageEnded.Broadcast(AnimInstance, Montage, bInterrupted);
}

void UHiSkeletalMeshComponent::SyncAnimSequence(UAnimSequenceBase* Anim)
{
	if (!Anim)
	{
		return;
	}
	if (!NeedFillTargetSkeletonPose())
	{
		return;
	}
	bool NotControled = false;
	if(const AHiCharacter* Character= Cast<AHiCharacter>(GetOwner()))
	{
		if(!Character->Controller)
		{
			NotControled = true;
		}
	}
	
	if(const USkeleton* TargetSkeleton = GetSkeleton())
	{
		
		const FString AnimName = Anim->GetName();
		if(!NotControled)
		{
			Anim->ClearAnimSequenceForFillTargetSkeleton();
		}
		const USkeleton * BaseSkeleton = Anim->GetSkeleton();
		if(BaseSkeleton && BaseSkeleton != TargetSkeleton)
		{
			GetSkeletonAnimationByTargetAnimation(Anim);
		}
		for( TWeakObjectPtr<UHiSkeletalMeshComponent> ChildMesh: SyncedMeshComponents)
		{
			if( !ChildMesh.IsValid() || ChildMesh->GetSkeletalMeshAsset() == nullptr)
			{
				continue;
			}
			const USkeleton* ChildSkeleton = ChildMesh->GetSkeleton();
			if(ChildSkeleton && ChildSkeleton != TargetSkeleton)
			{
				ChildMesh->GetSkeletonAnimationByTargetAnimation(Anim);
			}
		}
	}
}


void UHiSkeletalMeshComponent::UpdateSkeletonForSyncAnimations()
{
	AActor* CharacterOwner= GetOwner();
	if(!CharacterOwner)
	{
		return;
	}
	if(!GetSkeletalMeshAsset())
	{
		return;
	}
	UClass * PreAnimClass = GetAnimClass();
	bool reinit = false;
	if (SyncedMeshComponents.IsEmpty())
	{
		if(OrigMesh)
		{
			Super::SetSkeletalMesh(OrigMesh);
			OrigMesh = nullptr;
			reinit = true;
		}
	}
	else
	{
		reinit = true;
		if(OrigMesh == nullptr)
		{
			OrigMesh = GetSkeletalMeshAsset();
		}
		TArray<USkeletalMesh*> SkeletalMeshes;
		
		SkeletalMeshes.Add(OrigMesh);
		
		for( TWeakObjectPtr<UHiSkeletalMeshComponent> Mesh : SyncedMeshComponents)
		{
			if (Mesh.IsValid())
			{
				SkeletalMeshes.AddUnique(Mesh->GetSkeletalMeshAsset());
			}
		}
		if (SkeletalMeshes.Num() > 1)
		{
			TArray<USkeleton*> SkeletonsToMerge;
			TSubclassOf<UAnimInstance > PostProcessAnimBlueprint;
			for(USkeletalMesh*Mesh:SkeletalMeshes)
			{
				SkeletonsToMerge.AddUnique(Mesh->GetSkeleton());
				if(TSubclassOf<UAnimInstance > AnimInstance = Mesh->GetPostProcessAnimBlueprint())
				{
					PostProcessAnimBlueprint = AnimInstance;
				}
			}
			USkeleton* MergedSkeleton = nullptr;
			if (SkeletonsToMerge.Num() > 1)
			{
				FSkeletonMergeParams SkeletonMergeParams;
				SkeletonMergeParams.SkeletonsToMerge = SkeletonsToMerge;
				SkeletonMergeParams.bCheckSkeletonsCompatibility = true;
				MergedSkeleton = USkeletalMergingLibrary::MergeSkeletons(SkeletonMergeParams, SyncedMeshMergeFlags);
				MergedSkeleton->FixBoneTreeNum();
				UpdateTranslationRetargetingMode(MergedSkeleton, OrigMesh->GetSkeleton());
				for(const FSkeletalMergeFlag& f : SyncedMeshMergeFlags)
				{
					FString Prefix = f.Flag == EMergeSkeletonFlag::RenameToAttach ? f.BoneNamePrefixForRename : "";
					UpdateTranslationRetargetingMode(MergedSkeleton, f.SkeletonToMerge, Prefix);
					FixSkeletonRemappingByBoneNameMapping(MergedSkeleton, f.SkeletonToMerge, Prefix);
				}
			}
			else
			{
				MergedSkeleton = SkeletonsToMerge[0];
			}
			
			FSkeletalMeshMergeParams MeshMergeParams;
			MeshMergeParams.MeshesToMerge = SkeletalMeshes;
			MeshMergeParams.bSkeletonBefore = true;
			MeshMergeParams.Skeleton = MergedSkeleton;
			USkeletalMesh* MergedMesh = USkeletalMergingLibrary::MergeMeshes(MeshMergeParams);
			if(PostProcessAnimBlueprint)
			{
				MergedMesh->SetPostProcessAnimBlueprint(PostProcessAnimBlueprint);
			}
			//MergedMesh->SetSkeleton(MergedSkeleton);
			MergedSkeleton->SetPreviewMesh(MergedMesh);
			// fill Mesh RequiredBones
			if(SkeletonsToMerge.Num() > 1)
			{
				FSkeletalMeshRenderData* Resource = MergedMesh->GetResourceForRendering();
				const int32 RequiredBoneCount = MergedSkeleton->GetReferenceSkeleton().GetRawBoneNum();
				const int32 MaxNumLODs = Resource->LODRenderData.Num();
				for (int32 LODIdx = 0; LODIdx < MaxNumLODs; LODIdx++)
				{
					Resource->LODRenderData[LODIdx].RequiredBones.Empty(RequiredBoneCount);
					for(int32 i=0; i<RequiredBoneCount; i++)
					{
						Resource->LODRenderData[LODIdx].RequiredBones.Add(i);
					}

					Resource->LODRenderData[LODIdx].RequiredBones.Shrink();	
				}
			}
			Super::SetSkeletalMesh(MergedMesh);
		}
	}
	if(!reinit)
	{
		return;
	}
	if (PreAnimClass)
	{
		SetAnimInstanceClass(PreAnimClass);
	}
	for(const FSkeletalMergeFlag& f : SyncedMeshMergeFlags)
	{
		FString Prefix = f.Flag == EMergeSkeletonFlag::RenameToAttach ? f.BoneNamePrefixForRename : "";
		FixSkeletonRemappingByBoneNameMapping(GetSkeletalMeshAsset()->GetSkeleton(), f.SkeletonToMerge, Prefix);
	}
	
	UHiAvatarLocomotionAppearance * AppearanceComponent = CharacterOwner->FindComponentByClass<UHiAvatarLocomotionAppearance>();
	if (AppearanceComponent)
	{
		for (FHiLinkAnimGraphConfig& LinkedAnimGraphConfig : AppearanceComponent->LinkedAnimGraph)
		{
			LinkAnimGraphByTag(LinkedAnimGraphConfig.Tag, LinkedAnimGraphConfig.AnimBlueprintClass);
		}
	}
	ForEachAnimInstance([](UAnimInstance* InAnimInstance)
	{
		InAnimInstance->NativeBeginPlay();
		InAnimInstance->BlueprintBeginPlay();
	});
	UpdateAnimNodeSyncedAnimSequence();
	OnMergedMeshFinished.Broadcast();
}


USkeleton* UHiSkeletalMeshComponent::MergeSkeletons(const TArray<USkeleton*>& SkeletonsToMerge, FName SkeletonName,
	bool CheckCompatibility, bool GenerateMergedAsset )
{
	const int32 num = SkeletonsToMerge.Num();
	if (num == 0)
	{
		return nullptr;
	}
	if(num ==1)
	{
		return SkeletonsToMerge[0];
	}
	FSkeletonMergeParams Params;
	Params.SkeletonsToMerge = SkeletonsToMerge;
	Params.bCheckSkeletonsCompatibility = CheckCompatibility;
	USkeleton* RetSkeleton= USkeletalMergingLibrary::MergeSkeletons(Params, GenerateMergedAsset);//, SkeletonName);
	return RetSkeleton;
}

USkeletalMesh* UHiSkeletalMeshComponent::MergeSkeletalMeshes(const TArray<USkeletalMesh*>& SkeletalMeshes)
{
	TArray<TObjectPtr<USkeleton>> Skeletons;
	TArray<TObjectPtr<USkeletalMesh>> ToSkeletalMeshes;
	for ( USkeletalMesh* MeshPtr : SkeletalMeshes)
	{
		if (MeshPtr)
		{
			ToSkeletalMeshes.AddUnique(MeshPtr);
			if(USkeleton * Skeleton = MeshPtr->GetSkeleton())
			{
				Skeletons.AddUnique(Skeleton);
			}
		}
	}
	const int32 ToMergedMeshNum = ToSkeletalMeshes.Num();
	if (ToMergedMeshNum == 0)
	{
		return nullptr;
	}
	if(ToMergedMeshNum ==1)
	{
		return ToSkeletalMeshes[0];
	}
	
	USkeleton * MergedSkeleton = Skeletons.Num() > 0 ?  MergeSkeletons(Skeletons) : nullptr;
	
	FSkeletalMeshMergeParams Params;
	Params.MeshesToMerge = ToSkeletalMeshes;
	Params.bSkeletonBefore = true;
	Params.Skeleton = MergedSkeleton;
	USkeletalMesh* NewMesh = USkeletalMergingLibrary::MergeMeshes(Params);
	return NewMesh;
}

void UHiSkeletalMeshComponent::SetSkeletalMesh(USkeletalMesh* NewMesh, bool bReinitPose)
{
	Super::SetSkeletalMesh(NewMesh, bReinitPose);
	OrigMesh = nullptr;
	if (NewMesh)
	{
		if (!SyncedMeshComponents.IsEmpty())
		{
			UpdateSkeletonForSyncAnimations();
		}
	}
}

void UHiSkeletalMeshComponent::FixSkeletonRemappingByBoneNameMapping(USkeleton* Skeleton, USkeleton* TargetSkeleton,
	FString Prefix)
{
	if (!Skeleton || !TargetSkeleton)
	{
		return;
	}
	if (Skeleton == TargetSkeleton)
	{
		return;
	}
	TMap<FName, FName> RenameMap;
	TMap<FName, FName> InversionRenameMap;
	if(!Prefix.IsEmpty())
	{
		for ( const FMeshBoneInfo & Info :TargetSkeleton->GetReferenceSkeleton().GetRefBoneInfo())
		{
			FName BoneName = Info.Name;
			FName NewName = FName(Prefix + BoneName.ToString());
			RenameMap.Add(BoneName, NewName);
			InversionRenameMap.Add(NewName, BoneName);
		}
	}
	Skeleton->FixSkeletonRemappingByBoneNameMapping(TargetSkeleton, RenameMap);
	TargetSkeleton->FixSkeletonRemappingByBoneNameMapping(Skeleton, InversionRenameMap);
	//for ( TSoftObjectPtr<USkeleton> childSkeleton: TargetSkeleton->GetCompatibleSkeletons())
	//{
	//	Skeleton->FixSkeletonRemappingByBoneNameMapping(childSkeleton.Get(), RenameMap);
	//}
}

void UHiSkeletalMeshComponent::UpdateTranslationRetargetingMode(USkeleton* Skeleton, const USkeleton* SourceSkeleton, const FString& BoneNamePrefix)
{
	const FReferenceSkeleton& RefSourceSkeleton = SourceSkeleton->GetReferenceSkeleton();
	const FReferenceSkeleton& TargetSkeleton = Skeleton->GetReferenceSkeleton();
	const int32 NumBones = RefSourceSkeleton.GetNum();
	
	for ( int32 BoneIndex = 0; BoneIndex < NumBones; ++BoneIndex)
	{
		FName BoneName = RefSourceSkeleton.GetBoneName(BoneIndex);

		FName TargetBoneName = BoneNamePrefix.IsEmpty() ? BoneName : FName(BoneNamePrefix + BoneName.ToString());
		const int32 TargetBoneIndex = TargetSkeleton.FindRawBoneIndex(TargetBoneName);
		if (TargetBoneIndex != INDEX_NONE)
		{
			Skeleton->SetBoneTranslationRetargetingMode(TargetBoneIndex, SourceSkeleton->GetBoneTranslationRetargetingMode(BoneIndex));
		}
	}
}

USkeleton* UHiSkeletalMeshComponent::GetSkeleton() const
{
	if(! GetSkeletalMeshAsset())
	{
		return nullptr;
	}
	return OrigMesh ? OrigMesh->GetSkeleton() : GetSkeletalMeshAsset()->GetSkeleton();
}


