// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Logging/LogMacros.h"

HIGAME_API DECLARE_LOG_CATEGORY_EXTERN(LogHiGame, Log, All);
HIGAME_API DECLARE_LOG_CATEGORY_EXTERN(LogHiAbilitySystem, Log, All);
HIGAME_API DECLARE_LOG_CATEGORY_EXTERN(LogHiGameFeature, Log, All);


HIGAME_API FString GetClientServerContextString(UObject* ContextObject = nullptr);
