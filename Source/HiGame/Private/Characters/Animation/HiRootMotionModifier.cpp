// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/Animation/HiRootMotionModifier.h"
#include "GameFramework/Character.h"
#include "Components/CapsuleComponent.h"
#include "Animation/AnimInstance.h"
#include "MotionWarpingComponent.h"
#include "DrawDebugHelpers.h"

DEFINE_LOG_CATEGORY_STATIC(LogHiMotionWarping, Log, All)

static FQuat ZeroQuat(EForceInit::ForceInitToZero);

URootMotionModifier_RotateTranslation::URootMotionModifier_RotateTranslation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bInLocalSpace = true;
}

FTransform URootMotionModifier_RotateTranslation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}

	const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();

	FTransform FinalRootMotion = InRootMotion;

	// if (PreviousPosition <= 0.0001)
	// {
	// 	int i = 0;
	// 	i++;
	// }

	const FTransform RootMotionTotal = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, EndTime);

	if (bWarpTranslation)
	{
		FVector DeltaTranslation = InRootMotion.GetTranslation();

		const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, FMath::Min(CurrentPosition, EndTime));

		const float HorizontalDelta = RootMotionDelta.GetTranslation().Size2D();
		const float HorizontalTarget = FVector::Dist2D(CharacterTransform.GetLocation(), GetTargetLocation());
		const float HorizontalOriginal = RootMotionTotal.GetTranslation().Size2D();
		const float HorizontalTranslationWarped = !FMath::IsNearlyZero(HorizontalOriginal) ? ((HorizontalDelta * HorizontalTarget) / HorizontalOriginal) : 0.f;
		
		if (bInLocalSpace)
		{
			const FTransform MeshRelativeTransform = FTransform(CharacterOwner->GetBaseRotationOffset(), CharacterOwner->GetBaseTranslationOffset());
			const FTransform MeshTransform = MeshRelativeTransform * CharacterOwner->GetActorTransform();
			DeltaTranslation = MeshTransform.InverseTransformPositionNoScale(GetTargetLocation()).GetSafeNormal2D() * HorizontalTranslationWarped;
		}
		else
		{
			DeltaTranslation = (GetTargetLocation() - CharacterTransform.GetLocation()).GetSafeNormal2D() * HorizontalTranslationWarped;
		}

		if (!bIgnoreZAxis)
		{
			const float CapsuleHalfHeight = CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
			const FVector CapsuleBottomLocation = (CharacterOwner->GetActorLocation() - FVector(0.f, 0.f, CapsuleHalfHeight));
			const float VerticalDelta = RootMotionDelta.GetTranslation().Z;
			const float VerticalTarget = GetTargetLocation().Z - CapsuleBottomLocation.Z;
			const float VerticalOriginal = RootMotionTotal.GetTranslation().Z;
			const float VerticalTranslationWarped = !FMath::IsNearlyZero(VerticalOriginal) ? ((VerticalDelta * VerticalTarget) / VerticalOriginal) : 0.f;

			DeltaTranslation.Z = VerticalTranslationWarped;
		}
		else
		{
			DeltaTranslation.Z = InRootMotion.GetTranslation().Z;
		}

		FinalRootMotion.SetTranslation(DeltaTranslation);
	}

	if (bWarpRotation)
	{
		const FQuat WarpedRotation = WarpRotation(InRootMotion, RootMotionTotal, DeltaSeconds);
		FinalRootMotion.SetRotation(WarpedRotation);
	}

	// Debug
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
	const int32 DebugLevel = FMotionWarpingCVars::CVarMotionWarpingDebug.GetValueOnGameThread();
	if (DebugLevel == 1 || DebugLevel == 3)
	{
		PrintLog(TEXT("SimpleWarp"), InRootMotion, FinalRootMotion);
	}

	if (DebugLevel == 2 || DebugLevel == 3)
	{
		const float DrawDebugDuration = FMotionWarpingCVars::CVarMotionWarpingDrawDebugDuration.GetValueOnGameThread();
		DrawDebugCoordinateSystem(CharacterOwner->GetWorld(), GetTargetLocation(), GetTargetRotator(), 50.f, false, DrawDebugDuration, 0, 1.f);
	}
#endif

	return FinalRootMotion;
}

URootMotionModifier_ClearRotation::URootMotionModifier_ClearRotation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bInLocalSpace = false;
}

FTransform URootMotionModifier_ClearRotation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
 	UMotionWarpingComponent *OwnerComponent = GetOwnerComponent();

	if (!OwnerComponent)
	{
		return InRootMotion;
	}

	const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, FMath::Min(CurrentPosition, EndTime));
	
	ACharacter *Actor = OwnerComponent->GetCharacterOwner();

	const FTransform ActorToWorld = Actor->GetTransform();
	USkeletalMeshComponent * Mesh = Actor->GetMesh();
	const FTransform ComponentTransform = Mesh->GetComponentTransform();

	// if (!FMath::IsNearlyZero(ActorToWorld.Rotator().Pitch, 0.001))
	// {
	// 	int i = 0;
	// 	i++;
	// }
	//
	// FRotator ComponentRotator = ComponentTransform.Rotator();
	// FRotator ActorToWorldRotator = ActorToWorld.Rotator();

	const FTransform ComponentToActor = ActorToWorld.GetRelativeTransform(ComponentTransform);
	const FTransform ActorToComponent = ComponentTransform.GetRelativeTransform(ActorToWorld);

	FRotator TargetRotation = Actor->GetActorRotation();
	
	// FQuat Quat = TargetRotation.Quaternion();
	
	if (bClearPitch)
	{
		TargetRotation.Pitch = 0;
	}
	if (bClearRoll)
	{
		TargetRotation.Roll = 0;
	}
	if (bClearYaw)
	{
		TargetRotation.Yaw = 0;
	}

	FTransform TargetActorTransform(TargetRotation, ActorToWorld.GetTranslation());
	FTransform TargetComponentTransform = ActorToComponent * TargetActorTransform;
	
	const FTransform NewComponentToWorld = RootMotionDelta * TargetComponentTransform;
	const FTransform NewActorTransform = ComponentToActor * NewComponentToWorld;

	const FVector DeltaWorldTranslation = NewActorTransform.GetTranslation() - ActorToWorld.GetTranslation();

	const FQuat NewWorldRotation = TargetComponentTransform.GetRotation() * RootMotionDelta.GetRotation();
	
	const FQuat DeltaWorldRotation = NewWorldRotation * TargetComponentTransform.GetRotation().Inverse();
	
	return FTransform(DeltaWorldRotation, DeltaWorldTranslation);
}

URootMotionModifier_WarpRotation::URootMotionModifier_WarpRotation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	bInLocalSpace = false;
}

FTransform URootMotionModifier_WarpRotation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	FTransform FinalRootMotion = InRootMotion;
	FinalRootMotion.ScaleTranslation(Scale);
	if (bWarpRotation)
	{
		const FQuat WarpedRotation = ProcessRotation(InRootMotion, DeltaSeconds);
		FinalRootMotion.SetRotation(WarpedRotation);
	}
	return FinalRootMotion;
}

FQuat URootMotionModifier_WarpRotation::ProcessRotation(const FTransform& RootMotionDelta, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return FQuat::Identity;
	}
	
	const FQuat TargetRotation = GetTargetRotation();

	const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();
	const FQuat CurrentRotation = CharacterTransform.GetRotation();

	float velocity = AngularVelocity;
	
	if (IsValid(AngularVelocityCurve))
	{
		velocity = AngularVelocityCurve->GetFloatValue(TotalTime);
	}
	
	TotalTime += DeltaSeconds;

	FQuat Rotation = FMath::QInterpConstantTo(CurrentRotation, TargetRotation, DeltaSeconds, velocity);

	return Rotation * CurrentRotation.Inverse();
}

void URootMotionModifier_WarpRotation::OnWarpBegin()
{
	TotalTime = 0.0f;
	
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner)
	{
		const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();
		CachedTargetTransform.SetRotation(CharacterTransform.GetRotation());
	}
}

void URootMotionModifier_WarpRotation::OnWarpEnd()
{
	//TotalTime = 0;
}

URootMotionModifier_SimpleRotateTranslation::URootMotionModifier_SimpleRotateTranslation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FTransform URootMotionModifier_SimpleRotateTranslation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	FTransform FinalRootMotion = InRootMotion;
	const FVector &translation = Rotation.RotateVector(InRootMotion.GetTranslation());
	FinalRootMotion.SetTranslation(translation);
	FinalRootMotion.ScaleTranslation(Scale);

	return FinalRootMotion;
}

URootMotionModifier_HiSimpleWarp::URootMotionModifier_HiSimpleWarp(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FTransform URootMotionModifier_HiSimpleWarp::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}

	const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();

	FTransform FinalRootMotion = InRootMotion;

	const FTransform RootMotionTotal = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, EndTime);

	if (bWarpTranslation)
	{
		FVector DeltaTranslation = InRootMotion.GetTranslation();

		const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, FMath::Min(CurrentPosition, EndTime));

		if (!bIgnoreHorizontal)
		{
			const float HorizontalDelta = RootMotionDelta.GetTranslation().Size2D();
			const float HorizontalTarget = FVector::Dist2D(CharacterTransform.GetLocation(), GetTargetLocation());
			const float HorizontalOriginal = RootMotionTotal.GetTranslation().Size2D();
			const float HorizontalTranslationWarped = !FMath::IsNearlyZero(HorizontalOriginal) ? ((HorizontalDelta * HorizontalTarget) / HorizontalOriginal) : 0.f;
		
			const FTransform MeshRelativeTransform = FTransform(CharacterOwner->GetBaseRotationOffset(), CharacterOwner->GetBaseTranslationOffset());
			const FTransform MeshTransform = MeshRelativeTransform * CharacterOwner->GetActorTransform();
			DeltaTranslation = MeshTransform.InverseTransformPositionNoScale(GetTargetLocation()).GetSafeNormal2D() * HorizontalTranslationWarped;	
		}

		if (!bIgnoreZAxis)
		{
			const float CapsuleHalfHeight = CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
			const FVector CapsuleBottomLocation = (CharacterOwner->GetActorLocation() - FVector(0.f, 0.f, CapsuleHalfHeight));
			float VerticalDelta = RootMotionDelta.GetTranslation().Z;
			const float VerticalTarget = GetTargetLocation().Z - CapsuleBottomLocation.Z;
			float VerticalOriginal = RootMotionTotal.GetTranslation().Z;
			if (FMath::IsNearlyZero(VerticalOriginal))
			{
				// If root motion no Z translation, use time interpolation.
				// Attention: CurrentPosition may sampled into next frame and large then EndTime ! This cause VerticalOriginal is nearly zero, but VerticalDelta is one frame.
				VerticalOriginal = EndTime - PreviousPosition;
				VerticalDelta = CurrentPosition - PreviousPosition;
				VerticalDelta = FMath::Min(VerticalDelta, VerticalOriginal);
			}
			const float VerticalTranslationWarped = !FMath::IsNearlyZero(VerticalOriginal) ? ((VerticalDelta * VerticalTarget) / VerticalOriginal) : 0.f;

			DeltaTranslation.Z = VerticalTranslationWarped;

			// FString Name("SimpleWarp");
			// UE_LOG(LogHiMotionWarping, Log, TEXT("ZAxis %s NetMode: %d Char: %s Anim: %s Win: [%f %f][%f %f] DT: %f WT: %f, CapsuleBottomLocation: %s, TargetLocation: %s, VerticalDelta: %f, VerticalTarget: %f, VerticalOriginal: %f, VerticalTranslationWarped %f"),
			// *Name, (int32)CharacterOwner->GetWorld()->GetNetMode(), *GetNameSafe(CharacterOwner), *GetNameSafe(Animation.Get()), StartTime, EndTime, PreviousPosition, CurrentPosition, DeltaSeconds,
			// CharacterOwner->GetWorld()->GetTimeSeconds(), *CapsuleBottomLocation.ToCompactString(), *GetTargetLocation().ToCompactString(), VerticalDelta, VerticalTarget, VerticalOriginal, VerticalTranslationWarped);
		}
		else
		{
			DeltaTranslation.Z = InRootMotion.GetTranslation().Z;
		}

		FinalRootMotion.SetTranslation(DeltaTranslation);
	}

	if (bWarpRotation)
	{
		const FQuat WarpedRotation = WarpRotation(InRootMotion, RootMotionTotal, DeltaSeconds);
		FinalRootMotion.SetRotation(WarpedRotation);
	}

	// Debug
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
	const int32 DebugLevel = FMotionWarpingCVars::CVarMotionWarpingDebug.GetValueOnGameThread();
	if (DebugLevel == 1 || DebugLevel == 3)
	{
		PrintLog(TEXT("SimpleWarp"), InRootMotion, FinalRootMotion);
	}

	if (DebugLevel == 2 || DebugLevel == 3)
	{
		const float DrawDebugDuration = FMotionWarpingCVars::CVarMotionWarpingDrawDebugDuration.GetValueOnGameThread();
		DrawDebugCoordinateSystem(CharacterOwner->GetWorld(), GetTargetLocation(), GetTargetRotator(), 50.f, false, DrawDebugDuration, 0, 1.f);
	}
#endif

	return FinalRootMotion;
}

URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	
}

void URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::WrapRelatedBone()
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return;
	}

	FCSPose<FCompactPose> CSPose;
	
	if (bRestart)
    {
    		//LastAdjustBoneTransform = BoneTransform_PreviousPosition;
    	LastAdjustBoneTransform = CharacterOwner->GetMesh()->GetSocketTransform(BoneToModify.BoneName);
    	bRestart = false;
    	
    	const FTransform RootMotionTotal = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), StartTime, EndTime);
		const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();
		
		const float CapsuleHalfHeight = CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
		const FVector CapsuleBottomLocation = (CharacterOwner->GetActorLocation() - FVector(0.f, 0.f, CapsuleHalfHeight));
    	
		const float VerticalTarget = GetTargetLocation().Z - CapsuleBottomLocation.Z;
		float VerticalOriginal = RootMotionTotal.GetTranslation().Z;
		
		const FTransform MeshRelativeTransform = FTransform(CharacterOwner->GetBaseRotationOffset(), CharacterOwner->GetBaseTranslationOffset());
		MeshInitTransform = MeshRelativeTransform * CharacterOwner->GetActorTransform();

		UMotionWarpingUtilities::ExtractComponentSpacePose(Animation.Get(), RequiredBones, StartTime, false, CSPose);
		FTransform BoneTransform_StartPosition;
	
		for (int32 BoneIndex = 1; BoneIndex < CSPose.GetPose().GetNumBones(); BoneIndex++)
		{
			const FName TargetBoneName = RequiredBones.GetReferenceSkeleton().GetBoneName(RequiredBones.GetBoneIndicesArray()[BoneIndex]);
			if (BoneToModify.BoneName == TargetBoneName)
			{
				BoneTransform_StartPosition = CSPose.GetComponentSpaceTransform(FCompactPoseBoneIndex(BoneIndex)) * MeshInitTransform;
			}
		}
		
		UMotionWarpingUtilities::ExtractComponentSpacePose(Animation.Get(), RequiredBones, EndTime, false, CSPose);
		FTransform BoneTransform_EndPosition;
	
		for (int32 BoneIndex = 1; BoneIndex < CSPose.GetPose().GetNumBones(); BoneIndex++)
		{
			const FName TargetBoneName = RequiredBones.GetReferenceSkeleton().GetBoneName(RequiredBones.GetBoneIndicesArray()[BoneIndex]);
			if (BoneToModify.BoneName == TargetBoneName)
			{
				BoneTransform_EndPosition = CSPose.GetComponentSpaceTransform(FCompactPoseBoneIndex(BoneIndex)) * MeshInitTransform;
			}
		}


		const float HorizontalTarget = FVector::Dist2D(CharacterTransform.GetLocation(), GetTargetLocation());
		const float HorizontalOriginal = RootMotionTotal.GetTranslation().Size2D();
		
		FVector DeltaTranslation = BoneTransform_EndPosition.GetLocation() - BoneTransform_StartPosition.GetLocation();

		float DeltaTranslationSize2D = DeltaTranslation.Size2D();
		FVector DeltaTranslationXY = DeltaTranslation.GetSafeNormal2D() * (DeltaTranslationSize2D - HorizontalOriginal + HorizontalTarget);
		
		float DeltaTranslationZ = DeltaTranslation.Z - VerticalOriginal + VerticalTarget;

		HorizontalTranslationScale = !FMath::IsNearlyZero(DeltaTranslationSize2D, 1e-3) ? DeltaTranslationXY.Size2D() / DeltaTranslationSize2D : 1.0f;
		VerticalTranslationScale = !FMath::IsNearlyZero(DeltaTranslation.Z, 1e-3) ? DeltaTranslationZ / DeltaTranslation.Z : 1.0f;

		// UE_LOG(LogRootMotion, Error, TEXT("URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::WrapRelatedBone 111 [%f:%f] %s VerticalOriginal = %f, HorizontalTarget = %f, DeltaTranslation = %s, MeshTranslation = %s, BoneTranslation = %s, %s"), PreviousPosition, EndTime, *BoneToModify.BoneName.ToString(), VerticalOriginal, VerticalTarget, *DeltaTranslation.ToString(), *MeshInitTransform.GetLocation().ToString(), *LastAdjustBoneTransform.GetLocation().ToString(), *CharacterOwner->GetMesh()->GetSocketTransform(BoneToModify.BoneName, RTS_ParentBoneSpace).GetLocation().ToString());
    }
    	
	// Extract pose
	UMotionWarpingUtilities::ExtractComponentSpacePose(Animation.Get(), RequiredBones, PreviousPosition, false, CSPose);
	const FCompactPose & Pose_PreviousPosition = CSPose.GetPose();
	FTransform BoneTransform_PreviousPosition;
	
	for (int32 BoneIndex = 1; BoneIndex < CSPose.GetPose().GetNumBones(); BoneIndex++)
	{
		const FName TargetBoneName = RequiredBones.GetReferenceSkeleton().GetBoneName(RequiredBones.GetBoneIndicesArray()[BoneIndex]);
		if (BoneToModify.BoneName == TargetBoneName)
		{
			BoneTransform_PreviousPosition = CSPose.GetComponentSpaceTransform(FCompactPoseBoneIndex(BoneIndex)) * MeshInitTransform;
		}
	}
	
	UMotionWarpingUtilities::ExtractComponentSpacePose(Animation.Get(), RequiredBones, FMath::Min(CurrentPosition, EndTime), false, CSPose);
	const FCompactPose & Pose_CurrentPosition = CSPose.GetPose();
	FTransform BoneTransform_CurrentPosition;
	
	for (int32 BoneIndex = 1; BoneIndex < CSPose.GetPose().GetNumBones(); BoneIndex++)
	{
		const FName TargetBoneName = RequiredBones.GetReferenceSkeleton().GetBoneName(RequiredBones.GetBoneIndicesArray()[BoneIndex]);
		if (BoneToModify.BoneName == TargetBoneName)
		{
			BoneTransform_CurrentPosition = CSPose.GetComponentSpaceTransform(FCompactPoseBoneIndex(BoneIndex)) * MeshInitTransform;
		}
	}
	
	FVector LastTranslation = LastAdjustBoneTransform.GetLocation();
	FVector DeltaTranslation = BoneTransform_CurrentPosition.GetLocation() - BoneTransform_PreviousPosition.GetLocation();
	FVector DeltaTranslation2D = DeltaTranslation.GetSafeNormal2D() * DeltaTranslation.Size2D() * HorizontalTranslationScale;
	
	AdjustBoneTransform = BoneTransform_CurrentPosition;
	AdjustBoneTransform.SetTranslation(FVector(DeltaTranslation2D.X, DeltaTranslation2D.Y, DeltaTranslation.Z * VerticalTranslationScale));

	// UE_LOG(LogRootMotion, Error, TEXT("URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::WrapRelatedBone 222 %f, %f, AdjustBoneTransform = %s, LastTranslation = %s, %s, %s"), VerticalTranslationScale, HorizontalTranslationScale, *AdjustBoneTransform.GetLocation().ToString(), *LastTranslation.ToString(), *BoneTransform_CurrentPosition.GetLocation().ToString(), *DeltaTranslation.ToString());

	LastAdjustBoneTransform = AdjustBoneTransform;
}

FTransform URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}

	const FTransform& CharacterTransform = CharacterOwner->GetActorTransform();

	FTransform FinalRootMotion = InRootMotion;

	const FTransform RootMotionTotal = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, EndTime);
	

	if (bWarpTranslation)
	{
		FVector DeltaTranslation = InRootMotion.GetTranslation();

		const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, FMath::Min(CurrentPosition, EndTime));

		if (!bIgnoreHorizontal)
		{
			const float HorizontalDelta = RootMotionDelta.GetTranslation().Size2D();
			const float HorizontalTarget = FVector::Dist2D(CharacterTransform.GetLocation(), GetTargetLocation());
			const float HorizontalOriginal = RootMotionTotal.GetTranslation().Size2D();
			const float HorizontalTranslationWarped = !FMath::IsNearlyZero(HorizontalOriginal, 1e-3) ? (HorizontalDelta * HorizontalTarget) / HorizontalOriginal : 0.f;
			
			const FTransform MeshRelativeTransform = FTransform(CharacterOwner->GetBaseRotationOffset(), CharacterOwner->GetBaseTranslationOffset());
			const FTransform MeshTransform = MeshRelativeTransform * CharacterOwner->GetActorTransform();
			DeltaTranslation = MeshTransform.InverseTransformPositionNoScale(GetTargetLocation()).GetSafeNormal2D() * HorizontalTranslationWarped;	
		}

		if (!bIgnoreZAxis)
		{
			const float CapsuleHalfHeight = CharacterOwner->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
			const FVector CapsuleBottomLocation = (CharacterOwner->GetActorLocation() - FVector(0.f, 0.f, CapsuleHalfHeight));
			float VerticalDelta = RootMotionDelta.GetTranslation().Z;
			const float VerticalTarget = GetTargetLocation().Z - CapsuleBottomLocation.Z;
			float VerticalOriginal = RootMotionTotal.GetTranslation().Z;

			if (FMath::IsNearlyZero(VerticalOriginal))
			{
				// If root motion no Z translation, use time interpolation.
				// Attention: CurrentPosition may sampled into next frame and large then EndTime ! This cause VerticalOriginal is nearly zero, but VerticalDelta is one frame.
				VerticalOriginal = EndTime - PreviousPosition;
				VerticalDelta = CurrentPosition - PreviousPosition;
				VerticalDelta = FMath::Min(VerticalDelta, VerticalOriginal);
			}

			const float VerticalTranslationWarped = !FMath::IsNearlyZero(VerticalOriginal) ? ((VerticalDelta * VerticalTarget) / VerticalOriginal) : 0.f;

			DeltaTranslation.Z = VerticalTranslationWarped;

			//FString Name("SimpleWarp");
			//UE_LOG(LogHiMotionWarping, Error, TEXT("ZAxis %s NetMode: %d Char: %s Anim: %s Win: [%f %f][%f %f] DT: %f WT: %f, CapsuleBottomLocation: %s, TargetLocation: %s, VerticalDelta: %f, VerticalTarget: %f, VerticalOriginal: %f, VerticalTranslationWarped %f"),
			//*Name, (int32)CharacterOwner->GetWorld()->GetNetMode(), *GetNameSafe(CharacterOwner), *GetNameSafe(Animation.Get()), StartTime, EndTime, PreviousPosition, CurrentPosition, DeltaSeconds,
			//CharacterOwner->GetWorld()->GetTimeSeconds(), *CapsuleBottomLocation.ToCompactString(), *GetTargetLocation().ToCompactString(), VerticalDelta, VerticalTarget, VerticalOriginal, VerticalTranslationWarped);
		}
		else
		{
			DeltaTranslation.Z = InRootMotion.GetTranslation().Z;
		}

		FinalRootMotion.SetTranslation(DeltaTranslation);
	}

	if (bWarpRotation)
	{
		const FQuat WarpedRotation = WarpRotation(InRootMotion, RootMotionTotal, DeltaSeconds);
		FinalRootMotion.SetRotation(WarpedRotation);
	}

	// Debug
#if !(UE_BUILD_SHIPPING || UE_BUILD_TEST)
	const int32 DebugLevel = FMotionWarpingCVars::CVarMotionWarpingDebug.GetValueOnGameThread();
	if (DebugLevel == 1 || DebugLevel == 3)
	{
		PrintLog(TEXT("SimpleWarp"), InRootMotion, FinalRootMotion);
	}

	if (DebugLevel == 2 || DebugLevel == 3)
	{
		const float DrawDebugDuration = FMotionWarpingCVars::CVarMotionWarpingDrawDebugDuration.GetValueOnGameThread();
		DrawDebugCoordinateSystem(CharacterOwner->GetWorld(), GetTargetLocation(), GetTargetRotator(), 50.f, false, DrawDebugDuration, 0, 1.f);
	}
#endif

	WrapRelatedBone();
	return FinalRootMotion;
}

void URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::InitRequiredBones()
{
	if (BoneToModify.BoneName == NAME_None)
	{
		return;
	}
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return;
	}

	const FBoneContainer& BoneContainer = CharacterOwner->GetMesh()->GetAnimInstance()->GetRequiredBones();

	// Init FBoneContainer with only the bones that we are interested in
	TArray<FBoneIndexType> RequiredBoneIndexArray;
	RequiredBoneIndexArray.Add(0);
	
	const int32 BoneIndex = BoneContainer.GetPoseBoneIndexForBoneName(BoneToModify.BoneName);
	if (BoneIndex != INDEX_NONE)
	{
		RequiredBoneIndexArray.Add(BoneIndex);
	}

	BoneContainer.GetReferenceSkeleton().EnsureParentsExistAndSort(RequiredBoneIndexArray);

	// Init BoneContainer
	RequiredBones = FBoneContainer(RequiredBoneIndexArray, FCurveEvaluationOption(false), *BoneContainer.GetAsset());
}

void URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::OnWarpBegin()
{
	Super::OnWarpBegin();
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return;
	}
	bRestart = true;

	MeshInitTransform = CharacterOwner->GetMesh()->GetComponentTransform();
	InitRequiredBones();
}

void URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::GetAdjustBoneTransform(const FName &TargetBoneName, FTransform& OutTransform, float& OutAlpha)
{
	OutTransform = FTransform::Identity;
	OutAlpha = 0.f;
	
	if (TargetBoneName == BoneToModify.BoneName)
	{
		OutTransform = AdjustBoneTransform;
		OutAlpha = 1.0f;

		//UE_LOG(LogRootMotion, Error, TEXT("URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::GetAdjustBoneTransform %s"), *AdjustBoneTransform.ToString());
	}
}

void URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp::GetAdjustmentBoneTransformAndAlpha(ACharacter* Character, const FName &BoneName, FTransform& OutTransform, float& OutAlpha)
{
	OutTransform = FTransform::Identity;
	OutAlpha = 0.f;

	const UMotionWarpingComponent* MotionWarpingComp = Character ? Character->FindComponentByClass<UMotionWarpingComponent>() : nullptr;
	if (MotionWarpingComp)
	{
		for (URootMotionModifier* Modifier : MotionWarpingComp->GetModifiers())
		{
			if (Modifier && Modifier->GetState() == ERootMotionModifierState::Active)
			{
				if (URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp* AdjustmentBlendWarpModifier = Cast<URootMotionModifier_HiSimpleWarp_AdjustmentBlendWarp>(Modifier))
				{
					// We must check if the Animation for the modifier is still relevant because in RootMotionFromMontageOnlyMode the montage could be aborted 
					// but the modifier will remain in the list until the next update
					const FAnimMontageInstance* RootMotionMontageInstance = Character->GetRootMotionAnimMontageInstance();
					const UAnimMontage* Montage = RootMotionMontageInstance ? ToRawPtr(RootMotionMontageInstance->Montage) : nullptr;
					if (Modifier->Animation == Montage)
					{
						AdjustmentBlendWarpModifier->GetAdjustBoneTransform(BoneName, OutTransform, OutAlpha);
						return;
					}
				}
			}
		}
	}
}

URootMotionModifier_HiScaleRotation::URootMotionModifier_HiScaleRotation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FTransform URootMotionModifier_HiScaleRotation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}
	
	FTransform FinalRootMotion = InRootMotion;

	const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PreviousPosition, FMath::Min(CurrentPosition, EndTime));
	
	FRotator Rotator = RootMotionDelta.Rotator();
	
	Rotator.Yaw *= Scale.Y;
	FinalRootMotion.SetRotation(Rotator.Quaternion());
	
	return FinalRootMotion;
}

void URootMotionModifier_HiScaleRotation::OnTargetTransformChanged()
{
	FRotator TargetRotator = GetTargetRotator();
	FTransform RootMotionTotal = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), StartTime, EndTime);
	FRotator Rotator = RootMotionTotal.Rotator();

	Scale = FMath::IsNearlyZero(Rotator.Yaw) ? FVector(1.0f, 1.0f, 1.0f) : FVector(1.0f, FMath::Abs(TargetRotator.Yaw / Rotator.Yaw), 1.0f);
}

void URootMotionModifier_HiScaleRotation::OnWarpBegin()
{
	OnTargetTransformChanged();
}

URootMotionModifier_HiScaleTranslation::URootMotionModifier_HiScaleTranslation(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FTransform URootMotionModifier_HiScaleTranslation::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}

	FTransform FinalRootMotion = InRootMotion;
	
	// Here must not use PreviousPosition, as SimulatedRootMotionPositionFixup will duplicate invoke this after restore position of server.
	// If use PreviousPosition, then calculat RootMotion not correct.
	const float PrevPos = CurrentPosition - DeltaSeconds;
	const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PrevPos, FMath::Min(CurrentPosition, EndTime));

	FVector Location = RootMotionDelta.GetLocation() * Scale;
	FinalRootMotion.SetTranslation(Location);

	AccDelta += RootMotionDelta.GetLocation();
	UE_LOG(LogRootMotion, Verbose, TEXT("HiScaleTranslation ProcessRootMotion owner: %s, role: %s, Animation: %s, deltaSecods: %f, prev: %f(%f), cur: %f, delta: %s, acc: %s, scale: %s"),
		*CharacterOwner->GetName(),
		*UEnum::GetValueAsString(TEXT("Engine.ENetRole"), CharacterOwner->GetLocalRole()),
		*Animation->GetName(),
		DeltaSeconds, PrevPos, PreviousPosition, CurrentPosition, *RootMotionDelta.GetLocation().ToString(), *AccDelta.ToString(), *Scale.ToString());

	return FinalRootMotion;
}

void URootMotionModifier_HiScaleTranslation::OnTargetTransformChanged()
{
	Scale = GetTargetScale();
}

void URootMotionModifier_HiScaleTranslation::OnWarpBegin()
{
	AccDelta = FVector();
	OnTargetTransformChanged();
}

URootMotionModifier_HiScaleToTargetLength::URootMotionModifier_HiScaleToTargetLength(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

FTransform URootMotionModifier_HiScaleToTargetLength::ProcessRootMotion(const FTransform& InRootMotion, float DeltaSeconds)
{
	const ACharacter* CharacterOwner = GetCharacterOwner();
	if (CharacterOwner == nullptr)
	{
		return InRootMotion;
	}

	FTransform FinalRootMotion = InRootMotion;
	
	// Here must not use PreviousPosition, as SimulatedRootMotionPositionFixup will duplicate invoke this after restore position of server.
	// If use PreviousPosition, then calculat RootMotion not correct.
	const float PrevPos = CurrentPosition - DeltaSeconds;
	const FTransform RootMotionDelta = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), PrevPos, FMath::Min(CurrentPosition, EndTime));

	FVector Location = RootMotionDelta.GetLocation() * Scale;
	FinalRootMotion.SetTranslation(Location);

	return FinalRootMotion;
}

void URootMotionModifier_HiScaleToTargetLength::OnTargetTransformChanged()
{
	const FVector TargetLength = GetTargetLength();
	const FVector RootMotionTranslation = UMotionWarpingUtilities::ExtractRootMotionFromAnimation(Animation.Get(), StartTime, EndTime).GetLocation();
	float ScaleXY = (TargetLength.X == 0.0f || FMath::IsNearlyZero(RootMotionTranslation.Size2D())) ? TargetLength.X / RootMotionTranslation.Size2D() : 1.0f;
	float ScaleZ = (TargetLength.Z == 0.0f || FMath::IsNearlyZero(RootMotionTranslation.Z)) ? TargetLength.Z / RootMotionTranslation.Z : 1.0f;

	Scale = FVector(ScaleXY, ScaleXY, ScaleZ);
}

void URootMotionModifier_HiScaleToTargetLength::OnWarpBegin()
{
	OnTargetTransformChanged();
}