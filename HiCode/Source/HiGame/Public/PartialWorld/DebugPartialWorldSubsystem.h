#pragma once

#include "CoreMinimal.h"
#include "DistributedDSWorldSubsystem.h"
#include "Subsystems/WorldSubsystem.h"
#include "Math/Box2D.h"
#include "GEOQuadTreeTypes.h"
#include "DebugPartialWorldSubsystem.generated.h"

UCLASS()
class UDebugPartialWorldSubsystem : public UDistributedDSTickableWorldSubsystem
{
	GENERATED_BODY()
public:
	//~ Begin FTickableGameObject
	virtual void Tick(float DeltaSeconds) override;
	virtual bool IsTickableInEditor() const override { return true; }
	virtual ETickableTickType GetTickableTickType() const override;
	virtual TStatId GetStatId() const override;
	virtual bool DoesSupportInstanceType(ESSInstanceType InstanceType) const override;
	//~End FTickableGameObject

	virtual void PostInitialize() override;

	void SetGeoSpaceInfo(const FGeoWorldConfig& WorldConfig, const TArray<FGeoRegionInfo>& InRegionInfoList);

	FColor GetSpaceColor(FSpaceID SpaceID);

private:

	void DrawGeoRegion(const FGeoRegionInfo& RegionInfo);

	TArray<FGeoRegionInfo> RegionInfoList;
	UMaterialInstanceDynamic* DMI_PostProcess;
	UTextureRenderTarget2D* CellInfo;
	FGeoWorldConfig GeoWorldConfig;

	uint32 LocalSpaceID;

	static const TArray<FLinearColor> ColorArray;
};
