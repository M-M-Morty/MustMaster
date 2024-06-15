// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/HiPlayerCameraManager.h"
#include "Characters/HiCharacter.h"
#include "Characters/HiPlayerController.h"
#include "Component/HiCharacterDebugComponent.h"
#include "Characters/Camera/HiPlayerCameraBehavior.h"
#include "Kismet/KismetMathLibrary.h"
#include "IXRTrackingSystem.h" // for IsHeadTrackingAllowed()
#include "Characters/Camera/HiScreenAreaCameraController.h"
#include "Characters/Camera/CameraPostProcessorBase.h"
#include "Component/HiLocomotionComponent.h"
#include "Component/HiDoubleObjectCameraComponent.h"
#include "CameraAnimationCameraModifier.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "Characters/Camera/HiCameraViewUpdater.h"


#if WITH_PLUGINS_VISIONER
#include "VisionerInstance.h"
#endif

const FName NAME_CameraBehavior(TEXT("CameraBehavior"));

AHiPlayerCameraManager::AHiPlayerCameraManager()
{
	CameraBehavior = CreateDefaultSubobject<USkeletalMeshComponent>(NAME_CameraBehavior);
	CameraBehavior->SetupAttachment(GetRootComponent());
	CameraBehavior->bHiddenInGame = true;
}

void AHiPlayerCameraManager::BeginPlay()
{
	Super::BeginPlay();

	for (UCameraPostProcessorBase* PostProcessor : CameraPostProcessors)
	{
		PostProcessor->Initialize(this);
	}

#if WITH_PLUGINS_VISIONER
	if (VisionerScriptInstance)
	{
		check(VisionerScriptInstance->GetOwningCameraManager());
		VisionerScriptInstance->BeginPlay();
	}
#endif
}

void AHiPlayerCameraManager::BeginDestroy()
{
	if (CustomViewUpdater)
	{
		CustomViewUpdater = nullptr;
	}
	Super::BeginDestroy();
}

void AHiPlayerCameraManager::PostRegisterAllComponents()
{
	Super::PostRegisterAllComponents();

#if WITH_PLUGINS_VISIONER
	if (!VisionerBlueprintClass)
	{
		//GEngine->AddOnScreenDebugMessage(-1, 15.0f, FColor::Red, TEXT("The Visioner blueprint of this VisionerCameraManager is empty!"));
		UE_LOG(LogTemp, Log, TEXT("Missing visioner blueprint"));
	}
	else
	{
		VisionerScriptInstance = NewObject<UVisionerInstance>(this, VisionerBlueprintClass);
		VisionerScriptInstance->InitializeVisioner(this);
	}
#endif
}

void AHiPlayerCameraManager::OnPossess_Implementation(AHiCharacter* NewCharacter)
{
	// Set "Controlled Pawn" when Player Controller Possesses new character. (called from Player Controller)
	check(NewCharacter);
	bool bResetCameraCache = true;
	if (ControlledCharacter)
	{
		bResetCameraCache = false;
		OnUnPossess();
	}
	ControlledCharacter = NewCharacter;

	// Update references in the Camera Behavior AnimBP.
	UHiPlayerCameraBehavior* CastedBehv = Cast<UHiPlayerCameraBehavior>(CameraBehavior->GetAnimInstance());
	if (CastedBehv)
	{
		TObjectPtr<UHiLocomotionComponent> LocomotionComponent = NewCharacter->GetLocomotionComponent();
		if (LocomotionComponent)
		{
			LocomotionComponent->OnMovementStateChangedDelegate.AddUniqueDynamic(
				CastedBehv, &UHiPlayerCameraBehavior::SetMovementState);
			LocomotionComponent->SetCameraBehavior(CastedBehv);
			CastedBehv->MovementState = LocomotionComponent->GetMovementState();
			CastedBehv->MovementAction = LocomotionComponent->GetMovementAction();
			CastedBehv->Gait = LocomotionComponent->GetGait();
			CastedBehv->SetRotationMode(LocomotionComponent->GetRotationMode());

			if (bResetCameraCache)
			{
				SmoothedFov = DefaultFOV;
			}
		}

		CastedBehv->OnPossess(NewCharacter);
	}
	
	// Initial position
	const FVector& TPSLoc = ControlledCharacter->GetThirdPersonPivotTarget().GetLocation();
	SetActorLocation(TPSLoc);
	if (bResetCameraCache)
	{
		SmoothedPivotTarget.SetLocation(TPSLoc);
	}
	
	HiCharacterDebugComponent = ControlledCharacter->FindComponentByClass<UHiCharacterDebugComponent>();
	ResetCameraTarget();
}

void AHiPlayerCameraManager::OnUnPossess_Implementation()
{
	UHiPlayerCameraBehavior* CastedBehv = Cast<UHiPlayerCameraBehavior>(CameraBehavior->GetAnimInstance());
	if (!CastedBehv)
	{
		return;
	}
	if (!ControlledCharacter)
	{
		return;
	}
	TObjectPtr<UHiLocomotionComponent> LocomotionComponent = ControlledCharacter->GetLocomotionComponent();
	if (!LocomotionComponent)
	{
		return;
	}
	LocomotionComponent->OnMovementStateChangedDelegate.RemoveDynamic(
		CastedBehv, &UHiPlayerCameraBehavior::SetMovementState);
	ControlledCharacter = nullptr;
	ResetCameraTarget();
}

float AHiPlayerCameraManager::GetCameraBehaviorParam(FName CurveName) const
{
	UAnimInstance* Inst = CameraBehavior->GetAnimInstance();
	if (Inst)
	{
		return Inst->GetCurveValue(CurveName);
	}
	return 0.0f;
}

void AHiPlayerCameraManager::ResetCameraTarget()
{
	for (TObjectPtr<UCameraPostProcessorBase> PostProcessor : CameraPostProcessors)
	{
		PostProcessor->OnTargetChanged(ControlledCharacter);
	}
}

void AHiPlayerCameraManager::ProcessModifierViewRotation(float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot)
{
	for (int32 ModifierIdx = 0; ModifierIdx < ModifierList.Num(); ModifierIdx++)
	{
		if (ModifierList[ModifierIdx] != NULL &&
			!ModifierList[ModifierIdx]->IsDisabled())
		{
			if (ModifierList[ModifierIdx]->ProcessViewRotation(ViewTarget.Target, DeltaTime, OutViewRotation, OutDeltaRot))
			{
				break;
			}
		}
	}
}

void AHiPlayerCameraManager::ProcessLimitRotation(FRotator& OutViewRotation)
{
	// Limit euler angles
	const bool bIsHeadTrackingAllowed =
		GEngine->XRSystem.IsValid() &&
		(GetWorld() != nullptr ? GEngine->XRSystem->IsHeadTrackingAllowedForWorld(*GetWorld()) : GEngine->XRSystem->IsHeadTrackingAllowed());
	if (bIsHeadTrackingAllowed)
	{
		// With the HMD devices, we can't limit the view pitch, because it's bound to the player's head.  A simple normalization will suffice
		OutViewRotation.Normalize();
	}
	else
	{
		// Limit Player View Axes
		LimitViewPitch(OutViewRotation, ViewPitchMin, ViewPitchMax);
		LimitViewYaw(OutViewRotation, ViewYawMin, ViewYawMax);
		LimitViewRoll(OutViewRotation, ViewRollMin, ViewRollMax);
	}
}

void AHiPlayerCameraManager::ProcessViewRotation(float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot)
{
	FRotator DeltaRotCache = OutDeltaRot;

	if (CustomViewUpdater)
	{
		OutViewRotation = CustomViewUpdater->ProcessInputRotation(DeltaTime, OutViewRotation, OutDeltaRot);
		OutDeltaRot = FRotator::ZeroRotator;
	}
	else if (VisionerScriptInstance)
	{
		EvaluateVisionerRotation(DeltaTime, OutViewRotation, OutDeltaRot);

		if (ControlledCharacter)
		{
			ControlledCharacter->AdjustInputAfterProcessView(OutViewRotation, 0.0f);
		}
	}
	else
	{
		ProcessModifierViewRotation(DeltaTime, OutViewRotation, OutDeltaRot);
	}
}

void AHiPlayerCameraManager::ApplyCustomViewUpdater(TSubclassOf<UHiCameraViewUpdater> ViewUpdaterClass, const FAlphaBlendArgs& BlendInArgs)
{
	if (CustomViewUpdater)
	{
		CustomViewUpdater->StopUpdater();
		CustomViewUpdater = nullptr;
	}
	if (ViewUpdaterClass)
	{
		CustomViewUpdater = NewObject<UHiCameraViewUpdater>(this, ViewUpdaterClass);
	}
	if (CustomViewUpdater)
	{
		CustomViewUpdater->StartUpdater(this);
	}
	// Do Reset
	CustomViewBlend = FAlphaBlend(BlendInArgs);
	CachedCustomCameraView = GetCameraCacheView();
}

FMinimalViewInfo AHiPlayerCameraManager::ApplyCameraViewModifiers(float DeltaTime, FMinimalViewInfo InView)
{
	ApplyCameraModifiers(DeltaTime, InView);
	return InView;
}

// 最上层的Update，会基于外部定制的Updater与基础逻辑进行混合
void AHiPlayerCameraManager::UpdateCamera(float DeltaTime)
{
	if (!CustomViewBlend.IsComplete())
	{
		CustomViewBlend.Update(DeltaTime);

		if (CustomViewBlend.IsComplete() && CustomViewUpdater)
		{
			CustomViewUpdater->OnUpdaterFullyBlended();
		}
	}

	FMinimalViewInfo MainCameraView;
	if (CustomViewUpdater)
	{
		MainCameraView = CustomViewUpdater->ProcessCameraView(DeltaTime);
	}
	else
	{
		Super::UpdateCamera(DeltaTime);
		MainCameraView = GetCameraCacheView();
	}

	if (!CustomViewBlend.IsComplete())
	{
		MainCameraView.BlendViewInfo(CachedCustomCameraView, CustomViewBlend.GetDesiredValue() - CustomViewBlend.GetAlpha());
	}

	FillCameraCache(MainCameraView);
	SetActorLocationAndRotation(MainCameraView.Location, MainCameraView.Rotation, false);
}

// In order to develop the final camera controller, refactoring needs to start with this function.
void AHiPlayerCameraManager::DoUpdateCamera(float DeltaTime)
{
	 // Use last frame's POV
	FMinimalViewInfo CameraView = GetCameraCacheView();
	CameraView.Rotation = GetOwningPlayerController()->GetControlRotation();

	if (ACameraActor* CamActor = Cast<ACameraActor>(ViewTarget.Target))
	{
		// Viewing through a camera actor.
		CamActor->GetCameraComponent()->GetCameraView(DeltaTime, CameraView);
	}
	else if (VisionerScriptInstance)
	{
		// 正式框架的开始
		EvaluateVisionerView(DeltaTime, CameraView);

		// Todo: Move to node
		for (int32 ModifierIdx = 0; ModifierIdx < ModifierList.Num(); ++ModifierIdx)
		{
			if (UCameraAnimationCameraModifier* CameraAnimationModifier = Cast<UCameraAnimationCameraModifier>(ModifierList[ModifierIdx]))
			{
				CameraAnimationModifier->UpdateSlot(DeltaTime, CameraView);
				break;
			}
		}

		ApplyCameraModifiers(DeltaTime, CameraView);
	}
	else
	{
		// 原始框架
		DoUpdateClassicCamera(DeltaTime, CameraView);
	}

	// The yaw & pitch angle will be corrected
	FRotator NewControlRotation = CameraView.Rotation;
	NewControlRotation.Roll = 0.0f;
	GetOwningPlayerController()->SetControlRotation(NewControlRotation);

	// Post Process
	FVisionerEvaluateContext Output;
	Output.POV = CameraView;
	Output.ViewTarget = ControlledCharacter;
	for (TObjectPtr<UCameraPostProcessorBase> PostProcessor : CameraPostProcessors)
	{
		PostProcessor->Process(DeltaTime, Output);
	}

	// Cache results
	FillCameraCache(CameraView);
}

// This function is copied from the parent class.
void AHiPlayerCameraManager::DoUpdateClassicCamera(const float DeltaTime, FMinimalViewInfo& NewPOV)
{
	NewPOV = ViewTarget.POV;

	// update color scale interpolation
	if (bEnableColorScaleInterp)
	{
		float BlendPct = FMath::Clamp((GetWorld()->TimeSeconds - ColorScaleInterpStartTime) / ColorScaleInterpDuration, 0.f, 1.0f);
		ColorScale = FMath::Lerp(OriginalColorScale, DesiredColorScale, BlendPct);
		// if we've maxed
		if (BlendPct == 1.0f)
		{
			// disable further interpolation
			bEnableColorScaleInterp = false;
		}
	}

	// Don't update outgoing viewtarget during an interpolation when bLockOutgoing is set.
	if ((PendingViewTarget.Target == NULL) || !BlendParams.bLockOutgoing)
	{
		// Update current view target
		ViewTarget.CheckViewTarget(PCOwner);
		UpdateViewTarget(ViewTarget, DeltaTime);
	}

	// our camera is now viewing there
	NewPOV = ViewTarget.POV;

	// if we have a pending view target, perform transition from one to another.
	if (PendingViewTarget.Target != NULL)
	{
		BlendTimeToGo -= DeltaTime;

		// Update pending view target
		PendingViewTarget.CheckViewTarget(PCOwner);
		UpdateViewTarget(PendingViewTarget, DeltaTime);

		// blend....
		if (BlendTimeToGo > 0)
		{
			float DurationPct = (BlendParams.BlendTime - BlendTimeToGo) / BlendParams.BlendTime;

			float BlendPct = 0.f;
			switch (BlendParams.BlendFunction)
			{
			case VTBlend_Linear:
				BlendPct = FMath::Lerp(0.f, 1.f, DurationPct);
				break;
			case VTBlend_Cubic:
				BlendPct = FMath::CubicInterp(0.f, 0.f, 1.f, 0.f, DurationPct);
				break;
			case VTBlend_EaseIn:
				BlendPct = FMath::Lerp(0.f, 1.f, FMath::Pow(DurationPct, BlendParams.BlendExp));
				break;
			case VTBlend_EaseOut:
				BlendPct = FMath::Lerp(0.f, 1.f, FMath::Pow(DurationPct, 1.f / BlendParams.BlendExp));
				break;
			case VTBlend_EaseInOut:
				BlendPct = FMath::InterpEaseInOut(0.f, 1.f, DurationPct, BlendParams.BlendExp);
				break;
			case VTBlend_PreBlended:
				BlendPct = 1.0f;
				break;
			default:
				break;
			}

			// Update pending view target blend
			NewPOV = ViewTarget.POV;
			NewPOV.BlendViewInfo(PendingViewTarget.POV, BlendPct);//@TODO: CAMERA: Make sure the sense is correct!  BlendViewTargets(ViewTarget, PendingViewTarget, BlendPct);
		}
		else
		{
			// we're done blending, set new view target
			ViewTarget = PendingViewTarget;

			// clear pending view target
			PendingViewTarget.Target = NULL;

			BlendTimeToGo = 0;

			// our camera is now viewing there
			NewPOV = PendingViewTarget.POV;

			OnBlendComplete().Broadcast();
		}
	}

	if (bEnableFading)
	{
		if (bAutoAnimateFade)
		{
			FadeTimeRemaining = FMath::Max(FadeTimeRemaining - DeltaTime, 0.0f);
			if (FadeTime > 0.0f)
			{
				FadeAmount = FadeAlpha.X + ((1.f - FadeTimeRemaining / FadeTime) * (FadeAlpha.Y - FadeAlpha.X));
			}

			if ((bHoldFadeWhenFinished == false) && (FadeTimeRemaining <= 0.f))
			{
				// done
				StopCameraFade();
			}
		}

		if (bFadeAudio)
		{
			ApplyAudioFade();
		}
	}

	if (AllowPhotographyMode())
	{
		const bool bPhotographyCausedCameraCut = UpdatePhotographyCamera(NewPOV);
		bGameCameraCutThisFrame = bGameCameraCutThisFrame || bPhotographyCausedCameraCut;
	}
}

void AHiPlayerCameraManager::ApplyWorldRotation(FRotator InRotation)
{
	// Current Camera Rotation
	FMinimalViewInfo CurrentPOV = GetCameraCacheView();
	CurrentPOV.Rotation += InRotation;
	SetCameraCachePOV(CurrentPOV);

	FMinimalViewInfo LastFramePOV = GetLastFrameCameraCacheView();
	LastFramePOV.Rotation += InRotation;
	SetLastFrameCameraCachePOV(LastFramePOV);

	ViewTarget.POV.Rotation += InRotation;
	PendingViewTarget.POV.Rotation += InRotation;

	CurrentPOV.Rotation.DiagnosticCheckNaN(TEXT("APlayerCameraManager::ApplyWorldOffset: CameraCache.POV.Location"));
	LastFramePOV.Rotation.DiagnosticCheckNaN(TEXT("APlayerCameraManager::ApplyWorldOffset: LastFrameCameraCache.POV.Location"));
	ViewTarget.POV.Rotation.DiagnosticCheckNaN(TEXT("APlayerCameraManager::ApplyWorldOffset: ViewTarget.POV.Location"));
	PendingViewTarget.POV.Rotation.DiagnosticCheckNaN(TEXT("APlayerCameraManager::ApplyWorldOffset: PendingViewTarget.POV.Location"));

	// Current Control Rotation
	APlayerController* PlayerController = GetOwningPlayerController();
	if (PlayerController)
	{
		FRotator CurrentControlRotation = PlayerController->GetControlRotation();
		PlayerController->SetControlRotation(CurrentControlRotation + InRotation);
	}
}

void AHiPlayerCameraManager::SetTargetCameraRotation(FRotator Rotation)
{
	TargetCameraRotation = Rotation;
}

void AHiPlayerCameraManager::EnablePivotSmooth(bool enable)
{
	bEnablePivotSmooth = enable;
}

void AHiPlayerCameraManager::EvaluateVisionerRotation(const float DeltaTime, FRotator& OutViewRotation, FRotator& OutDeltaRot)
{
#if WITH_PLUGINS_VISIONER
	if (!VisionerScriptInstance)
	{
		return;
	}

	FVisionerUpdateContext UpdateContext(VisionerScriptInstance, DeltaTime);
	VisionerScriptInstance->UpdateVisioner(UpdateContext);

	FVisionerRotationContext EvaluateOutput(VisionerScriptInstance, DeltaTime, OutDeltaRot, OutViewRotation);
	VisionerScriptInstance->EvaluateRotation(EvaluateOutput);

	OutViewRotation = EvaluateOutput.ViewOrientation;
	OutDeltaRot = EvaluateOutput.DeltaRotation;
#endif
}

void AHiPlayerCameraManager::EvaluateVisionerView(const float DeltaTime, FMinimalViewInfo& InOutView)
{
#if WITH_PLUGINS_VISIONER
	if (!VisionerScriptInstance)
	{
		return;
	}

	FVisionerViewContext EvaluateOutput(VisionerScriptInstance, DeltaTime);
	VisionerScriptInstance->EvaluateView(EvaluateOutput);

	InOutView.Location = EvaluateOutput.GetViewLocation();
	InOutView.Rotation = EvaluateOutput.GetViewOrientation();
	InOutView.FOV = EvaluateOutput.GetViewFOV();
#endif
}

void AHiPlayerCameraManager::ChangeVisionerViewTarget(class AActor* NewViewTarget)
{
#if WITH_PLUGINS_VISIONER
	if (VisionerScriptInstance)
	{
		VisionerScriptInstance->DefaultViewTarget = NewViewTarget;
	}
#endif
}

UCameraPostProcessorBase* AHiPlayerCameraManager::FindCameraPostProcessorByName(const FName PostProcessorName)
{
	for (TObjectPtr<UCameraPostProcessorBase> PostProcessor : CameraPostProcessors)
	{
		if (PostProcessor->GetIdentityName() == PostProcessorName)
		{
			return PostProcessor;
		}
	}
	return nullptr;
}