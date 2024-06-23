#include "PartialWorld/DebugPartialWorldSubsystem.h"

#include "DistributedDSUtils.h"
#include "Kismet/GameplayStatics.h"
#include "PartialWorldPlayerState.h"

const TArray<FLinearColor> UDebugPartialWorldSubsystem::ColorArray = {
	FLinearColor(1.00, 0.00, 0.00, 0.3),
	FLinearColor(0.00, 1.00, 0.00, 0.3),
	FLinearColor(0.00, 0.00, 1.00, 0.3),
	FLinearColor(1.00, 1.00, 0.00, 0.3),
	FLinearColor(1.00, 0.00, 1.00, 0.3),
	FLinearColor(0.00, 1.00, 1.00, 0.3),
	FLinearColor(0.45, 0.87, 0.32, 0.3),
	FLinearColor(0.23, 0.65, 0.89, 0.3),
	FLinearColor(0.89, 0.22, 0.31, 0.3),
	FLinearColor(0.67, 0.76, 0.34, 0.3),
	FLinearColor(0.56, 0.35, 0.78, 0.3),
	FLinearColor(0.12, 0.56, 0.33, 0.3),
	FLinearColor(0.34, 0.89, 0.23, 0.3),
	FLinearColor(0.78, 0.34, 0.56, 0.3),
	FLinearColor(0.90, 0.45, 0.21, 0.3),
	FLinearColor(0.21, 0.90, 0.45, 0.3),
	FLinearColor(0.32, 0.87, 0.45, 0.3),
	FLinearColor(0.45, 0.32, 0.87, 0.3),
	FLinearColor(0.87, 0.45, 0.32, 0.3),
	FLinearColor(0.65, 0.89, 0.23, 0.3),
	FLinearColor(0.89, 0.65, 0.23, 0.3),
	FLinearColor(0.23, 0.89, 0.65, 0.3),
	FLinearColor(0.56, 0.12, 0.33, 0.3),
	FLinearColor(0.33, 0.56, 0.12, 0.3),
	FLinearColor(0.12, 0.33, 0.56, 0.3),
	FLinearColor(0.78, 0.90, 0.45, 0.3),
	FLinearColor(0.45, 0.78, 0.90, 0.3),
	FLinearColor(0.90, 0.78, 0.45, 0.3),
	FLinearColor(0.34, 0.21, 0.90, 0.3),
	FLinearColor(0.21, 0.34, 0.90, 0.3)
};

static int32 GActorTransferDebug = 0;
static FAutoConsoleCommand CVarActorTransferDebug(
	TEXT("dds.Runtime.ToggleActorTransferDebug"),
	TEXT("Toggles debug display of actor transfer."),
	FConsoleCommandDelegate::CreateLambda([] { GActorTransferDebug = !GActorTransferDebug; }));

bool UDebugPartialWorldSubsystem::DoesSupportInstanceType(ESSInstanceType InstanceType) const
{
#if WITH_EDITOR
	return InstanceType == ESSInstanceType::Client;
#else
	return false;
#endif
}


void UDebugPartialWorldSubsystem::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (FDistributedDSUtils::IsUseLocalAdapter())
	{
		return;
	}
	if (UWorld* World = GetWorld())
	{
		if (World->IsNetMode(NM_DedicatedServer))
		{
			return;
		}
		if (!World->GetName().Equals(TEXT("PartialWorld")))
		{
			return;
		}
		for (const auto& RegionInfo : RegionInfoList)
		{
			DrawGeoRegion(RegionInfo);
		}

		double CreateServerSimulatedProxyDistance = 100.0;
		double TransferServerSimulatedProxyDistance = 500.0;
		double DestroyServerSimulatedProxyDistance = 3000.0;
		GConfig->GetDouble(TEXT("ProjectSettings"), TEXT("CreateServerSimulatedProxyDistance"), CreateServerSimulatedProxyDistance, GGameIni);
		GConfig->GetDouble(TEXT("ProjectSettings"), TEXT("TransferServerSimulatedProxyDistance"), TransferServerSimulatedProxyDistance, GGameIni);
		GConfig->GetDouble(TEXT("ProjectSettings"), TEXT("DestroyServerSimulatedProxyDistance"), DestroyServerSimulatedProxyDistance, GGameIni);

		for( FConstPlayerControllerIterator Iterator = World->GetPlayerControllerIterator(); Iterator; ++Iterator )
		{
			APlayerController* PlayerController = Iterator->Get();
			if (APartialWorldPlayerState* PlayerState = Cast<APartialWorldPlayerState>(PlayerController->PlayerState.Get()))
			{
				uint32 PlayerSpaceID = PlayerState->GetSpaceID();
				if (PlayerSpaceID && PlayerSpaceID != LocalSpaceID)
				{
					LocalSpaceID = PlayerSpaceID;
					FlushPersistentDebugLines(World);
					DrawDebugSphere(World, FVector(0, 0, 400), 100, 50, GetSpaceColor(LocalSpaceID), true);
					//DrawDebugBox(World, FVector(0, 0, 100), FVector(CreateServerSimulatedProxyDistance, CreateServerSimulatedProxyDistance, 0), FColor::Black, true, -1, 0, 5);
					DrawDebugBox(World, FVector(0, 0, 100), FVector(TransferServerSimulatedProxyDistance, TransferServerSimulatedProxyDistance, 0), FColor::Black, true, -1, 0, 5);
					//DrawDebugBox(World, FVector(0, 0, 100), FVector(DestroyServerSimulatedProxyDistance, DestroyServerSimulatedProxyDistance, 0), FColor::Black, true, -1, 0, 5);
					break;
				}
			}
		}
	}

	//for (TActorIterator<ADistributedDSDemoCharacter> It(GetWorld()); It; ++It)
	//{
	//	// set body color
	//	FColor SpaceColor = GetSpaceColor(It->SpaceID);
	//	FLinearColor Color = (SpaceColor != FColor::Black) ? SpaceColor : FLinearColor(0.45, 0.406, 0.362, 0);
	//	It->SetBodyColor(Color);
	//	It->SpaceLabels = FString::Join(GeoWorldConfig.GetSpaceLabels(It->SpaceID), TEXT(","));
	//}
}

ETickableTickType UDebugPartialWorldSubsystem::GetTickableTickType() const
{
	return IsTemplate() ? ETickableTickType::Never : ETickableTickType::Always;
}

TStatId UDebugPartialWorldSubsystem::GetStatId() const
{
	RETURN_QUICK_DECLARE_CYCLE_STAT(UDebugPartialWorldSubsystem, STATGROUP_Tickables);
}

void UDebugPartialWorldSubsystem::PostInitialize()
{
	Super::PostInitialize();
}

void UDebugPartialWorldSubsystem::SetGeoSpaceInfo(const FGeoWorldConfig& WorldConfig, const TArray<FGeoRegionInfo>& InRegionInfoList)
{
	RegionInfoList = InRegionInfoList;
	GeoWorldConfig = WorldConfig;
	for (const auto& RegionInfo : RegionInfoList)
	{
		DrawGeoRegion(RegionInfo);
	}
}

void UDebugPartialWorldSubsystem::DrawGeoRegion(const FGeoRegionInfo& RegionInfo)
{
	UWorld* World = GetWorld();

	auto DrawBox2D = [World](const FBox& Box, const FColor& Color, double Z = 50.f)
	{
		if (Box.IsValid)
		{
			FVector BoundsExtent(Box.GetExtent());
			BoundsExtent.Z = Z;
			FVector BoundsOrigin(Box.GetCenter());
			FBox Box2 = FBox::BuildAABB(BoundsOrigin, BoundsExtent);

			DrawDebugSolidBox(World, Box2, Color, FTransform::Identity, false, -1.f, 255);
		}
	};

	FColor Color = GetSpaceColor(RegionInfo.SpaceID).WithAlpha(64);
	DrawBox2D(RegionInfo.RegionBound, Color, 5.f);
}

FColor UDebugPartialWorldSubsystem::GetSpaceColor(FSpaceID SpaceID)
{
	uint32 ColorIdx = (SpaceID - 1) % (uint32)ColorArray.Num();
	return ColorArray[ColorIdx].ToFColor(false);
}
