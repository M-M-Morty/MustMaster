// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Components/PawnComponent.h"
#include "HiPawnComponent.generated.h"


UINTERFACE(BlueprintType)
class HIGAME_API UHiReadyInterface : public UInterface
{
	GENERATED_BODY()
};

class IHiReadyInterface
{
	GENERATED_BODY()

public:
	virtual bool IsPawnComponentReadyToInitialize() const = 0;
};


/**
 * UHiPawnComponent
 *
 *	An actor component that can be used for adding custom behavior to pawns.
 */
UCLASS(Blueprintable, Meta = (BlueprintSpawnableComponent))
class HIGAME_API UHiPawnComponent : public UPawnComponent, public IHiReadyInterface
{
	GENERATED_BODY()

public:

	UHiPawnComponent(const FObjectInitializer& ObjectInitializer);

	virtual bool IsPawnComponentReadyToInitialize() const override { return true; }

	virtual void InitializeComponent() override;

	// Needs #RegisterPossessCallback to HiCharacter
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Component")
	void OnPossessedBy(AController* NewController);
	virtual void OnPossessedBy_Implementation(AController* NewController);

	// Needs #RegisterPossessCallback to HiCharacter
	UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Hi|Component")
	void OnUnPossessedBy(AController* NewController);
	virtual void OnUnPossessedBy_Implementation(AController* NewController);
};
