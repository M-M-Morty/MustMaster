// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "MaterialGroupComponent.generated.h"


UCLASS(ClassGroup=(Rendering), meta=(BlueprintSpawnableComponent))
class HIGAME_API UMaterialGroupComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UMaterialGroupComponent();
	
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = MaterialGroup)
	FName TargetComponentName;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetUseMaskedMaterials", Category=MaterialGroup)
	uint8 bUseMaskedMaterials : 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<UMaterialInterface*> OriginalMaterials;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<UMaterialInterface*> MaskedMaterials;
	
	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetUseMaskedMaterials(bool bInUseMaskedMaterials);
#if WITH_EDITOR
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif
protected:
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
	void UpdateTargetComponentMaterials();

	UPROPERTY()
	uint8 bPreviousUseMaskedMaterials : 1;
};
