// Fill out your copyright notice in the Description page of Project Settings.


#include "HiAbilities/HiTargetDataFilter.h"
#include "Characters/HiCharacter.h"
#include "HiAbilities/HiMountActor.h"

FHiTargetDataFilter::FHiTargetDataFilter()
{
	
}

FHiTargetDataFilter::FHiTargetDataFilter(ECalcFilterType FilterType)
{
	this->FilterType = FilterType;
}

bool FHiTargetDataFilter::FilterPassesForActor(const AActor* ActorToBeFiltered) const
{
	switch (FilterType.GetValue())
	{
	case AllActor:
		return true;
		
	case Self:
		return ActorToBeFiltered == SelfActor;

	case NoSelf:
		return ActorToBeFiltered != SelfActor;

	// case AllEnemy:
	// 	return IsEnemy(ActorToBeFiltered);

	default:
		return true;
	}
}

// bool FHiTargetDataFilter::IsEnemy(const AActor* ActorToBeFiltered) const
// {
// 	auto const SelfIdentity = GetActorIdentity(SelfActor);
// 	if (SelfIdentity == ECharIdentity::None)
// 		return false;
//     
// 	auto const TargetIdentity = GetActorIdentity(ActorToBeFiltered);
// 	if (TargetIdentity == ECharIdentity::None)
// 		return false;
//
// 	if (SelfIdentity == ECharIdentity::NPC || TargetIdentity == ECharIdentity::NPC)
// 		return false;
// 	
// 	return SelfIdentity != TargetIdentity;
// }
//
// ECharIdentity FHiTargetDataFilter::GetActorIdentity(const AActor* Actor) const
// {
// 	const auto HiCharacter = Cast<AHiCharacter>(Actor);
// 	if (IsValid(HiCharacter))
// 	{
// 		return HiCharacter->Identity;
// 	}
// 	
// 	
// 	const auto HiMountActor = Cast<AHiMountActor>(Actor);
// 	if (IsValid(HiMountActor))
// 	{
// 		return HiMountActor->Identity;
// 	}
// 	
// 	return ECharIdentity::None;
// }

FHiTargetDataFilter::~FHiTargetDataFilter()
{
}
