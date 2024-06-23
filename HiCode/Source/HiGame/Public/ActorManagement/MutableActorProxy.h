#pragma once

#include "CoreMinimal.h"
#include "MutableActorProxy.generated.h"


UCLASS(Blueprintable, Abstract)
class UMutableActorProxy : public UObject
{
	GENERATED_BODY()
	
public:	
	UMutableActorProxy();
};
