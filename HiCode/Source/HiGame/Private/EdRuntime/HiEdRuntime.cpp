// Fill out your copyright notice in the Description page of Project Settings.

#include "EdRuntime/HiEdRuntime.h"

#include "EdRuntime/HiEdRuntimeStruct.h"
#include "GameplayTagsManager.h"
#if WITH_EDITOR
#include "Editor.h"
#include "UnrealEdGlobals.h"
#include "Editor/UnrealEdEngine.h"
#include "SplineComponentVisualizer.h"
#endif



bool UHiEdRuntime::IsEditor()
{
#if WITH_EDITOR
	return true;
#else
	return false;
#endif
}

TArray<FString> UHiEdRuntime::FindFiles(const FString& Directory, bool Files, bool Directories)
{
	TArray<FString> Output;
	Output.Empty();
	// 这里不检查DirectoryExists，因为Directory会有特殊写法，比如 xxx/*
	FFileManagerGeneric::Get().FindFiles(Output, *Directory, Files, Directories);
	return Output;
}

TArray<FString> UHiEdRuntime::FindFilesRecursive(const FString& Directory, const FString& Extension, bool Files, bool Directories)
{
	TArray<FString> output;
	output.Empty();
	if (FPaths::DirectoryExists(Directory))
	{
		FFileManagerGeneric::Get().FindFilesRecursive(output, *Directory, *Extension, Files, Directories);
	}
	return output;
}

const FString UHiEdRuntime::LoadFileToString(const FString& FilePath)
{
	FString FileData = "";
	if (FPaths::FileExists(FilePath))
	{
		FFileHelper::LoadFileToString(FileData, *FilePath);
	}
	return FileData;
}


FString UHiEdRuntime::EncodeJsonToString(const FJsonObjectWrapper& JsonWrapper)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	FString JsonString;
	TSharedRef<TJsonWriter<>> JsonWriter = TJsonWriterFactory<>::Create(&JsonString);
	if (FJsonSerializer::Serialize(JsonObject.ToSharedRef(), JsonWriter))
	{
		return JsonString;
	}
	return FString();
}



FString UHiEdRuntime::GetStringField(const FJsonObjectWrapper& JsonWrapper, const FString& Key)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	FString Value;
	if (JsonObject->TryGetStringField(Key, Value))
	{
		return Value;
	}
	return FString();
}

bool UHiEdRuntime::GetBoolField(const FJsonObjectWrapper& JsonWrapper, const FString& Key)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	bool Value;
	if (JsonObject->TryGetBoolField(Key, Value))
	{
		return Value;
	}
	return false;
}


//FJsonObjectWrapper UHiEdRuntime::GetUE5ArrayField(const FJsonObjectWrapper& JsonWrapper, const FString& Key)
//{
//	FJsonObjectWrapper Val;
//
//	TSharedPtr<FJsonValue> Value = JsonWrapper.JsonObject->TryGetField(Key);
//	FString JsonString;
//	TSharedRef<TJsonWriter<>> JsonWriter = TJsonWriterFactory<>::Create(&JsonString);
//	if (FJsonSerializer::Serialize(Value, FString(), JsonWriter))
//	{
//		Val.JsonObjectFromString(JsonString);
//	}
//	//TArray< TSharedPtr<FJsonValue> > DataArr = Value.ToSharedRef()->AsArray();
//	return Val;
//}

FJsonObjectWrapper UHiEdRuntime::GenerateJsonWrapperForUE5Map(const FString& DataType, const FString& DataValue)
{
	FJsonObjectWrapper Val;
	FJsonObject JsonObject;
	JsonObject.SetField("Type", MakeShared<FJsonValueString>(DataType));
	JsonObject.SetField("Value", MakeShared<FJsonValueString>(DataValue));
	//const FString Str = FString::Printf(TEXT("{\"Type\": %s, \"Value\":%s}"), *DataType, *DataValue);
	Val.JsonObject = MakeShared<FJsonObject>(JsonObject);
	return Val;
}

int32 UHiEdRuntime::GetNumberField(const FJsonObjectWrapper& JsonWrapper, const FString& Key)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	int32 Value;
	if (JsonObject->TryGetNumberField(Key, Value))
	{
		return Value;
	}
	return 0;

}


FTransform UHiEdRuntime::GetTransformFieldBase(const TSharedPtr<FJsonObject> TransformObject)
{
	FEdVector location;
	FEdQuat rotation;
	FEdVector scale;
	if (FJsonObjectConverter::JsonObjectToUStruct(TransformObject->GetObjectField("translation").ToSharedRef(), &location, 0, 0)
		&& FJsonObjectConverter::JsonObjectToUStruct(TransformObject->GetObjectField("rotation").ToSharedRef(), &rotation, 0, 0)
		&& FJsonObjectConverter::JsonObjectToUStruct(TransformObject->GetObjectField("scale3D").ToSharedRef(), &scale, 0, 0))
	{
		FTransform transform = FTransform(FQuat(rotation.x,rotation.y,rotation.z,rotation.w), FVector(location.x,location.y,location.z), FVector(scale.x,scale.y,scale.z));
		return transform;
	}
	return FTransform();

}

FTransform UHiEdRuntime::GetTransformField(const FJsonObjectWrapper& JsonWrapper, const FString& Key)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	TSharedPtr<FJsonObject> TransformObject = JsonObject->GetObjectField(Key);
	return GetTransformFieldBase(TransformObject);
}

const TArray<FJsonObjectWrapper> UHiEdRuntime::GetUE5DataArray(const FJsonObjectWrapper& JsonWrapper)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	TArray<FJsonObjectWrapper> Val;
	if (IsVaildUE5Data(OutArray))
	{
		TArray< TSharedPtr<FJsonValue> > DataArr = OutArray[1].ToSharedRef()->AsArray();
		for (int i = 0; i < DataArr.Num(); ++i)
		{
			TSharedPtr<FJsonValue>& Data = DataArr[i];
			// TArray< TSharedPtr<FJsonValue> > ArrayValue = Data.ToSharedRef()->AsArray();
			FJsonObjectWrapper JsonWrapperNew;
			JsonWrapperNew.JsonObject = Data.ToSharedRef()->AsObject();
			//const FString Str = FString::Printf(TEXT("{%s:[%s,%s]}"), *FString::FromInt(i), *ArrayValue[0].ToSharedRef()->AsString(), *ArrayValue[1].ToSharedRef()->AsString());
			Val.Add(JsonWrapperNew);
		}
	}
	return Val;
}

const TArray< TSharedPtr<FJsonValue> > UHiEdRuntime::GetUE5DataArrayInteral(const FJsonObjectWrapper& JsonWrapper)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	TArray< TSharedPtr<FJsonValue> > OutArray;
	auto& Data = JsonObject.ToSharedRef()->Values;
	if (Data.Contains("Type"))
	{
		OutArray.Add(Data["Type"]);
	}
	if (Data.Contains("Value"))
	{
		OutArray.Add(Data["Value"]);
	}
	/*for (auto& Data : JsonObject.ToSharedRef()->Values)
	{
		FString Key = Data.Key;
		TSharedPtr<FJsonValue> Value = Data.Value;
		OutArray.Add(Value);
	}*/
	return OutArray;
}

bool UHiEdRuntime::IsVaildUE5Data(const TArray< TSharedPtr<FJsonValue> > Array)
{
	return Array.Num() == 2;
}

FString UHiEdRuntime::GetUE5DataType(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		FString DataType = OutArray[0].ToSharedRef()->AsString();
		return DataType;
	}
	return FString();
}

FTransform UHiEdRuntime::GetUE5DataTransform(const FJsonObjectWrapper& JsonWrapper)
{

	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		FTransform DataValue = GetTransformFieldBase(OutArray[1].ToSharedRef()->AsObject());
		return DataValue;
	}
	return FTransform();
}

FVector UHiEdRuntime::GetUE5DataVector(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		FEdVector Vec;
		if (FJsonObjectConverter::JsonObjectToUStruct(OutArray[1].ToSharedRef()->AsObject().ToSharedRef(), &Vec, 0, 0))
		{
			FVector DataValue = FVector(Vec.x, Vec.y, Vec.z);
			return DataValue;
		}
	}
	return FVector();
}

bool UHiEdRuntime::GetUE5DataBoolean(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		bool DataValue = OutArray[1].ToSharedRef()->AsBool();
		return DataValue;
	}

	return false;
}

double UHiEdRuntime::GetUE5DataFloat(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		double DataValue = OutArray[1].ToSharedRef()->AsNumber();
		return DataValue;
	}

	return 0.0;
}

FString UHiEdRuntime::GetUE5DataString(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		FString DataValue = OutArray[1].ToSharedRef()->AsString();
		return DataValue;
	}

	return FString();
}

int UHiEdRuntime::GetUE5DataInt(const FJsonObjectWrapper& JsonWrapper)
{
	const TArray< TSharedPtr<FJsonValue> > OutArray = GetUE5DataArrayInteral(JsonWrapper);
	if (IsVaildUE5Data(OutArray))
	{
		int DataValue = int(OutArray[1].ToSharedRef()->AsNumber());
		return DataValue;
	}

	return 0;
}

/*void UHiEdRuntime::SetTransformField(const FJsonObjectWrapper& JsonWrapper, const FString& Key, const FTransform& Transform)
{
	TSharedPtr<FJsonObject> JsonObject = JsonWrapper.JsonObject.ToSharedRef();
	//TSharedPtr<FJsonObject> TransformObject = JsonObject->GetObjectField(Key);
	FEdTransform Trans;
	FVector translation_ = Transform.GetLocation();
	Trans.translation = {translation_.X, translation_.Y, translation_.Z};
	FQuat rotation_ = Transform.GetRotation();
	Trans.rotation = {rotation_.X, rotation_.Y, rotation_.Z, rotation_.W};
	FVector scale3D_ = Transform.GetScale3D();
	Trans.scale3D = {scale3D_.X, scale3D_.Y, scale3D_.Z};
	TSharedPtr<FJsonObject> TransformObject = FJsonObjectConverter::UStructToJsonObject(Trans, 0, 0);
	//FString JsonString;
	//FJsonObjectConverter::UStructToJsonObjectString(Trans, JsonString);
	JsonObject->SetObjectField(Key, TransformObject);
}*/


FGameplayTag UHiEdRuntime::RequestGameplayTag(FName TagName)
{
	UGameplayTagsManager& TagManager = UGameplayTagsManager::Get();
	return TagManager.RequestGameplayTag(TagName, false);
}


bool UHiEdRuntime::IsReplicated(const UObject* Object, const FName& PropertyName)
{
	const UClass* Class = Object->GetClass();
	FProperty* Property = Class->FindPropertyByName(PropertyName);
	if (Property)
	{
		return Property->HasAnyPropertyFlags(CPF_Net);
	}
	return false;
}

FString UHiEdRuntime::GetActorId(const AActor* Actor)
{
	return FString::FromInt(Actor->GetUniqueID());
}

UWorld* UHiEdRuntime::GetEditorWorld()
{
#if WITH_EDITOR
	if (GEditor)
	{
		return GEditor->GetEditorWorldContext().World();
	}
#endif
	return nullptr;
}

void UHiEdRuntime::OnSetKeyType(USplineComponent* SplineComponent, ESplinePointType::Type Type)
{
#if WITH_EDITOR
	if (!SplineComponent)
		return;
	//FSplineComponentVisualizer::OnSetKeyType(ConvertSplinePointTypeToInterpCurveMode(Type));
	TSharedPtr<FComponentVisualizer> Visualizer = GUnrealEd->FindComponentVisualizer(SplineComponent->GetClass());
	TSharedPtr<FSplineComponentVisualizer> SplineVisualizer = StaticCastSharedPtr<FSplineComponentVisualizer>(Visualizer);
	check(SplineVisualizer.IsValid());
	FProperty* SplineCurvesProperty = FindFProperty<FProperty>(USplineComponent::StaticClass(), GET_MEMBER_NAME_CHECKED(USplineComponent, SplineCurves));
	SplineComponent->Modify();
	if (AActor* Owner = SplineComponent->GetOwner())
	{
		Owner->Modify();
	}
	SplineVisualizer->NotifyPropertyModified(SplineComponent, SplineCurvesProperty);
	SplineComponent->UpdateSpline();
	SplineComponent->bSplineHasBeenEdited = true;
	GEditor->RedrawLevelEditingViewports(true);
#endif
}
