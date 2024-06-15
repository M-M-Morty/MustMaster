// Copyright Epic Games, Inc. All Rights Reserved.

#include "AnimGraphNode/HiAnimGraphNode_TranslateBone.h"


/////////////////////////////////////////////////////
// UHiAnimGraphNode_TranslateBone

#define LOCTEXT_NAMESPACE "A3Nodes"

UHiAnimGraphNode_TranslateBone::UHiAnimGraphNode_TranslateBone(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FLinearColor UHiAnimGraphNode_TranslateBone::GetNodeTitleColor() const
{
	return FLinearColor(0.7f, 0.7f, 0.7f);
}

FText UHiAnimGraphNode_TranslateBone::GetTooltipText() const
{
	return LOCTEXT("TranslateBone", "Translate Bone (Parent Bone Space)");
}

FText UHiAnimGraphNode_TranslateBone::GetNodeTitle(ENodeTitleType::Type TitleType) const
{
	return LOCTEXT("TranslateBone", "Translate Bone (Parent Bone Space)");
}

FText UHiAnimGraphNode_TranslateBone::GetMenuCategory() const
{
	return LOCTEXT("RotateRootBoneCateogory", "Animation|Misc.");
}

void UHiAnimGraphNode_TranslateBone::CustomizePinData(UEdGraphPin* Pin, FName SourcePropertyName, int32 ArrayIndex) const
{
	Super::CustomizePinData(Pin, SourcePropertyName, ArrayIndex);
}

void UHiAnimGraphNode_TranslateBone::PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent)
{
	const FName PropertyName = (PropertyChangedEvent.Property ? PropertyChangedEvent.Property->GetFName() : NAME_None);

	// Reconstruct node to show updates to PinFriendlyNames.
	if ((PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, bMapRange))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputRange, Min))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputRange, Max))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, Scale))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, Bias))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, bClampResult))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, ClampMin))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, ClampMax))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, bInterpResult))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, InterpSpeedIncreasing))
		|| (PropertyName == GET_MEMBER_NAME_STRING_CHECKED(FInputScaleBiasClamp, InterpSpeedDecreasing)))
	{
		ReconstructNode();
	}

	Super::PostEditChangeProperty(PropertyChangedEvent);
}

#undef LOCTEXT_NAMESPACE
