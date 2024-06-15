// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Animation/HiAnimInstance.h"

#include "Component/HiJumpComponent.h"
#include "Component/HiLocomotionComponent.h"
#include "Characters/HiCharacter.h"
#include "Characters/Animation/HiAnimInstanceProxy.h"
#include "Component/HiGlideComponent.h"
#include "Component/HiSkeletalMeshComponent.h"

#if WITH_EDITOR
#include "AssetRegistry/AssetRegistryModule.h"
#endif

DEFINE_LOG_CATEGORY_STATIC(HIAnimInstanceLog, Log, All);
void UHiAnimInstance::NativeInitializeAnimation()
{
	Super::NativeInitializeAnimation();
	Character = Cast<AHiCharacter>(TryGetPawnOwner());
	if (Character)
	{
		LocomotionComponent = Character->FindComponentByClass<UHiLocomotionComponent>();
		JumpComponent = Character->FindComponentByClass<UHiJumpComponent>();
		GlideComponent = Character->FindComponentByClass<UHiGlideComponent>();
		Character->OnCharacterComponentInitialized.AddDynamic(this, &UHiAnimInstance::OnUpdateComponent);
		UpdateFaceMeshComponent();
	}
	OnMontageStarted.AddDynamic(this, &UHiAnimInstance::OnMontageStartToPlay);
}

void UHiAnimInstance::NativeUninitializeAnimation()
{
	Super::NativeUninitializeAnimation();
	if (Character)
	{
		Character->OnCharacterComponentInitialized.RemoveDynamic(this, &UHiAnimInstance::OnUpdateComponent);
	}
	OnMontageStarted.RemoveAll(this);
}

float UHiAnimInstance::Montage_Play_With_PoseSearch_Implementation(UAnimMontage* MontageToPlay, float InPlayRate, EMontagePlayReturnType ReturnValueType, float InTimeToStartMontageAt, bool bStopAllMontages)
{
	return Montage_Play(MontageToPlay, InPlayRate, ReturnValueType, InTimeToStartMontageAt, bStopAllMontages);
}

float UHiAnimInstance::GetMontageStartPosition_Implementation(UAnimMontage* MontageToPlay)
{
	return 0.0f;
}

void UHiAnimInstance::UpdateFaceMeshComponent()
{
	if(const USkeletalMeshComponent* Mesh = GetOwningComponent())
	{
		for (TObjectPtr<USceneComponent> Comp : Mesh->GetAttachChildren())
		{
			if(UHiSkeletalMeshComponent * HiSkeletalMesh = Cast<UHiSkeletalMeshComponent>(Comp))
			{
				if(const USkeleton * Skeleton = HiSkeletalMesh->GetSkeleton())
				{
					if(Skeleton->GetReferenceSkeleton().FindBoneIndex("cn_head_faceskin") != INDEX_NONE)
					{
						FaceMeshComponent = HiSkeletalMesh;
						break;
					}
				}
			}
		}
	}
}


void UHiAnimInstance::OnAnimNodeInitialize(UAnimSequenceBase* Anim)
{
	if(FaceAnimBlendWeight == 0)
	{
		return;
	}
	//UE_LOG(HIAnimInstanceLog, Log, TEXT("[%lld]OnAnimNodeInitialize %s"), GFrameCounter, *Anim->GetName());
	if(FaceMeshComponent && !Anim->GetFillTargetSkeletonAnimSequence().IsEmpty())
	{
		if(const USkeleton * FaceSkeleton = FaceMeshComponent->GetSkeleton())
		{
			for(const UAnimSequenceBase* TargetAnim : Anim->GetFillTargetSkeletonAnimSequence())
			{
				if(TargetAnim && TargetAnim->GetSkeleton() == FaceSkeleton)
				{
					FaceAnimBlendWeight = 0.0;
					break;
				}
			}
		}
	}
}

void UHiAnimInstance::OnUpdateComponent()
{
	if (Character)
	{
		LocomotionComponent = Character->FindComponentByClass<UHiLocomotionComponent>();
		UHiJumpComponent* NewJumpComponent = Character->FindComponentByClass<UHiJumpComponent>();
		if (NewJumpComponent != JumpComponent)
		{
			JumpComponent = NewJumpComponent;
		}
		UpdateFaceMeshComponent();
	}
}

void UHiAnimInstance::PreUpdateAnimation(float DeltaSeconds)
{
	//UE_LOG(HIAnimInstanceLog, Log, TEXT("[%lld]PreUpdateAnimation %s"), GFrameCounter, *GetName());
	FaceAnimBlendWeight = 1.0;
	Super::PreUpdateAnimation(DeltaSeconds);
}

void UHiAnimInstance::OnMontageStartToPlay(UAnimMontage* Montage)
{
	UE_LOG(HIAnimInstanceLog, Log, TEXT("[%s]OnMontageStartToPlay %s"), *GetName(), *Montage->GetPathName());
	if(UHiSkeletalMeshComponent* MeshComponent = Cast<UHiSkeletalMeshComponent>(GetSkelMeshComponent()))
	{
		MeshComponent->OnMontageStartToPlay(this, Montage);
	}
}

#if WITH_EDITOR

FString UHiAnimInstance::GetSkeletonName(const USkeleton* Skeleton, const FString& ParentName)
{
	FString Name;
	if (!Skeleton)
	{
		return Name;
	}
	FString SkeletonName = Skeleton->GetName();

	while (SkeletonName.EndsWith("_Skeleton") || SkeletonName.StartsWith("_Weapon")||
		SkeletonName.StartsWith("_Prop") )
	{
		SkeletonName = SkeletonName.Mid(0, SkeletonName.Find("_", ESearchCase::IgnoreCase, ESearchDir::FromEnd));
	}

	while (SkeletonName.StartsWith("SK_") || SkeletonName.StartsWith("Prop_")||
		SkeletonName.StartsWith("Weapon_") || (!ParentName.IsEmpty() && SkeletonName.StartsWith(ParentName)))
	{
		SkeletonName = SkeletonName.Mid(SkeletonName.Find("_") +1);
	}
	const int32 start_idx = SkeletonName.Find("_") + 1;
	Name = SkeletonName.Mid(start_idx, SkeletonName.Len()-start_idx);
	return Name;
}

UDataTable* UHiAnimInstance::GenerateSkeletonAnimationsTable(USkeleton* Skeleton, FString PackagePath, bool IncludeSubClass)
{
	if (Skeleton == nullptr)
	{
		return nullptr;
	}
	
	FAssetRegistryModule* const AssetRegistryModule = FModuleManager::Get().GetModulePtr<FAssetRegistryModule>("AssetRegistry");
	if (!AssetRegistryModule)
	{
		return nullptr;
	}
	const IAssetRegistry& AssetRegistry = AssetRegistryModule->Get();
	TArray<FAssetData> Assets;
	AssetRegistry.GetAssetsByClass(UAnimSequence::StaticClass()->GetClassPathName(), Assets, IncludeSubClass);
	FAssetData SkeletonAssetData(Skeleton);
	FString SkeletonTextName = SkeletonAssetData.GetExportTextName();
	TMap<FString, FString> AllAnimAssets;
	for (FAssetData Asset : Assets)
	{
		if(!Asset.PackagePath.ToString().StartsWith("/Game/Character/"))
		{
			continue;
		}
		if (Asset.TagsAndValues.FindTag(TEXT("Skeleton")).AsString() == SkeletonTextName )
		{
			AllAnimAssets.Add(Asset.AssetName.ToString(), Asset.GetObjectPathString());
		}
	}
	if (AllAnimAssets.IsEmpty())
	{
		return nullptr;
	}
	FString NewObjectName= Skeleton->GetName();
	
	FString SkeletonName = GetSkeletonName(Skeleton, "");
	if(SkeletonName.Find("_") != -1)
	{
		SkeletonName = SkeletonName.Mid(0, SkeletonName.Find("_"));
	}
	FString SubString = NewObjectName;
	FString Suffix = "_fixed";
	FString NewObjectPath = PackagePath + "/" + NewObjectName;

	TObjectPtr<UDataTable> AnimTable = LoadDataTable(NewObjectPath);
	if (AnimTable)
	{
		AnimTable->EmptyTable();
	}
	else
	{
		AnimTable = NewObject<UDataTable>(CreatePackage( *NewObjectPath),
			UDataTable::StaticClass(), *NewObjectName, RF_Public | RF_Standalone | RF_Transactional);
	}
	AnimTable->RowStruct = FHiAnimSequencePath::StaticStruct();
	bool bFindMatchingAnim = false;
	
	for( TTuple<FString ,FString> Pair: AllAnimAssets)
	{
		if (!bFindMatchingAnim)
		{
			bFindMatchingAnim = true;
		}
		FString AnimName = Pair.Key;
		FString ObjectPath = Pair.Value;
		if (AnimName.EndsWith(Suffix))
		{
			AnimName = AnimName.Mid(0,AnimName.Len()-Suffix.Len());
		}
		else
		{
			if (AnimTable->FindRow<FHiAnimSequencePath>(FName(AnimName), "Search"))
			{
				continue;
			}
		}
		AnimTable->AddRow(FName(AnimName), FHiAnimSequencePath(AnimName, ObjectPath));
		if(AnimName.Mid(0, AnimName.Len() - 3).EndsWith("_Body"))
		{
			// is body skin anim
			FString NoSkinName = AnimName.Mid(0, AnimName.Len()-8);
			AnimTable->AddRow(FName(NoSkinName), FHiAnimSequencePath(NoSkinName, ObjectPath));
		}
		if (AnimName.EndsWith("_" + SkeletonName))
		{
			FString NoNameName = AnimName.Mid(0, AnimName.Len() - SkeletonName.Len() - 1);
			AnimTable->AddRow(FName(NoNameName), FHiAnimSequencePath(NoNameName, ObjectPath));
		}
	}
	if (bFindMatchingAnim)
	{
		FAssetRegistryModule::AssetCreated(AnimTable);
		AnimTable->Modify();
		return AnimTable.Get();
	}
	return nullptr;
}


UDataTable * UHiAnimInstance::GenerateActorAnimMontageTable(USkeleton* Skeleton, FString ActorName, FString PackagePath)
{
	if (Skeleton == nullptr)
	{
		return nullptr;
	}
	TMap<FString, FString> AllAnimAssets;
	FAssetRegistryModule* const AssetRegistryModule = FModuleManager::Get().GetModulePtr<FAssetRegistryModule>("AssetRegistry");
	if (!AssetRegistryModule)
	{
		return nullptr;
	}
	if (ActorName.EndsWith("_C"))
	{
		ActorName = ActorName.Mid(0, ActorName.Len()-2);
	}
	const IAssetRegistry& AssetRegistry = AssetRegistryModule->Get();
	TArray<FAssetData> Assets;
	AssetRegistry.GetAssetsByClass(UAnimMontage::StaticClass()->GetClassPathName(), Assets, true);
	FAssetData SkeletonAssetData(Skeleton);
	FString SkeletonTextName = SkeletonAssetData.GetExportTextName();
	for (FAssetData Asset : Assets)
	{
		if(!Asset.PackagePath.ToString().StartsWith("/Game/Character/"))
		{
			continue;
		}
		if (Asset.TagsAndValues.FindTag(TEXT("Skeleton")).AsString() == SkeletonTextName)
		{
			AllAnimAssets.Add(Asset.AssetName.ToString(), Asset.GetObjectPathString());
		}
	}
	if (AllAnimAssets.IsEmpty())
	{
		return nullptr;
	}
	FString SubString = ActorName;
	bool bFindMatchingMontage = false;
	FString NewObjectPath = PackagePath + "/" + ActorName;
	FString NewObjectName= ActorName;

	TObjectPtr<UDataTable> MontageTable = LoadDataTable(NewObjectPath);
	if (MontageTable)
	{
		MontageTable->EmptyTable();
	}
	else
	{
		MontageTable  = NewObject<UDataTable>(CreatePackage( *NewObjectPath),
			UDataTable::StaticClass(), *NewObjectName, RF_Public | RF_Standalone | RF_Transactional);
	}
	MontageTable->RowStruct = FHiAnimSequencePath::StaticStruct();
	do
	{
	
		int StartPos = SubString.Find("_", ESearchCase::IgnoreCase, ESearchDir::FromStart, 1);
		if (StartPos == INDEX_NONE)
		{
			break;
		}
		SubString = SubString.Mid(StartPos);
		if (SubString.Len() == 0)
		{
			break;;
		}
		FString Suffix = SubString + "_Montage";
		for( TTuple<FString, FString> Pair : AllAnimAssets)
		{
			FString AnimName = Pair.Key;
			if (AnimName.EndsWith(Suffix))
			{
				if (!bFindMatchingMontage)
				{
					bFindMatchingMontage = true;
				}
				
				AnimName = AnimName.Mid(0,AnimName.Len()-Suffix.Len());
				MontageTable->AddRow(FName(AnimName), FHiAnimSequencePath(AnimName, Pair.Value));
			}
		}
	}
	while (!bFindMatchingMontage );
	if (bFindMatchingMontage)
	{
		FAssetRegistryModule::AssetCreated(MontageTable);
		MontageTable->Modify();
	}
	return MontageTable;
}

UDataTable*  UHiAnimInstance::GenerateActorAnimMontageTableByMesh(USkeletalMeshComponent* MeshComponent, FString ActorName,
	FString PackagePath)
{
	if (!MeshComponent || ActorName.IsEmpty())
	{
		return nullptr;
	}
	USkeletalMesh* Mesh = MeshComponent->GetSkeletalMeshAsset();
	if(!Mesh)
	{
		return nullptr;
	}
	return GenerateActorAnimMontageTable(Mesh->GetSkeleton(),	ActorName, PackagePath);
}

#endif


void UHiAnimInstance::UpdateAnimNodeAnimSequence()
{
	GetProxyOnGameThread<FHiAnimInstanceProxy>().MarkNeedInitializeSyncAnimSequence();
	GetProxyOnGameThread<FHiAnimInstanceProxy>().InitializeAnimNodeAnimSequence(this);
}

UDataTable* UHiAnimInstance::LoadDataTable(FString Path)
{
	UDataTable* DataTable = LoadObject<UDataTable>(nullptr, *Path);
	return DataTable;
}

FString UHiAnimInstance::LoadAnimPathFromDataTable(UDataTable* DataTable, FString AnimName)
{
	if (!DataTable)
	{
		return "";
	}
	if(FHiAnimSequencePath::StaticStruct() != DataTable->RowStruct)
	{
		return "";
	}
	const FHiAnimSequencePath* RowData = DataTable->FindRow<FHiAnimSequencePath>(FName(AnimName), nullptr);
	if (RowData && !RowData->AnimPath.IsEmpty())
	{
		return RowData->AnimPath;
	}
	return "";
}


FAnimInstanceProxy* UHiAnimInstance::CreateAnimInstanceProxy()
{
	return new FHiAnimInstanceProxy(this);
}

UAnimMontage* UHiAnimInstance::LoadMontage_Play(UAnimInstance* Instance, FString MontageName, float InPlayRate, EMontagePlayReturnType ReturnValueType,
                                                float InTimeToStartMontageAt, bool bStopAllMontages)
{
	UAnimMontage* AnimMontage = LoadObject<UAnimMontage>(nullptr, *MontageName);
	if (Instance != nullptr && AnimMontage != nullptr)
	{
		Instance->Montage_Play(AnimMontage, InPlayRate, ReturnValueType, InTimeToStartMontageAt, bStopAllMontages);
	}
	return AnimMontage;
}

UAnimMontage* UHiAnimInstance::LoadSlotAnimAsDynamicMontage(FString AnimName, FName SlotNodeName, float BlendInTime,
 float BlendOutTime , float InPlayRate, int32 LoopCount, float BlendOutTriggerTime, float InTimeToStartMontageAt)
{
	UAnimSequence* Anim = LoadObject<UAnimSequence>(nullptr, *AnimName);
	if (Anim != nullptr)
	{
		return UAnimMontage::CreateSlotAnimationAsDynamicMontage(Anim, SlotNodeName, BlendInTime, BlendOutTime, InPlayRate, LoopCount, BlendOutTriggerTime, InTimeToStartMontageAt);
	}
	return nullptr;
}

UAnimMontage* UHiAnimInstance::LoadMontageSlotAnimAsDynamicMontage(UAnimMontage* Montage)
{
	return nullptr;
}

void UHiAnimInstance::OpenInsert(float BlendInTime)
{
	IsinsertActive = true;
	BlendInInsertTime = BlendInTime;
}

void UHiAnimInstance::CloseInsert(float BlendOutTime)
{
	IsinsertActive = false;
	BlendOutInsertTime = BlendOutTime;
}
