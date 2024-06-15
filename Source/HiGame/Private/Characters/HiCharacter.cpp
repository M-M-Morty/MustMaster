// Fill out your copyright notice in the Description page of Project Settings.


#include "Characters/HiCharacter.h"
#include "Component/HiAbilitySystemComponent.h"
#include "Component/HiAIComponent.h"
#include "Component/HiLocomotionComponent.h"
#include "Component/HiCharacterMovementComponent.h"
#include "Characters/HiPlayerController.h"
#include "HiPlayerState.h"
#include "Attributies/HiAttributeSet.h"
#include "Components/GameFrameworkComponentManager.h"
#include "InteractSystem/InteractManagerComponent.h"
#include "MotionWarpingComponent.h"
#include "Net/UnrealNetwork.h"
#include "Event/DialogueFlowEvent.h"


namespace CharacterReplication
{
	static ENetRole SavedRole;
}



// Sets default values
AHiCharacter::AHiCharacter(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
	, TimerManager(new FTimerManager())
{
	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;
	
	AbilitySystemComponent = CreateDefaultSubobject<UHiAbilitySystemComponent>(TEXT("gas"));
}

void AHiCharacter::PreNetReceive()
{
	Super::PreNetReceive();
	CharacterReplication::SavedRole = GetLocalRole();
}

void AHiCharacter::PostNetReceive()
{
	Super::PostNetReceive();
	if (GetLocalRole() == CharacterReplication::SavedRole)
	{
		return;
	}
	if (AHiPlayerController* PlayerController = Cast<AHiPlayerController>(GetController()))
	{
		if (PlayerController->GetLocalRole() == GetLocalRole())
		{
			PlayerController->OnPossessPawnReady();
		}
	}
}

void AHiCharacter::FinishDestroy()
{
	if (TimerManager)
	{
		delete TimerManager;
		TimerManager = nullptr;
	}

	Super::FinishDestroy();
}

void AHiCharacter::RegisterPossessCallback(UHiPawnComponent* HiPawnComponent)
{
	if (HiPawnComponent)
	{
		OnPossessedByDelegate.AddUniqueDynamic(HiPawnComponent, &UHiPawnComponent::OnPossessedBy);
		OnUnPossessedByDelegate.AddUniqueDynamic(HiPawnComponent, &UHiPawnComponent::OnUnPossessedBy);
	}
}

void AHiCharacter::UnregisterPossessCallback(UHiPawnComponent* HiPawnComponent)
{
	if (HiPawnComponent)
	{
		OnPossessedByDelegate.RemoveDynamic(HiPawnComponent, &UHiPawnComponent::OnPossessedBy);
		OnUnPossessedByDelegate.RemoveDynamic(HiPawnComponent, &UHiPawnComponent::OnUnPossessedBy);
	}
}

void AHiCharacter::OnPossessedBy(AController* NewController)
{
	if (OnPossessedByDelegate.IsBound())
	{
		OnPossessedByDelegate.Broadcast(NewController);
	}
	
	UE_LOG(LogBlueprintUserMessages, Display, TEXT("<Role: %d> %s On Possessed By (%s)")
		, GetLocalRole(), *GetName(), *GetNameSafe(NewController));
}

void AHiCharacter::OnUnPossessedBy(AController* NewController)
{
	if (OnUnPossessedByDelegate.IsBound())
	{
		OnUnPossessedByDelegate.Broadcast(NewController);
	}

	UE_LOG(LogBlueprintUserMessages, Display, TEXT("<Role: %d> %s On UnPossessed By (%s)")
		, GetLocalRole(), *GetName(), *GetNameSafe(NewController));
}

bool AHiCharacter::NeedInsetShadow_Implementation()
{
	return false;
}

// Called every frame
void AHiCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

	if (TimerManager)
	{
		TimerManager->Tick(DeltaTime);
	}
}

void AHiCharacter::ResetJumpState()
{
	if (GetLocalRole() == ENetRole::ROLE_SimulatedProxy)
	{
		// Simulated Proxy follows network synchronization data and does not simulate on its own
		return;
	}

	// modify for in air state
	bPressedJump = false;
	bWasJumping = false;
	JumpKeyHoldTime = 0.0f;
	JumpForceTimeRemaining = 0.0f;
	if (GetCharacterMovement())
	{
		const auto MovementMode = GetCharacterMovement()->MovementMode;
		const bool bIsInAir = MovementMode == MOVE_Falling || MovementMode == MOVE_Flying || MovementMode == MOVE_Custom;
		if (!bIsInAir)
		{
			JumpCurrentCount = 0;
			JumpCurrentCountPreJump = 0;
		}
	}
}

void AHiCharacter::ClearTimerHandle(const UObject* WorldContextObject, FTimerHandle Handle)
{
	if (Handle.IsValid())
	{
		if (TimerManager)
		{
			TimerManager->ClearTimer(Handle);
		}
	}
}

void AHiCharacter::ClearAndInvalidateTimerHandle(const UObject* WorldContextObject, FTimerHandle& Handle)
{
	if (Handle.IsValid())
	{
		if (TimerManager)
		{
			TimerManager->ClearTimer(Handle);
		}
	}
}

FTimerHandle AHiCharacter::SetTimerDelegate(FTimerDynamicDelegate Delegate, float Time, bool bLooping, float InitialStartDelay, float InitialStartDelayVariance)
{
	FTimerHandle Handle;
	if (Delegate.IsBound())
	{
		if(TimerManager)
		{
			InitialStartDelay += FMath::RandRange(-InitialStartDelayVariance, InitialStartDelayVariance);
			if (Time <= 0.f || (Time + InitialStartDelay) < 0.f)
			{
				FString ObjectName = GetNameSafe(Delegate.GetUObject());
				FString FunctionName = Delegate.GetFunctionName().ToString(); 
				FFrame::KismetExecutionMessage(*FString::Printf(TEXT("%s %s SetTimer passed a negative or zero time. The associated timer may fail to be created/fire! If using InitialStartDelayVariance, be sure it is smaller than (Time + InitialStartDelay)."), *ObjectName, *FunctionName), ELogVerbosity::Warning);
			}

			Handle = TimerManager->K2_FindDynamicTimerHandle(Delegate);
			TimerManager->SetTimer(Handle, Delegate, Time, bLooping, (Time + InitialStartDelay));
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning, 
			TEXT("SetTimer passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}

	return Handle;
}

FTimerHandle AHiCharacter::SetTimerForNextTickDelegate(FTimerDynamicDelegate Delegate)
{
	FTimerHandle Handle;
	if (Delegate.IsBound())
	{
		if (TimerManager)
		{
			Handle = TimerManager->SetTimerForNextTick(Delegate);
		}
	}
	else
	{
		UE_LOG(LogBlueprintUserMessages, Warning,
			TEXT("SetTimerForNextTick passed a bad function (%s) or object (%s)"),
			*Delegate.GetFunctionName().ToString(), *GetNameSafe(Delegate.GetUObject()));
	}

	return Handle;
}

void AHiCharacter::TouchStarted(ETouchIndex::Type FingerIndex, FVector Location)
{
	Jump();
}

void AHiCharacter::TouchStopped(ETouchIndex::Type FingerIndex, FVector Location)
{
	StopJumping();
}


// Called to bind functionality to input
void AHiCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
	//// Set up gameplay key bindings
	check(PlayerInputComponent);
	
	PlayerInputComponent->BindAxis("Turn", this, &APawn::AddControllerYawInput);
	PlayerInputComponent->BindAxis("LookUp", this, &APawn::AddControllerPitchInput);
	// handle touch devices
	PlayerInputComponent->BindTouch(IE_Pressed, this, &AHiCharacter::TouchStarted);
	PlayerInputComponent->BindTouch(IE_Released, this, &AHiCharacter::TouchStopped);
}

bool AHiCharacter::IsPlayer()
{
	//return (GetLocalRole() == ROLE_AutonomousProxy);
	return IsPlayerControlled();
}

bool AHiCharacter::IsClientPlayer()
{
	return (GetLocalRole() == ROLE_AutonomousProxy) && IsPlayer();
}

bool AHiCharacter::IsStandalone()
{
	return (GetNetMode() == NM_Standalone);
}

FVector AHiCharacter::GetBoneLocation(FName BoneName)
{
	return GetMesh()->GetBoneLocation(BoneName);
}

FTransform AHiCharacter::GetBoneTransform(FName BoneName)
{
	auto Idx = GetMesh()->GetBoneIndex(BoneName);
	return GetMesh()->GetBoneTransform(Idx);
}

FVector AHiCharacter::GetSocketLocation(FName SocketName)
{
	return GetMesh()->GetSocketLocation(SocketName);
}

FTransform AHiCharacter::GetSocketTransform(FName SocketName, ERelativeTransformSpace TransformSpace)
{
	return GetMesh()->GetSocketTransform(SocketName, TransformSpace);
}

UActorComponent* AHiCharacter::GetComponentByName(const FString& ComponentName) const
{
	TArray<UActorComponent*> FoundComponents;
	this->GetComponents<UActorComponent>(FoundComponents, false);
	for (UActorComponent* Component : FoundComponents)
	{
		// Search for the one that has a specified name
		if (Component->GetName().Equals(ComponentName, ESearchCase::IgnoreCase))
		{
			return Component;
		}
	}
	return nullptr;	
}

AHiPlayerController* AHiCharacter::GetHiPlayerController() const
{
	return CastChecked<AHiPlayerController>(Controller, ECastCheckedType::NullAllowed);
}
	
AHiPlayerState* AHiCharacter::GetHiPlayerState() const
{
	return CastChecked<AHiPlayerState>(GetPlayerState(), ECastCheckedType::NullAllowed);
}

UHiAbilitySystemComponent* AHiCharacter::GetHiAbilitySystemComponent() const
{
	return Cast<UHiAbilitySystemComponent>(GetAbilitySystemComponent());
}

UAbilitySystemComponent* AHiCharacter::GetAbilitySystemComponent()const
{	
	return AbilitySystemComponent;
}

FName AHiCharacter::AddAttributeSet(UHiAttributeSet* InAttributeSet)
{
	check(InAttributeSet);
	const FName AttributeName = InAttributeSet->GetFName();
	AttributeSets.Add(AttributeName, InAttributeSet);

	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->AddAttributeSet(InAttributeSet);
	}
	
	return AttributeName;
}

void AHiCharacter::RemoveAttributeSet(UHiAttributeSet* InAttributeSet)
{
	check(InAttributeSet);

	const FName AttributeName = InAttributeSet->GetFName();
	AttributeSets.Remove(AttributeName);
	
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->RemoveAttributeSet(InAttributeSet);
	}
}

UClass *AHiCharacter::GetClass()
{
	return Super::GetClass();
}

void AHiCharacter::MoveBlockedBy(const FHitResult& Impact)
{
	if (LocomotionComponent)
	{
		LocomotionComponent->MoveBlockedBy(Impact);
	}

	ReceiveMoveBlockedBy(Impact);
	OnMoveBlockedBy.Broadcast(Impact);
}

/*
void AHiCharacter::OnAbilitySystemInitialized_Implement()
{
	
}

void AHiCharacter::OnAbilitySystemUninitialized_Implement()
{
	
}*/

void AHiCharacter::AdjustInputAfterProcessView_Implementation(const FRotator& ViewRotation, const float LateralCurvatureAdjustAngle/* = 0.0f*/)
{
	if (InputVectorMode == EHiInputVectorMode::CameraSpace)
	{
		const FVector ForwardInput = FVector(ControlInputVector.X, 0.0f, 0.0f);
		const FVector RightInput = FVector(0.0f, ControlInputVector.Y, 0.0f);

		FRotator ForwardRotator = FRotator(0.0f, ViewRotation.Yaw, 0.0f);
		FRotator RightRotator = ForwardRotator;
		RightRotator.Yaw += LateralCurvatureAdjustAngle;

		ControlInputVector = ForwardRotator.RotateVector(ForwardInput) + RightRotator.RotateVector(RightInput);
	}
}

void AHiCharacter::Destroyed()
{
	//RemoveListener();
	Super::Destroyed();
}

//Client only
void AHiCharacter::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();	
	BP_OnRep_PlayerState();
}

void AHiCharacter::OnRep_Controller()
{
	Super::OnRep_Controller();
	BP_OnRep_Controller();
}

void AHiCharacter::PreInitializeComponents()
{
	BP_PreInitializeComponents();
	Super::PreInitializeComponents();

	UGameFrameworkComponentManager::AddGameFrameworkComponentReceiver(this);
}

void AHiCharacter::PostInitializeComponents()
{
	// Initial component ref
	LocomotionComponent = FindComponentByClass<UHiLocomotionComponent>();
	JumpComponent = FindComponentByClass<UHiJumpComponent>();

	ACharacter::PostInitializeComponents();

	// Force do animation tick before movement component updates
	USkeletalMeshComponent* MeshComponent = GetMesh();
	check(MeshComponent);
	UHiCharacterMovementComponent* MyCharacterMovementComponent = Cast<UHiCharacterMovementComponent>(GetMovementComponent());

	/// Process Tick Order
	///		See InitializeComponent @ UHiLocomotionComponent
	///		See InitializeComponent @ UHiAvatarLocomotionAppearance
	///		See InitializeComponent @ UHiCharacterMovementComponent
	///		See PostInitializeComponents @ ACharacter
	if (MyCharacterMovementComponent && MeshComponent->IsPlayingRootMotionFromEverythingNetwork())
	{
		/*** Main Order: Controller --> Appearance --> Mesh --> MotionWarping --> Movement --> AnimEvent ***/

		// Old Order: Movement Tick --> Mesh Tick
		// New Order: Mesh Tick --> Movement Tick --> Anim Event Tick
		MeshComponent->PrimaryComponentTick.RemovePrerequisite(MyCharacterMovementComponent, MyCharacterMovementComponent->PrimaryComponentTick);
		MyCharacterMovementComponent->PrimaryComponentTick.AddPrerequisite(MeshComponent, MeshComponent->PrimaryComponentTick);

		MeshComponent->DispatchAnimEventsTickFunction.bAllowTickOnDedicatedServer = false;
		MeshComponent->AddDispatchAnimEventsPrerequisiteComponent(MyCharacterMovementComponent);

		// Order: MotionWarping --> Mesh Tick
		UMotionWarpingComponent* MotionWarpingComponent = FindComponentByClass<UMotionWarpingComponent>();
		if (MotionWarpingComponent)
		{
			MotionWarpingComponent->AddTickPrerequisiteComponent(MeshComponent);
		}
	}
	else
	{
		/*** Main Order : Controller --> Appearance --> Movement --> Mesh --> AnimEvent   ***/
		/***                          MotionWarping -->                                   ***/
	}

	OnCharacterComponentInitialized.Broadcast();
}

void AHiCharacter::Multicast_OnAttributeChanged_Implementation(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec) {
	this->OnAttributeChanged(Attribute, NewValue, OldValue, Spec);
}

void AHiCharacter::BeginPlay()
{
	UGameFrameworkComponentManager::SendGameFrameworkComponentExtensionEvent(this, UGameFrameworkComponentManager::NAME_GameActorReady);

	Super::BeginPlay();

	if (GetLocalRole() == ROLE_AutonomousProxy)
	{
		FDialogueFlowEvent::Get().OnPlayDialogueMainCharacterTransform.AddDynamic(this, &AHiCharacter::CallbackDialogueCharTransChanged);
	}
}

void AHiCharacter::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	UGameFrameworkComponentManager::RemoveGameFrameworkComponentReceiver(this);

	Super::EndPlay(EndPlayReason);
}

void AHiCharacter::OnRep_AttachmentReplication()
{
	if (bEnableAttachmentReplication)
	{
		Super::OnRep_AttachmentReplication();
	}
}

void AHiCharacter::CallbackDialogueCharTransChanged(const FTransform& CharTransform)
{
	Svr_SetCharacterTransform(CharTransform);
}

void AHiCharacter::Svr_SetCharacterTransform_Implementation(const FTransform& CharTransform)
{
	SetActorTransform(CharTransform);
}

void AHiCharacter::SerializeTransferPrivateData(FArchive& Ar, UPackageMap* PackageMap)
{
	Super::SerializeTransferPrivateData(Ar, PackageMap);
}

void AHiCharacter::PostTransfer()
{
	Super::PostTransfer();
}

void AHiCharacter::GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME_CONDITION(AHiCharacter, EditorID, COND_InitialOnly);
}

