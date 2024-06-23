// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiLocomotionCharacter.h"
#include "AbilitySystemInterface.h"
#include "HiAbilities/HiGameplayAbility.h"
#include "HiAbilities/HiGASLibrary.h"
#include "HiCharacterEnumLibrary.h"
#include "TimerManager.h"
#include "HiCharacter.generated.h"

class UHiAttributeSet;

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnMoveBlockedBy, const FHitResult&, HitResult);

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnPossessedByEvent, AController*, NewController);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FOnUnPossessedByEvent, AController*, NewController);


UCLASS(Blueprintable, BlueprintType, config=Game, Meta = (ShortTooltip = "The base character pawn class used by this project."))
class HIGAME_API AHiCharacter : public AHiLocomotionCharacter, public IAbilitySystemInterface
{
	GENERATED_BODY()

public:
	// Sets default values for this actor's properties
	AHiCharacter(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());
	virtual void FinishDestroy() override;

	virtual void ResetJumpState() override;

protected:
	//~ Begin AActor Interface
	virtual void PreInitializeComponents() override;
	virtual void PostInitializeComponents() override;
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	//~ End AActor Interface

	UFUNCTION(BlueprintCallable, Category="Gameplay|Character")
	class AHiPlayerController* GetHiPlayerController() const;
	
	UFUNCTION(BlueprintCallable, Category="Gameplay|Character")
	class AHiPlayerState* GetHiPlayerState() const;
	
	virtual void Destroyed() override;
	
	/** Handler for when a touch input begins. */
	void TouchStarted(ETouchIndex::Type FingerIndex, FVector Location);
	/** Handler for when a touch input stops. */
	void TouchStopped(ETouchIndex::Type FingerIndex, FVector Location);
	
public:	

	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	//Server Only, Calls before Server`s AcknowledgePossession.
	//virtual void PossessedBy(AController* NewController) override;

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Character")
	void UnregisterPossessCallback(UHiPawnComponent* HiPawnComponent);

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Character")
	void RegisterPossessCallback(UHiPawnComponent* HiPawnComponent);

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Character")
	void OnPossessedBy(AController* NewController);

	UFUNCTION(BlueprintCallable, Category = "Gameplay|Character")
	void OnUnPossessedBy(AController* NewController);

	UFUNCTION(BlueprintNativeEvent, Category = "Rendering|Character", CallInEditor)
	bool NeedInsetShadow();

	/** Always called immediately before properties are received from the remote. */
	virtual void PreNetReceive() override;

	/** Always called immediately after properties are received from the remote. */
	virtual void PostNetReceive() override;

	/** Returns the properties used for network replication, this needs to be overridden by all actor classes with native replicated properties */
	virtual void GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const override;

	UFUNCTION(BlueprintImplementableEvent, Category = Attribute)
	void OnAttributeChanged(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec);

	UFUNCTION(NetMulticast, Reliable)
	void Multicast_OnAttributeChanged(FGameplayAttribute Attribute, float NewValue, float OldValue, const FGameplayEffectSpec& Spec);

	UFUNCTION(BlueprintImplementableEvent, Category = Attribute)
	void K2_OnGamePlayTagNewOrRemove(const FGameplayTag RaiseShieldTag, int32 NewCount);
	
	// UFUNCTION(BlueprintImplementableEvent)
	// void OnDamaged(float DamageAmount, const FHitResult& HitInfo, AActor* InstigatorCharacter, AActor* DamageCauser, const UGameplayAbility* DamageAbility, const FGameplayEffectSpec& DamageGESpec);
	//
	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	class UHiAbilitySystemComponent* GetHiAbilitySystemComponent() const;
	
	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	virtual UAbilitySystemComponent* GetAbilitySystemComponent()const override;

	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	UClass *GetClass();

	/** Add attribute set to character and ASC */
	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	FName AddAttributeSet(UHiAttributeSet* InAttributeSet);

	/** Remove attribute set from character and ASC */
	UFUNCTION(BlueprintCallable, Category="Gameplay|Ability")
	void RemoveAttributeSet(UHiAttributeSet* InAttributeSet);

	UPROPERTY(BlueprintAssignable)
	FOnMoveBlockedBy OnMoveBlockedBy;
	
	virtual void MoveBlockedBy(const FHitResult& Impact);

	UFUNCTION(BlueprintImplementableEvent)
	void ReceiveMoveBlockedBy(const FHitResult& Impact);
	
	/**
	 * Notify client when attack check with hit info.
	 * This may merge with HandleDamage in future (Need to modify GE support user data to contain hit info.)
	 * Right now it will broadcast to all clients.
	 * @param KnockInfo custom knock params.
	 *
	 * TODO this will move to blueprint after PostGameplayEffectExecute expose to blueprint. 
	 */
	UFUNCTION(BlueprintImplementableEvent)
	void HandleKnock(AActor* InstigatorCharacter, AActor* DamageCauser, const UObject* KnockInfo);

	UFUNCTION(BlueprintImplementableEvent, Category = "Ability")
	void ClientOnRep_ActivateAbilities();	

	UFUNCTION(BlueprintImplementableEvent, Category = "Ability")
	void OnAbilitySystemInitialized();

	UFUNCTION(BlueprintImplementableEvent, Category = "Ability")
	void OnAbilitySystemUninitialized();

	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Input")
	void AdjustInputAfterProcessView(const FRotator& ViewRotation, const float LateralCurvatureAdjustAngle = 0.0f);

	UFUNCTION(BlueprintCallable, Category="Gameplay|Timer")
	void ClearTimerHandle(const UObject* WorldContextObject, FTimerHandle Handle);

	UFUNCTION(BlueprintCallable, Category="Gameplay|Timer")
	void ClearAndInvalidateTimerHandle(const UObject* WorldContextObject, FTimerHandle& Handle);

	UFUNCTION(BlueprintCallable, Category="Gameplay|Timer")
	FTimerHandle SetTimerDelegate(UPARAM(DisplayName="Event") FTimerDynamicDelegate Delegate, float Time, bool bLooping, float InitialStartDelay = 0.f, float InitialStartDelayVariance = 0.f);

	UFUNCTION(BlueprintCallable, Category="Gameplay|Timer")
	FTimerHandle SetTimerForNextTickDelegate(UPARAM(DisplayName = "Event") FTimerDynamicDelegate Delegate);

public:
	UFUNCTION(BlueprintCallable)
	bool IsPlayer();

	UFUNCTION(BlueprintCallable)
	bool IsClientPlayer();

	UFUNCTION(BlueprintCallable)
	bool IsStandalone();

	UFUNCTION(BlueprintCallable)
	FVector GetBoneLocation(FName BoneName);

	UFUNCTION(BlueprintCallable)
	FTransform GetBoneTransform(FName BoneName);

	UFUNCTION(BlueprintCallable)
	FVector GetSocketLocation(FName SocketName);

	UFUNCTION(BlueprintCallable)
	FTransform GetSocketTransform(FName SocketName, ERelativeTransformSpace TransformSpace = RTS_World);

	UFUNCTION(BlueprintCallable)
	UActorComponent* GetComponentByName(const FString& ComponentName) const;
	
protected:
	//client only
	virtual  void OnRep_PlayerState() override;

	virtual void OnRep_Controller() override;
	
	UFUNCTION(BlueprintImplementableEvent)//implement c++ try again
	void BP_OnRep_PlayerState();
	
	UFUNCTION(BlueprintImplementableEvent)
	void BP_OnRep_Controller();
	
	UFUNCTION(BlueprintImplementableEvent)
	void BP_PreInitializeComponents();

	virtual void OnRep_AttachmentReplication();

	float TimeSeconds = 0.0f;

public:
	UFUNCTION()
	void CallbackDialogueCharTransChanged(const FTransform& CharTransform);

	UFUNCTION(Reliable, Server)
	void Svr_SetCharacterTransform(const FTransform& CharTransform);

protected:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Gameplay|Ability", meta = (AllowPrivateAccess = "true"))
	UHiAbilitySystemComponent* AbilitySystemComponent;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Gameplay|Ability", meta = (AllowPrivateAccess = "true"))
	TMap<FName, UHiAttributeSet*> AttributeSets;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated)
	FString EditorID = FString();

public:
	// UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="Gameplay|Ability", Meta = (AllowPrivateAccess = "true"))
	// ECharIdentity Identity = ECharIdentity::Player;
	
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Gameplay|Ability", Meta = (AllowPrivateAccess = "true"))
	EHiInputVectorMode InputVectorMode = EHiInputVectorMode::CameraSpace;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Gameplay|Ability")
	bool AISwitch = true; 
	
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Gameplay|Ability")
	bool InWithStand = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite)
	bool bEnableAttachmentReplication = true;

	UPROPERTY(BlueprintAssignable)
	FOnPossessedByEvent OnPossessedByDelegate;

	UPROPERTY(BlueprintAssignable)
	FOnUnPossessedByEvent OnUnPossessedByDelegate;

	FTimerManager* TimerManager;

	inline FTimerManager& GetTimerManager() const
	{
		return *TimerManager;
	}

	virtual void SerializeTransferPrivateData(FArchive& Ar, UPackageMap* PackageMap) override;
	virtual void PostTransfer() override;

private:
	FVector AccelerationCopy;
};
