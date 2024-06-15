// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemInterface.h"
#include "AIController.h"
#include "Runtime/AIModule/Classes/BehaviorTree/BehaviorTree.h"
#include "HiAIController.generated.h"


class UHiAttributeSet;
/**
 * 
 */
UCLASS()
class HIGAME_API AHiAIController : public AAIController
{
	GENERATED_BODY()
	
public:
	AHiAIController();
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	void StopBehaviorTree();
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	void PauseBehaviorTree(const FString& Reason);
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	void ResumeBehaviorTree(const FString& Reason);
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	FString GetAIDebugInfo() const;
	
	UFUNCTION(BlueprintCallable, Category = "AI")
	FString GetBTDebugInfo() const;
};
