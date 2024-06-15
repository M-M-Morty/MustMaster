// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "EdActor.generated.h"

UCLASS()
class HIGAME_API AEdActor : public AActor
{
	GENERATED_BODY()
	
public:	
	// Sets default values for this actor's properties
	AEdActor();

#if WITH_EDITOR
	// UObject	
	virtual void PostEditChangeChainProperty(FPropertyChangedChainEvent& PropertyChangedEvent) override;
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
#endif

	UFUNCTION(BlueprintCallable)
	void CallFromPython(const FString& Params);

	UFUNCTION(BlueprintCallable)
	void CallLowLevelRename(FName NewName, UObject* NewOuter);

	UFUNCTION(BlueprintCallable)
	FString CallGetPathName();

	UFUNCTION(BlueprintCallable)
	void SetActorGuid(const FGuid& InGuid);

	UFUNCTION(BlueprintCallable)
	FBox GetBodyBounds(const UPrimitiveComponent* PrimitiveComp);

	UFUNCTION(BlueprintCallable)
	FTransform GetMassSpaceToWorldSpace(const UPrimitiveComponent* PrimitiveComp);

	/**
	 *	Move the physics body to a new pose.
	 *	@param	bTeleport	If true, no velocity is inferred on the kinematic body from this movement, but it moves right away.
	 */
	UFUNCTION(BlueprintCallable)
	void SetBodyTransform(UPrimitiveComponent* PrimitiveComp, const FTransform& NewTransform, ETeleportType Teleport, bool bAutoWake = true);

	/* BlueprintImplementableEvent  Begin */
	UFUNCTION(BlueprintImplementableEvent, Category = Python)
	void FromPython(const FString& Params);
	/* BlueprintImplementableEvent  End*/

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

public:
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Replicated)
	FString EditorID = FString();
};
