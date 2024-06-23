// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/VisionerCustomView/HiVisionerView_DoubleObject.h"
#include "GameFramework/Character.h"
#include "Components/CapsuleComponent.h"
#include "Kismet/KismetMathLibrary.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Characters/VisionerCustomView/HiCameraViewUtils.h"
#include "VisionerInstance.h"


UHiVisionerView_DoubleObject::UHiVisionerView_DoubleObject(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UHiVisionerView_DoubleObject::IgnoreSmooth()
{
	bIsResetFrame = true;
	bEnableAutoRecoveryPlayerViewYawTimer = false;
	LeftUnlockTargetSightDuration = CameraSchemeConfig.AutoUnlockTargetSightDuration;
}

void UHiVisionerView_DoubleObject::Initialize_Implementation(const FVisionerInitializeContext& Context)
{
	// Initialize InView
	const int MainViewIndex = 0;
	InitializeLinkView_Internal(MainViewIndex, Context);
	const int TargetViewIndex = 1;
	InitializeLinkView_Internal(TargetViewIndex, Context);
	// Reset Parameters
	TargetCharacter = nullptr;
	ControlledCharacter = nullptr;
	AspectRatio = Context.GetVisionerInstanceObject()->AspectRatio;
}

void UHiVisionerView_DoubleObject::ReInitializeView(FVisionerUpdateContext& Context)
{
	DrivenByTargetWeight = 0.0f;
	TargetDrivenWeight = 1.0f;
	bEnableAutoFaceTargetTimer = true;
	bLockPlayerControlYaw = false;

	TargetLockState = EHiTargetLockState::Optimal;

	/* 1st Prepare update context */
	check(ControlledCharacter && TargetCharacter);
	// Calculate the optimal Yaw solution
	FVisionerViewContext BestViewContext = Context.GetVisionerInstanceObject()->GetCameraCacheView();

	FHiCameraUpdateContext_DoubleObject UpdateContext;
	UpdateContext.Scheme = this;
	UpdateContext.VerticalFOV = DoubleObjectTools::CalculateVerticleFOV(BestViewContext.GetViewFOV(), AspectRatio);
	UpdateContext.PlayerCenter = ControlledCharacter->GetActorLocation();
	UpdateContext.TargetCenter = TargetCharacter->GetActorLocation();

	FVisionerView& BestView = BestViewContext.VisionerView;
	PlayerForwardOffsetProcessor.Reset(UpdateContext, BestView);
	PlayerViewPitchProcessor.Reset(UpdateContext, BestView);
	CameraPitchProcessor.Reset(UpdateContext, BestView);
	// Calculate best pitch view
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, BestView);
	// Calculate best yaw view
	DoubleObjectTools::CalculateBestCameraWithRatioYawView(CameraSchemeConfig, UpdateContext, BestView);
	// Refresh view yaw
	DoubleObjectTools::CalculateObjectsViewYaw(BestView.Location, BestView.Orientation.Yaw, UpdateContext.PlayerCenter, UpdateContext.TargetCenter, PreviousPlayerViewYaw, PreviousTargetViewYaw);

	FVector CameraToTarget = TargetCharacter->GetActorLocation() - BestView.Location;
	float TargetViewYaw = FRotator::NormalizeAxis(BestView.Orientation.Yaw - CameraToTarget.ToOrientationRotator().Yaw);
	if (FMath::Abs(PreviousTargetViewYaw) + FMath::Abs(PreviousPlayerViewYaw) >= CameraSchemeConfig.LockTargetViewYaw + CameraSchemeConfig.LimitPlayerViewYaw)
	{
		// Find suitable player view yaw & target view yaw
		float FinalPlayerViewYaw = CameraSchemeConfig.LimitPlayerViewYaw;
		float FinalPlayerViewYawTan = FMath::Tan(FMath::DegreesToRadians(FinalPlayerViewYaw));
		float FinalTargetViewYaw = CameraSchemeConfig.LockTargetViewYaw;
		float FinalTargetViewYawTan = FMath::Tan(FMath::DegreesToRadians(FinalTargetViewYaw));
		if (FinalTargetViewYawTan > CameraSchemeConfig.ObjectsYawTanRatio * FinalPlayerViewYawTan)
		{
			FinalTargetViewYawTan = FinalPlayerViewYawTan * CameraSchemeConfig.ObjectsYawTanRatio;
			FinalTargetViewYaw = FMath::RadiansToDegrees(FMath::Atan(FinalTargetViewYawTan));
		}
		else
		{
			FinalPlayerViewYawTan = FinalTargetViewYawTan / CameraSchemeConfig.ObjectsYawTanRatio;
			FinalPlayerViewYaw = FMath::RadiansToDegrees(FMath::Atan(FinalPlayerViewYawTan));
		}

		float TargetViewYawSign = FMath::Sign(TargetViewYaw);
		FinalPlayerViewYaw *= -TargetViewYawSign;
		FinalTargetViewYaw *= TargetViewYawSign;

		// Find suitable camera yaw
		DoubleObjectTools::CalculateCameraWithFixedView(CameraSchemeConfig, UpdateContext, FinalPlayerViewYaw, FinalTargetViewYaw, BestView);
		AutoCorrectRotateYaw = FRotator3f::NormalizeAxis(BestView.Orientation.Yaw - BestView.Orientation.Yaw);
		// Refresh view yaw
		DoubleObjectTools::CalculateObjectsViewYaw(BestView.Location
			, BestView.Orientation.Yaw, UpdateContext.PlayerCenter, UpdateContext.TargetCenter, PreviousPlayerViewYaw, PreviousTargetViewYaw);
	}
	else
	{
		// Calculate best yaw view
		DoubleObjectTools::CalculateBestCameraWithRatioYawView(CameraSchemeConfig, UpdateContext, BestView);
		// Refresh view yaw
		DoubleObjectTools::CalculateObjectsViewYaw(BestView.Location
			, BestView.Orientation.Yaw, UpdateContext.PlayerCenter, UpdateContext.TargetCenter, PreviousPlayerViewYaw, PreviousTargetViewYaw);
	}
	check(FMath::Abs(PreviousPlayerViewYaw) <= CameraSchemeConfig.LimitPlayerViewYaw + 1e-4f);
	check(FMath::Abs(PreviousTargetViewYaw) <= CameraSchemeConfig.LockTargetViewYaw + 1e-4f);

	//SetCachedCameraView(EnterBestCameraPOV);

	PreviousPlayerCenter = UpdateContext.PlayerCenter;
	PreviousTargetCenter = UpdateContext.TargetCenter;
}

void UHiVisionerView_DoubleObject::Update_Implementation(FVisionerUpdateContext& Context)
{
	const int MainViewIndex = 0;
	UpdateLinkView_Internal(MainViewIndex, Context);
	ACharacter* NewControlledCharacter = Cast<ACharacter>(Context.ViewTarget);
	const int TargetViewIndex = 1;
	UpdateLinkView_Internal(TargetViewIndex, Context);
	ACharacter* NewTargetCharacter = Cast<ACharacter>(Context.ViewTarget);

	if (NewControlledCharacter != ControlledCharacter || NewTargetCharacter != TargetCharacter)
	{
		ControlledCharacter = NewControlledCharacter;
		TargetCharacter = NewTargetCharacter;
		if (ControlledCharacter && TargetCharacter)
		{
			ReInitializeView(Context);
		}
	}
}

void UHiVisionerView_DoubleObject::EvaluateRotation_Implementation(FVisionerRotationContext& ViewContext)
{
	// Do scalar
	InputDeltaRotation.Pitch = ViewContext.DeltaRotation.Pitch * CameraSchemeConfig.RotationScalar.X;
	InputDeltaRotation.Yaw = ViewContext.DeltaRotation.Yaw * CameraSchemeConfig.RotationScalar.Y;
	InputDeltaRotation.Roll = ViewContext.DeltaRotation.Roll * CameraSchemeConfig.RotationScalar.Z;
	ViewContext.ViewOrientation = ViewContext.ViewOrientation + InputDeltaRotation;
	ViewContext.DeltaRotation = FRotator::ZeroRotator;

	if (!FMath::IsNearlyEqual(TargetDrivenWeight, DrivenByTargetWeight))
	{
		const float WeightThrehold = 0.01f;
		float DeltaWeight = TargetDrivenWeight - DrivenByTargetWeight;
		float AbsDeltaWeight = FMath::Abs(DeltaWeight);
		float WeightStep = AbsDeltaWeight * CameraSchemeConfig.LockTargetSmoothSpeed * ViewContext.DeltaTime;
		if (WeightStep < WeightThrehold * ViewContext.DeltaTime)
		{
			WeightStep = WeightThrehold * ViewContext.DeltaTime;
		}
		if (WeightStep >= AbsDeltaWeight)
		{
			WeightStep = AbsDeltaWeight;
			bEnableAutoFaceTargetTimer = false;
		}

		if (TargetDrivenWeight > DrivenByTargetWeight)
		{
			if (bEnableAutoFaceTargetTimer)
			{
				float CorrectRotateYawStep = AutoCorrectRotateYaw / DeltaWeight * WeightStep;
				ViewContext.ViewOrientation.Yaw += CorrectRotateYawStep;
				AutoCorrectRotateYaw -= CorrectRotateYawStep;
			}
		}

		DrivenByTargetWeight += WeightStep * FMath::Sign(DeltaWeight);
		return;
	}

	if (TargetLockState == EHiTargetLockState::Free || !ControlledCharacter || !TargetCharacter)
	{
		return;
	}

	// Adjust the Yaw to make circular motion
	float LateralInputSign = (ControlledCharacter->GetPendingMovementInputVector().Y);
	float ErrorThreshold = 0.01f;
	CircleMoveAjustAngle = 0.0f;	// Reset
	if (bEnableCircleMove)
	{
		if (-LateralInputSign * PreviousPlayerViewYaw > CameraSchemeConfig.LimitPlayerViewYaw - ErrorThreshold || -LateralInputSign * PreviousTargetViewYaw > CameraSchemeConfig.LockTargetViewYaw - ErrorThreshold)
		{
			FVector TargetPoint = TargetCharacter->GetActorLocation();
			FVector PlayerPoint = ControlledCharacter->GetActorLocation();
			FVector PlayerToTargetDirection = TargetPoint - PlayerPoint;
			PlayerToTargetDirection.Z = 0;
			float MovementROC = PlayerToTargetDirection.Size();
			float PredictedMovementDistance = ControlledCharacter->GetCharacterMovement()->Velocity.Size() * ViewContext.DeltaTime;
			float CircularMotionCorrectAngle = ((MovementROC > 1.0f) ? FMath::RadiansToDegrees(FMath::Asin(PredictedMovementDistance * 0.5 / MovementROC)) : 0.0f);
			float AngleFromPlayerTargetVectorToCameraForward = FRotator3f::NormalizeAxis(GetCachedCameraOrientation().Yaw - CalculatePlayerToTargetYaw());			// (-180,180]
			//OutAjustAngle = -AngleFromPlayerTargetVectorToCameraForward + LateralInputSign * CircularMotionCorrectAngle;
			CircleMoveAjustAngle = -LateralInputSign * CircularMotionCorrectAngle;
			ViewContext.ViewOrientation.Yaw += CircleMoveAjustAngle;
		}
	}

	//UE_LOG(LogTemp, Warning, L"[ZL] process yaw   PlayerToTarget %.2f (Delta %.2f)   Adjust: %.3f      CurrectDis: %.2f      PlayerToTarget: %.2f     Camera: %.2f", CurrentPlayerToTargetYaw, CaptureTargetYawOffset, OutAjustAngle, PlayerToTargetDirection.Size(), PlayerToTargetRotator.Yaw, OutViewRotation.Yaw);
}

void UHiVisionerView_DoubleObject::EvaluateView_Implementation(FVisionerViewContext& ViewContext)
{	
	if (!ControlledCharacter || !TargetCharacter)
	{
		return;
	}


	//FMinimalViewInfo& InOutPOV = ViewContext.POV;
	FVisionerView& OutputView = ViewContext.VisionerView;

	if (bEnableCircleMove)
	{
		OutputView.Orientation.Yaw += CircleMoveAjustAngle;
	}
	// When there is an automatic correction angle transition
	//      The final calculated angle needs to be fixed with #AutoCorrectRotateYaw to ensure that the character view is smooth
	if (bEnableAutoFaceTargetTimer)
	{
		OutputView.Orientation.Yaw += AutoCorrectRotateYaw;
	}

	UCapsuleComponent* PlayerCapsule = ControlledCharacter->GetCapsuleComponent();
	check(PlayerCapsule);
	UCapsuleComponent* TargetCapsule = TargetCharacter->GetCapsuleComponent();
	check(TargetCapsule);
	USkeletalMeshComponent* TargetMesh = TargetCharacter->GetMesh();
	check(TargetMesh);

	//UE_LOG(LogTemp, Warning, L"[ZL] check visible: %d    hidden: %d", TargetMesh->IsVisible(), TargetCharacter->IsHidden());

	/* Prepare update context */
	FHiCameraUpdateContext_DoubleObject UpdateContext;

	UpdateContext.Scheme = this;
	UpdateContext.DeltaTime = ViewContext.DeltaTime;
	UpdateContext.VerticalFOV = DoubleObjectTools::CalculateVerticleFOV(OutputView.FOV, AspectRatio);
	UpdateContext.PlayerCenter = OutputView.Location; //ControlledCharacter->GetActorLocation();
	UpdateContext.TargetCenter = TargetMesh->Bounds.Origin; //TargetCapsule->GetComponentLocation();
	UpdateContext.TargetLower = UpdateContext.TargetCenter - FVector(0, 0, TargetMesh->Bounds.BoxExtent.Z);
	UpdateContext.TargetUpper = UpdateContext.TargetLower + FVector(0, 0, TargetMesh->Bounds.BoxExtent.Z * 2);
	UpdateContext.PlayerHeight = PlayerCapsule->GetScaledCapsuleHalfHeight() * 2;
	UpdateContext.InputDeltaRotation = InputDeltaRotation;
	UpdateContext.PlayerMovementMode = ControlledCharacter->GetCharacterMovement()->MovementMode;
	UpdateContext.bHasPlayerVelocity = !ControlledCharacter->GetCharacterMovement()->Velocity.IsNearlyZero();
	UpdateContext.bIsTargetHidden = TargetCharacter->IsHidden();

	// Project target to the ray from player with direction of camera forward
	const FVector CameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, OutputView.Orientation.Yaw, 0.0f));
	const FVector CameraHorizontalRight = FVector(-CameraHorizontalForward.Y, CameraHorizontalForward.X, 0);

	FVector TargetToPlayer = UpdateContext.PlayerCenter - UpdateContext.TargetLower;

	float TargetToPlayerRightOffset = CameraHorizontalRight | TargetToPlayer;
	UpdateContext.WatchForwardLowerPoint = UpdateContext.TargetLower + TargetToPlayerRightOffset * CameraHorizontalRight;
	UpdateContext.WatchForwardUpperPoint = UpdateContext.WatchForwardLowerPoint + (UpdateContext.TargetUpper - UpdateContext.TargetLower);

	if (UpdateContext.bIsTargetHidden && TargetLockState != EHiTargetLockState::Free)
	{
		LeaveDrivenByTarget();
	}

	/* 1st: Calculate the current player view parameters */
	/* 1.1 Forward offset update */
	PlayerForwardOffsetProcessor.Update(UpdateContext, OutputView);

	/* 1.2 Player View Yaw update */
	if (bEnableAutoRecoveryPlayerViewYawTimer)
	{
		PlayerViewYawRecoveryLeft -= UpdateContext.DeltaTime;
		if (PlayerViewYawRecoveryLeft <= 0)
		{
			bEnableAutoRecoveryPlayerViewYawTimer = false;
			PreviousPlayerViewYaw = 0.0f;
		}
		else
		{
			float DurationPct = PlayerViewYawRecoveryLeft / PlayerViewYawRecoveryDuration;
			float BlendPct = FMath::InterpEaseInOut(0.f, 1.f, DurationPct, 2.0f);
			PreviousPlayerViewYaw = PlayerViewYawRecoveryTarget * BlendPct;
		}
	}

	/* 1.3 Player View Pitch update */
	PlayerViewPitchProcessor.Update(UpdateContext, OutputView);

	/* 2nd. Process pitch */
	CameraPitchProcessor.Update(UpdateContext, OutputView);
	// Update camera location to player back with fixed #DistanceToPlayerPoint & #CameraPitch & #PlayerViewPitch
	DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, OutputView);

	/* 3rd. Player rotate camera */
	if (!UpdateContext.InputDeltaRotation.IsNearlyZero() || !FMath::IsNearlyEqual(TargetDrivenWeight, DrivenByTargetWeight) || TargetLockState == EHiTargetLockState::Free)
	{
		// Processing camera position based on [Camera Yaw] & [Player View Yaw]
		DoubleObjectTools::CalculateCameraWithFixedPlayerView(CameraSchemeConfig, UpdateContext, PreviousPlayerViewYaw, OutputView);

		// Refresh view yaw
		DoubleObjectTools::CalculateObjectsViewYaw(OutputView.Location, OutputView.Orientation.Yaw, UpdateContext.PlayerCenter, UpdateContext.TargetCenter, PreviousPlayerViewYaw, PreviousTargetViewYaw);

		// Update lock state (Delay calculation CalculateObjectsViewYaw is required, and the value may be updated)
		UpdateTargetLockStateWithRotation(UpdateContext, ViewContext);
	}
	else
	{
		// Processing camera position based on [Camera Yaw] & [Player View Yaw] & [Target View Yaw]
		bool bRetVal = CalculateBestCameraWithYawView(UpdateContext, OutputView);

		//if (bRetVal)
		//{
			// Update target lock state by current view
		UpdateTargetLockStateWithoutRotation(UpdateContext, ViewContext);
		//}
		//else
		//{
		//	LeaveDrivenByTarget();
		//}

		// Refresh view yaw
		DoubleObjectTools::CalculateObjectsViewYaw(OutputView.Location, OutputView.Orientation.Yaw, UpdateContext.PlayerCenter, UpdateContext.TargetCenter, PreviousPlayerViewYaw, PreviousTargetViewYaw);

		// 3rd. Handling displacement out of the screen
		bool bNeedRotateCamera = false;
		if (FMath::Abs(PreviousTargetViewYaw) > CameraSchemeConfig.LockTargetViewYaw)
		{
			PreviousTargetViewYaw = FMath::Clamp(PreviousTargetViewYaw, -CameraSchemeConfig.LockTargetViewYaw, CameraSchemeConfig.LockTargetViewYaw);
			bNeedRotateCamera = true;
		}

		if (FMath::Abs(PreviousPlayerViewYaw) > CameraSchemeConfig.LimitPlayerViewYaw)
		{
			PreviousPlayerViewYaw = FMath::Clamp(PreviousPlayerViewYaw, -CameraSchemeConfig.LimitPlayerViewYaw, CameraSchemeConfig.LimitPlayerViewYaw);
			bNeedRotateCamera = true;
		}

		if (bNeedRotateCamera)
		{
			const FVector InputLocation = OutputView.Location;
			const float InputYaw = OutputView.Orientation.Yaw;
			DoubleObjectTools::CalculateCameraWithFixedView(CameraSchemeConfig, UpdateContext, PreviousPlayerViewYaw, PreviousTargetViewYaw, OutputView);
			//UE_LOG(LogTemp, Warning, L"[ZL] calc with PlayerYaw: %.2f   TargetYaw: %.2f   CameraYaw: %.2f", PreviousPlayerViewYaw, PreviousTargetViewYaw, OutputView.Orientation.Yaw);

			const float MaxYawCorrectDelta = CameraSchemeConfig.MaxYawCorrectSpeed * UpdateContext.DeltaTime;
			if (FMath::Abs(InputYaw - OutputView.Orientation.Yaw) > MaxYawCorrectDelta && !bLockPlayerControlYaw && !bIsResetFrame)
			{
				// In the locked state, if the automatic correction speed is exceeded, the locked state will be automatically exited
				float DeltaYaw = FRotator3f::NormalizeAxis(OutputView.Orientation.Yaw - InputYaw);
				DeltaYaw = FMath::Clamp(DeltaYaw, -MaxYawCorrectDelta, MaxYawCorrectDelta);
				OutputView.Orientation.Yaw = InputYaw + DeltaYaw;
				DoubleObjectTools::CalculateCameraWithPlayerViewPitch(UpdateContext, CameraSchemeConfig.DistanceToPlayerPoint, OutputView);
				DoubleObjectTools::CalculateCameraWithFixedPlayerView(CameraSchemeConfig, UpdateContext, PreviousPlayerViewYaw, OutputView);
			}
		}
	}

	/*** 3rd. Cache values for next frame  ***/

	UpdateTargetLockStateWithTimer(UpdateContext, OutputView);

	SetCachedCameraView(ViewContext);

	PreviousPlayerCenter = UpdateContext.PlayerCenter;
	PreviousTargetCenter = UpdateContext.TargetCenter;

	// Finally, in order to integrate, we should restore the angle of complement
	if (bEnableAutoFaceTargetTimer)
	{
		OutputView.Orientation.Yaw -= AutoCorrectRotateYaw;
	}

	//UE_LOG(LogTemp, Warning, L"[ZL] double target get -- Loc: %s  Rot: %s   Reset: %d", *InOutPOV.Location.ToString(), *ViewContext.Orientation.ToString(), bIsResetFrame);

	//const FVector CheckCameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, ViewContext.Orientation.Yaw, 0.0f));
	//float DistanceToPlayer = (UpdateContext.PlayerCenter - InOutPOV.Location) | CheckCameraHorizontalForward;
	//{
	//	UE_LOG(LogTemp, Warning, L"[ZL] <Control: %d>  DoubleObject::Update  After   Distance: %.3f    LockState: %d    PlayerYaw: %.3f    MonsterYaw: %.3f"
	//		, ControlledCharacter->HasAuthority(), DistanceToPlayer, TargetLockState, PreviousPlayerViewYaw, PreviousTargetViewYaw
	//	);
	//}

	bIsResetFrame = false;

	/*** 4nd: Debug ***/

	//{
	//	// Debug Draw Mesh Bounds
	//	UWorld* World = ControlledCharacter->GetWorld();
	//	check(World);

	//	::DrawDebugCapsule(World, UpdateContext.PlayerCenter, PlayerCapsule->GetScaledCapsuleHalfHeight(), PlayerCapsule->GetScaledCapsuleRadius(), PlayerCapsule->GetComponentRotation().Quaternion(), FColor::Green);
	//	::DrawDebugBox(World, TargetMesh->Bounds.Origin, TargetMesh->Bounds.BoxExtent, TargetMesh->GetComponentRotation().Quaternion(), FColor::Green);

	//	FVector PlayerYawCheckPoint = UpdateContext.PlayerCenter;
	//	FVector TargetYawCheckPoint = UpdateContext.TargetCenter;
	//	PlayerYawCheckPoint.Z = TargetYawCheckPoint.Z = InOutPOV.Location.Z;
	//	::DrawDebugLine(World, PlayerYawCheckPoint, TargetYawCheckPoint, FColor::Red);
	//}
}

float UHiVisionerView_DoubleObject::CalculatePlayerToTargetYaw()
{
	FVector TargetPoint = TargetCharacter->GetActorLocation();
	FVector PlayerPoint = ControlledCharacter->GetActorLocation();

	FVector PlayerToTargetDirection = TargetPoint - PlayerPoint;
	FRotator PlayerToTargetRotator = UKismetMathLibrary::Conv_VectorToRotator(PlayerToTargetDirection);

	return PlayerToTargetRotator.Yaw;
}

/*
 *  Move camera location to suit view angle with Fixed player view
 *  - InputPOV
 *        rotation is the control result of the current frame
 *        location is the value of the previous frame
 */
bool UHiVisionerView_DoubleObject::CalculateBestCameraWithYawView(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	/*
	 * 2nd. recalculate TargetYawInPlayerBackView, to ignore player movement
	 * 	  Target Yaw in the "Player Back View"
	 *    Player Back View: the view that the camera is directly behind the character by horizontal moving.
	 */
	const FRotator PreviousCameraHorizontalRotator(0.0f, GetCachedCameraOrientation().Yaw, 0.0f);
	FVector PreviousCameraRightDirection = UKismetMathLibrary::GetRightVector(PreviousCameraHorizontalRotator);
	FVector PreviousCameraToPlayer = PreviousPlayerCenter - GetCachedCameraLocation();
	FVector PreviousCameraLocationBehindPlayer = GetCachedCameraLocation() + PreviousCameraToPlayer.ProjectOnToNormal(PreviousCameraRightDirection);
	float PreviousTargetYawBehindPlayer = (UpdateContext.TargetCenter - PreviousCameraLocationBehindPlayer).ToOrientationRotator().Yaw;
	float TargetYawInPlayerBackView = FRotator3f::NormalizeAxis(GetCachedCameraOrientation().Yaw - PreviousTargetYawBehindPlayer);	// (-180,180]
	PreviousTargetViewYaw = (UpdateContext.TargetCenter - GetCachedCameraLocation()).ToOrientationRotator().Yaw;
	PreviousTargetViewYaw = FRotator3f::NormalizeAxis(GetCachedCameraOrientation().Yaw - PreviousTargetViewYaw);					// (-180,180]

	/* 3rd. recalculate PlayerViewYaw & TargetViewYaw */
	bool bUseFixedPlayerView = true;
	{
		// Recalculate TargetYawInPlayerBackView after characters' movement
		float CurrentTargetYaw = (UpdateContext.TargetCenter - ViewContext.Location).ToOrientationRotator().Yaw;
		float NewTargetYawInPlayerBackView = FRotator3f::NormalizeAxis(ViewContext.Orientation.Yaw - CurrentTargetYaw);			// (-180,180]

		// In the case of opposite displacement, if the line between two objectss passes the forward direction of the camera, then switch to Optimal
		if (TargetYawInPlayerBackView * NewTargetYawInPlayerBackView <= 0 && PreviousPlayerViewYaw * PreviousTargetViewYaw < 0)
		{
			TargetLockState = EHiTargetLockState::Optimal;
		}

		if (TargetLockState == EHiTargetLockState::Common)
		{
			// Do Lerp
			if (PreviousPlayerViewYaw * PreviousTargetViewYaw < 0 && NewTargetYawInPlayerBackView < TargetYawInPlayerBackView)
			{
				PreviousPlayerViewYaw = PreviousPlayerViewYaw * (NewTargetYawInPlayerBackView / TargetYawInPlayerBackView);
			}
			else
			{
				bUseFixedPlayerView = false;
			}
		}
	}

	if (TargetLockState == EHiTargetLockState::Optimal)
	{
		// Adjust the camera position based on the [Yaw] value in the field of view
		DoubleObjectTools::CalculateBestCameraWithRatioYawView(CameraSchemeConfig, UpdateContext, ViewContext);
	}
	else
	{
		if (bUseFixedPlayerView)
		{
			DoubleObjectTools::CalculateCameraWithFixedPlayerView(CameraSchemeConfig, UpdateContext, PreviousPlayerViewYaw, ViewContext);
		}
		else
		{
			DoubleObjectTools::CalculateCameraWithFixedTargetView(CameraSchemeConfig, UpdateContext, PreviousTargetViewYaw, ViewContext);
		}
	}
	return true;
}

void UHiVisionerView_DoubleObject::UpdateTargetLockStateWithRotation(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerViewContext& ViewContext)
{
	// If the rotation angle is controlled by player, the player's angle will be maintained.
	// No matter how the player and target move

	if (TargetLockState == EHiTargetLockState::Optimal)
	{
		TargetLockState = EHiTargetLockState::Common;
	}

	FVector PlayerToTarget = UpdateContext.PlayerCenter - UpdateContext.TargetCenter;
	PlayerToTarget.Z = 0.0f;
	const float PlayerToTargetHorizontalDistance = PlayerToTarget.Size();

	if (FMath::Abs(PreviousTargetViewYaw) > CameraSchemeConfig.LockTargetViewYaw || PlayerToTargetHorizontalDistance < CameraSchemeConfig.NearestLockTargetDistance)
	{
		if (TargetLockState != EHiTargetLockState::Free)
		{
			LeaveDrivenByTarget();
		}
	}
	else
	{
		if (TargetLockState == EHiTargetLockState::Free && !UpdateContext.bIsTargetHidden && PlayerToTargetHorizontalDistance > CameraSchemeConfig.NearestLockTargetDistance)
		{
			EnterDrivenByTarget(ViewContext);
		}
	}
}

void UHiVisionerView_DoubleObject::UpdateTargetLockStateWithTimer(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerView& ViewContext)
{
	if (!bEnableAutoLeaveDrivenTimer)
	{
		return;
	}

	if (FMath::Abs(PreviousTargetViewYaw) > CameraSchemeConfig.LockTargetViewYaw)
	{
		LeftUnlockTargetSightDuration -= UpdateContext.DeltaTime;

		if (LeftUnlockTargetSightDuration < 0)
		{
			bEnableAutoLeaveDrivenTimer = false;
			if (FMath::IsNearlyZero(PreviousPlayerViewYaw))
			{
				PreviousPlayerViewYaw = 0.0f;
			}
			else
			{
				PlayerViewYawRecoveryDuration = FMath::Abs(PreviousPlayerViewYaw) / CameraSchemeConfig.PlayerViewYawRecoverySpeed;
				PlayerViewYawRecoveryLeft = PlayerViewYawRecoveryDuration;
				PlayerViewYawRecoveryTarget = PreviousPlayerViewYaw;
				bEnableAutoRecoveryPlayerViewYawTimer = true;
			}
			// At present, locking can only be released by active rotation
			//LeaveDrivenByTarget();
		}
	}
	else
	{
		const FVector CameraHorizontalForward = UKismetMathLibrary::GetForwardVector(FRotator(0.0f, ViewContext.Orientation.Yaw, 0.0f));

		FVector CameraToPlayer = UpdateContext.PlayerCenter - ViewContext.Location;
		FVector CameraToTarget = UpdateContext.TargetCenter - ViewContext.Location;

		float TargetForwardLength = CameraToTarget | CameraHorizontalForward;
		float PlayerForwardLength = CameraToPlayer | CameraHorizontalForward;

		if (TargetForwardLength > PlayerForwardLength)
		{
			bEnableAutoLeaveDrivenTimer = false;
			bEnableAutoRecoveryPlayerViewYawTimer = false;
			TargetLockState = EHiTargetLockState::Common;
		}
	}
}

void UHiVisionerView_DoubleObject::UpdateTargetLockStateWithoutRotation(const FHiCameraUpdateContext_DoubleObject& UpdateContext, FVisionerViewContext& ViewContext)
{
	float TargetViewYawTan = FMath::Tan(FMath::DegreesToRadians(PreviousTargetViewYaw));
	float PlayerViewYawTan = FMath::Tan(FMath::DegreesToRadians(PreviousPlayerViewYaw));
	float ObjectsTanRatioError = FMath::Abs(TargetViewYawTan + PlayerViewYawTan * CameraSchemeConfig.ObjectsYawTanRatio);
	const float SwitchStateThreshold = 0.0001f;

	if (TargetLockState == EHiTargetLockState::Common)
	{
		if (UpdateContext.InputDeltaRotation.IsNearlyZero() && ObjectsTanRatioError < SwitchStateThreshold && UpdateContext.bHasPlayerVelocity)
		{
			TargetLockState = EHiTargetLockState::Optimal;
		}
	}
	else  //	TargetLockState == EHiTargetLockState::Optimal
	{
		if (ObjectsTanRatioError >= SwitchStateThreshold)
		{
			TargetLockState = EHiTargetLockState::Common;
		}
	}

	FVector PlayerToTarget = UpdateContext.PlayerCenter - UpdateContext.TargetCenter;
	PlayerToTarget.Z = 0.0f;
	const float PlayerToTargetHorizontalDistance = PlayerToTarget.Size();

	if (PlayerToTargetHorizontalDistance < CameraSchemeConfig.NearestLockTargetDistance)
	{
		TargetLockState = EHiTargetLockState::Free;
	}
}

void UHiVisionerView_DoubleObject::EnterDrivenByTarget(const FVisionerViewContext& ViewContext)
{
	TargetDrivenWeight = 1.0f;

	check(ControlledCharacter && TargetCharacter);

	// Calculate the optimal Yaw solution
	FHiCameraUpdateContext_DoubleObject UpdateContext;
	UpdateContext.PlayerCenter = ControlledCharacter->GetActorLocation();
	UpdateContext.TargetCenter = TargetCharacter->GetActorLocation();

	if (FMath::IsNearlyZero(DrivenByTargetWeight))
	{
		PreviousPlayerViewYaw = 0.0f;
		AutoCorrectRotateYaw = 0.0f;
	}

	SetCachedCameraView(ViewContext);

	PreviousPlayerCenter = UpdateContext.PlayerCenter;
	PreviousTargetCenter = UpdateContext.TargetCenter;

	bEnableAutoRecoveryPlayerViewYawTimer = false;
	bEnableAutoLeaveDrivenTimer = false;

	TargetLockState = EHiTargetLockState::Common;
}

void UHiVisionerView_DoubleObject::LeaveDrivenByTarget()
{
	bEnableAutoLeaveDrivenTimer = true;
	bEnableAutoRecoveryPlayerViewYawTimer = false;
	LeftUnlockTargetSightDuration = CameraSchemeConfig.AutoUnlockTargetSightDuration;
	TargetLockState = EHiTargetLockState::Free;

	//TargetDrivenWeight = 0.0f;
	//AutoCorrectRotateYaw = 0.0f;
}

/********************************* External controls for animation events ***************************************************/

void UHiVisionerView_DoubleObject::LockControlPitch(bool bEnabled, float InLockTargetViewPitch/* = 0.0f*/)
{
	CameraPitchProcessor.LockControlPitch(bEnabled, InLockTargetViewPitch);
}

void UHiVisionerView_DoubleObject::LockControlYaw(bool bEnabled)
{
	bLockPlayerControlYaw = bEnabled;
}
