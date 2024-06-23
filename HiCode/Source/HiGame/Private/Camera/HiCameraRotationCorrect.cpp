// Fill out your copyright notice in the Description page of Project Settings.


#include "Camera/HiCameraRotationCorrect.h"

#include "Characters/HiCharacter.h"
#include "Characters/HiPlayerCameraManager.h"
#include "Kismet/KismetMathLibrary.h"

DEFINE_LOG_CATEGORY_STATIC(LogHiCameraRotationCorrect, Log, All);

static float GetShortestTargetDegree(float CurrentAngle, float TargetAngle)
{
	if (TargetAngle - CurrentAngle > 180.0f)
	{
		return TargetAngle - 360.0f;
	}
	else if (TargetAngle - CurrentAngle < -180.0f)
	{
		return TargetAngle + 360.0f;
	}
	return TargetAngle;
}

UHiCameraRotationCorrect::UHiCameraRotationCorrect(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	RotationCorrectMode = EHiCameraRotationCorrectMode::Override;
}

FRotator UHiCameraRotationCorrect::GetTargetRotator(const FRotator &ActorRotator, const FRotator &CurrentRotator) const
{
	FRotator TargetRotator(UseTargetPitch ?  ActorRotator.Pitch + TargetPitch : CurrentRotator.Pitch,
							UseTargetYaw ?  ActorRotator.Yaw + TargetYaw : CurrentRotator.Yaw,
							UseTargetRoll ?  ActorRotator.Roll + TargetRoll : CurrentRotator.Roll);

	return TargetRotator;
}

bool UHiCameraRotationCorrect::ProcessViewRotation(class AActor* ViewTarget, float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot)
{
	if (Alpha < 0.f)
		return false;
	
	if (RotationCorrectMode != EHiCameraRotationCorrectMode::Additive)
		return false;

	AHiCharacter *Character = Cast<AHiCharacter>(ViewTarget);
	if (!Character)
		return false;

	const FRotator &ActorRotator = Character->GetActorRotation();

	const FRotator &TargetRotator = GetTargetRotator(ActorRotator, OutViewRotation);

	if (!TargetRotator.Equals(OutViewRotation))
	{
		if (UseTargetYaw)
		{
			float target = GetShortestTargetDegree(OutViewRotation.Yaw, TargetRotator.Yaw);
			OutViewRotation.Yaw = UKismetMathLibrary::Ease(OutViewRotation.Yaw, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		if (UseTargetPitch)
		{
			float target = GetShortestTargetDegree(OutViewRotation.Pitch, TargetRotator.Pitch);
			OutViewRotation.Pitch = UKismetMathLibrary::Ease(OutViewRotation.Pitch, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		if (UseTargetRoll)
		{
			float target = GetShortestTargetDegree(OutViewRotation.Roll, TargetRotator.Roll);
			OutViewRotation.Roll = UKismetMathLibrary::Ease(OutViewRotation.Roll, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		
		//UE_LOG(LogHiCameraRotationCorrect, Error, TEXT("ModifyCamera ViewRotation: %s, ActorRotator: %s, NewViewRotation: %s"), *ViewRotation.ToString(), *ActorRotator.ToString(), *NewViewRotation.ToString());
	}

	// if (!FMath::IsNearlyEqual(OutViewRotation.Yaw, ActorRotator.Yaw + TargetYaw))
	// {
	// 	float OldYaw = OutViewRotation.Yaw;
	// 	OutViewRotation.Yaw = UKismetMathLibrary::Ease(OutViewRotation.Yaw, ActorRotator.Yaw + TargetYaw, 0.5, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
	// 	UE_LOG(LogHiCameraRotationCorrect, Error, TEXT("ProcessViewRotation OldYaw: %f, ActorRotator: %f, OutViewRotation: %f"), OldYaw, ActorRotator.Yaw, OutViewRotation.Yaw);
	// }
	
	return false;
}

void UHiCameraRotationCorrect::ModifyCamera(float DeltaTime, FVector ViewLocation, FRotator ViewRotation, float FOV, FVector& NewViewLocation, FRotator& NewViewRotation, float& NewFOV)
{
	if (Alpha < 0.f)
		return;
	
	if (RotationCorrectMode != EHiCameraRotationCorrectMode::Override)
		return;

	AHiPlayerCameraManager *CameraManager = Cast<AHiPlayerCameraManager>(CameraOwner);

	if (!CameraManager)
		return;

	AHiCharacter *Character = Cast<AHiCharacter>(CameraManager->ControlledCharacter);

	if (!Character)
		return;

	const FRotator &ActorRotator = Character->GetActorRotation();

	const FRotator &TargetRotator = GetTargetRotator(ActorRotator, ViewRotation);
	
	if (!TargetRotator.Equals(ViewRotation))
	{
		NewViewRotation = ViewRotation;
		if (UseTargetYaw)
		{
			float target = GetShortestTargetDegree(ViewRotation.Yaw, TargetRotator.Yaw);
			NewViewRotation.Yaw = UKismetMathLibrary::Ease(ViewRotation.Yaw, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		if (UseTargetPitch)
		{
			float target = GetShortestTargetDegree(ViewRotation.Pitch, TargetRotator.Pitch);
			NewViewRotation.Pitch = UKismetMathLibrary::Ease(ViewRotation.Pitch, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		if (UseTargetRoll)
		{
			float target = GetShortestTargetDegree(ViewRotation.Roll, TargetRotator.Roll);
			NewViewRotation.Roll = UKismetMathLibrary::Ease(ViewRotation.Roll, target, 0.5 * Alpha, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		}
		
		//NewViewRotation = UKismetMathLibrary::REase(ViewRotation, TargetRotator, 0.5, true, EEasingFunc::EaseOut, DeltaTime / SmoothSpeed);
		CameraManager->GetOwningPlayerController()->SetControlRotation(NewViewRotation);
		//UE_LOG(LogHiCameraRotationCorrect, Error, TEXT("ModifyCamera ViewRotation: %s, ActorRotator: %s, NewViewRotation: %s"), *ViewRotation.ToString(), *ActorRotator.ToString(), *NewViewRotation.ToString());
	}
}

void UHiCameraRotationCorrect::SetTargetYaw(float target_yaw)
{
	if (target_yaw >= -180.0f && target_yaw <= 180.0f)
	{
		UseTargetYaw = true;
		TargetYaw = target_yaw;
	}
	else
	{
		UseTargetYaw = false;
		TargetYaw = 0.0f;
	}
}

void UHiCameraRotationCorrect::SetTargetPitch(float target_pitch)
{
 	if (target_pitch >= -180.0f && target_pitch <= 180.0f)
	{
		UseTargetPitch = true;
		TargetPitch = target_pitch;
	}
	else
	{
		UseTargetPitch = false;
		TargetPitch = 0.0f;
	}
}

void UHiCameraRotationCorrect::SetTargetRoll(float target_roll)
{
	if (target_roll >= -180.0f && target_roll <= 180.0f)
	{
		UseTargetRoll = true;
		TargetRoll = target_roll;
	}
	else
	{
		UseTargetRoll = false;
		TargetRoll = 0.0f;
	}
}
