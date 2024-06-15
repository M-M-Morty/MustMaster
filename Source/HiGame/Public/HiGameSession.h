#pragma once

#include "GameFramework/GameSession.h"
#include "HiGameSession.generated.h"

UCLASS()
class HIGAME_API AHiGameSession : public AGameSession
{
	GENERATED_BODY()

public:
	virtual FString ApproveLogin(const FString& Options) override;
};