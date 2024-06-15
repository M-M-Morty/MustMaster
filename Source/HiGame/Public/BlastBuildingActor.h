// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DataTable.h"
#include "GameFramework/Actor.h"

#include "BlastBuildingActor.generated.h"

USTRUCT(BlueprintType)
struct FBlastMaterialInfo
{
	GENERATED_BODY()
	
public:
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartFrameValue{1.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float EndFrameValue{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float LastTimeInSeconds{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString MaterialParamName {"Display Frame"};
};

USTRUCT(BlueprintType)
struct FBlastEffectsInfo
{	GENERATED_BODY()
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartTime{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float EndTime{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString EffectName;
};

USTRUCT(BlueprintType)
struct FCBlastBuildingPartInfo : public  FTableRowBase
{
	
	GENERATED_BODY()
public:
	
	FCBlastBuildingPartInfo(){}

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool bCrashImmediatelyWithoutSustain {false};
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString MaterialTagName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString SustainPartName;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float Density{1.0f};

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float BlastTotalShowTime{15.0f};

	// todo: precompute in triangle granularity. now use bounding box size * density instead.
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float Quality{-1.0f}; 

	// todo: precompute in triangle granularity. now use bounding box center instead.
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FVector CenterOfGravity = FVector::ZeroVector;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FBox BoundingBox;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString BlastMeshName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FBlastEffectsInfo> BlastEffectInfos;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FBlastMaterialInfo> BlastMaterialInfos;
	
};

namespace EBuildingPartState 
{ 
	enum Type 
	{ 
		Default,
		Hide,
		Falling,
	}; 
}

struct SFallingPartInfo
{
	float FallingStartVelocity{0};
	float FallingStartTime;
	float FallingLastTime;
	float MovedDistance;
};

struct SBlastingPartInfo
{
	bool									bInBlasting{false};
	float									StartTime;
	float									TotalShowTime;

	float									OriginHeight; // for move back
	float									BlastStartHeight;
	float									MoveBackVelocity;
	float									MoveBackUsedTimeRate{0.6f};
	TArray<float>							LastTimes;
	TArray<float>							StartFrameValues;
	TArray<float>							EndFrameValues;
	TArray<float>							NowFrameValues;
	FString									MaterialParamName;
	TSoftObjectPtr<UStaticMeshComponent>	BlastingComp;
};

UCLASS(Blueprintable, BlueprintType, config=Game, Meta = (ShortTooltip = "T......"))
class HIGAME_API ABlastBuildingActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ABlastBuildingActor();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<UDataTable> DetailMeshes;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<UDataTable> BuildingPartInfo;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	float Gravity{9.8f};

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	bool bUpdateState{false};


	UFUNCTION(BlueprintImplementableEvent)
	void CollapseInC(UStaticMeshComponent* Collision_Mesh);

	UFUNCTION(BlueprintImplementableEvent)
	void ShowDebrisInC(const FString& PartName);

	UFUNCTION(BlueprintCallable)
	void StartBlasting(const FString& PartName);

	UFUNCTION(BlueprintCallable)
	void StartEffect(const FString& PartName);

private:
	TMap<FString, EBuildingPartState::Type>				CollisionMeshState;

	TMap<FString, TArray<FString>>						PartSustainRelations;

	TMap<FString, SFallingPartInfo>						FallingPartInfos;

	TMap<FString, SBlastingPartInfo>					BlastingPartInfos;

	TMap<FString, TSoftObjectPtr<UStaticMeshComponent>>	NameToCollision;

	float												TotalQuality{-1.0f};
	
	FVector												TotalCenterOfGravity;

private:
	void InitializePartSustainRelations();
	SFallingPartInfo GetInitializedFallingPartInfo() const;

	bool CheckFallingPartCollapse(const FString& PartName, const SFallingPartInfo& FallingPart);
	
	void UpdateBlasting();
};
