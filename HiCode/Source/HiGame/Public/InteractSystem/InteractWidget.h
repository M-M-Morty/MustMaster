// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "InteractItemComponent.h"
#include "Blueprint/UserWidget.h"
#include "InteractWidget.generated.h"

/**
 * 
 */
UCLASS()
class UInteractWidget : public UUserWidget
{
	GENERATED_BODY()	
	
public:
	virtual void NativeConstruct();

	virtual void NativeTick(const FGeometry& MyGeometry, float InDeltaTime) override;
	virtual void SetupAttachment(USceneComponent* InSceneComponent, FName InComponentSocket = NAME_None);

	virtual void SetHideMeWhenOutOfScreen(bool bInHideMeWhenOutOfScreen) { bHideMeWhenOutOfScreen = bInHideMeWhenOutOfScreen; }
	
	virtual void Destroy();
	virtual void RemoveFromParent() override;

	void RefreshLocation();
	
	UFUNCTION()
	void GetInteractTimeTickEvent(float CurDelayTime,float DurationTime);

	bool IsBoundActionDelayTimeDelegate = false;

protected:
	bool IsPointInScreen(FVector2D TestScreenLocation, FVector2D ViewportSize);
	FVector2D ProjectPointOntoScreenSide(FVector2D Point, FVector2D ViewportSize);
	FVector2D ClampWidgetPosition(FVector2D WidgetPosition, FVector2D ViewportSize);

	//the 3D world component that I'm following.
	UPROPERTY(BlueprintReadOnly)
	USceneComponent* FollowingComponent = 0;

	UPROPERTY(BlueprintReadOnly)
	FName FollowingComponentSocket = NAME_None;

	UPROPERTY(EditDefaultsOnly)
	FVector2D WidgetSize_WidgetSpace;

	/* widget size in screen space */
	FVector2D WidgetSize_ScreenSpace;

	bool bHideMeWhenOutOfScreen = true;

	UPROPERTY(BlueprintReadOnly)
	float InteractDelayTime =.0f;

	UPROPERTY(BlueprintReadOnly)
	float InteractTimeTick = .0;

	UPROPERTY(BlueprintReadOnly)
	UInteractItemComponent* InteractComponent =nullptr;
	



public:
	virtual void OnInteractStateChanged(EInteractItemState OldState, EInteractItemState NewState);

protected:
	UFUNCTION(BlueprintImplementableEvent, meta = (DisplayName = "On Interact State Changed"))
	void K2_OnInteractStateChanged(EInteractItemState OldState, EInteractItemState NewState);
};
