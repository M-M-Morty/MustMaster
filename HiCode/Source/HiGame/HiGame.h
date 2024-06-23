// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"


UENUM(BlueprintType)
enum class EGASAbilityInputID : uint8
{
	None	UMETA(DisplayName = "None"),
	Dodge	UMETA(DisplayName = "Dodge"),
	DodgeFwd	UMETA(DisplayName = "DodgeFwd"),
	DodgeLeft	UMETA(DisplayName = "DodgeLeft"),
	DodgeRight	UMETA(DisplayName = "DodgeRight"),
	Attack	UMETA(DisplayName = "Attack"),
	Combo	UMETA(DistplayName = "Combo"),
	Block	UMETA(DisplayName = "Block"),
	Kick	UMETA(DisplayName = "Kick"),
};