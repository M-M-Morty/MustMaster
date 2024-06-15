// Fill out your copyright notice in the Description page of Project Settings.


#include "AnimGraphNode/HiAnimGraphNode_LayeredBoneBlend.h"
#include "AnimNodes/AnimNode_LayeredBoneBlend.h"
#include "Kismet2/BlueprintEditorUtils.h"
#include "ToolMenus.h"

#include "AnimGraphCommands.h"
#include "ScopedTransaction.h"

#include "DetailLayoutBuilder.h"
#include "Kismet2/CompilerResultsLog.h"
#include "UObject/UE5ReleaseStreamObjectVersion.h"

/////////////////////////////////////////////////////
// UHiAnimGraphNode_LayeredBoneBlend

#define LOCTEXT_NAMESPACE "UHiAnimGraphNode_LayeredBoneBlend"

UHiAnimGraphNode_LayeredBoneBlend::UHiAnimGraphNode_LayeredBoneBlend(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FLinearColor UHiAnimGraphNode_LayeredBoneBlend::GetNodeTitleColor() const
{
	return FLinearColor(0.2f, 0.8f, 0.2f);
}

FText UHiAnimGraphNode_LayeredBoneBlend::GetTooltipText() const
{
	return LOCTEXT("HiAnimGraphNode_LayeredBoneBlend_Tooltip", "Hi Layered blend per bone");
}

FText UHiAnimGraphNode_LayeredBoneBlend::GetNodeTitle(ENodeTitleType::Type TitleType) const
{
	return LOCTEXT("HiAnimGraphNode_LayeredBoneBlend_Title", "Hi Layered blend per bone");
}

void UHiAnimGraphNode_LayeredBoneBlend::PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent)
{
	const FName PropertyName = (PropertyChangedEvent.Property ? PropertyChangedEvent.Property->GetFName() : NAME_None);

	// Reconstruct node to show updates to PinFriendlyNames.
	if (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FHiAnimNode_LayeredBoneBlend, BlendMode))
	{
		// If we  change blend modes, we need to resize our containers
		FScopedTransaction Transaction(LOCTEXT("ChangeBlendMode", "Change Blend Mode"));
		Modify();

		const int32 NumPoses = Node.BlendPoses.Num();
		if (Node.BlendMode == ELayeredBoneBlendMode::BlendMask)
		{
			Node.LayerSetup.Reset();
			Node.BlendMasks.SetNum(NumPoses);
		}
		else
		{
			Node.BlendMasks.Reset();
			Node.LayerSetup.SetNum(NumPoses);
		}

		FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(GetBlueprint());
	}

	Super::PostEditChangeProperty(PropertyChangedEvent);
}

FString UHiAnimGraphNode_LayeredBoneBlend::GetNodeCategory() const
{
	return TEXT("Animation|Blends");
}

void UHiAnimGraphNode_LayeredBoneBlend::CustomizeDetails(IDetailLayoutBuilder& DetailBuilder)
{
	TSharedRef<IPropertyHandle> NodeHandle = DetailBuilder.GetProperty(FName(TEXT("Node")), GetClass());

	if (Node.BlendMode != ELayeredBoneBlendMode::BranchFilter)
	{
		DetailBuilder.HideProperty(NodeHandle->GetChildHandle(GET_MEMBER_NAME_CHECKED(FAnimNode_LayeredBoneBlend, LayerSetup)));
	}

	if (Node.BlendMode != ELayeredBoneBlendMode::BlendMask)
	{
		DetailBuilder.HideProperty(NodeHandle->GetChildHandle(GET_MEMBER_NAME_CHECKED(FAnimNode_LayeredBoneBlend, BlendMasks)));
	}

	Super::CustomizeDetails(DetailBuilder);
}

void UHiAnimGraphNode_LayeredBoneBlend::PreloadRequiredAssets()
{
	// Preload our blend profiles in case they haven't been loaded by the skeleton yet.
	if (Node.BlendMode == ELayeredBoneBlendMode::BlendMask)
	{
		int32 NumBlendMasks = Node.BlendMasks.Num();
		for (int32 MaskIndex = 0; MaskIndex < NumBlendMasks; ++MaskIndex)
		{
			UBlendProfile* BlendMask = Node.BlendMasks[MaskIndex];
			PreloadObject(BlendMask);
		}
	}

	Super::PreloadRequiredAssets();
}

void UHiAnimGraphNode_LayeredBoneBlend::AddPinToBlendByFilter()
{
	FScopedTransaction Transaction( LOCTEXT("AddPinToBlend", "AddPinToBlendByFilter") );
	Modify();

	Node.AddPose();
	ReconstructNode();
	FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(GetBlueprint());
}

void UHiAnimGraphNode_LayeredBoneBlend::RemovePinFromBlendByFilter(UEdGraphPin* Pin)
{
	FScopedTransaction Transaction( LOCTEXT("RemovePinFromBlend", "RemovePinFromBlendByFilter") );
	Modify();

	FProperty* AssociatedProperty;
	int32 ArrayIndex;
	GetPinAssociatedProperty(GetFNodeType(), Pin, /*out*/ AssociatedProperty, /*out*/ ArrayIndex);

	if (ArrayIndex != INDEX_NONE)
	{
		Node.RemovePose(ArrayIndex);
		ReconstructNode();
		FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(GetBlueprint());
	}
}

void UHiAnimGraphNode_LayeredBoneBlend::GetNodeContextMenuActions(UToolMenu* Menu, UGraphNodeContextMenuContext* Context) const
{
	if (!Context->bIsDebugging)
	{
		{
			FToolMenuSection& Section = Menu->AddSection("HiAnimGraphNodeLayeredBoneblend", LOCTEXT("LayeredBoneBlend", "Layered Bone Blend"));
			if (Context->Pin != NULL)
			{
				// we only do this for normal BlendList/BlendList by enum, BlendList by Bool doesn't support add/remove pins
				if (Context->Pin->Direction == EGPD_Input)
				{
					//@TODO: Only offer this option on arrayed pins
					Section.AddMenuEntry(FAnimGraphCommands::Get().RemoveBlendListPin);
				}
			}
			else
			{
				Section.AddMenuEntry(FAnimGraphCommands::Get().AddBlendListPin);
			}
		}
	}
}

void UHiAnimGraphNode_LayeredBoneBlend::ValidateAnimNodeDuringCompilation(class USkeleton* ForSkeleton, class FCompilerResultsLog& MessageLog)
{
	UAnimGraphNode_Base::ValidateAnimNodeDuringCompilation(ForSkeleton, MessageLog);

	bool bCompilationError = false;
	// Validate blend masks
	if (Node.BlendMode == ELayeredBoneBlendMode::BlendMask)
	{
		int32 NumBlendMasks = Node.BlendMasks.Num();
		for (int32 MaskIndex = 0; MaskIndex < NumBlendMasks; ++MaskIndex)
		{
			const UBlendProfile* BlendMask = Node.BlendMasks[MaskIndex];
			if (BlendMask == nullptr && !GetAnimBlueprint()->bIsTemplate)
			{
				MessageLog.Error(*FText::Format(LOCTEXT("LayeredBlendNullMask", "@@ has null BlendMask for Blend Pose {0}. "), FText::AsNumber(MaskIndex)).ToString(), this, BlendMask);
				bCompilationError = true;
			}
			
			if (BlendMask && BlendMask->Mode != EBlendProfileMode::BlendMask)
			{
				MessageLog.Error(*FText::Format(LOCTEXT("LayeredBlendProfileModeError", "@@ is using a BlendProfile(@@) without a BlendMask mode for Blend Pose {0}. "), FText::AsNumber(MaskIndex)).ToString(), this, BlendMask);
				bCompilationError = true;
			}
		}
	}

	// Don't rebuild the node's data if compilation failed. We may be attempting to do so with invalid data.
	if (bCompilationError)
	{
		return;
	}

	// ensure to cache the per-bone blend weights
 	if (!Node.ArePerBoneBlendWeightsValid(ForSkeleton))
 	{
 		Node.RebuildPerBoneBlendWeights(ForSkeleton);
 	}
}

void UHiAnimGraphNode_LayeredBoneBlend::Serialize(FArchive& Ar)
{
	Super::Serialize(Ar);

	Ar.UsingCustomVersion(FUE5ReleaseStreamObjectVersion::GUID);

	if (Ar.IsLoading() && Ar.CustomVer(FUE5ReleaseStreamObjectVersion::GUID) < FUE5ReleaseStreamObjectVersion::AnimLayeredBoneBlendMasks)
	{
		if (Node.BlendMode == ELayeredBoneBlendMode::BlendMask && Node.BlendMasks.Num() != Node.BlendPoses.Num())
		{
			Node.BlendMasks.SetNum(Node.BlendPoses.Num());
		}
	}
}

void UHiAnimGraphNode_LayeredBoneBlend::PostLoad()
{
	Super::PostLoad();

	// Post-load our blend masks, in case they've been pre-loaded, but haven't had their bone references initialized yet.
	if (Node.BlendMode == ELayeredBoneBlendMode::BlendMask)
	{
		int32 NumBlendMasks = Node.BlendMasks.Num();
		for (int32 MaskIndex = 0; MaskIndex < NumBlendMasks; ++MaskIndex)
		{
			if(UBlendProfile* BlendMask = Node.BlendMasks[MaskIndex])
			{
				BlendMask->ConditionalPostLoad();
			}
		}
	}
}

#undef LOCTEXT_NAMESPACE
