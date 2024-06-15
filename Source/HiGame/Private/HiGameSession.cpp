#include "HiGameSession.h"

#include "DistributedDSUtils.h"
#include "GameplayEntitySubsystem.h"
#include "Kismet/GameplayStatics.h"

FString AHiGameSession::ApproveLogin(const FString& Options)
{
	FString ErrorMessage = Super::ApproveLogin(Options);
	if (!ErrorMessage.IsEmpty())
	{
		return ErrorMessage;
	}
	if ( Aether::GetSSInstanceType() == ESSInstanceType::Game )
	{
		FString PlayerID = UGameplayStatics::ParseOption(Options, "PlayerID");
		if (PlayerID.IsEmpty())
		{
			ErrorMessage = "PlayerID param not found";
			return ErrorMessage;
		}
		
		uint64 PlayerProxyID = FCString::Atoi64(*PlayerID);
		
		if (FDistributedDSUtils::IsUseLocalAdapter())
		{
			UGameplayEntitySubsystem* GameplayEntitySubsystem = GetWorld()->GetSubsystem<UGameplayEntitySubsystem>();
			if (GameplayEntitySubsystem)
			{
				GameplayEntitySubsystem->AddPlayerInLocalMode(PlayerProxyID, "");
			}
		}
		
		if (!GetWorld()->GetSubsystem<UGameplayEntitySubsystem>()->CanPlayerLogin(PlayerProxyID))
		{
			ErrorMessage = "PlayerID not allowed";
			return ErrorMessage;
		}
	}

	return ErrorMessage;
}
