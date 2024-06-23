#include "ActorManagement/MutableActorManager.h"


AMutableActorManager::AMutableActorManager()
	: Super()
{
	bReplicates = false;
	bNetLoadOnClient = false;
#if WITH_EDITORONLY_DATA
	bIsSpatiallyLoaded = true;
#endif
}


void AMutableActorManager::BeginPlay()
{
	Super::BeginPlay();
}

