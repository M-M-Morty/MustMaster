// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/VisionerCustomView/HiCameraProcessor_DoubleObject.h"
#include "Characters/VisionerCustomView/HiVisionerView_DoubleObject.h"
#include "Characters/VisionerCustomView/HiCameraViewUtils.h"


/****************************** PlayerForwardOffset Processor ********************************/

void FCameraProcessor_PlayerForwardOffset::Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	PreviousPlayerForwardOffset = 0.0f;
}

void FCameraProcessor_PlayerForwardOffset::Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	if (UpdateContext.Scheme->IsResetFrame())
	{
		Reset(UpdateContext, ViewContext);
		return;
	}

	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();

	const FRotator PreviousCameraRotation = UpdateContext.Scheme->GetCachedCameraOrientation();
	const FVector PreviousCameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, PreviousCameraRotation.Yaw, 0.0f));
	const FVector PreviousCameraLocation = UpdateContext.Scheme->GetCachedCameraLocation();
	const FVector NewCameraToPlayer = UpdateContext.PlayerCenter - PreviousCameraLocation;
	const FVector OldCameraToPlayer = UpdateContext.Scheme->GetPreviousPlayerCenterLocation() - PreviousCameraLocation;

	PreviousPlayerForwardOffset = (NewCameraToPlayer | PreviousCameraHorizontalForward) - (OldCameraToPlayer | PreviousCameraHorizontalForward);
	float ReduceRatio = CameraSchemeConfig.PlayerForwardOffset_LerpSpeed * UpdateContext.DeltaTime;
	ReduceRatio = FMath::Min(ReduceRatio, 1.0f);

	PreviousPlayerForwardOffset *= (1.0f - ReduceRatio);
	PreviousPlayerForwardOffset = FMath::Clamp(PreviousPlayerForwardOffset
		, CameraSchemeConfig.PlayerForwardOffset_MinOffset
		, CameraSchemeConfig.PlayerForwardOffset_MaxOffset);

	// Update context parameters
	const FVector CurrentCameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, ViewContext.Orientation.Yaw, 0.0f));
	FVector PlayerForwardOffset = -CurrentCameraHorizontalForward * PreviousPlayerForwardOffset;
	UpdateContext.PlayerCenter += PlayerForwardOffset;
}

/****************************** PlayerViewPitch Processor ********************************/

void FCameraProcessor_PlayerViewPitch::Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();
	PreviousPlayerViewPitch = CameraSchemeConfig.PlayerViewPitch_MinPercent * 0.01f * UpdateContext.VerticalFOV;
	UnstableAveragePlayerViewPitch = PreviousPlayerViewPitch;
	UnstableGroundDuration = 0.0f;

	// Reset Update Context parameters
	UpdateContext.PlayerViewPitch = PreviousPlayerViewPitch;
}

void FCameraProcessor_PlayerViewPitch::Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	if (UpdateContext.Scheme->IsResetFrame())
	{
		Reset(UpdateContext, ViewContext);
		return;
	}

	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();
	const EHiTargetLockState TargetLockState = UpdateContext.Scheme->GetTargetLockState();

	ViewContext.Orientation.Pitch = FRotator3f::NormalizeAxis(ViewContext.Orientation.Pitch);		// (-180,180]

	// New Player View Pitch
	const FVector CameraRightDirection = UKismetMathLibrary::GetRightVector(FRotator(0.0f, ViewContext.Orientation.Yaw, 0.0f));
	FVector HeightUpdatedPlayerCenter = UpdateContext.Scheme->GetPreviousPlayerCenterLocation();
	HeightUpdatedPlayerCenter.Z = UpdateContext.PlayerCenter.Z;
	FVector CameraToPlayer = HeightUpdatedPlayerCenter - UpdateContext.Scheme->GetCachedCameraLocation();
	CameraToPlayer -= CameraToPlayer.ProjectOnToNormal(CameraRightDirection);
	check(FMath::Abs(CameraToPlayer | CameraRightDirection) < 1e-4f);

	float NewPlayerToCameraPitch = CameraToPlayer.ToOrientationRotator().Pitch;
	NewPlayerToCameraPitch = FRotator3f::NormalizeAxis(NewPlayerToCameraPitch);		// (-180,180]
	float NewPlayerViewPitch = NewPlayerToCameraPitch - UpdateContext.Scheme->GetCachedCameraOrientation().Pitch;
	const float PlayerViewMaxPitch = CameraSchemeConfig.PlayerViewPitch_MaxPercent * 0.01f * UpdateContext.VerticalFOV;
	const float PlayerViewMinPitch = CameraSchemeConfig.PlayerViewPitch_MinPercent * 0.01f * UpdateContext.VerticalFOV;
	NewPlayerViewPitch = FMath::Clamp(NewPlayerViewPitch, PlayerViewMinPitch, PlayerViewMaxPitch);

	float PitchUpdateSpeed = CameraSchemeConfig.PlayerViewPitch_InAirSmoothSpeed;
	if (UpdateContext.PlayerMovementMode == EMovementMode::MOVE_Walking)
	{
		if (TargetLockState != EHiTargetLockState::Free || UpdateContext.Scheme->IsAutoLeaveDriven())
		{
			// Force on ground
			const float PlayerGroundHeight = UpdateContext.PlayerCenter.Z - UpdateContext.PlayerHeight - UpdateContext.TargetLower.Z;
			const float GroundPitchRatio = PlayerGroundHeight / (UpdateContext.TargetUpper.Z - UpdateContext.TargetLower.Z);
			const float GroundPlayerViewMaxPitch = CameraSchemeConfig.PlayerViewPitch_GroundMaxPercent * 0.01f * UpdateContext.VerticalFOV;
			NewPlayerViewPitch = FMath::GetMappedRangeValueClamped(FFloatRange(0, 1), FFloatRange(PlayerViewMinPitch, GroundPlayerViewMaxPitch), GroundPitchRatio);
			NewPlayerViewPitch = SmoothGroundPitch(NewPlayerViewPitch, UpdateContext.DeltaTime);
		}
		else
		{
			NewPlayerViewPitch = PlayerViewMinPitch;
		}
		PitchUpdateSpeed = CameraSchemeConfig.PlayerViewPitch_GroundSmoothSpeed;
	}

	// Smooth
	float PlayerViewPitchDiff = NewPlayerViewPitch - PreviousPlayerViewPitch;
	float PlayerViewPitchStep = PlayerViewPitchDiff;
	if (PlayerViewPitchDiff > 0)
	{
		PlayerViewPitchStep *= UpdateContext.DeltaTime * PitchUpdateSpeed;
		if (PlayerViewPitchStep < PlayerViewPitchDiff)
		{
			NewPlayerViewPitch = PreviousPlayerViewPitch + PlayerViewPitchStep;
		}
	}
	else if (PlayerViewPitchDiff < 0)
	{
		PlayerViewPitchStep *= UpdateContext.DeltaTime * PitchUpdateSpeed;
		if (PlayerViewPitchStep > PlayerViewPitchDiff)
		{
			NewPlayerViewPitch = PreviousPlayerViewPitch + PlayerViewPitchStep;
		}
	}
	// Update cached data
	PreviousPlayerViewPitch = NewPlayerViewPitch;
	// Update context parameters
	UpdateContext.PlayerViewPitch = NewPlayerViewPitch;
	// Refresh camera location
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
}

float FCameraProcessor_PlayerViewPitch::SmoothGroundPitch(float NewValue, float DeltaTime)
{
	float UnstableValueDelta = NewValue - UnstableAveragePlayerViewPitch;
	if (UnstableValueDelta * (NewValue - PreviousPlayerViewPitch) < -1e-4f)
	{
		// Do reset unstable average
		UnstableAveragePlayerViewPitch = NewValue;
		UnstableGroundDuration = 0.0f;
	}

	// Do average
	UnstableAveragePlayerViewPitch = UnstableAveragePlayerViewPitch * UnstableGroundDuration + DeltaTime * NewValue;
	UnstableGroundDuration = DeltaTime + UnstableGroundDuration;
	UnstableAveragePlayerViewPitch /= UnstableGroundDuration;
	UnstableGroundDuration = FMath::Min(UnstableGroundDuration, UnstableMaxRecordingDuration);

	float SmoothValue = PreviousPlayerViewPitch;
	UnstableValueDelta = NewValue - SmoothValue;
	if (FMath::Abs(UnstableValueDelta) > TolerancePlayerViewPitch && UnstableGroundDuration >= UnstableMaxRecordingDuration - 1e-4f)
	{
		// Start change
		SmoothValue = UnstableAveragePlayerViewPitch;
	}
	return SmoothValue;
}

/****************************** CameraPitch Processor ********************************/

void FCameraProcessor_CameraPitch::Reset(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	bLockPlayerControlPitch = false;
	PreviousEstimatedBestPitch = CurrentEstimatedBestPitch = ViewContext.Orientation.Pitch;
}

void FCameraProcessor_CameraPitch::Update(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	if (UpdateContext.Scheme->IsResetFrame())
	{
		Reset(UpdateContext, ViewContext);
		return;
	}

	const EHiTargetLockState TargetLockState = UpdateContext.Scheme->GetTargetLockState();
	CalculateEstimatedBestCameraPitch(UpdateContext, ViewContext);
	if (UpdateContext.InputDeltaRotation.IsNearlyZero() && UpdateContext.Scheme->IsSchemeNotLeaving() && TargetLockState != EHiTargetLockState::Free)
	{
		if (!bLockPlayerControlPitch)
		{
			CalculateBestCameraWithDynamicPitchView(UpdateContext, ViewContext);
		}
		else
		{
			CalculateBestCameraWithFixedPitchView(UpdateContext, ViewContext);
		}
	}
	PreviousEstimatedBestPitch = CurrentEstimatedBestPitch;
}

void FCameraProcessor_CameraPitch::LockControlPitch(bool bEnabled, float InLockTargetViewPitch)
{
	bLockPlayerControlPitch = bEnabled;
	LockTargetViewPitch = InLockTargetViewPitch;
}

void FCameraProcessor_CameraPitch::CalculateEstimatedBestCameraPitch(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();

	const float HalfVerticalFOV = 0.5f * UpdateContext.VerticalFOV;
	const float InputPitch = ViewContext.Orientation.Pitch;
	const FVector InputLocation = ViewContext.Location;

	/* 1st. Find current camera location for horizontal viewing, answer is ViewContext.Location.Z */
	ViewContext.Orientation.Pitch = 0.0f;
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
	const float CurrentCameraHorizontalHeight = ViewContext.Location.Z;

	/* 2nd. Find the estimated best pitch under the condition that the bottom heights of two targets are the same */
	const float InputPlayerViewPitch = UpdateContext.PlayerViewPitch;
	const FVector InputPlayerCenter = UpdateContext.PlayerCenter;
	const float LowestTargetViewPitch = CameraSchemeConfig.TargetViewPitch_HeadPercent_Lowest * 0.01f * UpdateContext.VerticalFOV;
	const float HighestTargetViewPitch = CameraSchemeConfig.TargetViewPitch_HeadPercent_Highest * 0.01f * UpdateContext.VerticalFOV;
	UpdateContext.PlayerCenter.Z = UpdateContext.WatchForwardLowerPoint.Z + UpdateContext.PlayerHeight * 0.5f;
	UpdateContext.PlayerViewPitch = CameraSchemeConfig.PlayerViewPitch_MinPercent * 0.01f * UpdateContext.VerticalFOV;
	const float LowestCameraHorizontalHeight = CurrentCameraHorizontalHeight + UpdateContext.PlayerCenter.Z - InputPlayerCenter.Z;
	DoubleObjectTools::CalculateFixedCameraWithPitchView(CameraSchemeConfig, UpdateContext.WatchForwardUpperPoint, UpdateContext, LowestTargetViewPitch, ViewContext);
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
	UpdateContext.PlayerViewPitch = InputPlayerViewPitch;
	UpdateContext.PlayerCenter = InputPlayerCenter;
	const float LowestCameraBestPitch = ViewContext.Orientation.Pitch;

	/* 3rd. Find suitable target view pitch based on camera height */
	check(!FMath::IsNearlyEqual(UpdateContext.WatchForwardUpperPoint.Z, UpdateContext.WatchForwardLowerPoint.Z));
	float ValueRatio = (CurrentCameraHorizontalHeight - LowestCameraHorizontalHeight) / (UpdateContext.WatchForwardUpperPoint.Z - UpdateContext.WatchForwardLowerPoint.Z);

	EstimatedTargetViewPitch = FMath::GetMappedRangeValueClamped(FVector2f(0, 1), FVector2f(LowestTargetViewPitch, HighestTargetViewPitch), ValueRatio);
	CurrentEstimatedBestPitch = FMath::GetMappedRangeValueUnclamped(FVector2f(0, 1), FVector2f(LowestCameraBestPitch, 0.0f), ValueRatio);

	//UE_LOG(LogTemp, Warning, L"[ZL] estimated best pitch   %.2f     target view pitch: %.2f     ratio: %.2f", PreviousEstimatedBestPitch, EstimatedTargetViewPitch, ValueRatio);

	ViewContext.Orientation.Pitch = InputPitch;
	ViewContext.Location = InputLocation;
}

void FCameraProcessor_CameraPitch::CalculateBestCameraWithDynamicPitchView(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();
	const EHiTargetLockState TargetLockState = UpdateContext.Scheme->GetTargetLockState();
	const float HalfVerticalFOV = 0.5f * UpdateContext.VerticalFOV;

	// The camera moves directly behind the character by default
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
	const float InputPitch = ViewContext.Orientation.Pitch;
	const float InputPlayerViewPitch = UpdateContext.PlayerViewPitch;
	const FVector InputLocation = ViewContext.Location;
	const FVector InputPlayerCenter = UpdateContext.PlayerCenter;

	/* 4th. Calculate current target view pitch */

	FRotator CameraToTargetRotator = (UpdateContext.WatchForwardUpperPoint - InputLocation).ToOrientationRotator();
	float TargetUpperViewPitch = FRotator3f::NormalizeAxis(CameraToTargetRotator.Pitch - InputPitch);			// (-180,180]
	CameraToTargetRotator = (UpdateContext.WatchForwardLowerPoint - InputLocation).ToOrientationRotator();
	float TargetLowerViewPitch = FRotator3f::NormalizeAxis(CameraToTargetRotator.Pitch - InputPitch);			// (-180,180]

	float OffsetToleranceRatio = CameraSchemeConfig.TargetViewPitch_OffsetTolerancePercent * 0.01f;
	FFloatRange TargetUpperViewPitchRange{
		EstimatedTargetViewPitch - OffsetToleranceRatio * UpdateContext.VerticalFOV,
		EstimatedTargetViewPitch + OffsetToleranceRatio * UpdateContext.VerticalFOV
	};

	if (TargetUpperViewPitch < -HalfVerticalFOV || TargetLowerViewPitch > HalfVerticalFOV)
	{
		// Can not watch any boss, ignoring the optimal correction
		ViewContext.Orientation.Pitch = InputPitch;
		ViewContext.Location = InputLocation;
		//UE_LOG(LogTemp, Warning, L"[ZL] ignore pitch diff a   TargetView [%.2f, %.2f]   state: %d", TargetUpperViewPitch, TargetLowerViewPitch, TargetLockState);
		return;
	}
	if (TargetUpperViewPitch < TargetUpperViewPitchRange.GetUpperBoundValue() && TargetLowerViewPitch > -HalfVerticalFOV)
	{
		// Boss is visible as a whole, ignoring the optimal correction
		ViewContext.Orientation.Pitch = InputPitch;
		ViewContext.Location = InputLocation;
		//UE_LOG(LogTemp, Warning, L"[ZL] ignore pitch diff b   TargetView [%.2f, %.2f]   Range: [%.2f, %.2f]", TargetUpperViewPitch, TargetLowerViewPitch, TargetUpperViewPitchRange.GetLowerBoundValue(), TargetUpperViewPitchRange.GetUpperBoundValue());
		return;
	}
	else if (TargetUpperViewPitchRange.Contains(TargetUpperViewPitch))
	{
		// Boss visual pitch is within the tolerance range, ignoring the optimal adjustment
		ViewContext.Orientation.Pitch = InputPitch;
		ViewContext.Location = InputLocation;
		//UE_LOG(LogTemp, Warning, L"[ZL] ignore pitch diff c   TargetView [%.2f, %.2f]   Range: [%.2f, %.2f]", TargetUpperViewPitch, TargetLowerViewPitch, TargetUpperViewPitchRange.GetLowerBoundValue(), TargetUpperViewPitchRange.GetUpperBoundValue());
		return;
	}

	/* 5th. Change input pitch */
	float BestPitchDiff = CurrentEstimatedBestPitch - PreviousEstimatedBestPitch;

	// If the target point in the field of vision crosses the limit, try to maintain the limit
	const float TargetViewPitch = EstimatedTargetViewPitch + OffsetToleranceRatio * UpdateContext.VerticalFOV * FMath::Sign(BestPitchDiff);
	const float LimitBestViewPitch = DoubleObjectTools::CalculateFixedCameraWithPitchView(CameraSchemeConfig, UpdateContext.WatchForwardUpperPoint, UpdateContext, TargetViewPitch, ViewContext);
	//const float CurrentBestPitch = ViewContext.Orientation.Pitch;
	const float CurrentBestPitch = CurrentEstimatedBestPitch;

	if ((CurrentBestPitch - InputPitch) * BestPitchDiff <= 0)
	{
		// When the optimal pitch tends to the current pitch, the current pitch is used by input
		//UE_LOG(LogTemp, Warning, L"[ZL] ignore pitch diff d    input: %.2f    ground best pitch: %.2f    BestPitchDiff: %.2f", InputPitch, CurrentBestPitch, BestPitchDiff);
		ViewContext.Orientation.Pitch = InputPitch;
		ViewContext.Location = InputLocation;
		return;
	}

	BestPitchDiff *= CameraSchemeConfig.PitchCorrect_AutoRotateScale;
	float MaxAdjustPitch = FMath::Abs(CurrentBestPitch - InputPitch);
	MaxAdjustPitch = FMath::Min(CameraSchemeConfig.PitchCorrect_MaxRotateSpeed * UpdateContext.DeltaTime, MaxAdjustPitch);
	//BestPitchDiff = FMath::Clamp(BestPitchDiff, -MaxAdjustPitch, MaxAdjustPitch);
	if (BestPitchDiff > 0)
	{
		BestPitchDiff = FMath::Min(BestPitchDiff, CameraSchemeConfig.PitchCorrect_MaxPitch - InputPitch);
		BestPitchDiff = FMath::Max(0, FMath::Min(BestPitchDiff, MaxAdjustPitch));
	}
	else
	{
		BestPitchDiff = FMath::Max(BestPitchDiff, CameraSchemeConfig.PitchCorrect_MinPitch - InputPitch);
		BestPitchDiff = FMath::Min(0, FMath::Max(BestPitchDiff, -MaxAdjustPitch));
	}

	//FVector CameraToTargetTest = UpdateContext.WatchForwardUpperPoint - InOutPOV.Location;
	//UE_LOG(LogTemp, Warning, L"[ZL] update pitch %.2f (= %.2f + %.2f)   Estimatedbestpitch: %.2f    LimitBestViewPitch: %.2f    view pitch: %.2f  [%.2f, %.2f]    TargetViewPitch: %.2f    OriTargetUpperViewPitch: %.2f"
	//	, InputPitch + BestPitchDiff, InputPitch, BestPitchDiff, CurrentBestPitch, LimitBestViewPitch
	//	, CameraToTargetTest.ToOrientationRotator().Pitch
	//	, TargetUpperViewPitchRange.GetLowerBoundValue(), TargetUpperViewPitchRange.GetUpperBoundValue(), TargetViewPitch, TargetUpperViewPitch
	//);

	ViewContext.Orientation.Pitch = InputPitch + BestPitchDiff;

	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
}

void FCameraProcessor_CameraPitch::CalculateBestCameraWithFixedPitchView(FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	const FHiViewConfig_DoubleObject& CameraSchemeConfig = UpdateContext.Scheme->GetCameraSchemeConfig();
	const float InputPitch = ViewContext.Orientation.Pitch;
	const FVector InputLocation = ViewContext.Location;

	FRotator CameraToTargetRotator = (UpdateContext.WatchForwardUpperPoint - InputLocation).ToOrientationRotator();
	const float TargetUpperViewPitch = FRotator3f::NormalizeAxis(CameraToTargetRotator.Pitch - InputPitch);			// (-180,180]
	CameraToTargetRotator = (UpdateContext.WatchForwardLowerPoint - InputLocation).ToOrientationRotator();
	const float TargetLowerViewPitch = FRotator3f::NormalizeAxis(CameraToTargetRotator.Pitch - InputPitch);			// (-180,180]

	const float HalfVerticalFOV = 0.5f * UpdateContext.VerticalFOV;
	const float TargetViewPitch = LockTargetViewPitch * UpdateContext.VerticalFOV;

	if (TargetUpperViewPitch < TargetViewPitch && TargetLowerViewPitch > -HalfVerticalFOV)
	{
		// Boss is visible as a whole, ignoring the optimal correction
		DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
		return;
	}

	const float LimitDeltaBestPitch = DoubleObjectTools::CalculateFixedCameraWithPitchView(CameraSchemeConfig, UpdateContext.WatchForwardUpperPoint, UpdateContext, TargetViewPitch, ViewContext);
	ViewContext.Orientation.Pitch += LimitDeltaBestPitch;		// Ignore all limits
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, ViewContext);
}

