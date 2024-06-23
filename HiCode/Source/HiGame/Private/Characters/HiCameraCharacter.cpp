// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/HiCameraCharacter.h"
#include "Components/SphereComponent.h"
#include "GameFramework/SpringArmComponent.h"
#include "Camera/CameraComponent.h"
#include "Kismet/KismetMathLibrary.h"

// Sets default values
AHiCameraCharacter::AHiCameraCharacter(const FObjectInitializer& ObjectInitializer)
	:Super(ObjectInitializer)
{
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;	
	SphereComponent= CreateDefaultSubobject<USphereComponent>(TEXT("Sphere"));
	RootComponent = SphereComponent;	
	SphereComponent->SetCollisionProfileName(UCollisionProfile::NoCollision_ProfileName);
	
	if (DrawDebug)
	{
		SphereComponent->InitSphereRadius(SphereRadius);	
		SphereComponent->SetVisibility(true);
		SphereComponent->bHiddenInGame = false;
	}	

	SpringArmComponent = CreateDefaultSubobject<USpringArmComponent>(TEXT("SpringArm"));
	SpringArmComponent->SetupAttachment(RootComponent);
	SpringArmComponent->TargetArmLength = InitalArmLength;
	SpringArmComponent->bEnableCameraLag = true;
	SpringArmComponent->CameraLagSpeed = CameraLagSpeed;
	SpringArmComponent->SetRelativeRotation(InitalRotation);	
		
	CameraComponent = CreateDefaultSubobject<UCameraComponent>(TEXT("Camera"));
	CameraComponent->SetupAttachment(SpringArmComponent);

}