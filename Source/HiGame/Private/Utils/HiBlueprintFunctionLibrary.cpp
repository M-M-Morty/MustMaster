// Fill out your copyright notice in the Description page of Project Settings.


#include "HiBlueprintFunctionLibrary.h"

#include "Animation/AnimNodeReference.h"
#include "PoseSearch/AnimNode_PoseSearchHistoryCollector.h"
// #include "Animation/AnimPoseSearchProvider.h"
#include "PoseSearch/PoseSearchContext.h"

UObject *UHiBlueprintFunctionLibrary::GetObjectPropertyByName(TSubclassOf<UObject> ObjectClass, UObject *Object, const FName &Name)
{
	UClass *objectclass = Object->GetClass();

	FProperty *Property = objectclass->FindPropertyByName(Name);
	if (Property)
	{
		FObjectProperty *ObjectProperty = CastField<FObjectProperty>(Property);
		UObject* ProperyValue = ObjectProperty->GetObjectPropertyValue(ObjectProperty->ContainerPtrToValuePtr<void>(Object));
		if (ProperyValue && ProperyValue->IsA(ObjectClass))
		{
			return ProperyValue;
		}
	}
	return nullptr;
}

float UHiBlueprintFunctionLibrary::GetStartPostionFromPoseSearch(const UAnimInstance *AnimInstance, const FAnimNodeReference &PoseSearchHistoryNode, UAnimSequenceBase *Sequence)
{
#if WITH_PLUGINS_POSESEARCH
	// using namespace UE::PoseSearch;
	//
	// const UPoseSearchSequenceMetaData* MetaData = Sequence ? Sequence->FindMetaDataByClass<UPoseSearchSequenceMetaData>() : nullptr;
	// if (!MetaData || !MetaData->IsValidForSearch())
	// {
	// 	return 0.0f;
	// }
	//
	// FAnimNode_PoseSearchHistoryCollector *Collector = PoseSearchHistoryNode.GetAnimNodePtr<FAnimNode_PoseSearchHistoryCollector>();
	//
	// if (!Collector)
	// {
	// 	return 0.0f;
	// }
	//
	// FPoseHistory& PoseHistory = Collector->GetPoseHistory();
	//
	// FSearchContext SearchContext;
	// SearchContext.OwningComponent = AnimInstance->GetSkelMeshComponent();
	// SearchContext.BoneContainer = &AnimInstance->GetRequiredBones();
	// SearchContext.History = &PoseHistory;
	//
	// UE::PoseSearch::FSearchResult Result = MetaData->Schema->Search(AnimInstance, MetaData, SearchContext);
	//
	// if (Result.PoseIdx >= 0)
	// {
	// 	return Result.AssetTime;
	// }
#endif

	return 0.0f;
}

FTransform UHiBlueprintFunctionLibrary::GetSocketTransformFromAnimation(const UAnimSequenceBase *Animation, const FName &SocketName, float CurrentTime, bool bExtractRootMotion)
{
	FCompactPose Poses;
	FBlendedCurve Curves;
	UE::Anim::FStackAttributeContainer Atrributes;

	USkeleton * Skeleton = Animation->GetSkeleton();

	const FReferenceSkeleton& RefSkel = Animation->GetSkeleton()->GetReferenceSkeleton();

	int32 BoneIndex = RefSkel.FindBoneIndex(SocketName);
	TArray<FBoneIndexType> RequiredBones;
	RequiredBones.Add(BoneIndex);
	Skeleton->GetReferenceSkeleton().EnsureParentsExistAndSort(RequiredBones);

	FBoneContainer BoneContainer(RequiredBones, false, *Skeleton);

	Poses.SetBoneContainer(&BoneContainer);
	
	FAnimExtractContext Context;
	FAnimationPoseData AnimationPoseData(Poses, Curves, Atrributes);

	Context.CurrentTime = CurrentTime;
	Context.bExtractRootMotion = bExtractRootMotion;
	
	if (const UAnimSequence* AnimSequence = Cast<UAnimSequence>(Animation))
	{
		AnimSequence->GetBonePose(AnimationPoseData, Context);
	}
	else if (const UAnimMontage* AnimMontage = Cast<UAnimMontage>(Animation))
	{
		const FAnimTrack& AnimTrack = AnimMontage->SlotAnimTracks[0].AnimTrack;
		AnimTrack.GetAnimationPose(AnimationPoseData, Context);
	}

	const FCompactPoseBoneIndex CompactPoseBoneIndex = BoneContainer.MakeCompactPoseIndex(FMeshPoseBoneIndex(BoneIndex));
	
	FCompactPoseBoneIndex ParentIndex = Poses.GetParentBoneIndex(CompactPoseBoneIndex);

	FTransform MeshSpaceTransform = Poses[CompactPoseBoneIndex];

	while (ParentIndex != FCompactPoseBoneIndex(0))
	{
		MeshSpaceTransform = Poses[ParentIndex] * MeshSpaceTransform;
		ParentIndex = Poses.GetParentBoneIndex(CompactPoseBoneIndex);
	}

	return MeshSpaceTransform;
}

FString UHiBlueprintFunctionLibrary::GetClassPath(const UClass* Class)
{
	if (!Class)
	{
		return FString(); 
	}
	FSoftClassPath ClassPath = FSoftClassPath(Class);
	return ClassPath.ToString();
}

FString UHiBlueprintFunctionLibrary::GetObjectClassPath(const UObject* Object)
{
	if (!Object)
	{
		return FString(); 
	}
	FSoftClassPath ClassPath = FSoftClassPath(Object->GetClass());
	return ClassPath.ToString();
}


FString UHiBlueprintFunctionLibrary::GetPIEWorldNetDescription(const UObject* WorldContextObject)
{
	FString Description;
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	if (World)
	{
		if (World->WorldType == EWorldType::PIE)
		{
			switch(World->GetNetMode())
			{
			case NM_Client:
				// GPlayInEditorID 0 is always the server, so 1 will be first client.
				Description = FString::Format(TEXT("Client {0}: "), {int32(GPlayInEditorID)});
				break;
			case NM_DedicatedServer:
			case NM_ListenServer:
				Description = TEXT("Server: ");
				break;
			default:
				break;
			}
		}
	}
	return Description;
}

bool UHiBlueprintFunctionLibrary::IsWorldPlaying(const UObject* WorldContextObject)
{
	UWorld* World = GEngine->GetWorldFromContextObject(WorldContextObject, EGetWorldErrorMode::ReturnNull);
	if (World && World->GetGameInstance())
	{
		return true;
	}
	return false;
}

void UHiBlueprintFunctionLibrary::RegisterAllComponents(AActor* Actor)
{
	Actor->RegisterAllComponents();
}

void UHiBlueprintFunctionLibrary::UnregisterAllComponents(AActor* Actor, bool bForReregister)
{
	Actor->UnregisterAllComponents(bForReregister);
}


bool UHiBlueprintFunctionLibrary::IsInClientLoadRegion(UWorld* World,  const FTransform& Transform)
{
#if WITH_EDITOR && LQT_DISTRIBUTED_DS
	const FVector& Location = Transform.GetLocation();
	bool bInLoadedArea = World->GetDistributedRegionList().IsEmpty();
	for(auto& Box : World->GetDistributedRegionList())
	{
		if(Box.IsInsideXY(Location))
		{
			bInLoadedArea = true;
			break;
		}
	}

	return bInLoadedArea;
#else
	return true;
#endif
	
}
