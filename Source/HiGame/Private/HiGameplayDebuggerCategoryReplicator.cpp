// Fill out your copyright notice in the Description page of Project Settings.

#include "HiGameplayDebuggerCategoryReplicator.h"


AHiGameplayDebuggerCategoryReplicator::AHiGameplayDebuggerCategoryReplicator()
{
	bAlwaysRelevant = true;
}

void AHiGameplayDebuggerCategoryReplicator::SetReplicatorOwner(APlayerController* InOwnerPC)
{
	Super::SetReplicatorOwner(InOwnerPC);
}
