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
		FString AuthorityKey = UGameplayStatics::ParseOption(Options, "token");
		if (PlayerID.IsEmpty())
		{
			ErrorMessage = "PlayerID param not found";
			return ErrorMessage;
		}
		uint64 PlayerProxyID = FCString::Atoi64(*PlayerID);
		UGameplayEntitySubsystem* GameplayEntitySubsystem = GetWorld()->GetSubsystem<UGameplayEntitySubsystem>();
		if (GameplayEntitySubsystem == nullptr)
		{
			ErrorMessage = "GameplayEntitySubsystem not found";
			return ErrorMessage;
		}
		if (FDistributedDSUtils::IsUseLocalAdapter())
		{
			GameplayEntitySubsystem->AddPlayerInLocalMode(PlayerProxyID, "");
		}
		if (!GameplayEntitySubsystem->CheckPlayerExist(PlayerProxyID))
		{
			ErrorMessage = "PlayerID not exist";
			return ErrorMessage;
		}
		if (!GameplayEntitySubsystem->CheckPlayerAuthority(PlayerProxyID, AuthorityKey))
		{
			ErrorMessage = "AuthorityKey check failure";
			return ErrorMessage;
		}
	}

	return ErrorMessage;
}
