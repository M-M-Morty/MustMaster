// Fill out your copyright notice in the Description page of Project Settings.
// 模拟车辆模型贴合起伏表面
#pragma once

#include "CoreMinimal.h"
#include "Components/SceneComponent.h"
#include "VehicleBodySimulator.generated.h"

class UCharacterMovementComponent;

UCLASS(meta=(BlueprintSpawnableComponent))
class HIGAME_API UVehicleBodySimulator : public USceneComponent
{
	GENERATED_BODY()

public:
	// Sets default values for this component's properties
	UVehicleBodySimulator();

protected:
	// Called when the game starts
	virtual void BeginPlay() override;
	
public:
	//Begin UActorComponent Interface
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
	virtual void InitializeComponent() override;
	//End UActorComponent Interface

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float SpringHookean;			// 悬架弹簧的胡克系数
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float SpringLinearDamping;		// 线性阻尼

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float SpringAngularDamping;		// 旋转阻尼
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float SpringLength;				// 悬架弹簧长度

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float MinLocalOffsetZLimit;		// 模拟结果与逻辑位置的Clamp范围

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float MaxLocalOffsetZLimit;		// 模拟结果与逻辑位置的Clamp范围

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	FVector RotationLimit;			// 模拟结果与逻辑旋转的Clamp范围
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	TArray<FVector> WheelPoints;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float SimPhysicsGravity;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	float MaxSimPhysicsTimeInterval;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	bool TraceFloorComplex;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	FVector2D TraceFloorRangeEx;	// 查找地面起始点和终点的范围修正

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	bool DrawDebugPoints;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	FLinearColor UnderFloorDebugColor;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "VehicleBody Settings")
	FLinearColor OverFloorDebugColor;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, AdvancedDisplay, Category = "VehicleBody Settings")
	TEnumAsByte<ETickingGroup> TickGroup;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, AdvancedDisplay, Category = "VehicleBody Settings")
	bool SimulateAllowed;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, AdvancedDisplay, Category = "VehicleBody Settings")
	FName TraceFloorProfileName;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "VehicleBody To Animation")
	FVector RootBoneLocation;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "VehicleBody To Animation")
	FRotator RootBoneRotation;

private:
	UFUNCTION()
	FVector MatrixMulVector3(const FMatrix& matrix, const FVector& vector);

	UFUNCTION()
	FMatrix CalculateWorldInertiaTensorInverse(const FMatrix& orientation, const FVector& inverseInertiaTensorLocal);
	
	UFUNCTION()
	void SimulateBody(float DeltaTime);

	UFUNCTION()
	void UpdateFakePhysicsVelocity(float DeltaTime);

	UFUNCTION()
	void UpdateFakePhysicsBody_Bone(float DeltaTime);

	UFUNCTION()
	void UpdateFakePhysicsBody_Component(float DeltaTime);

	UFUNCTION()
	float GetFloorHeight(const FVector& WorldLocation);

	UFUNCTION()
	void ClearForcesAndVelocity();

	UFUNCTION()
	void ApplyForceAtPosition(const FVector& WorldForce, const FVector& WorldPosition);

	UFUNCTION()
	void SimulateTick(float DeltaTime);

private:
	UPROPERTY(BlueprintReadWrite, meta = (AllowPrivateAccess = "true"))
	int32 PointsUnderFloor;
	
	UPROPERTY()
	UPrimitiveComponent* RigidComponent;

	UPROPERTY()
	UCharacterMovementComponent* OwnerMovementComponent;

	UPROPERTY()
	float m_BaseLinearDamping;

	UPROPERTY()
	float m_BaseAngularDamping;

	UPROPERTY()
	FVector m_ExternalForces;

	UPROPERTY()
	FVector m_ExternalTorques;

	UPROPERTY()
	FVector m_FakeLinearVelocity;

	UPROPERTY()
	FVector m_FakeAngularVelocity;

	UPROPERTY()
	bool m_bSimulateBody;

	UPROPERTY()
	bool m_bUsingBoneUpdate;

	UPROPERTY()
	EVisibilityBasedAnimTickOption m_OriginVisibilityBasedAnimTickOption;
};
