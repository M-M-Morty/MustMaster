// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimInstanceProxy.h"
#include "HiAnimInstanceProxy.generated.h"


/**
 * 
 */

USTRUCT(BlueprintType)
struct FHiAnimInstanceProxy : public FAnimInstanceProxy
{
	GENERATED_BODY()
public:
	FHiAnimInstanceProxy();
	FHiAnimInstanceProxy(UAnimInstance* Instance);
	virtual void InitSyncAnimSequence(UAnimSequenceBase* Anim) const override;
	virtual void InitializeAnimNodeAnimSequence(UAnimInstance* Instance) override;
	void MarkNeedInitializeSyncAnimSequence() { isSyncAnimNodeInitialized = false;}
	bool IsNeedInitializeSyncAnimSequence() const { return !isSyncAnimNodeInitialized;}
private:
	bool isSyncAnimNodeInitialized = false;
};
