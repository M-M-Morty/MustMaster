// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAIController.h"
#include "Attributies/HiAttributeSet.h"
#include "Component/HiAbilitySystemComponent.h"

AHiAIController::AHiAIController()
{
}

void AHiAIController::StopBehaviorTree()
{
	UBehaviorTreeComponent* BTComp = Cast<UBehaviorTreeComponent>(BrainComponent);
	if (BTComp == NULL)
	{
		UE_VLOG(this, LogBehaviorTree, Log, TEXT("StopBehaviorTree: spawning BehaviorTreeComponent.."));

		BTComp = NewObject<UBehaviorTreeComponent>(this, TEXT("BTComponent"));
		BTComp->RegisterComponent();
	}

	// make sure BrainComponent points at the newly created BT component
	BrainComponent = BTComp;

	check(BTComp != NULL);
	BTComp->StopTree(EBTStopMode::Safe);
}

void AHiAIController::PauseBehaviorTree(const FString& Reason)
{
	UBehaviorTreeComponent* BTComp = Cast<UBehaviorTreeComponent>(BrainComponent);
	if (BTComp == NULL)
	{
		UE_VLOG(this, LogBehaviorTree, Log, TEXT("PauseBehaviorTree: spawning BehaviorTreeComponent.."));

		BTComp = NewObject<UBehaviorTreeComponent>(this, TEXT("BTComponent"));
		BTComp->RegisterComponent();
	}

	BTComp->PauseLogic(Reason);
}

void AHiAIController::ResumeBehaviorTree(const FString& Reason)
{
	UBehaviorTreeComponent* BTComp = Cast<UBehaviorTreeComponent>(BrainComponent);
	if (BTComp == NULL)
	{
		UE_VLOG(this, LogBehaviorTree, Log, TEXT("ResumeBehaviorTree: spawning BehaviorTreeComponent.."));

		BTComp = NewObject<UBehaviorTreeComponent>(this, TEXT("BTComponent"));
		BTComp->RegisterComponent();
	}

	BTComp->ResumeLogic(Reason);
}

FString AHiAIController::GetAIDebugInfo() const
{
	UBehaviorTreeComponent* BTComp = Cast<UBehaviorTreeComponent>(BrainComponent);
	if (!IsValid(BTComp))
	{
		return TEXT("BrainComponent InValid");
	}
	
	FString DebugInfo;
	FString CurrentAITask = BTComp->DescribeActiveTasks();
	FString CurrentAIState = BTComp->IsRunning() ? TEXT("Running") : BTComp->IsPaused() ? TEXT("Paused") : TEXT("Inactive");
	FString CurrentAIAssets = BTComp->DescribeActiveTrees();
	
	DebugInfo += FString::Printf(TEXT("Behavior:[%s], Tree:[%s] Active task:[%s]\n"), *CurrentAIState, *CurrentAIAssets, *CurrentAITask);
	return DebugInfo;
}

FString AHiAIController::GetBTDebugInfo() const
{
	if (!IsValid(BrainComponent))
	{
		return TEXT("BrainComponent InValid");
	}
	return BrainComponent->GetDebugInfoString();
}
