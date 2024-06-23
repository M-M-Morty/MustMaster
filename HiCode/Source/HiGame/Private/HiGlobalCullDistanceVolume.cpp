// Fill out your copyright notice in the Description page of Project Settings.


#include "HiGlobalCullDistanceVolume.h"


AHiGlobalCullDistanceVolume::AHiGlobalCullDistanceVolume(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

bool AHiGlobalCullDistanceVolume::EncompassesPoint(FVector Point, float SphereRadius, float* OutDistanceToPoint) 
{
	//return Super::EncompassesPoint(Point, SphereRadius, OutDistanceToPoint);
	return true;
}
