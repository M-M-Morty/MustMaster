// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimNotify/HiAnimNotifyState_TimedChangeMID.h"


TArray<USceneComponent*> UHiAnimNotifyState_TimedChangeMID::GetMeshComponentChildren(USkeletalMeshComponent* MeshComp)
{
	TArray<USceneComponent*> Children;
	if (IsValidChecked(MeshComp))
	{
		MeshComp->GetChildrenComponents(false, Children);	
	}	
	return Children;
}

void UHiAnimNotifyState_TimedChangeMID::NotifyBegin(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
                                                    float TotalDuration, const FAnimNotifyEventReference& EventReference)
{
	PRAGMA_DISABLE_DEPRECATION_WARNINGS
	Super::NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
	PRAGMA_ENABLE_DEPRECATION_WARNINGS	
	if(!IsValidChecked(MeshComp))
	{
		return;
	}
	UWorld* World = MeshComp->GetWorld();
	if (World->GetNetMode() == NM_DedicatedServer)
	{
		return;
	}
#if WITH_EDITOR
	if (World->WorldType != EWorldType::PIE && World->WorldType != EWorldType::Game)
	{
		//get origin materials from mesh component
 		Materials.Reset();
		MeshComp->GetUsedMaterials(Materials);	
		if (IsValid(DynamicMaterial))
		{
			const int32 NumMaterials = MeshComp->GetNumMaterials();
			for (int32 MaterialIndex = 0; MaterialIndex < NumMaterials; MaterialIndex++)
			{
				MeshComp->SetMaterial(MaterialIndex, DynamicMaterial);	
			}
		}
	}
	else
#endif// WITH_EDITOR
	{
		Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference);
	}	
}

void UHiAnimNotifyState_TimedChangeMID::NotifyTick(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	float FrameDeltaTime, const FAnimNotifyEventReference& EventReference)
{
	Super::NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference);
}

void UHiAnimNotifyState_TimedChangeMID::NotifyEnd(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
	const FAnimNotifyEventReference& EventReference)
{
	PRAGMA_DISABLE_DEPRECATION_WARNINGS
	Super::NotifyEnd(MeshComp, Animation, EventReference);
	PRAGMA_ENABLE_DEPRECATION_WARNINGS

	if(!IsValid(MeshComp))
	{
		return;
	}

	UWorld* World = MeshComp->GetWorld();
	if (World->GetNetMode() == NM_DedicatedServer)
	{
		return;
	}

#if WITH_EDITOR
	if (World->WorldType != EWorldType::PIE && World->WorldType != EWorldType::Game)
	{		
		const int32 NumMaterials = MeshComp->GetNumMaterials();
		if (NumMaterials == Materials.Num())
		{
			for (int32 MaterialIndex = 0; MaterialIndex < NumMaterials; MaterialIndex++)
			{
				MeshComp->SetMaterial(MaterialIndex, Materials[MaterialIndex]);	
			}
			Materials.Reset();
		}
	}
	else
#endif//WITH_EDITOR
	{
		Received_NotifyEnd(MeshComp, Animation, EventReference);	
	}	
}

