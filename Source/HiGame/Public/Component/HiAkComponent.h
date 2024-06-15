// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AkComponent.h"
#include "HiAkComponent.generated.h"

/**
 * 
 */
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class HIGAME_API UHiAkComponent : public UAkComponent
{
	GENERATED_BODY()
public:	
	// Sets default values for this component's properties
	UHiAkComponent(const FObjectInitializer& ObjectInitializer);

	UFUNCTION(BlueprintImplementableEvent, BlueprintCallable, BlueprintCosmetic, Category = "Audiokinetic|AkGameObject", meta = (AdvancedDisplay = "1", AutoCreateRefTerm = "PostEventCallback,ExternalSources"))
	int32 PostAkEventDoppler(
		class UAkAudioEvent * AkEvent,	
		UPARAM(meta = (Bitmask, BitmaskEnum = "/Script/AkAudio.EAkCallbackType")) int32 CallbackMask,
		const FOnAkPostEventCallback& PostEventCallback,
		const TArray<FAkExternalSourceInfo>& ExternalSources,
		const FString& in_EventName		
	);	
	
	UFUNCTION(BlueprintNativeEvent, Category = "AkComponent|Doppler Effect")
	void UpdateDopllerEffect(float DeltaTime);
	UFUNCTION(BlueprintCallable, Category = "AkComponent|Doppler Effect")
	float CalculateDopplerSpeedRatio(float DeltaTime);

	
protected:
	UPROPERTY()
	FVector SourceLastFramePosition = FVector::ZeroVector;
	UPROPERTY()
	FVector ListenerLastFramePosition = FVector::ZeroVector;
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "AkComponent|Doppler Effect")
	bool bForceEnableDoppler = false;
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "AkComponent|Doppler Effect")
	float SpeedOfSound = 34000.0f;
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "AkComponent|Doppler Effect")
	FName DopplerRTPCName = TEXT("Speed");
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "AkComponent|Doppler Effect")
	float InterpolationTimeMs = 0.0f;
};
