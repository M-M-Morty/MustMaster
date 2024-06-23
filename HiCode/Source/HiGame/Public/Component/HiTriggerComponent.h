// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/StaticMeshComponent.h"
#include "HiTriggerComponent.generated.h"

/**
 * 
 */
UCLASS(BlueprintType, Blueprintable, Meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiTriggerComponent : public UStaticMeshComponent
{
	GENERATED_BODY()
public:
	UHiTriggerComponent(const FObjectInitializer& ObjectInitializer);

	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	#if WITH_EDITOR		
		virtual bool SetStaticMesh(class UStaticMesh* NewMesh);
    	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;		

		UMaterial* GetActiveWireFrameMaterial();
		UMaterialInstanceDynamic* GetActiveWireFrameMID();
		void UpdateRelativeScale();

		UFUNCTION(BlueprintCallable, CallInEditor, Category="Settings")
		void CreateTriggerMesh();
	
protected:
	virtual void OnRegister() override;
	#endif	
	
	UFUNCTION(BlueprintImplementableEvent)
	void ReviceComponentBeginOverlap(UPrimitiveComponent* OverlappedComponent, AActor* OtherActor, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex, bool bFromSweep, const FHitResult& SweepResult);

	UFUNCTION(BlueprintImplementableEvent)
	void ReviceComponentEndOverlap(UPrimitiveComponent* OverlappedComp, AActor* Other, UPrimitiveComponent* OtherComp, int32 OtherBodyIndex);

protected:

#if WITH_EDITORONLY_DATA
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Settings", Meta = (AllowPrivateAccess = "true"))
	float TriggerScale = 1.0f;
	
	//UPROPERTY(EditDefaultsOnly, Category="Settings")//, Meta = (EditCondition = "bHasFlowers"))
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Settings", Meta = (AllowPrivateAccess = "true"))
	FLinearColor WireFrameColor = FLinearColor::White;	
	UPROPERTY()
	TObjectPtr<UMaterialInstanceDynamic> WireFrameMaterialInst;
	TSoftObjectPtr<UMaterial> WireFrameMaterialBase;

#endif
};
