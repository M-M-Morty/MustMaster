// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "Engine/DataTable.h"
#include "BlastSimpleBuildingActor.generated.h"

USTRUCT(BlueprintType)
struct FBlastMaterialParamInfo
{
	GENERATED_BODY()
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartValue{1.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float EndValue{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartTimeInSeconds{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float EndTimeInSeconds{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString  MaterialOwnedCompName;
};

USTRUCT(BlueprintType)
struct FSkeletonAnimInfo
{
	GENERATED_BODY()
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString SkeletonCompName;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString SkeletonDieAnimPath;
};


USTRUCT(BlueprintType)
struct FEffectInfo
{
	GENERATED_BODY()
	
public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float StartTime{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float EndTime{0.0f};
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString EffectName;
};

struct SInfoInBlasting
{
	bool									bInBlasting{false};
	bool									bOnBlastPlayEnd{false};
	float									BlastingStartTime;
	float									TotalShowTime;
	float									TotalBlastTime{-1};
	
	TArray<float>							ParamStartChangeTimeInSeconds;
	TArray<float>							ParamEndChangeTimeInSeconds;
	TArray<float>							ParamStartValues;
	TArray<float>							ParamEndValues;
	TArray<float>							NowValues;
	TArray<FString>							MaterialOwnedCompNames;
	FString									MaterialParamName;
};

USTRUCT(BlueprintType)
struct FBuildingTopBlastInfo : public  FTableRowBase
{
	GENERATED_BODY()
public:
	FBuildingTopBlastInfo(){}

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float TotalShowTime{-1.0f};

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float TotalBlastPlayTime{-1.0f};
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FString MaterialParamName {"Display Frame"};

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FEffectInfo> EffectInfos;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FBlastMaterialParamInfo> MaterialInfos;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TArray<FSkeletonAnimInfo> SkeletonAnimInfos;
};

//delegate when blast happend
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FBlastSimpleDelegate);

UCLASS(Blueprintable, BlueprintType, config = Game, Meta = (ShortTooltip = "T......"))
class HIGAME_API ABlastSimpleBuildingActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ABlastSimpleBuildingActor();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;
	
	UPROPERTY(Category = Buildings, VisibleAnywhere, BlueprintReadWrite, meta = (DisplayName = "未破碎之前的整体建筑"))
	TObjectPtr<UStaticMeshComponent> MainBuilding;

	UPROPERTY(Category = Buildings, VisibleAnywhere, BlueprintReadWrite, meta = (DisplayName = "未破碎之前顶部的碰撞体"))
	TObjectPtr<UStaticMeshComponent> TopCollision;

	UPROPERTY(Category = Buildings, VisibleAnywhere, BlueprintReadWrite, meta = (DisplayName = "未破碎之前底座的碰撞体"))
	TObjectPtr<UStaticMeshComponent> BaseCollision;

	UPROPERTY(Category = Buildings, VisibleAnywhere, BlueprintReadWrite, meta = (DisplayName = "破碎后的建筑底座"))
	TObjectPtr<UStaticMeshComponent> BaseBrokenBuilding;

	UPROPERTY(Category = Buildings, VisibleAnywhere, BlueprintReadWrite, meta = (DisplayName = "要进行破碎动画的建筑顶部"))
	TObjectPtr<UStaticMeshComponent> TopBlastBuilding;
	

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<UDataTable> BuildingPartInfo;
	
	UFUNCTION(BlueprintCallable)
	void StartBlasting(const FString& PartName);

	UPROPERTY(BlueprintAssignable)
	FBlastSimpleDelegate StartBlastDelegate;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true", DisplayName = "破碎的时候需要联动的物体列表"))
	TArray<TObjectPtr<AActor>> AttachmentActors;
	
private:
	bool					bHasBlasted{false};
	SInfoInBlasting			InfoInBlasting;


	FTimerHandle			HandleEndPlayForServer;
	FTimerHandle			TimerHandleEndMaterialBlast;
	FTimerHandle			TimerHandleEndPlay;
	FTimerHandle			EffectHandleStartPlay;
	FTimerHandle			EffectHandleEndPlay;
	
	void UpdateBlasting();
	void OnBlastPlayEnd();
	
	void StartEffect();

	void StartMaterialBlast();
	void StartSkeletonBlastingAnimation() const;

	void SetMaterialAutoPlay(bool bAutoPlay);

	void ShowSceneCompByName(const FString& PrefixesName, bool bShown, bool bUseCollision);

	void InitBuildingState();
};
