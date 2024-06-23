// Fill out your copyright notice in the Description page of Project Settings.

#include "InteractSystem/InteractWidget.h"

#include "InteractSystem/InteractItemComponent.h"
#include "Blueprint/WidgetLayoutLibrary.h"
#include "Kismet/GameplayStatics.h"
#include "InteractSystem/InteractWidgetUpdater.h"

void UInteractWidget::NativeConstruct()
{
	Super::NativeConstruct();

	WidgetSize_ScreenSpace = WidgetSize_WidgetSpace * UWidgetLayoutLibrary::GetViewportScale(GetWorld());
	SetVisibility(ESlateVisibility::Hidden);
	
	auto Updater = AInteractWidgetUpdater::Get(this);
	if (Updater)
	{
		Updater->RegisterNewInteractWidget(this);
	}
}

void UInteractWidget::NativeTick(const FGeometry& MyGeometry, float InDeltaTime)
{
	Super::NativeTick(MyGeometry, InDeltaTime);
	/*
	InteractComponent = Cast<UInteractItemComponent>(FollowingComponent);
	if(InteractComponent->Observer)
	{
		InteractComponent->Observer->OnInteractActionDelayTime.AddDynamic(this,&UInteractWidget::GetInteractTimeTickEvent);
	}
	*/
}

void UInteractWidget::SetupAttachment(USceneComponent* InSceneComponent, FName InComponentSocket)
{
	check(InSceneComponent);
	FollowingComponent = InSceneComponent;

	FollowingComponentSocket = InComponentSocket;

	RefreshLocation();
}

void UInteractWidget::GetInteractTimeTickEvent(float CurDelayTime,float DurationTime)
{
	//initialize the Time Defined in Widget By Delegate The Native
	InteractTimeTick = CurDelayTime;
	InteractDelayTime = DurationTime;
}

void UInteractWidget::OnInteractStateChanged(EInteractItemState OldState, EInteractItemState NewState)
{
	K2_OnInteractStateChanged(OldState, NewState);
}

void UInteractWidget::Destroy()
{
	SetVisibility(ESlateVisibility::Hidden);
	RemoveFromParent();
}

void UInteractWidget::RemoveFromParent()
{
	Super::RemoveFromParent();

	auto Updater = AInteractWidgetUpdater::Get(this);
	if (Updater)
	{
		Updater->UnregisterInteractWidget(this);
	}
}

bool UInteractWidget::IsPointInScreen(FVector2D TestScreenLocation, FVector2D ViewportSize)
{
	return (TestScreenLocation.X >= 0.0f && TestScreenLocation.X <= ViewportSize.X) && (TestScreenLocation.Y >= 0.0f && TestScreenLocation.Y <= ViewportSize.Y);
}

FVector2D UInteractWidget::ProjectPointOntoScreenSide(FVector2D Point, FVector2D ViewportSize)
{
	//if (!ensure((Point.X >= 0.0f && Point.X <= ViewportSize.X) && (Point.Y >= 0.0f && Point.Y <= ViewportSize.Y)))
	//	return FVector2D(Point.X, Point.Y);

	FVector Point3D = FVector(Point.X, Point.Y, 0.f);

	//4 vertices by clockwise
	FVector A = FVector(0.f, 0.f, 0.f);
	FVector B = FVector(ViewportSize.X, 0.f, 0.f);
	FVector C = FVector(ViewportSize.X, ViewportSize.Y, 0.f);
	FVector D = FVector(0.f, ViewportSize.Y, 0.f);

	FVector ScreenCenter = FVector(ViewportSize.X / 2.f, ViewportSize.Y / 2.f, 0.f);

	FVector Result = FVector::ZeroVector;

	if (Point3D.X < ScreenCenter.X)
	{
		if (Point3D.Y < ScreenCenter.Y)
		{
			if (!ensure(FMath::SegmentIntersection2D(ScreenCenter, Point3D, A, B, Result) || FMath::SegmentIntersection2D(ScreenCenter, Point3D, A, D, Result)))
			{
				return FVector2D(Point.X, Point.Y);
			}
		}
		else
		{
			if (!ensure(FMath::SegmentIntersection2D(ScreenCenter, Point3D, A, D, Result) || FMath::SegmentIntersection2D(ScreenCenter, Point3D, D, C, Result)))
			{
				return FVector2D(Point.X, Point.Y);
			}
		}
	}
	else
	{
		if (Point3D.Y < ScreenCenter.Y)
		{
			if (!ensure(FMath::SegmentIntersection2D(ScreenCenter, Point3D, A, B, Result) || FMath::SegmentIntersection2D(ScreenCenter, Point3D, B, C, Result)))
			{
				return FVector2D(Point.X, Point.Y);
			}
		}
		else
		{
			if (!ensure(FMath::SegmentIntersection2D(ScreenCenter, Point3D, B, C, Result) || FMath::SegmentIntersection2D(ScreenCenter, Point3D, C, D, Result)))
			{
				return FVector2D(Point.X, Point.Y);
			}
		}
	}

	return FVector2D(Result.X, Result.Y);
}

FVector2D UInteractWidget::ClampWidgetPosition(FVector2D WidgetPosition, FVector2D ViewportSize)
{
	WidgetPosition.X = FMath::Clamp(WidgetPosition.X, 0.f, ViewportSize.X - WidgetSize_ScreenSpace.X);
	WidgetPosition.Y = FMath::Clamp(WidgetPosition.Y, 0.f, ViewportSize.Y - WidgetSize_ScreenSpace.Y);
	return WidgetPosition;
}

void UInteractWidget::RefreshLocation()
{
	if (!FollowingComponent)
	{
		return;
	}

	FVector WorldLocation;
	if (FollowingComponentSocket == NAME_None)
	{
		if (FollowingComponent)
		{
			WorldLocation = FollowingComponent->GetComponentLocation();
		}
	}
	else
	{
		if (FollowingComponent)
		{
			WorldLocation = FollowingComponent->GetSocketLocation(FollowingComponentSocket);
		}
	}

	//project world->screen
	auto PC = UGameplayStatics::GetPlayerController(GetWorld(), 0);
	check(PC);

	FVector2D ScreenLocation;
	FVector2D ViewportSize = UWidgetLayoutLibrary::GetViewportSize(GetWorld());
	if (PC->ProjectWorldLocationToScreen(WorldLocation, ScreenLocation))
	{
		if (IsPointInScreen(ScreenLocation, ViewportSize))
		{
			FVector2D WidgetLocation = ScreenLocation - WidgetSize_ScreenSpace / 2.f;
			SetPositionInViewport(ClampWidgetPosition(WidgetLocation, ViewportSize));
		}
		else
		{
			if (bHideMeWhenOutOfScreen)
			{
				Super::SetVisibility(ESlateVisibility::Hidden);
			}
			else
			{
				ScreenLocation = ProjectPointOntoScreenSide(ScreenLocation, ViewportSize);
				FVector2D WidgetLocation = ScreenLocation - WidgetSize_ScreenSpace / 2.f;
				SetPositionInViewport(ClampWidgetPosition(WidgetLocation, ViewportSize));
			}
		}
	}
}