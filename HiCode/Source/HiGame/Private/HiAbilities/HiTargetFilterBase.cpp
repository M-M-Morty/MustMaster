// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiTargetFilterBase.h"
#include "Characters/HiCharacter.h"
#include "HiAbilities/HiMountActor.h"

UHiTargetFilterBase::UHiTargetFilterBase()
{
	
}

bool UHiTargetFilterBase::FilterActor_Implementation(const AActor* ActorToBeFiltered)
{
	return true;
}
