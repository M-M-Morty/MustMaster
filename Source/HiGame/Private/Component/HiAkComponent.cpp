// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/HiAkComponent.h"
#include "GameFramework/Character.h"
#include "Kismet/GameplayStatics.h"
#include "AkGameplayStatics.h"
#include "Kismet/KismetMathLibrary.h"

UHiAkComponent::UHiAkComponent(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	//PrimaryComponentTick.bStartWithTickEnabled = true;
	//PrimaryComponentTick.bCanEverTick = true;
}

void UHiAkComponent::UpdateDopllerEffect_Implementation(float DeltaTime)
{
	float DopplerSpeedRatio = CalculateDopplerSpeedRatio(DeltaTime);
	//UE_LOG(LogTemp, Display, TEXT("UpdateDopllerEffect_Implementation %f"), DopplerSpeedRatio);
	UAkGameplayStatics::SetRTPCValue(nullptr, DopplerSpeedRatio, InterpolationTimeMs, GetOwner(), DopplerRTPCName );
}

float UHiAkComponent::CalculateDopplerSpeedRatio(float DeltaTime)
{
	float DopplerSpeedRatio = 0.0f;
	ACharacter* PlayerCharacter = UGameplayStatics::GetPlayerCharacter(this, 0);
	if (PlayerCharacter)
	{
		//get velocity of source manlually
		const FVector SourceLocation = GetOwner()->GetActorLocation();
		FVector DeltaSourceLocation = SourceLastFramePosition - SourceLocation;
		SourceLastFramePosition = SourceLocation;		

		const FVector ListnerLocation = PlayerCharacter->GetActorLocation();
		FVector DeltaListenerLocation = ListenerLastFramePosition - ListnerLocation;
		ListenerLastFramePosition = ListnerLocation;		
		
		FVector distanceVector = SourceLocation - ListnerLocation;

		FVector ListenderProjectVector =  UKismetMathLibrary::ProjectVectorOnToVector(DeltaListenerLocation, distanceVector);
		float V0 = (distanceVector.Length() - (ListenderProjectVector + distanceVector).Length())/DeltaTime;
		
		FVector SourceProjectVector =  UKismetMathLibrary::ProjectVectorOnToVector(DeltaSourceLocation, distanceVector);
		
		float Vs = ((SourceProjectVector + distanceVector).Length() - distanceVector.Length())/DeltaTime;
		DopplerSpeedRatio = (V0 + SpeedOfSound)/(SpeedOfSound - Vs);
	}
	return DopplerSpeedRatio;
}
