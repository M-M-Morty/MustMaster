#pragma once

#include "CoreMinimal.h"
#include "GlobalActor.h"
#include "MutableActorManager.generated.h"

UCLASS()
class AMutableActorManager : public AGlobalActor
{
	GENERATED_BODY()

public:
	AMutableActorManager();
	
protected:
	virtual void BeginPlay() override;
	
};
