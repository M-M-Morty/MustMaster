// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Abilities/GameplayAbilityTargetTypes.h"
#include "Engine/NetSerialization.h"
#include "HiTargetTypes.generated.h"

/** Target data with a single hit result, data is packed into the hit result */
USTRUCT(BlueprintType)
struct HIGAME_API FHiGameplayAbilityTargetData_SingleHit : public FGameplayAbilityTargetData
{
	GENERATED_USTRUCT_BODY()

	FHiGameplayAbilityTargetData_SingleHit()
	{ }
	
	FHiGameplayAbilityTargetData_SingleHit(FHitResult InHitResult, UObject* Info)
		: HitResult(MoveTemp(InHitResult)), KnockInfo(Info)
	{ }

	// -------------------------------------

	virtual TArray<TWeakObjectPtr<AActor> >	GetActors() const override
	{
		TArray<TWeakObjectPtr<AActor> >	Actors;
		if (HitResult.HasValidHitObjectHandle())
		{
			Actors.Push(HitResult.HitObjectHandle.FetchActor());
		}
		return Actors;
	}

	// SetActors() will not work here because the actor "array" is drawn from the hit result data, and changing that doesn't make sense.

	// -------------------------------------

	virtual bool HasHitResult() const override
	{
		return true;
	}

	virtual const FHitResult* GetHitResult() const override
	{
		return &HitResult;
	}

	virtual bool HasOrigin() const override
	{
		return true;
	}

	virtual FTransform GetOrigin() const override
	{
		return FTransform((HitResult.TraceEnd - HitResult.TraceStart).Rotation(), HitResult.TraceStart);
	}

	virtual bool HasEndPoint() const override
	{
		return true;
	}

	virtual FVector GetEndPoint() const override
	{
		return HitResult.Location;
	}

	virtual void ReplaceHitWith(AActor* NewHitActor, const FHitResult* NewHitResult)
	{
		bHitReplaced = true;

		HitResult = FHitResult();
		if (NewHitResult != nullptr)
		{
			HitResult = *NewHitResult;
		}
	}

	// -------------------------------------

	/** Hit result that stores data */
	UPROPERTY()
	FHitResult	HitResult;

	UPROPERTY()
	bool bHitReplaced = false;
	
	virtual UObject* GetKnockInfo() const
	{
		return KnockInfo;
	}

	virtual void SetKnockInfo(UObject* Info)
	{
		this->KnockInfo = Info;
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess);

	virtual UScriptStruct* GetScriptStruct() const override
	{
		return FHiGameplayAbilityTargetData_SingleHit::StaticStruct();
	}

	UPROPERTY()
	UObject* KnockInfo = nullptr;
};

template<>
struct TStructOpsTypeTraits<FHiGameplayAbilityTargetData_SingleHit> : public TStructOpsTypeTraitsBase2<FHiGameplayAbilityTargetData_SingleHit>
{
	enum
	{
		WithNetSerializer = true	// For now this is REQUIRED for FGameplayAbilityTargetDataHandle net serialization to work
	};
};

/** TargetData for AOE */
USTRUCT(BlueprintType)
struct HIGAME_API FHiGameplayAbilityTargetData_ActorArray : public FGameplayAbilityTargetData
{
	GENERATED_USTRUCT_BODY()

	/** We could be selecting this group of actors from any type of location, so use a generic location type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	FGameplayAbilityTargetingLocationInfo SourceLocation;

	/** Rather than targeting a single point, this type of targeting selects multiple actors. */
	UPROPERTY(EditAnywhere, Category = Targeting)
	TArray<TWeakObjectPtr<AActor> > TargetActorArray;

	virtual TArray<TWeakObjectPtr<AActor> >	GetActors() const override
	{
		return TargetActorArray;
	}

	virtual bool SetActors(TArray<TWeakObjectPtr<AActor>> NewActorArray) override
	{
		TargetActorArray = NewActorArray;
		return true;
	}

	// -------------------------------------

	virtual bool HasOrigin() const override
	{
		return true;
	}

	virtual FTransform GetOrigin() const override
	{
		FTransform ReturnTransform = SourceLocation.GetTargetingTransform();

		//Aim at first valid target, if we have one. Duplicating GetEndPoint() code here so we don't iterate through the target array twice.
		for (int32 i = 0; i < TargetActorArray.Num(); ++i)
		{
			if (TargetActorArray[i].IsValid())
			{
				FVector Direction = (TargetActorArray[i].Get()->GetActorLocation() - ReturnTransform.GetLocation()).GetSafeNormal();
				if (Direction.IsNormalized())
				{
					ReturnTransform.SetRotation(Direction.Rotation().Quaternion());
					break;
				}
			}
		}
		return ReturnTransform;
	}

	// -------------------------------------

	virtual bool HasEndPoint() const override
	{
		//We have an endpoint if we have at least one valid actor in our target array
		for (int32 i = 0; i < TargetActorArray.Num(); ++i)
		{
			if (TargetActorArray[i].IsValid())
			{
				return true;
			}
		}
		return false;
	}

	virtual FVector GetEndPoint() const override
	{
		for (int32 i = 0; i < TargetActorArray.Num(); ++i)
		{
			if (TargetActorArray[i].IsValid())
			{
				return TargetActorArray[i].Get()->GetActorLocation();
			}
		}
		return FVector::ZeroVector;
	}

	// -------------------------------------

	virtual UScriptStruct* GetScriptStruct() const override
	{
		return FHiGameplayAbilityTargetData_ActorArray::StaticStruct();
	}

	virtual FString ToString() const override
	{
		return TEXT("FHiGameplayAbilityTargetData_ActorArray");
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess);

	virtual UObject* GetKnockInfo() const
	{
		return KnockInfo;
	}

	virtual void SetKnockInfo(UObject* Info)
	{
		this->KnockInfo = Info;
	}
	
	UPROPERTY()
	UObject* KnockInfo = nullptr;
};

template<>
struct TStructOpsTypeTraits<FHiGameplayAbilityTargetData_ActorArray> : public TStructOpsTypeTraitsBase2<FHiGameplayAbilityTargetData_ActorArray>
{
	enum
	{
		WithNetSerializer = true	// For now this is REQUIRED for FGameplayAbilityTargetDataHandle net serialization to work
	};
};

/** TargetData for AOE with HitResults */
USTRUCT(BlueprintType)
struct HIGAME_API FHiGameplayAbilityTargetData_HitArray : public FGameplayAbilityTargetData
{
	GENERATED_USTRUCT_BODY()

	/** We could be selecting this group of actors from any type of location, so use a generic location type */
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
	FGameplayAbilityTargetingLocationInfo SourceLocation;

	/** Rather than targeting a single point, this type of targeting selects multiple actors. */
	UPROPERTY(EditAnywhere, Category = Targeting)
	TArray<FHitResult> Hits;

	// -------------------------------------
	
	virtual TArray<TWeakObjectPtr<AActor> >	GetActors() const override
	{
		TArray<TWeakObjectPtr<AActor> >	Actors;
		for (int Ind = 0; Ind < Hits.Num(); Ind++)
		{
			FHitResult Hit = Hits[Ind];
			if (Hit.HasValidHitObjectHandle())
			{
				Actors.Push(Hit.HitObjectHandle.FetchActor());
			}
		}

		return Actors;
	}

	virtual bool HasOrigin() const override
	{
		return true;
	}

	virtual FTransform GetOrigin() const override
	{
		FTransform ReturnTransform = SourceLocation.GetTargetingTransform();

		//Aim at first valid target, if we have one. Duplicating GetEndPoint() code here so we don't iterate through the target array twice.
		for (int32 i = 0; i < Hits.Num(); ++i)
		{
				FVector Direction = (Hits[i].Location - ReturnTransform.GetLocation()).GetSafeNormal();
				if (Direction.IsNormalized())
				{
					ReturnTransform.SetRotation(Direction.Rotation().Quaternion());
					break;
				}
		}
		return ReturnTransform;
	}

	// -------------------------------------

	virtual bool HasEndPoint() const override
	{
		return Hits.Num() > 0;
	}

	virtual FVector GetEndPoint() const override
	{
		for (int32 i = 0; i < Hits.Num(); ++i)
		{
			return Hits[i].Location;
		}
		return FVector::ZeroVector;
	}

	// -------------------------------------

	virtual UScriptStruct* GetScriptStruct() const override
	{
		return FHiGameplayAbilityTargetData_HitArray::StaticStruct();
	}

	virtual FString ToString() const override
	{
		return TEXT("FHiGameplayAbilityTargetData_HitArray");
	}

	bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess);

	virtual UObject* GetKnockInfo() const
	{
		return KnockInfo;
	}

	virtual void SetKnockInfo(UObject* Info)
	{
		this->KnockInfo = Info;
	}
	
	UPROPERTY()
	UObject* KnockInfo = nullptr;
};

template<>
struct TStructOpsTypeTraits<FHiGameplayAbilityTargetData_HitArray> : public TStructOpsTypeTraitsBase2<FHiGameplayAbilityTargetData_HitArray>
{
	enum
	{
		WithNetSerializer = true	// For now this is REQUIRED for FGameplayAbilityTargetDataHandle net serialization to work
	};
};