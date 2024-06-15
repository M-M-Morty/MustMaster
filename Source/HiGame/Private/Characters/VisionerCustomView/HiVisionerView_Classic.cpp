// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/VisionerCustomView/HiVisionerView_Classic.h"
#include "Characters/HiPlayerCameraManager.h"
#include "Characters/HiCharacter.h"
#include "Component/HiLocomotionComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "VisionerInstance.h"


namespace ClassicViewParameters
{
	const FName NAME_CameraBehavior(TEXT("CameraBehavior"));
	const FName NAME_CameraOffset_X(TEXT("CameraOffset_X"));
	const FName NAME_CameraOffset_Y(TEXT("CameraOffset_Y"));
	const FName NAME_CameraOffset_Z(TEXT("CameraOffset_Z"));
	const FName NAME_Override_Debug(TEXT("Override_Debug"));
	const FName NAME_PivotLagSpeed_X(TEXT("PivotLagSpeed_X"));
	const FName NAME_PivotLagSpeed_Y(TEXT("PivotLagSpeed_Y"));
	const FName NAME_PivotLagSpeed_Z(TEXT("PivotLagSpeed_Z"));
	const FName NAME_PivotOffset_X(TEXT("PivotOffset_X"));
	const FName NAME_PivotOffset_Y(TEXT("PivotOffset_Y"));
	const FName NAME_PivotOffset_Z(TEXT("PivotOffset_Z"));
	const FName NAME_Fov(TEXT("Fov"));
	const FName NAME_FovLagSpeed(TEXT("FovLagSpeed"));
}


UHiVisionerView_Classic::UHiVisionerView_Classic(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UHiVisionerView_Classic::EvaluateView_Implementation(FVisionerViewContext& Output)
{
	AHiCharacter* ControlledCharacter = Cast<AHiCharacter>(Output.ViewTarget);
	if (!ControlledCharacter)
	{
		return;
	}

	// Step 1: Get Camera Parameters from CharacterBP via the Camera Interface
	const FTransform& PivotTarget = ControlledCharacter->GetThirdPersonPivotTarget();

	// Step 2: FOV
	float TargetFov = GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_Fov);
	SmoothedFov = FMath::FInterpTo(SmoothedFov, TargetFov, Output.DeltaTime
		, GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_FovLagSpeed));
	Output.SetViewFOV(SmoothedFov);

	// Step 3: Calculate Target Camera Rotation. Use the Control Rotation and interpolate for smooth camera rotation.
	const FRotator& InterpResult = Output.GetOwningPlayerController()->GetControlRotation();

	//FMath::RInterpTo(GetCameraRotation(), GetOwningPlayerController()->GetControlRotation(), DeltaTime, GetCameraBehaviorParam(Output.GetOwningCameraManager(), NAME_RotationLagSpeed));

	TargetCameraRotation = UKismetMathLibrary::RLerp(InterpResult, DebugViewRotation,
		GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_Override_Debug), true);

	// Step 4: Calculate the Smoothed Pivot Target (Orange Sphere).
	// Get the 3P Pivot Target (Green Sphere) and interpolate using axis independent lag for maximum control.

	bool IsOnGround = false;
	bool IsWalking = false;
	if (ControlledCharacter->GetLocomotionComponent())
	{
		IsOnGround = ControlledCharacter->GetLocomotionComponent()->GetMovementState() == EHiMovementState::Grounded;
	}
	if (ControlledCharacter->GetCharacterMovement())
	{
		IsWalking = ControlledCharacter->GetCharacterMovement()->IsWalking();
	}
	if (bEnablePivotSmooth || (IsOnGround && IsWalking))
	{
		const FVector LagSpd(GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotLagSpeed_X)
			, GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotLagSpeed_Y)
			, GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotLagSpeed_Z));
		const FVector& AxisIndpLag = CalculateAxisIndependentLag(SmoothedPivotTarget.GetLocation(),
			PivotTarget.GetLocation(), TargetCameraRotation, LagSpd,
			PivotSmoothAlpha, PivotSmoothEasingFunc,
			Output.DeltaTime);
		SmoothedPivotTarget.SetLocation(AxisIndpLag);
	}
	else
	{
		SmoothedPivotTarget.SetLocation(PivotTarget.GetLocation());		// Not use AxisIndpLag, The camera shakes violently
	}
	SmoothedPivotTarget.SetRotation(PivotTarget.GetRotation());
	SmoothedPivotTarget.SetScale3D(FVector::OneVector);

	// Step 5: Calculate Pivot Location (BlueSphere). Get the Smoothed
	// Pivot Target and apply local offsets for further camera control.
	PivotLocation =
		SmoothedPivotTarget.GetLocation() +
		UKismetMathLibrary::GetForwardVector(SmoothedPivotTarget.Rotator())
			* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotOffset_X)
			+ UKismetMathLibrary::GetRightVector(SmoothedPivotTarget.Rotator())
			* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotOffset_Y)
			+ UKismetMathLibrary::GetUpVector(SmoothedPivotTarget.Rotator())
			* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_PivotOffset_Z);

	// Step 6: Calculate Target Camera Location. Get the Pivot location and apply camera relative offsets.
	float ScaleDelta = ControlledCharacter->ConsumeCameraScaleInput() * DistanceScaleFactor;

	FVector Offset = (UKismetMathLibrary::GetForwardVector(TargetCameraRotation)
		* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_CameraOffset_X)
		+ UKismetMathLibrary::GetRightVector(TargetCameraRotation)
		* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_CameraOffset_Y)
		+ UKismetMathLibrary::GetUpVector(TargetCameraRotation)
		* GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_CameraOffset_Z));

	float DesireDistance = Offset.Size() * (DistanceScale + ScaleDelta);

	if (DesireDistance >= MinDistance && DesireDistance <= MaxDistance)
	{
		DistanceScale += ScaleDelta;
	}

	TargetCameraLocation = UKismetMathLibrary::VLerp(
		PivotLocation +
		Offset * DistanceScale,
		PivotTarget.GetLocation() + DebugViewOffset,
		GetCameraBehaviorParam(Output.GetOwningCameraManager(), ClassicViewParameters::NAME_Override_Debug));

	Output.SetViewLocation(TargetCameraLocation);
	Output.SetViewOrientation(TargetCameraRotation);
}

float UHiVisionerView_Classic::GetCameraBehaviorParam(APlayerCameraManager* PlayerCameraManager, const FName ParamName)
{
	AHiPlayerCameraManager* HiPlayerCameraManager = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (!HiPlayerCameraManager)
	{
		return 0.0f;
	}
	return HiPlayerCameraManager->GetCameraBehaviorParam(ParamName);
}

float UHiVisionerView_Classic::GetVisionerCurveValue(APlayerCameraManager* PlayerCameraManager, const FName ParamName)
{
	AHiPlayerCameraManager* HiPlayerCameraManager = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (!HiPlayerCameraManager)
	{
		return 0.0f;
	}
	if (UVisionerInstance* VisionerInstance = HiPlayerCameraManager->GetVisionerBP())
	{
		//VisionerInstance->GetCurveValue(ParamName);
	}
	return 0.0f;
}

FVector UHiVisionerView_Classic::CalculateAxisIndependentLag(FVector CurrentLocation, FVector TargetLocation,
	FRotator CameraRotation, FVector LagSpeeds,
	const FVector& SmoothAlpha, const TArray<TEnumAsByte<EEasingFunc::Type>>& SmoothEasingFunc,
	float DeltaTime)
{
	CameraRotation.Roll = 0.0f;
	CameraRotation.Pitch = 0.0f;
	const FVector UnrotatedCurLoc = CameraRotation.UnrotateVector(CurrentLocation);
	const FVector UnrotatedTargetLoc = CameraRotation.UnrotateVector(TargetLocation);

	FVector ResultVector;

	ResultVector.X = LagSpeeds.X > 0 ? UKismetMathLibrary::Ease(UnrotatedCurLoc.X, UnrotatedTargetLoc.X, SmoothAlpha.X, SmoothEasingFunc[0], DeltaTime * LagSpeeds.X) : UnrotatedTargetLoc.X;
	ResultVector.Y = LagSpeeds.Y > 0 ? UKismetMathLibrary::Ease(UnrotatedCurLoc.Y, UnrotatedTargetLoc.Y, SmoothAlpha.Y, SmoothEasingFunc[1], DeltaTime * LagSpeeds.Y) : UnrotatedTargetLoc.Y;
	ResultVector.Z = LagSpeeds.Z > 0 ? UKismetMathLibrary::Ease(UnrotatedCurLoc.Z, UnrotatedTargetLoc.Z, SmoothAlpha.Z, SmoothEasingFunc[2], DeltaTime * LagSpeeds.Z) : UnrotatedTargetLoc.Z;

	return CameraRotation.RotateVector(ResultVector);
}
