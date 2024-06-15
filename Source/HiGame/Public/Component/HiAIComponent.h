// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiPawnComponent.h"
#include "GameplayAbilitySpec.h"
#include "BehaviorTree/BehaviorTree.h"
#include "HiAbilities/HiMountActor.h"
#include "HiAIComponent.generated.h"

/**
 * 
*/
USTRUCT(BlueprintType)
struct HIGAME_API FHiBTSwitchInfo
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AI)
	int32 Priority;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AI)
	UBehaviorTree* BehaviorTree;
};


/**
 * Struct defining a list of mount actor container
 */
USTRUCT(BlueprintType)
struct HIGAME_API FHiMountActorCfg
{
	GENERATED_BODY()

public:
	FHiMountActorCfg() {}

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AI)
	TSubclassOf<AHiMountActor> MountClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AI)
	FName AttachSocketName;
};

class UHiAbilitySystemComponent;

UCLASS()
class HIGAME_API UHiAIComponent : public UHiPawnComponent
{
	GENERATED_BODY()
	
public:
	UHiAIComponent(const FObjectInitializer& ObjectInitializer);

	//Returns the skill component  if one exists on the specified actor.
	UFUNCTION(BlueprintCallable, Category = "AI")
	static UHiAIComponent* FindAIComponent(const AActor* Actor) { return (Actor ? Actor->FindComponentByClass<UHiAIComponent>() : nullptr); }

	UFUNCTION(BlueprintCallable, Category = "AI")
	void CreateMountActor(TSubclassOf<AHiMountActor> MountClass, FName AttachSocketName);

	UFUNCTION(BlueprintCallable, Category = "AI")
	void AddMountActor(AActor* Actor);
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	void DestroyAllMountActor();

	UFUNCTION(BlueprintImplementableEvent, Category = "AI")
	void ClientOnRep_ActivateAbilities();
	
	UFUNCTION(BlueprintImplementableEvent, Category="AI")
	void BP_OnMountActorDestroyed(AHiMountActor* MountActor);
	
	virtual void OnMountActorDestroyed(AHiMountActor* MountActor);
	
protected:
	virtual void OnRegister() override;

public:
	// UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = AI)
	TArray<AHiMountActor*> MountActors;
	
	// UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = AI)
	UBehaviorTree* InitBT;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = AI)
	TMap<FGameplayTag, FHiBTSwitchInfo> BTSwitch;
};
