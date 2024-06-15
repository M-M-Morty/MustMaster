// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GeometryCollection/GeometryCollectionComponent.h"
#include "Templates/SubclassOf.h"
#include "BlastItemActor.generated.h"

UCLASS(Blueprintable, BlueprintType, config=Game, Meta = (ShortTooltip = "T......"))
class HIGAME_API ABlastItemActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	ABlastItemActor();
	ABlastItemActor(const FObjectInitializer& ObjectInitializer);

	UPROPERTY()
	TObjectPtr<class USceneComponent> DummyRoot;

	UPROPERTY(Category = GeometryCollection, VisibleAnywhere, BlueprintReadWrite)
	TObjectPtr<UGeometryCollectionComponent> GeometryCollectionComponent = nullptr;

	//这里不在蓝图里直接加component去放这个属性是因为蓝图里放置的，在自己actor的geometry collection上引用不了。
	UPROPERTY(Category = GeometryCollection, EditAnywhere, BlueprintReadWrite)
    TSubclassOf<AFieldSystemActor> FieldSystemActorClass;

	UPROPERTY()
	TObjectPtr<AFieldSystemActor> FieldSystemActor;


	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool	bAutoGenerateAnchor{ true };

#if WITH_EDITOR
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
	virtual void PostActorCreated();
	
	void DeleteAnchor();
	void InitFieldsForGeometryCollection();

	virtual bool ShouldTickIfViewportsOnly() const  override { return true;}
private:
	FTransform AnchorBoxTransform;
	bool bUseAnchorBox{false};
#endif
	
protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	/** timer handle  */
	FTimerHandle TimerHandleDelayInit;
public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

private:
	bool Init();
	
	
	
	
	

};
