// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiCombineMeshComponent.h"
#include "SkeletalMergingLibrary.h"
#include "Animation/AnimInstance.h"
#include "Characters/Animation/HiAnimLayeredBlendInstanceProxy.h"
#include "Characters/Animation/HiCombineAnimInstance.h"

#pragma optimize( "", off )
UHiCombineMeshComponent::UHiCombineMeshComponent(const FObjectInitializer& ObjectInitializer)
: Super(ObjectInitializer)
{
}

void UHiCombineMeshComponent::OnRegister()
{
	
	Super::OnRegister();
}

void UHiCombineMeshComponent::OnUnregister()
{
	Super::OnUnregister();
}

void UHiCombineMeshComponent::InitAnim(bool bForceReinit)
{
	Super::InitAnim(bForceReinit);
	const UClass * AnimInstanceClass = GetAnimClass();
	if ( GetSkeletalMeshAsset() != nullptr && IsRegistered() && !SubMeshComponents.IsEmpty() && AnimInstanceClass == nullptr)
	{
		InitializeMergeAnimScriptInstance();
	}
}

void UHiCombineMeshComponent::OnChildAttached(USceneComponent* ChildComponent)
{
	Super::OnChildAttached(ChildComponent);
	
}

void UHiCombineMeshComponent::OnChildDetached(USceneComponent* ChildComponent)
{
	Super::OnChildDetached(ChildComponent);
}

void UHiCombineMeshComponent::OnAttachmentChanged()
{
	Super::OnAttachmentChanged();
	auto Parent = GetAttachParent();
    if (!Parent || Parent->IsA(UHiCombineMeshComponent::StaticClass()))
    {
        bIsSubMesh = true;
        if(bIsCombineMesh)
        {
            SetSkeletalMesh(nullptr);
            ClearAnimScriptInstance();
            bIsCombineMesh = false;
        	CleanCombineMesh();
        }
    }
}

void UHiCombineMeshComponent::InitializeMesh()
{
    bIsCombineMesh = false;
	auto Parent = GetAttachParent();
	if (!Parent || Parent->IsA(UHiCombineMeshComponent::StaticClass()))
	{
		bIsSubMesh = true;
	}
	else
	{
		bIsSubMesh = false;
		MergeSubMeshes();
	}
}

void UHiCombineMeshComponent::CleanCombineMesh()
{
	SubMeshComponents.Empty();
}

void UHiCombineMeshComponent::InitializeComponent()
{
    InitializeMesh();
	Super::InitializeComponent();
}

void UHiCombineMeshComponent::InitializeMergeAnimScriptInstance()
{
	if ( GetSkeletalMeshAsset() != nullptr && IsRegistered() )
	{
		if (AnimScriptInstance != nullptr && AnimScriptInstance->GetClass() == UHiCombineAnimInstance::StaticClass())
		{
			return;
		}
		AnimScriptInstance = NewObject<UHiCombineAnimInstance>(this);
		if (AnimScriptInstance)
		{
			AnimScriptInstance->InitializeAnimation();

			if (UHiCombineAnimInstance * CombineAnimInstance = Cast<UHiCombineAnimInstance>(AnimScriptInstance))
			{
				int SubMeshNum = SubMeshComponents.Num();
				for (int index=0; index < SubMeshNum; ++index)
				{
				 	TWeakObjectPtr<UHiCombineMeshComponent> SubMesh = SubMeshComponents[index];
					if(SubMesh->bBaseMesh)
					{
						CombineAnimInstance->SetBasePoseLinkedMeshComponent(SubMesh.Get());
					}
					else
					{
						int PoseIndex = CombineAnimInstance->AddLinkedMeshComponent(SubMesh.Get());
						CombineAnimInstance->SetLayeredBlendProfile(PoseIndex, SubMesh->BlendProfile);
						CombineAnimInstance->SetLayeredBoneMaskFilter(PoseIndex, SubMesh->LayerSetup);
						CombineAnimInstance->SetLayeredBoneBlendWeight(PoseIndex, SubMesh->BlendWeight);
					}
				}
			}
		
		}
	}
}

void UHiCombineMeshComponent::MergeSubMeshes()
{
	if (!bNeedMerge)
	{
		return;
	}
	if (bIsSubMesh)
	{
		return;
	}
	CleanCombineMesh();
	
	TArray<TObjectPtr<USkeleton>> Skeletons;
	TArray<TObjectPtr<USkeletalMesh>> SubSkeletalMeshes;
	for (USceneComponent* child : GetAttachChildren())
	{
		if(child->IsA(USkeletalMeshComponent::StaticClass()))
		{
			USkeletalMeshComponent * MeshComp = Cast<USkeletalMeshComponent>(child);
			if (MeshComp && MeshComp->GetSkeletalMeshAsset())
			{
			    //MeshComp->SetVisibility(false);
                //MeshComp->SetComponentTickEnabled(false);
                MeshComp->SetHiddenInGame(true);
				if(UHiCombineMeshComponent *HiMesh = Cast<UHiCombineMeshComponent>(MeshComp))
				{
					SubMeshComponents.AddUnique(HiMesh);
					USkeleton* Skeleton = MeshComp->GetSkeletalMeshAsset()->GetSkeleton();
					Skeletons.AddUnique(Skeleton);
					SubSkeletalMeshes.AddUnique(MeshComp->GetSkeletalMeshAsset());
				}
			}
		}
	}
	
	if (SubMeshComponents.IsEmpty())
	{
		return;
	}
	if(SubMeshComponents.Num()==1)
	{
		SetSkeletalMesh(SubSkeletalMeshes[0]);
		if(UClass* SubAnimClass = SubMeshComponents[0]->GetAnimClass())
		{
			SetAnimInstanceClass(SubAnimClass);
		}
		CleanCombineMesh();
		return;
	}
	USkeleton* TargetSkeleton = MergeSkeletons(Skeletons);
	if (!TargetSkeleton)
	{
		CleanCombineMesh();
		return;
	}
	UClass * PreAnimClass = GetAnimClass();
	FSkeletalMeshMergeParams Params;
	Params.MeshesToMerge = SubSkeletalMeshes;
	Params.bSkeletonBefore = true;
	Params.Skeleton = TargetSkeleton;
	USkeletalMesh* NewMesh = USkeletalMergingLibrary::MergeMeshes(Params);
	if (!NewMesh)
	{
		SubMeshComponents.Empty();
		return;
	}
	SetSkeletalMesh(NewMesh);// to Call init Anim
	if (PreAnimClass)
	{
		SetAnimInstanceClass(PreAnimClass);
	}
	bIsCombineMesh = true;
}

USkeleton* UHiCombineMeshComponent::MergeSkeletons(const TArray<USkeleton*>& SkeletonsToMerge)
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
	Params.bCheckSkeletonsCompatibility = true;
	USkeleton* RetSkeleton= USkeletalMergingLibrary::MergeSkeletons(Params);
	return RetSkeleton;
}

USkeletalMesh* UHiCombineMeshComponent::MergeSkeletalMeshes(const TArray<USkeletalMesh*>& SkeletalMeshes)
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

