// Fill out your copyright notice in the Description page of Project Settings.

#include "Component/HiGlideComponent.h"

#include "KismetAnimationLibrary.h"
#include "Characters/HiCharacter.h"
#include "Characters/Animation/HiLocomotionAnimInstance.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Component/HiLocomotionComponent.h"
#include "Utils/MathHelper.h"

// Sets default values for this component's properties
UHiGlideComponent::UHiGlideComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bStartWithTickEnabled = true;
	bWantsInitializeComponent = true;

	// ...
}


// Called when the game starts
void UHiGlideComponent::BeginPlay()
{
	Super::BeginPlay();

	// ...
	
}

void UHiGlideComponent::InitializeComponent()
{
	Super::InitializeComponent();

	CharacterOwner = GetPawnChecked<AHiCharacter>();
	
	MyCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(CharacterOwner->GetMovementComponent());
}

// Called every frame
void UHiGlideComponent::TickComponent(float DeltaTime, ELevelTick TickType,
                                      FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

void UHiGlideComponent::StartGlide_Implementation()
{
	if (bGlide)
	{
		return;
	}

	bGlide = true;
	GlideState = EHiGlideState::GlideIdle;

	OldMaxCustomMovementSpeed = MyCharacterMovementComponent->MaxCustomMovementSpeed;
	MyCharacterMovementComponent->MaxCustomMovementSpeed = MaxGlideSpeed;
	MyCharacterMovementComponent->SetGlideFallSpeed(GlideFallSpeed);

	ACharacter *Character = Cast<ACharacter>(GetOwner());

	if (Character)
	{
		Character->LandedDelegate.AddDynamic(this, &UHiGlideComponent::OnLandedCallback);
	}
}

void UHiGlideComponent::StopGlide_Implementation()
{
	bGlide = false;
	GlideState = EHiGlideState::None;
	ACharacter *Character = Cast<ACharacter>(GetOwner());
	if (Character)
	{
		Character->LandedDelegate.RemoveDynamic(this, &UHiGlideComponent::OnLandedCallback);
	}

	MyCharacterMovementComponent->MaxCustomMovementSpeed = OldMaxCustomMovementSpeed;
}

void UHiGlideComponent::OnLandedCallback_Implementation(const FHitResult& Hit)
{
	
}

void UHiGlideComponent::PhysGlide_Implementation(float DeltaTime)
{
	MyCharacterMovementComponent->PhysGlide(DeltaTime, 0);
	ProcessGlideRotation(DeltaTime);
	//UE_LOG(LogMantle, Error, TEXT("UHiMantleComponent::PhysMantle_Implementation %d, ActorLocation = %s"), (int32)OwnerCharacter->GetWorld()->GetNetMode(), *GetOwner()->GetActorLocation().ToString());
}

void UHiGlideComponent::ProcessGlideRotation_Implementation(float DeltaTime)
{
	const FVector &Acceleration = MyCharacterMovementComponent->GetCurrentAcceleration();
	if (Acceleration.IsNearlyZero())
	{
		GlideState = EHiGlideState::GlideIdle;
		AccelerationDirection = 0.0f;
		return;
	}
	const FRotator &TargetRotator = Acceleration.ToOrientationRotator();

	AHiCharacter *Owner = Cast<AHiCharacter>(GetOwner());

	if (!Owner)
		return;

	//TargetRotation = UMathHelper::RNearestInterpConstantTo(TargetRotation, Target, DeltaTime, TargetInterpSpeed);
	TargetRotation = Owner->GetActorRotation();
	AccelerationDirection = UKismetAnimationLibrary::CalculateDirection(Acceleration, TargetRotation);
	TargetRotation.Yaw = TargetRotator.Yaw;
	const FRotator ResultActorRotation = UMathHelper::RNearestInterpConstantTo(Owner->GetActorRotation(), TargetRotation, DeltaTime, ActorInterpSpeed);
	
	FRotator DeltaRotation = Owner->GetActorRotation().UnrotateVector(TargetRotation.Vector()).Rotation();
	if (FMath::Abs(DeltaRotation.Yaw) < MinTurnYaw)
	{
		GlideState = EHiGlideState::GlideForward;
	}
	else if (DeltaRotation.Yaw > 0.0f)
	{
		GlideState = EHiGlideState::GlideRight;
	}
	else
	{
		GlideState = EHiGlideState::GlideLeft;
	}

	UHiLocomotionComponent* LocomotionComponent = Owner->GetLocomotionComponent();
	if (LocomotionComponent)
	{
		LocomotionComponent->SetCharacterRotation(ResultActorRotation);
	}
}