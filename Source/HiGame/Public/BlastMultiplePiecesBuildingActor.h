// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "BlastSimpleBuildingActor.h"
#include "BlastMultiplePiecesBuildingActor.generated.h"
//delegate when blast happend
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FMultiplePiecesBlastDelegate);

UCLASS(Blueprintable, BlueprintType, config = Game, Meta = (ShortTooltip = "T......"))
class HIGAME_API ABlastMultiplePiecesBuildingActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ABlastMultiplePiecesBuildingActor();


	// Called every frame
	virtual void Tick(float DeltaTime) override;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<UDataTable> BuildingPartInfo;
	
	UFUNCTION(BlueprintCallable)
	void StartBlasting(const FString& PartName);

	UPROPERTY(BlueprintAssignable)
	FMultiplePiecesBlastDelegate StartBlastDelegate;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Meta = (AllowPrivateAccess = "true", DisplayName = "破碎的时候需要联动的物体列表"))
	TArray<TObjectPtr<AActor>> AttachmentActors;



	
private:
	TMap<FString, TSet<USceneComponent*>>	BuildingComp;

	void InitComp();
	void ShowSceneCompByName(const FString& PrefixesName, bool bShown, bool bUseCollision);
	void StartEffect();
	void UpdateBlasting();
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

public:	

private:
	bool					bHasBlasted{false};
	SInfoInBlasting			InfoInBlasting;
	FTimerHandle			HandleEndPlayForServer;
	FTimerHandle			HandleStartPlayForEffect;
	FTimerHandle			HandleEndPlayForEffect;
	
};
