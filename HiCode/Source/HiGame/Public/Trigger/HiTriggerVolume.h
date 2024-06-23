// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/TriggerVolume.h"
#include "Characters/HiCharacter.h"
#include "Component/HiTriggerComponent.h"
#include "HiTriggerVolume.generated.h"

class UHiTriggerComponent;

UCLASS(BlueprintType, Blueprintable)
class HIGAME_API AHiTriggerVolume : public ATriggerVolume
{
	GENERATED_UCLASS_BODY()

public:
	virtual void NotifyActorBeginOverlap(AActor* OtherActor) override;
	virtual void NotifyActorEndOverlap(AActor* OtherActor) override;

#if WITH_EDITOR
	virtual void CheckForErrors() override;
	//UFUNCTION(BlueprintCallable, CallInEditor, Category="Settings")
	void CreateBrushSubComponent();
#endif

	UFUNCTION(BlueprintCallable)
	void PostSpawnActor();

	UFUNCTION(BlueprintCallable)
	bool IsTargetActorValidToNotify(AActor* OtherActor) const;

protected:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Settings", Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<UClass> ValidParentClass = AHiCharacter::StaticClass();

	//UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Settings", Meta = (AllowPrivateAccess = "true"))
	//TSubclassOf<UHiTriggerComponent> InnerTriggerClass = UHiTriggerComponent::StaticClass();
};
