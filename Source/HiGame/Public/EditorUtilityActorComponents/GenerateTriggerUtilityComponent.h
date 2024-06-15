// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GenerateTriggerUtilityComponent.generated.h"

/**
 * 
 */


UENUM(BlueprintType)
enum class ETriggerFollowType : uint8
{
	Nerver,  
	Translate,
	Rotation,
	Scale,
	Transform// follow create translate, rotation, scale
};



UCLASS(BlueprintType, Blueprintable, Meta = (BlueprintSpawnableComponent))
class HIGAME_API UGenerateTriggerUtilityComponent : public UActorComponent
{
	GENERATED_BODY()
	
public:
	UGenerateTriggerUtilityComponent(const FObjectInitializer& ObjectInitializer);
#if WITH_EDITOR
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;	
	
	virtual  void OnComponentDestroyed(bool bDestroyingHierarchy) override;

	virtual void TickComponent(float DeltaTime, enum ELevelTick TickType, FActorComponentTickFunction *ThisTickFunction) override;

	UFUNCTION(BlueprintCallable)
	void GenerateTrigger();
	UFUNCTION(BlueprintCallable)
	void DeleteTrigger();
	UFUNCTION(BlueprintCallable)
	void UpdateTriggerActorTransform(bool Force);
#endif
	virtual bool IsEditorOnly() const override { return true; }
#if WITH_EDITORONLY_DATA	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	TSubclassOf<class AHiTriggerBox> TriggerActorClass;
	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	TObjectPtr<AHiTriggerBox> TriggerActor;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool	bAutoGenerateTrigger{ false };
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	ETriggerFollowType TriggerFollowType = ETriggerFollowType::Transform;	
#endif
};
