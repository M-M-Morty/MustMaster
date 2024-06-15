// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameplayEffectTypes.h"
#include "HiGameplayEffectContext.generated.h"

USTRUCT()
struct FHiGameplayEffectContext: public FGameplayEffectContext {
	GENERATED_BODY()

	/** Get custom user data from context */
	virtual UObject* GetUserData() const
	{
		return UserData.Get();
	}

	/** Set custom user data into context */
	void SetUserData(UObject* Data)
	{
		UserData = Data;
	}
	
protected:
	UPROPERTY()
	TWeakObjectPtr<UObject> UserData;
};
