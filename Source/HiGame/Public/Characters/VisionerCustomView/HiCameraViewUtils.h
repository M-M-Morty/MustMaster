// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/EngineTypes.h"
#include "VisionerView.h"


namespace DoubleObjectTools
{
	float CalculateVecterAngle(FVector A, FVector B)
	{
		A.Normalize();
		B.Normalize();
		return FMath::RadiansToDegrees(FMath::Acos(A | B));
	}

	//FVector CalculateCameraToCenterVector(FVector PlayerCenter, float PlayerHeight, float VerticalFOV, FRotator CameraRotation, float HalfPlayerScale, float UpperViewPosition)
	//{
	//	float UpperPitchRadians = FMath::DegreesToRadians(CameraRotation.Pitch + UpperViewPosition * VerticalFOV);
	//	float MidPitchRadians = UpperPitchRadians - FMath::DegreesToRadians(HalfPlayerScale * VerticalFOV);
	//	float HorizontalDistance = PlayerHeight * 0.5 / ((FMath::Tan(UpperPitchRadians) - FMath::Tan(MidPitchRadians)));
	//	//FVector LowerPoint = PlayerCenter + FVector::DownVector * PlayerHeight * 0.5f;
	//	FVector CameraLocation = PlayerCenter + FRotator(0.0f, CameraRotation.Yaw, 0.0f).Vector() * (-HorizontalDistance);
	//	CameraLocation += FVector::DownVector * (HorizontalDistance * FMath::Tan(MidPitchRadians));
	//	return CameraLocation;
	//}

	float CalculateVerticleFOV(const float HorizontalFOV, const float AspectRatio)
	{
		return FMath::RadiansToDegrees(FMath::Atan(FMath::Tan(FMath::DegreesToRadians(HorizontalFOV / 2)) / AspectRatio) * 2);
	}

	void CalculateObjectsViewYaw(const FVector CameraLocation, const float CameraYaw, const FVector PlayerLocation, const FVector TargetLocation, float& PlayerViewYaw, float& TargetViewYaw)
	{
		FVector CameraToPlayer = PlayerLocation - CameraLocation;
		PlayerViewYaw = FRotator3f::NormalizeAxis(CameraYaw - CameraToPlayer.ToOrientationRotator().Yaw);			// (-180,180]
		FVector CameraToTarget = TargetLocation - CameraLocation;
		TargetViewYaw = FRotator3f::NormalizeAxis(CameraYaw - CameraToTarget.ToOrientationRotator().Yaw);			// (-180,180]
	}

	// Return limits pitch angle
	float CalculateFixedCameraWithPitchView(const FHiViewConfig_DoubleObject& CameraSchemeConfig, const FVector WatchPoint, const FHiCameraUpdateContext_DoubleObject& UpdateContext, const float TargetViewPitch, FVisionerView& InOutContext)
	{
		const FVector CameraRightDirection = UKismetMathLibrary::GetRightVector(FRotator(0.0f, InOutContext.Orientation.Yaw, 0.0f));
		FVector PlayerToTarget = WatchPoint - UpdateContext.PlayerCenter;
		PlayerToTarget -= PlayerToTarget.ProjectOnToNormal(CameraRightDirection);
		check(FMath::Abs(PlayerToTarget | CameraRightDirection) < 1e-4f);
		FRotator PlayerToTargetRotator = PlayerToTarget.ToOrientationRotator();
		float CameraViewPitch = FMath::Abs(TargetViewPitch - UpdateContext.PlayerViewPitch);

		float SinTargetAngle = FMath::Sin(FMath::DegreesToRadians(CameraViewPitch)) / PlayerToTarget.Length() * CameraSchemeConfig.DistanceToPlayerPoint;
		float TargetAngle = FMath::RadiansToDegrees(FMath::Asin(SinTargetAngle));
		float CameraBestPitch = FRotator3f::NormalizeAxis(PlayerToTargetRotator.Pitch - TargetAngle - TargetViewPitch);			// (-180,180]
		InOutContext.Orientation.Pitch = FMath::Clamp(CameraBestPitch, CameraSchemeConfig.PitchCorrect_MinPitch, CameraSchemeConfig.PitchCorrect_MaxPitch);
		return CameraBestPitch - InOutContext.Orientation.Pitch;
	}

	/*
	 *  Move camera location to suit view angle
	 *  - InputPOV is currently in the ray facing the camera through the player's center
	 *  - It is an approximate algorithm and cannot calculate accurate results.
	 */
	void CalculateBestCameraWithRatioYawView(const FHiViewConfig_DoubleObject& CameraSchemeConfig, const FHiCameraUpdateContext_DoubleObject UpdateContext, FVisionerView& InOutContext)
	{
		const FVector CameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, InOutContext.Orientation.Yaw, 0.0f));
		const FVector CameraHorizontalRight = FVector(-CameraHorizontalForward.Y, CameraHorizontalForward.X, 0);

		// Move the camera behind the player
		FVector PlayerToCamera = InOutContext.Location - UpdateContext.PlayerCenter;
		PlayerToCamera -= PlayerToCamera.ProjectOnToNormal(CameraHorizontalRight);
		InOutContext.Location = PlayerToCamera + UpdateContext.PlayerCenter;

		FVector TargetToPlayer = UpdateContext.PlayerCenter - UpdateContext.TargetCenter;
		float TargetToPlayerRightOffset = CameraHorizontalRight | TargetToPlayer;

		// Move the camera position in parallel to meet the target angle scale
		PlayerToCamera.Z = 0;
		float PlayerProjectCameraLength = PlayerToCamera.Size();
		FVector TargetToCamera = InOutContext.Location - UpdateContext.TargetCenter;
		float TargetProjectCameraForwardLength = -(CameraHorizontalForward | TargetToCamera);
		float CameraRightCorrectOffset = (TargetToPlayerRightOffset * PlayerProjectCameraLength)
			/ (PlayerProjectCameraLength + CameraSchemeConfig.ObjectsYawTanRatio * TargetProjectCameraForwardLength);

		// Handling situations beyond the player offset boundary
		float LimitPlayerViewYawRadians = FMath::DegreesToRadians(CameraSchemeConfig.LimitPlayerViewYaw);
		float ViewPlayerYawTan = FMath::Tan(LimitPlayerViewYawRadians);
		float MaxCorrectOffset = ViewPlayerYawTan * PlayerProjectCameraLength;

		/*
		 * Player reaches the limit of angle position in the camera.
		 *     The camera needs to be pushed back to ensure that the player and target in the camera are in a fixed proportion
		 */
		CameraRightCorrectOffset = FMath::Clamp(CameraRightCorrectOffset, -MaxCorrectOffset, MaxCorrectOffset);

		InOutContext.Location -= CameraRightCorrectOffset * CameraHorizontalRight;
		FVector CameraToPlayer = UpdateContext.PlayerCenter - InOutContext.Location;
		float CapturePlayerYawOffset = FRotator3f::NormalizeAxis(InOutContext.Orientation.Yaw - CameraToPlayer.ToOrientationRotator().Yaw);			// (-180,180]
		return;
	}

	/*
	 *  Move camera location to suit view angle
	 *  - Fixed player view with PlayerYawRadius
	 */
	void CalculateCameraWithFixedPlayerView(const FHiViewConfig_DoubleObject& CameraSchemeConfig, const FHiCameraUpdateContext_DoubleObject UpdateContext, const float PlayerViewYaw, FVisionerView& InOutContext)
	{
		const FVector CameraRightDirection = UKismetMathLibrary::GetRightVector(FRotator(0.0f, InOutContext.Orientation.Yaw, 0.0f));

		// Move the camera position in parallel to meet the target angle scale
		FVector PlayerToCamera = InOutContext.Location - UpdateContext.PlayerCenter;
		PlayerToCamera -= PlayerToCamera.ProjectOnToNormal(CameraRightDirection);
		check(FMath::Abs(PlayerToCamera | CameraRightDirection) < 1e-4f);
		InOutContext.Location = PlayerToCamera + UpdateContext.PlayerCenter;

		// Handling situations beyond the player offset boundary
		float ViewPlayerYawTan = FMath::Tan(FMath::DegreesToRadians(PlayerViewYaw));
		PlayerToCamera.Z = 0.0f;
		float CameraRightCorrectOffset = ViewPlayerYawTan * PlayerToCamera.Length();
		InOutContext.Location += CameraRightCorrectOffset * CameraRightDirection;
	}

	void CalculateCameraWithFixedTargetView(const FHiViewConfig_DoubleObject& CameraSchemeConfig, const FHiCameraUpdateContext_DoubleObject UpdateContext, const float TargetViewYaw, FVisionerView& InOutContext)
	{
		const FVector CameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, InOutContext.Orientation.Yaw, 0.0f));
		const FVector CameraHorizontalLeft = FVector(CameraHorizontalForward.Y, -CameraHorizontalForward.X, 0);

		// Move the camera position in parallel to meet the target angle scale
		FVector CameraToTarget = UpdateContext.TargetCenter - InOutContext.Location;
		float TargetProjectCameraLength = CameraToTarget | CameraHorizontalForward;
		float TargetToCameraRightOffset = CameraToTarget | CameraHorizontalLeft;

		// Handling situations beyond the player offset boundary
		float ViewTargetYawTan = FMath::Tan(FMath::DegreesToRadians(TargetViewYaw));
		float CameraRightCorrectOffset = TargetToCameraRightOffset - ViewTargetYawTan * TargetProjectCameraLength;
		float ViewPlayerYawTan = FMath::Tan(FMath::DegreesToRadians(CameraSchemeConfig.LimitPlayerViewYaw));
		FVector PlayerToCamera = InOutContext.Location - UpdateContext.PlayerCenter;
		PlayerToCamera.Z = 0;
		float PlayerProjectCameraLength = PlayerToCamera.Size();
		float MaxCorrectOffset = ViewPlayerYawTan * PlayerProjectCameraLength;
		if (FMath::Abs(CameraRightCorrectOffset) > MaxCorrectOffset)
		{
			/*
			 * Player reaches the limit of angle position in the camera.
			 *     The camera needs to be pushed back to ensure that the player and target in the camera are in a fixed proportion
			 */
			CameraRightCorrectOffset = FMath::Clamp(CameraRightCorrectOffset, -MaxCorrectOffset, MaxCorrectOffset);
		}

		InOutContext.Location += CameraRightCorrectOffset * CameraHorizontalLeft;
	}

	void CalculateCameraWithFixedView(const FHiViewConfig_DoubleObject& CameraSchemeConfig, const FHiCameraUpdateContext_DoubleObject UpdateContext, const float PlayerViewYaw, const float TargetViewYaw, FVisionerView& InOutContext)
	{
		FVector HorizontalTargetCenter = UpdateContext.TargetCenter;
		HorizontalTargetCenter.Z = InOutContext.Location.Z;
		FVector HorizontalPlayerCenter = UpdateContext.PlayerCenter;
		HorizontalPlayerCenter.Z = InOutContext.Location.Z;

		FVector HorizontalPlayerToTarget = HorizontalTargetCenter - HorizontalPlayerCenter;
		float CameraAngleRadians = FMath::DegreesToRadians(FMath::Abs(PlayerViewYaw - TargetViewYaw));
		float PlayerToCameraDistance = (HorizontalPlayerCenter - InOutContext.Location).Length();
		float NewTargetAngle = FMath::RadiansToDegrees(FMath::Asin(FMath::Sin(CameraAngleRadians) / HorizontalPlayerToTarget.Length() * PlayerToCameraDistance));
		float OldTargetAngle = CalculateVecterAngle(HorizontalTargetCenter - HorizontalPlayerCenter, HorizontalTargetCenter - InOutContext.Location);
		if (FMath::Abs(NewTargetAngle - OldTargetAngle) > FMath::Abs(180 - NewTargetAngle - OldTargetAngle))
		{
			NewTargetAngle = 180 - NewTargetAngle;
		}

		if (PlayerViewYaw - TargetViewYaw < 0)
		{
			NewTargetAngle = -NewTargetAngle;
		}
		InOutContext.Orientation.Yaw = HorizontalPlayerToTarget.ToOrientationRotator().Yaw - NewTargetAngle + TargetViewYaw;
		FVector CameraToPlayerDir = UKismetMathLibrary::GetForwardVector(FRotator(0, InOutContext.Orientation.Yaw - PlayerViewYaw, 0));
		InOutContext.Location = HorizontalPlayerCenter - PlayerToCameraDistance * CameraToPlayerDir;
	}

	/*
	 * Calculate the camera position with required player's view pitch
	 *  - Based on previous camera location, current camera orientation
	 *  - Only adjust the camera vertically to match the current player's view pitch
	 */
	void CalculateCameraWithPlayerViewPitch(const FHiCameraUpdateContext_DoubleObject& UpdateContext, const float DistanceToPlayer, FVisionerView& InOutContext)
	{
		FRotator CameraToPlayerRotator = FRotator(-(UpdateContext.PlayerViewPitch + InOutContext.Orientation.Pitch), InOutContext.Orientation.Yaw + 180.0f, 0);
		FVector CameraToPlayerDirection = UKismetMathLibrary::Conv_RotatorToVector(CameraToPlayerRotator);
		InOutContext.Location = CameraToPlayerDirection * DistanceToPlayer + UpdateContext.PlayerCenter;
	}
}
