#include "HiAbilities/HiTargetTypes.h"

bool FHiGameplayAbilityTargetData_SingleHit::NetSerialize(FArchive& Ar, UPackageMap* Map, bool& bOutSuccess)
{
	HitResult.NetSerialize(Ar, Map, bOutSuccess);
	Ar << KnockInfo;

	return true;
}

bool FHiGameplayAbilityTargetData_ActorArray::NetSerialize(FArchive& Ar, UPackageMap* Map, bool& bOutSuccess)
{
	SourceLocation.NetSerialize(Ar, Map, bOutSuccess);
	SafeNetSerializeTArray_Default<1024>(Ar, TargetActorArray);
	Ar << KnockInfo;

	bOutSuccess &= true;
	return true;
}

bool FHiGameplayAbilityTargetData_HitArray::NetSerialize(FArchive& Ar, UPackageMap* Map, bool& bOutSuccess)
{
	SourceLocation.NetSerialize(Ar, Map, bOutSuccess);
	int32 ArrayNum = SafeNetSerializeTArray_HeaderOnly<1024>(Ar, Hits, bOutSuccess);
	for(int32 Ind = 0; Ind < ArrayNum; Ind ++)
	{
		Hits[Ind].NetSerialize(Ar, Map, bOutSuccess);
	}
	Ar << KnockInfo;

	bOutSuccess &= true;
	return true;
}
