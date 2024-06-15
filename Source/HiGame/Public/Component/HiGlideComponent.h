// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Component/HiPawnComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include "HiGlideComponent.generated.h"

class AHiCharacter;

UCLASS(ClassGroup=(Custom), meta=(BlueprintSpawnableComponent))
class HIGAME_API UHiGlideComponent : public UHiPawnComponent
{
	GENERATED_BODY()

public:
	// Sets default values for this component's properties
	UHiGlideComponent(const FObjectInitializer& ObjectInitializer);
	
	virtual void InitializeComponent() override;

protected:
	// Called when the game starts
	virtual void BeginPlay() override;
	
	TObjectPtr<UHiCharacterMovementComponent> MyCharacterMovementComponent;

	bool bGlide = false;

	float OldMaxCustomMovementSpeed = 0.0f;
	
	FRotator TargetRotation;

	UPROPERTY(Transient, DuplicateTransient)
	TObjectPtr<AHiCharacter> CharacterOwner;

public:

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float GlideFallSpeed = 300.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float MaxGlideSpeed = 300.0f;
	
	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float ActorInterpSpeed = 30.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	EHiGlideState GlideState = EHiGlideState::None;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float AccelerationDirection = 0.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float MinTurnYaw = 10.0f;
	
	// Called every frame
	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
	                           FActorComponentTickFunction* ThisTickFunction) override;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void PhysGlide(float DeltaTime);

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void StartGlide();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void StopGlide();
	
	UFUNCTION(BlueprintNativeEvent, Category="Hi|Locomotion System")
	void OnLandedCallback(const FHitResult& Hit);
	
	UFUNCTION(BlueprintNativeEvent, Category="Hi|Locomotion System")
	void ProcessGlideRotation(float DeltaTime);
};
