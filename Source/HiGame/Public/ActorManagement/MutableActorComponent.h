#pragma once

#include "CoreMinimal.h"
#include "GameplayEntitySubsystem.h"
#include "UnrealGameplayEntityComponent.h"
#include "MutableActorComponent.generated.h"


UCLASS(Blueprintable)
class UMutableActorComponent : public UUnrealGameplayEntityComponent
{
	GENERATED_UCLASS_BODY()
	
public:
	static void ExtendLuaMetatable(lua_State* L, const UStruct* Class, const FString& MetatableName);
	
	virtual void PostTransfer() override;

	UFUNCTION(BlueprintCallable)
	FString GenerateChildActorID();
};
