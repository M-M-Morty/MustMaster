// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "HiScreenZoneType.generated.h"

USTRUCT(BlueprintType)
struct FHiScreenZoneType
{
	GENERATED_BODY()
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Screen Left")
	float Left = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Screen Right")
	float Right = 1.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Screen Top")
	float Top = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Hi|Screen Bottom")
	float Bottom = 1.0f;

	FHiScreenZoneType operator - (FVector2D const& Other) const 
	{
		FHiScreenZoneType Zone;
		Zone.Left = Left - Other.X;
		Zone.Right = Right - Other.X;
		Zone.Top = Top - Other.Y;
		Zone.Bottom = Bottom - Other.Y;
		return Zone;
	}

	bool Valid()
	{
		return (Left <= Right) && (Top <= Bottom);
	}
};