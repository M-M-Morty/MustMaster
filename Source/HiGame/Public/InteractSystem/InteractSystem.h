#pragma once

#include "GameFramework/Pawn.h"
#include "InteractSystem.generated.h"

DECLARE_LOG_CATEGORY_EXTERN(LogInteractSystem, Log, All);

#define TRACE_CHANNEL_INTERACT_FOCUS_TEST ECollisionChannel::ECC_GameTraceChannel5

UENUM(BlueprintType)
enum class EInteractItemState : uint8
{
	IIS_None = 0,
	IIS_Prompt = 1,
	IIS_Focus = 2,
	IIS_Interacting = 3,
	//IIS_InteractCompleted=4,
};

USTRUCT(BlueprintType)
struct FInteractQueryParam
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadWrite)
	APawn* InitiatePawn = 0;
};

UENUM(BlueprintType)
enum class EInteractAction : uint8
{
	//nothing to do
	IA_None = 0, 

	//Set initiate pawn's LocoState
	IA_SetLocoState = 1, 

	//Activate an ability for initiate pawn
	IA_ActivateAbility = 2, 

	//Send a GameplayEvent to initiate pawn, and Payload.OptionalObject is this interact actor.
	IA_SendGameplayEventWithPayload = 3,
	
	IA_InterfaceImplement = 4,
	IA_InactToSublevelEvent = 5,
	//Use a custom executor to response the interact request, the executor must override TryInteract() event.
	IA_CustomExecutor = 99,

	
};

USTRUCT(BlueprintType)
struct FInteractInfo
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadWrite)
	int32 Type = 0;

	UPROPERTY(BlueprintReadWrite)
	float Range = 0.0f;

	UPROPERTY(BlueprintReadWrite)
	bool AutoInteract = false;
};

