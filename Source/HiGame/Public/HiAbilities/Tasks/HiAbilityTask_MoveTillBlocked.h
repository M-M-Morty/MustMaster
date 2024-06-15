// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Abilities/Tasks/AbilityTask.h"
#include "HiAbilityTask_MoveTillBlocked.generated.h"

USTRUCT(BlueprintType)
struct FMoveTillBlockedParams
{
	GENERATED_USTRUCT_BODY()

	FMoveTillBlockedParams()
		: InitSpeed(0)
		, InitAcc(0)
		, MoveDir(FVector())
		, AccCurve(nullptr)
	{
		
	}
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float InitSpeed;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	float InitAcc;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FVector MoveDir;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	UCurveFloat* AccCurve;
};

/**
 * 
 */
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FTaskDelegate);

UCLASS()
class HIGAME_API UHiAbilityTask_MoveTillBlocked : public UAbilityTask
{
	GENERATED_BODY()

	/**
	 * @brief 
	 * @param OwningAbility 
	 * @param TaskInstanceName 
	 * @param Montage 
	 * @param Params FMoveTillBlockedParams
	 * @return 
	 */
	UFUNCTION(BlueprintCallable, Category="Ability|Tasks", meta = (DisplayName="MoveTillBlocked",
	HidePin = "OwningAbility", DefaultToSelf = "OwningAbility", BlueprintInternalUseOnly = "TRUE"))
	static UHiAbilityTask_MoveTillBlocked* CreateMoveTillBlockedTask(UGameplayAbility* OwningAbility, FName TaskInstanceName, UAnimMontage* Montage, const FMoveTillBlockedParams& Params);

	UPROPERTY(BlueprintAssignable)
	FTaskDelegate OnStarted;
	
	UPROPERTY(BlueprintAssignable)
	FTaskDelegate OnCompleted;
	
	virtual void Activate() override;
	virtual void TickTask(float DeltaTime) override;
	virtual void OnDestroy(bool bInOwnerFinished) override;

public:
	ACharacter* GetOwnerCharacter() const;
	USkeletalMeshComponent* GetOwnerMesh() const;
	
private:
	UAnimMontage* MontageToPlay;

	float InitSpeed;
	float InitAcc;
	FVector MoveDir;
	UCurveFloat* AccCurve;

	FVector Velocity;
	float ElapsedTime;
};
