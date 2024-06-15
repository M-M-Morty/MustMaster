// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "HAL/FileManagerGeneric.h"
#include "JsonUtilities.h"
#include "JsonObjectWrapper.h"
#include "GameplayTagContainer.h"
#include "Components/SplineComponent.h"

#include "HiEdRuntime.generated.h"


/**
 * 
 */
UCLASS()
class HIGAME_API UHiEdRuntime : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
public:	
	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static TArray<FString> FindFiles(const FString& Directory, bool Files, bool Directories);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static TArray<FString> FindFilesRecursive(const FString& Directory, const FString& Extension, bool Files, bool Directories);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static const FString LoadFileToString(const FString& FilePath);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FString EncodeJsonToString(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FString GetStringField(const FJsonObjectWrapper& JsonWrapper, const FString& Key);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static bool GetBoolField(const FJsonObjectWrapper& JsonWrapper, const FString& Key);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static int32 GetNumberField(const FJsonObjectWrapper& JsonWrapper, const FString& Key);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FJsonObjectWrapper GenerateJsonWrapperForUE5Map(const FString& DataType, const FString& DataValue);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FString GetUE5DataType(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FTransform GetUE5DataTransform(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FVector GetUE5DataVector(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static bool GetUE5DataBoolean(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static double GetUE5DataFloat(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FString GetUE5DataString(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static int GetUE5DataInt(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static const TArray<FJsonObjectWrapper> GetUE5DataArray(const FJsonObjectWrapper& JsonWrapper);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FTransform GetTransformField(const FJsonObjectWrapper& JsonWrapper, const FString& Key);

	// UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	// static void SetTransformField(const FJsonObjectWrapper& JsonWrapper, const FString& Key, const FTransform& Transform);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FString GetActorId(const AActor* Actor);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static FGameplayTag RequestGameplayTag(FName TagName);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static bool IsReplicated(const UObject* Object, const FName& PropertyName);

	/*
	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
    static FGroupDataInfo LoadFGroupDataInfo(const FString& FilePath);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
    static bool SaveFGroupDataInfo(const FString& FilePath, const FGroupDataInfo& GroupDataInfo);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
    static FSuiteDataInfo LoadFSuiteDataInfo(const FString& FilePath);

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
    static bool SaveFSuiteDataInfo(const FString& FilePath, const FSuiteDataInfo& SuiteDataInfo);
	*/

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static UWorld* GetEditorWorld();

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static bool IsEditor();

	UFUNCTION(BlueprintCallable, Category = HiEdRuntime)
	static void OnSetKeyType(USplineComponent* SplineComponent, ESplinePointType::Type Type);

private:
	static FTransform GetTransformFieldBase(TSharedPtr<FJsonObject> TransformObject);
	static const TArray< TSharedPtr<FJsonValue> > GetUE5DataArrayInteral(const FJsonObjectWrapper& JsonWrapper);
	static bool IsVaildUE5Data(const TArray< TSharedPtr<FJsonValue> > OutArray);
};
