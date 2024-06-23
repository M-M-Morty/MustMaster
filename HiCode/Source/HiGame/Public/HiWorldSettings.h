#pragma once

#include "HiMissionFlowAsset.h"
#include "GameFramework/WorldSettings.h"
#include "HiWorldSettings.generated.h"

class UFlowComponent;

/**
 * World Settings used to start a Flow for this world
 */
UCLASS()
class HIGAME_API AHiWorldSettings : public AWorldSettings
{
	GENERATED_UCLASS_BODY()

public:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Mission")
	TObjectPtr<UHiMissionFlowAsset> MissionRootFlow;
	
#if WITH_EDITORONLY_DATA 
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Mission")
	bool bForceServerAcceptClientPosition = false;
#endif

public:

	virtual void PostLoad() override;
	virtual void PostInitializeComponents() override;

};