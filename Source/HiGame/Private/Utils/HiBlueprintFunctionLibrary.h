// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Kismet/BlueprintFunctionLibrary.h"
#include "Animation/AnimNodeReference.h"
#include "HiBlueprintFunctionLibrary.generated.h"

/**
 * 
 */
UCLASS()
class HIGAME_API UHiBlueprintFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	
	UFUNCTION(BlueprintPure, Category = "Blueprint Utils", meta = (ObjectClass = "Object"), meta = (DeterminesOutputType = "ObjectClass"))
	static UObject *GetObjectPropertyByName(TSubclassOf<UObject> ObjectClass, UObject *Object, const FName &Name);

	UFUNCTION(BlueprintPure, Category = "Blueprint Utils")
	static float GetStartPostionFromPoseSearch(const UAnimInstance* AnimInstance, const FAnimNodeReference& PoseSearchHistoryNode, UAnimSequenceBase *Sequence);

	UFUNCTION(BlueprintPure, Category = "Blueprint Utils")
	static FTransform GetSocketTransformFromAnimation(const UAnimSequenceBase *Asset, const FName &SocketName, float CurrentTime, bool bExtractRootMotion);

	UFUNCTION(BlueprintPure, Category = "Blueprint Utils")
	static FString GetClassPath(const UClass *Class);
	
	UFUNCTION(BlueprintPure, Category = "Blueprint Utils")
	static FString GetObjectClassPath(const UObject *Object);

	UFUNCTION(BlueprintCallable, Category=HiGamePlay, meta=(WorldContext="WorldContextObject"))
	static FString GetPIEWorldNetDescription(const UObject* WorldContextObject);

	UFUNCTION(BlueprintPure, Category=HiGamePlay, meta=(WorldContext="WorldContextObject"))
	static bool IsWorldPlaying(const UObject* WorldContextObject);
	
	
	UFUNCTION(BlueprintPure, Category=HiGamePlay, meta=(WorldContext="WorldContextObject"))
    static bool IsInClientLoadRegion(UWorld* World, const FTransform& Transform );
    	

	UFUNCTION(BlueprintCallable, Category=HiGamePlay)
	static void UnregisterAllComponents(AActor* Actor, bool bForReregister = false);
	
	UFUNCTION(BlueprintCallable, Category=HiGamePlay)
	static void RegisterAllComponents(AActor* Actor);
};
