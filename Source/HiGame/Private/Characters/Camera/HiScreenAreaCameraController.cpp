// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/Camera/HiScreenAreaCameraController.h"

#include "Kismet/KismetMathLibrary.h"
#include "GameFramework/PlayerController.h"
#include "Intersection/IntersectionUtil.h"


void HiScreenAreaCameraController::InitParameters(AActor* InActor, FHiScreenZoneType& InLimitZone, FHiScreenZoneType& InComfortZone, double InHalflife)
{
	if (!InLimitZone.Valid())
	{
		UE_LOG(LogTemp, Error, TEXT("<CameraGraph> Invalid limit zone (Left %.2f, Right %.2f, Top %.2f, Bottom %.2f)"), InLimitZone.Left, InLimitZone.Right, InLimitZone.Top, InLimitZone.Bottom);
		return;
	}
	if (!InComfortZone.Valid())
	{
		UE_LOG(LogTemp, Error, TEXT("<CameraGraph> Invalid comfort zone (Left %.2f, Right %.2f, Top %.2f, Bottom %.2f)"), InLimitZone.Left, InLimitZone.Right, InLimitZone.Top, InLimitZone.Bottom);
		return;
	}
	// Transform coordinates: The center of the screen is (0, 0)
	FVector2D CenterPoint(0.5, 0.5);
	LimitZone = InLimitZone - CenterPoint;
	ComfortZone = InComfortZone - CenterPoint;
	TargetActor = InActor;
	SmoothSpeed = InHalflife;
	PreviousRemainRotator = FRotator::ZeroRotator;
}

void HiScreenAreaCameraController::StartAutoRotator(const HiCameraBehaviorContext& InCameraBehaviorContext, const FVector& InCameraLocation, const FRotator& InCameraRotation, float& InOutFOV)
{
	/* Here center of the screen is(0, 0) */
	int ViewportX = 0, ViewportY = 0;
	InCameraBehaviorContext.PlayerControl->GetViewportSize(ViewportX, ViewportY);
	float VerticalFOV = InOutFOV * ViewportY / ViewportX;
	float HorizontalFOV = InOutFOV;
	FVector2D ScreenNormalPointToAngle(HorizontalFOV, VerticalFOV);
	
	// 1st. Rotate camera to face target.
	FVector TargetLocation = TargetActor->GetActorLocation();
	FVector DirToTarget = TargetLocation - InCameraBehaviorContext.PivotLocation;
	FVector DirToTargetInCameraSpace = InCameraRotation.UnrotateVector(DirToTarget);
	FRotator AssistAttackTargetRotation = UKismetMathLibrary::Conv_VectorToRotator(DirToTarget);

	FRotator RotatorToFaceTarget(
		FMath::FindDeltaAngleDegrees(InCameraRotation.Pitch, AssistAttackTargetRotation.Pitch), 
		FMath::FindDeltaAngleDegrees(InCameraRotation.Yaw, AssistAttackTargetRotation.Yaw), 0);
	double RotatorToFaceTargetAngle = RotatorToFaceTarget.Euler().Length();

	// 2nd. Rotate camera to boundary.
	FRotator CenterToCameraBoundaryAngle(0, 0, 0);
	if (RotatorToFaceTarget.Yaw > 0)	CenterToCameraBoundaryAngle.Yaw = LimitZone.Left * HorizontalFOV;
	else								CenterToCameraBoundaryAngle.Yaw = LimitZone.Right * HorizontalFOV;
	if (RotatorToFaceTarget.Pitch > 0)	CenterToCameraBoundaryAngle.Pitch = LimitZone.Top * VerticalFOV;
	else								CenterToCameraBoundaryAngle.Pitch = LimitZone.Bottom * VerticalFOV;

	// 3rd. Find the camera angle in the view screen.
	double CenterToBoundaryAngle = 0;
	if (FMath::Abs(RotatorToFaceTarget.Yaw) < 0.01)
		CenterToBoundaryAngle = CenterToCameraBoundaryAngle.Pitch;
	else if (FMath::Abs(RotatorToFaceTarget.Pitch) < 0.01)
		CenterToBoundaryAngle = CenterToCameraBoundaryAngle.Yaw;
	else
		if (FMath::Abs(RotatorToFaceTarget.Pitch / RotatorToFaceTarget.Yaw) > FMath::Abs(CenterToCameraBoundaryAngle.Pitch / CenterToCameraBoundaryAngle.Yaw))
			CenterToBoundaryAngle = CenterToCameraBoundaryAngle.Pitch * RotatorToFaceTargetAngle / RotatorToFaceTarget.Pitch;
		else
			CenterToBoundaryAngle = CenterToCameraBoundaryAngle.Yaw * RotatorToFaceTargetAngle / RotatorToFaceTarget.Yaw;

	// 4th. Calculate the intersection of line and circle, and then solve the camera rotation angle.
	double CameraBoundaryRadians = FMath::DegreesToRadians(FMath::Abs(CenterToBoundaryAngle));
	FVector2D CameraBoundaryDirection(FMath::Sin(CameraBoundaryRadians), FMath::Cos(CameraBoundaryRadians));
	IntersectionUtil::FLinearIntersection result = IntersectionUtil::LineSphereIntersection(
		FVector(0, InCameraBehaviorContext.ArmOffset, 0), FVector(CameraBoundaryDirection.X, CameraBoundaryDirection.Y, 0), FVector(0, 0, 0), DirToTarget.Length());

	if (result.numIntersections != 2)
	{
		// If the target is too close to the pivot, player can see the target no matter how adjust the camera.
		// At this time, automatic rotation is directly ignored.
		return;
	}
	FVector2D ResultIntersectionPoint = CameraBoundaryDirection * result.parameter.Max + FVector2D(0, InCameraBehaviorContext.ArmOffset);
	double CameraDeltaAngle = FMath::RadiansToDegrees(FMath::Atan2(ResultIntersectionPoint.X, ResultIntersectionPoint.Y));
	FRotator RotateToCameraBoundary(-RotatorToFaceTarget.Pitch / RotatorToFaceTargetAngle * CameraDeltaAngle, -RotatorToFaceTarget.Yaw / RotatorToFaceTargetAngle * CameraDeltaAngle, 0);
	PreviousRemainRotator = RotatorToFaceTarget + RotateToCameraBoundary;
	PreviousRemainRotator.Yaw = FRotator3f::NormalizeAxis(PreviousRemainRotator.Yaw);			// -180, 180

	// 5th. Ingore rotation inside the zone & Limit pitch
	if (FMath::Abs(RotatorToFaceTarget.Pitch) < FMath::Abs(RotateToCameraBoundary.Pitch))	PreviousRemainRotator.Pitch = 0;
	if (FMath::Abs(RotatorToFaceTarget.Yaw) < FMath::Abs(RotateToCameraBoundary.Yaw))		PreviousRemainRotator.Yaw = 0;
	PreviousRemainRotator.Pitch = FMath::Clamp(PreviousRemainRotator.Pitch, InCameraBehaviorContext.ViewPitchMin - InCameraRotation.Pitch, InCameraBehaviorContext.ViewPitchMax - InCameraRotation.Pitch);
}

void HiScreenAreaCameraController::ProcessCameraBehavior(const HiCameraBehaviorContext& InCameraBehaviorContext, const FVector& InCameraLocation, const FRotator& InCameraRotation, float& InOutFOV, FRotator& OutDeltaRotation)
{
	if (TargetActor)
	{
		StartAutoRotator(InCameraBehaviorContext, InCameraLocation, InCameraRotation, InOutFOV);
		if (!bLockTarget)
			TargetActor = nullptr;
	}

	if (!PreviousRemainRotator.IsNearlyZero(GetAutoStopRotateThreshold()))
	{
		// Smooth Speed
		OutDeltaRotation.Yaw = UKismetMathLibrary::Ease(0, PreviousRemainRotator.Yaw, 0.5, EEasingFunc::EaseOut, InCameraBehaviorContext.DeltaTime / SmoothSpeed);
		//OutDeltaRotation.Pitch = UKismetMathLibrary::Ease(0, PreviousRemainRotator.Pitch, 0.5, EEasingFunc::EaseOut, InCameraBehaviorContext.DeltaTime / SmoothSpeed);
		PreviousRemainRotator.Yaw -= OutDeltaRotation.Yaw;
		//PreviousRemainRotator.Pitch -= OutDeltaRotation.Pitch;
	}
	return;
}
