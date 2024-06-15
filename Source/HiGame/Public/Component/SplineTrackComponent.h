// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Components/SplineComponent.h"
#include "Components/SplineMeshComponent.h"
#include "EdRuntime/EdActor.h"
#include "SplineTrackComponent.generated.h"


class UShapeComponent;
/**
 * 
 */

USTRUCT(BlueprintType)
struct FSplineTransitionTargetArea
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly,SimpleDisplay, DisplayName="Begin Point, Percentage of Spline", meta=(ClampMin = 0, ClampMax = 1, UIMin = 0, UIMax = 1 ))
	float Begin = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, DisplayName="End Point, Percentage of Spline", meta=(ClampMin = 0, ClampMax = 1, UIMin = 0, UIMax = 1 ))
	float End = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, meta=(ClampMin = 0, ClampMax = 10, UIMin = 0, UIMax = 10 ))
	float DurationTime = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, DisplayName="Target Spline Actor")
	TObjectPtr<AActor> TargetSpline = nullptr;
};

USTRUCT(BlueprintType)
struct FSplineTransitionArea
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadOnly,SimpleDisplay, DisplayName="Begin Point, Percentage of Spline", meta=(ClampMin = 0, ClampMax = 1, UIMin = 0, UIMax = 1 ))
	float Begin = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, DisplayName="End Point, Percentage of Spline", meta=(ClampMin = 0, ClampMax = 1, UIMin = 0, UIMax = 1 ))
	float End = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, DisplayName="Target Spline Actors Areas")
	TArray<FSplineTransitionTargetArea> TargetAreas;
};

UCLASS(Blueprintable, meta=(BlueprintSpawnableComponent))
class HIGAME_API USplineTrackComponent : public USplineComponent
{
	GENERATED_BODY()

public:
	virtual ~USplineTrackComponent() override;

	virtual void BeginPlay() override;

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable)
	void OnConstructor();

	USplineMeshComponent * CreateSplineMesh();

	UFUNCTION()
	void UpdateSplineMeshByPoint(int PointIndex);

	UFUNCTION(BlueprintCallable)
	USplineComponent* GetParabolaSplineTrack(bool ToHead, FVector StartLocation, float& totle_time);

	UFUNCTION(BlueprintCallable)
	USplineComponent* GetParabolaSplineTrackToLocation(FVector StartLocation, FVector TargetLocation, float& totle_time);
	
	void UpdateCollision();

	UChildActorComponent * CreateChildComponent(const FTransform& RelativeTransform=FTransform::Identity);

	UFUNCTION(BlueprintCallable)
	void JumpToSplineTrack(AEdActor* trigger);

	UFUNCTION(BlueprintImplementableEvent)
	void OnJumpToTrack(bool IsHead = true);

	virtual void DestroyComponent(bool bPromoteChildren) override;

private:
	void CreateStartTrigger();

	template <typename T>
	T* CreateComponent(USceneComponent* Parent = nullptr , const FTransform& RelativeTransform=FTransform::Identity);

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Spline Mesh Info", meta=(AllowPrivateAccess="true"))
	UStaticMesh* StaticMesh = nullptr;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Spline Mesh Info", meta=(AllowPrivateAccess="true"))
	TEnumAsByte<ESplineMeshAxis::Type> ForwardAxis = ESplineMeshAxis::Z;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Spline Mesh Info", meta=(AllowPrivateAccess="true"))
	UMaterialInterface* Material = nullptr;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Trigger Collision", meta=(AllowPrivateAccess="true"))
	FVector HeadTriggerOffset = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Trigger Collision", meta=(AllowPrivateAccess="true"))
	float HeadTriggerScale = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Trigger Collision", meta=(AllowPrivateAccess="true"))
	FVector TailTriggerOffset = FVector::ZeroVector;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "Trigger Collision", meta=(AllowPrivateAccess="true"))
	float TailTriggerScale = 1.0f;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite, Category = "Trigger Collision", meta=(AllowPrivateAccess="true"))
	TSubclassOf<AActor> StartTriggerClass;

	TObjectPtr<UChildActorComponent> HeadTrigger = nullptr;

	TObjectPtr<UChildActorComponent> TailTrigger = nullptr;

	TObjectPtr<USplineComponent> TransferSpline = nullptr;
};

template <typename T>
T* USplineTrackComponent::CreateComponent(USceneComponent* Parent, const FTransform& RelativeTransform)
{
	auto Comp = Cast<T>(GetOwner()->AddComponentByClass(
		T::StaticClass(),
		false,
		RelativeTransform,
		false));
	if (!Comp)
		return nullptr;
	if (Parent && Comp->GetAttachParent() != Parent)
	{
		static FAttachmentTransformRules AttachmentTransformRules(
			EAttachmentRule::KeepRelative,
			EAttachmentRule::KeepRelative,
			EAttachmentRule::KeepRelative,
			true
		);
		Comp->AttachToComponent(Parent, AttachmentTransformRules);
	}

	Comp->SetMobility(EComponentMobility::Static);
	return Comp;
}
