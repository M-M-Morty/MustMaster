// Copyright Epic Games, Inc. All Rights Reserved.

#include "AnimGraphNode/HiAnimGraphNode_RotateBone.h"


/////////////////////////////////////////////////////
// UHiAnimGraphNode_RotateBone

#define LOCTEXT_NAMESPACE "A3Nodes"

UHiAnimGraphNode_RotateBone::UHiAnimGraphNode_RotateBone(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FLinearColor UHiAnimGraphNode_RotateBone::GetNodeTitleColor() const
{
	return FLinearColor(0.7f, 0.7f, 0.7f);
}

FText UHiAnimGraphNode_RotateBone::GetTooltipText() const
{
	return LOCTEXT("HiRotateBone", "Rotate Bone (Parent Bone Space)");
}

FText UHiAnimGraphNode_RotateBone::GetNodeTitle(ENodeTitleType::Type TitleType) const
{
	return LOCTEXT("HiRotateBone", "Rotate Bone (Parent Bone Space)");
}

FText UHiAnimGraphNode_RotateBone::GetMenuCategory() const
{
	return LOCTEXT("HiRotateBoneCateogory", "Animation|Misc.");
}

void UHiAnimGraphNode_RotateBone::CustomizePinData(UEdGraphPin* Pin, FName SourcePropertyName, int32 ArrayIndex) const
{
	Super::CustomizePinData(Pin, SourcePropertyName, ArrayIndex);

	//if (Pin->PinName == GET_MEMBER_NAME_STRING_CHECKED(FHiAnimNode_RotateBone, Pitch))
	//{
	//	if (!Pin->bHidden)
	//	{
	//		Pin->PinFriendlyName = Node.PitchScaleBiasClamp.GetFriendlyName(Pin->PinFriendlyName);
	//	}
	//}

	//if (Pin->PinName == GET_MEMBER_NAME_STRING_CHECKED(FHiAnimNode_RotateBone, Yaw))
	//{
	//	if (!Pin->bHidden)
	//	{
	//		Pin->PinFriendlyName = Node.YawScaleBiasClamp.GetFriendlyName(Pin->PinFriendlyName);
	//	}
	//}
}

void UHiAnimGraphNode_RotateBone::PostEditChangeProperty(struct FPropertyChangedEvent& PropertyChangedEvent)
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
