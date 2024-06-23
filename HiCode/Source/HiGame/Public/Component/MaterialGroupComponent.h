// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "MaterialGroupComponent.generated.h"

USTRUCT(Blueprintable)
struct FMaterialGroup
{
	GENERATED_BODY()
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<UMaterialInterface*> Materials;
};

UCLASS(ClassGroup=(Rendering), meta=(BlueprintSpawnableComponent))
class HIGAME_API UMaterialGroupComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UMaterialGroupComponent();
	
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetUseMaskedMaterials", Category=MaterialGroup)
	uint8 bUseMaskedMaterials : 1;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetDissolveAmount", Category=MaterialGroup, meta=(ClampMin="0.0", ClampMax="1.0"))
	float DissolveAmount;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetFresnel_Strength", Category=MaterialGroup)
	float Fresnel_Strength;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetFresnel_Power", Category=MaterialGroup)
	float Fresnel_Power;

	UPROPERTY(EditInstanceOnly, BlueprintSetter="SetEmissive_Strength", Category=MaterialGroup)
	float Emissive_Strength;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<FName> TargetComponentNames;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<FMaterialGroup> OriginalMaterials;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, NoClear, Category = MaterialGroup)
	TArray<FMaterialGroup> MaskedMaterials;
	
	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetUseMaskedMaterials(bool bInUseMaskedMaterials);

	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetDissolveAmount(float InDissolveAmount);

	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetFresnel_Strength(float InFresnel_Strength);

	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetFresnel_Power(float InFresnel_Power);

	UFUNCTION(BlueprintSetter, BlueprintCallable, Category=MaterialGroup)
	void SetEmissive_Strength(float InEmissive_Strength);

	UFUNCTION(Blueprintable, Category=MaterialGroup)
	void AddChild(UMaterialGroupComponent* Child);

	UFUNCTION(Blueprintable, Category=MaterialGroup)
	void RemoveChild(UMaterialGroupComponent* Child);

	UFUNCTION()
	void OnChildAttachment(USceneComponent* InSceneComponent, bool bIsAttached);
	
#if WITH_EDITOR
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif
protected:
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;

private:
	void ExtractComponentIfNeeded();
	
	void SwitchDissolveMaterials();

	void UpdateParameterValue(const FName& ParameterName, float Value);

	void UpdateAllParameterValues();

	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	uint8 bPreviousUseMaskedMaterials : 1;

	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	float PreviousDissolveAmount = 0.0f;
	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	float PreviousFresnel_Strength = 0.0f;
	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	float PreviousFresnel_Power = 0.0f;
	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	float PreviousEmissive_Strength = 0.0f;

	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	TArray<TWeakObjectPtr<UPrimitiveComponent>> TargetComponentReferences;

	UPROPERTY(VisibleInstanceOnly, Category=MaterialGroup)
	TArray<TWeakObjectPtr<UMaterialGroupComponent>> Children;
};
