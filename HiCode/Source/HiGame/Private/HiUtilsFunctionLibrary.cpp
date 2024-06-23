// Fill out your copyright notice in the Description page of Project Settings.

#include "HiUtilsFunctionLibrary.h"
#include "CoreMinimal.h"
#include "AbilitySystemBlueprintLibrary.h"
#include "EngineUtils.h"
#include "SequencerTrackInstanceBP.h"
#include "Animation/AnimInstance.h"
#include "Animation/AnimMontage.h"
#include "EntitySystem/MovieSceneEntitySystemLinker.h"
#include "Kismet/KismetSystemLibrary.h"
#include "NiagaraComponent.h"
#include "NiagaraSystemInstanceController.h"
#include "Components/TimelineComponent.h"
#include "NavigationSystem.h"
#include "HiAbilities/HiTargetTypes.h"
#include "AkAudioType.h"
#include "DistributedDSUtils.h"
#include "Trigger/HiTriggerVolume.h"
#include "Perception/AIPerceptionSystem.h"
#include "GameplayDebugger.h"
#include "HiGameplayDebuggerCategoryReplicator.h"
#include "Characters/HiPlayerController.h"
#include "Animation/AnimationAsset.h"
#include "Engine/AssetUserData.h"
#include "Kismet/GameplayStatics.h"
#if WITH_EDITOR
#include "Engine/SCS_Node.h"
#include "Engine/SimpleConstructionScript.h"
#endif

TMap<FString, UObject*> UHiUtilsFunctionLibrary::BlueprintTypeCache;

UClass* UHiUtilsFunctionLibrary::FindObjectFromName(const FName& InName)
{
	return FindObject<UClass>(ANY_PACKAGE, *InName.ToString());
}

FString UHiUtilsFunctionLibrary::GetEnumPathFromName(const FName& InName)
{
	UEnum* SubObjectClass = FindObject<UEnum>(ANY_PACKAGE, *InName.ToString());
	if (IsValid(SubObjectClass))
	{
		return SubObjectClass->GetPathName();
	}
	return FString();
}

FString UHiUtilsFunctionLibrary::GetStructPathFromName(const FName& InName)
{
	UStruct* SubObjectClass = FindObject<UStruct>(ANY_PACKAGE, *InName.ToString());
	if (IsValid(SubObjectClass))
	{
		return SubObjectClass->GetPathName();
	}
	return FString();
}

bool UHiUtilsFunctionLibrary::FilterPassesForActor(FGameplayTargetDataFilterHandle FilterHandle, const AActor* ActorToBeFiltered)
{
	return FilterHandle.FilterPassesForActor(ActorToBeFiltered);
}

FGameplayAbilityTargetDataHandle UHiUtilsFunctionLibrary::AbilityTargetDataFromHitResults(const TArray<FHitResult>& HitResults)
{
	FGameplayAbilityTargetDataHandle ReturnDataHandle;

	for (int32 i = 0; i < HitResults.Num(); i++)
	{
		FGameplayAbilityTargetData_SingleTargetHit* ReturnData = new FGameplayAbilityTargetData_SingleTargetHit();
		ReturnData->HitResult = HitResults[i];
		ReturnDataHandle.Add(ReturnData);
	}

	return ReturnDataHandle;
}

FGameplayAbilityTargetDataHandle UHiUtilsFunctionLibrary::AbilityTargetDataFromHitResultsWithKnockInfo(const TArray<FHitResult>& HitResults, UObject* KnockInfo)
{
	FGameplayAbilityTargetDataHandle ReturnDataHandle;

		for (int32 i = 0; i < HitResults.Num(); i++)
		{
			FHiGameplayAbilityTargetData_SingleHit* ReturnData = new FHiGameplayAbilityTargetData_SingleHit();
			ReturnData->HitResult = HitResults[i];
			ReturnData->SetKnockInfo(KnockInfo);
			ReturnDataHandle.Add(ReturnData);
		}

	
	return ReturnDataHandle;
}

FGameplayAbilityTargetDataHandle UHiUtilsFunctionLibrary::AbilityAOETargetDataFromHitResultsWithKnockInfo(const TArray<FHitResult>& HitResults, UObject* KnockInfo, const FGameplayAbilityTargetingLocationInfo& LocationInfo)
{
	FGameplayAbilityTargetDataHandle ReturnDataHandle;
	FHiGameplayAbilityTargetData_HitArray* ReturnData = new FHiGameplayAbilityTargetData_HitArray();
	ReturnData->Hits = HitResults;
	ReturnData->SourceLocation = LocationInfo;
	ReturnData->SetKnockInfo(KnockInfo);
	ReturnDataHandle.Add(ReturnData);
	return ReturnDataHandle;
}

FGameplayAbilityTargetDataHandle UHiUtilsFunctionLibrary::AbilityTargetDataArrayFromActors(const TArray<AActor*> Actors, UObject* KnockInfo, const FGameplayAbilityTargetingLocationInfo& LocationInfo)
{
	TArray<TWeakObjectPtr<AActor>> ActorsArr;
	for (auto CurActor : Actors)
	{
		ActorsArr.Add(CurActor);
	}
	
	FGameplayAbilityTargetDataHandle ReturnDataHandle;
	FHiGameplayAbilityTargetData_ActorArray* ReturnData = new FHiGameplayAbilityTargetData_ActorArray();
	ReturnData->SetActors(ActorsArr);
	ReturnData->SetKnockInfo(KnockInfo);
	ReturnData->SourceLocation = LocationInfo;
	
	ReturnDataHandle.Add(ReturnData);
	return ReturnDataHandle;
}

UObject* UHiUtilsFunctionLibrary::GetKnockInfoFromTargetData(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if (!Data)
		{
			return nullptr;
		}
		
		if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_SingleHit::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_SingleHit *HitData = static_cast<FHiGameplayAbilityTargetData_SingleHit*>(Data);
			if (HitData)
			{
				UObject* KnockInfo = HitData->GetKnockInfo();
				return KnockInfo;
			}
		}

		if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_ActorArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_ActorArray* HitArrData = static_cast<FHiGameplayAbilityTargetData_ActorArray*>(Data);
			if (HitArrData)
			{
				UObject* KnockInfo = HitArrData->GetKnockInfo();
				return KnockInfo;
			}
		}

		if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_HitArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_HitArray* HitArrData = static_cast<FHiGameplayAbilityTargetData_HitArray*>(Data);
			if (HitArrData)
			{
				UObject* KnockInfo = HitArrData->GetKnockInfo();
				return KnockInfo;
			}
		}
	}

	return nullptr;
}

void UHiUtilsFunctionLibrary::GetHitsFromTargetData(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index, TArray<FHitResult>& Hits)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_HitArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_HitArray *HitData = static_cast<FHiGameplayAbilityTargetData_HitArray*>(Data);
			if (HitData)
			{
				Hits = HitData->Hits;
			}
		}
	}
}

void UHiUtilsFunctionLibrary::GetSourceLocationFromTargetData(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index, FGameplayAbilityTargetingLocationInfo& SourceLocation)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_HitArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_HitArray *HitData = static_cast<FHiGameplayAbilityTargetData_HitArray*>(Data);
			if (HitData)
			{
				SourceLocation = HitData->SourceLocation;
			}
		}

		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_ActorArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_ActorArray *HitData = static_cast<FHiGameplayAbilityTargetData_ActorArray*>(Data);
			if (HitData)
			{
				SourceLocation = HitData->SourceLocation;
			}
		}
	}
}

void UHiUtilsFunctionLibrary::UpdateKnockInfoOfTargetData(const FGameplayAbilityTargetDataHandle& TargetData, UObject* KnockInfo)
{
	for (int32 TargetDataIndex = 0; TargetDataIndex < TargetData.Data.Num(); ++TargetDataIndex)
	{
		if (TargetData.Data.IsValidIndex(TargetDataIndex))
		{
			FGameplayAbilityTargetData* Data = TargetData.Data[TargetDataIndex].Get();
			if (!Data)
			{
				return;
			}
		
			if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_SingleHit::StaticStruct()))
			{
				FHiGameplayAbilityTargetData_SingleHit *HitData = static_cast<FHiGameplayAbilityTargetData_SingleHit*>(Data);
				if (HitData)
				{
					HitData->SetKnockInfo(KnockInfo);
					return;
				}
			}

			if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_ActorArray::StaticStruct()))
			{
				FHiGameplayAbilityTargetData_ActorArray* HitArrData = static_cast<FHiGameplayAbilityTargetData_ActorArray*>(Data);
				if (HitArrData)
				{
					HitArrData->SetKnockInfo(KnockInfo);
					return;
				}
			}

			if(Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_HitArray::StaticStruct()))
			{
				FHiGameplayAbilityTargetData_HitArray* HitArrData = static_cast<FHiGameplayAbilityTargetData_HitArray*>(Data);
				if (HitArrData)
				{
					HitArrData->SetKnockInfo(KnockInfo);
					return;
				}
			}
		}
	}
}

bool UHiUtilsFunctionLibrary::IsTargetActorArray(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_ActorArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_ActorArray *HitData = static_cast<FHiGameplayAbilityTargetData_ActorArray*>(Data);
			if (HitData)
			{
				return true;
			}
		}
	}

	return false;
}

bool UHiUtilsFunctionLibrary::IsTargetHitArray(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_HitArray::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_HitArray *HitData = static_cast<FHiGameplayAbilityTargetData_HitArray*>(Data);
			if (HitData)
			{
				return true;
			}
		}
	}

	return false;
}

bool UHiUtilsFunctionLibrary::IsSingleHitResult(const FGameplayAbilityTargetDataHandle& TargetData, int32 Index)
{
	if (TargetData.Data.IsValidIndex(Index))
	{
		FGameplayAbilityTargetData* Data = TargetData.Data[Index].Get();
		if(Data && Data->GetScriptStruct()->IsChildOf(FHiGameplayAbilityTargetData_SingleHit::StaticStruct()))
		{
			FHiGameplayAbilityTargetData_SingleHit *HitData = static_cast<FHiGameplayAbilityTargetData_SingleHit*>(Data);
			if (HitData)
			{
				return true;
			}
		}
	}

	return false;
}


void  UHiUtilsFunctionLibrary::FindAllMeshCompsFromBlueprintClass(UClass* Class, TArray<UStaticMeshComponent*>& Comps)
{
#if WITH_EDITOR
	if(!IsValid(Class))
	{
		return;
	}

	if (auto* BlueprintGeneratedClass = Cast<UBlueprintGeneratedClass> (Class))
	{
		USimpleConstructionScript* SCS = BlueprintGeneratedClass->SimpleConstructionScript;
		for(auto* Node : SCS->GetAllNodes())
		{
			if(UStaticMeshComponent * MeshComp = Cast<UStaticMeshComponent>(Node->ComponentTemplate))
			{
				Comps.Add(MeshComp);
			}
		}
	}
#endif
}


void UHiUtilsFunctionLibrary::RegisterComponent(UActorComponent* Component)
{
	Component->RegisterComponent();
}

float UHiUtilsFunctionLibrary::CheckLoadingProgress(const FString& MapName)
{
	static const int REPEATE_CHECK_TIMES = 5;
	static const float JUST_BEGIN_PROGRESS = 0.0;
	static const float AMOST_DONE_PROGRESS = 0.99;
	static const float SUCESS_LOAD_PROGRESS = 1.0;
	
	static int TaskNum = 0;
	static int FinishedCheckTimes = REPEATE_CHECK_TIMES;
	const UWorld* World= GEngine->GetCurrentPlayWorld(nullptr);
	const FString WorldName = World? World->GetName() : "";
	if (WorldName != MapName)
	{
		TaskNum = 0;
		FinishedCheckTimes = REPEATE_CHECK_TIMES;
		return JUST_BEGIN_PROGRESS;
	}

	const int Number = GetNumAsyncPackages();
	TaskNum = FMath::Max(Number, TaskNum);
	
	//UE_LOG(LogTemp, Warning, TEXT("CheckLoadingProgress : (%d, %d, %d, %s)"), Number, TaskNum, FinishedCheckTimes, *WorldName);
	if (Number == 0 || TaskNum == 0)
	{
		if (FinishedCheckTimes <= 0)
		{
			TaskNum = 0;
			FinishedCheckTimes = REPEATE_CHECK_TIMES;
			return SUCESS_LOAD_PROGRESS;
		}
		--FinishedCheckTimes;
		return AMOST_DONE_PROGRESS;
	}
	FinishedCheckTimes = REPEATE_CHECK_TIMES;
	return 1 - 1.0 * Number / TaskNum;
}

void UHiUtilsFunctionLibrary::DestroyComponent(UActorComponent* Component)
{
	if (Component)
	{
		Component->DestroyComponent();
	}
}

bool UHiUtilsFunctionLibrary::IsServer(const UObject* WorldContextObject)
{
	return UKismetSystemLibrary::IsDedicatedServer(WorldContextObject);
}

bool UHiUtilsFunctionLibrary::IsClient(const UObject* WorldContextObject)
{
	return !UKismetSystemLibrary::IsServer(WorldContextObject);
}

UObject* UHiUtilsFunctionLibrary::GetGWorld()
{
	return GWorld.GetReference();
}

UGameInstance* UHiUtilsFunctionLibrary::GetGGameInstance()
{
	if (GWorld.GetReference() == nullptr)
	{
		return nullptr;
	}
	return GWorld->GetGameInstance();
}

bool UHiUtilsFunctionLibrary::IsServerWorld()
{
	return IsServer(GetGWorld());
}

bool UHiUtilsFunctionLibrary::IsClientWorld()
{
	return IsClient(GetGWorld());
}

int64 UHiUtilsFunctionLibrary::GetNowTimestamp()
{
	return FDateTime::Now().ToUnixTimestamp();
}

int64 UHiUtilsFunctionLibrary::GetNowTimestampMs()
{
	return (FDateTime::Now().GetTicks() - FDateTime(1970, 1, 1).GetTicks()) / (ETimespan::TicksPerSecond / 1000);
}

float UHiUtilsFunctionLibrary::GetMontagePlayLength(UAnimMontage* Montage)
{
	return Montage->GetPlayLength();
}

FRotator UHiUtilsFunctionLibrary::Rotator_Normalized(const FRotator& Rotation)
{
	return Rotation.GetNormalized();
}

void UHiUtilsFunctionLibrary::SetMontageBlendInTime(UAnimMontage* Montage, float BlendTime)
{
	if (Montage)
	{
		Montage->BlendIn.SetBlendTime(BlendTime);
	}
}

void UHiUtilsFunctionLibrary::SetMontageBlendOutTime(UAnimMontage* Montage, float BlendTime)
{
	if (Montage)
	{
		Montage->BlendOut.SetBlendTime(BlendTime);
	}
}

void UHiUtilsFunctionLibrary::SetMontagePlayRate(USkeletalMeshComponent *Component, UAnimMontage *Montage, float PlayRate)
{
	UAnimInstance *Instance = Component->GetAnimInstance();
	if (!Instance)
	{
		return;
	}
	FAnimMontageInstance *MontageInstance = Instance->GetActiveInstanceForMontage(Montage);
	if (MontageInstance)
	{
		MontageInstance->SetPlayRate(PlayRate);
	}
}

void UHiUtilsFunctionLibrary::RegisterLuaConsoleCmd(const FString& CmdName, const FString& CmdHelp)
{
	IConsoleManager::Get().RegisterConsoleCommand(GetData(CmdName),GetData(CmdHelp), ECVF_Cheat);
}

TSet<FString>& UHiUtilsFunctionLibrary::ObjectGetAllCallableFunctionNames(UObject* Object)
{
	if (!IsValid(Object))
	{
		static TSet<FString> EmptyNames;
		return EmptyNames;
	}
	
    const auto Class = Object->IsA<UClass>() ? static_cast<UClass*>(Object) : Object->GetClass();
	const auto ClassName = Class->GetName();

	static TMap<FString, TSet<FString> > ClassCallableFunctionNames;

	if (!ClassCallableFunctionNames.Contains(ClassName))
	{
		ClassCallableFunctionNames.Add(ClassName, TSet<FString>());
		for (TFieldIterator<UFunction> It(Class, EFieldIteratorFlags::IncludeSuper, EFieldIteratorFlags::ExcludeDeprecated, EFieldIteratorFlags::IncludeInterfaces); It; ++It)
		{
			UFunction* Function = *It;
			if (Function->HasAnyFunctionFlags(FUNC_BlueprintCallable | FUNC_BlueprintPure | FUNC_Const))
			{
				const auto FName = Function->GetFName().ToString();
				ClassCallableFunctionNames[ClassName].Add(FName);
			}
		}
	}

	return ClassCallableFunctionNames[ClassName];
}

float UHiUtilsFunctionLibrary::GetNiagaraSystemInstanceAge(UNiagaraComponent* NiagaraComponent)
{
	if (!IsValid(NiagaraComponent))
	{
		return 0.0f;
	}

	if (auto const SystemInstanceController = NiagaraComponent->GetSystemInstanceController())
	{
		return SystemInstanceController->GetAge();
	}

	return 0.0f;
}

void UHiUtilsFunctionLibrary::GetTimelineValueRange(UTimelineComponent* TimelineComponent, float& MinValue, float& MaxValue)
{
	TSet<class UCurveBase*> Curves;
	TimelineComponent->GetAllCurves(Curves);
	for (UCurveBase* Curve : Curves)
	{
		Curve->GetValueRange(MinValue, MaxValue);
	}
}

void UHiUtilsFunctionLibrary::FindNavPath(AController* Controller, const FVector& GoalLocation, TArray<FVector>& OutPath)
{
	UNavigationSystemV1* NavSys = Controller ? FNavigationSystem::GetCurrent<UNavigationSystemV1>(Controller->GetWorld()) : nullptr;
	if (NavSys == nullptr || Controller == nullptr || Controller->GetPawn() == nullptr)
	{
		UE_LOG(LogNavigation, Warning, TEXT("UHiUtilsFunctionLibrary::FindNavPath called for NavSys:%s Controller:%s controlling Pawn:%s (if any of these is None then there's your problem"),
			*GetNameSafe(NavSys), *GetNameSafe(Controller), Controller ? *GetNameSafe(Controller->GetPawn()) : TEXT("NULL"));
		return;
	}
	
	const FVector AgentNavLocation = Controller->GetNavAgentLocation();
	const ANavigationData* NavData = NavSys->GetNavDataForProps(Controller->GetNavAgentPropertiesRef(), AgentNavLocation);
	if (NavData)
	{
		FPathFindingQuery Query(Controller, *NavData, AgentNavLocation, GoalLocation);
		FPathFindingResult Result = NavSys->FindPathSync(Query);
		if (Result.IsSuccessful())
		{
			TArray<FNavPathPoint>& PathPoints = Result.Path->GetPathPoints();
			for(auto iter = PathPoints.begin(); iter != PathPoints.end(); ++iter)
			{
				OutPath.Push((*iter).Location);
			}
		}
	}
}

bool UHiUtilsFunctionLibrary::GetRandomReachablePointInRadius(AController* Controller, const FVector& Origin, float Radius, FVector& ResultLocation)
{
	const UNavigationSystemV1* NavSys = Controller ? FNavigationSystem::GetCurrent<UNavigationSystemV1>(Controller->GetWorld()) : nullptr;
	if (NavSys == nullptr || Controller == nullptr || Controller->GetPawn() == nullptr)
	{
		UE_LOG(LogNavigation, Warning, TEXT("UHiUtilsFunctionLibrary::GetRandomReachablePointInRadius called for NavSys:%s Controller:%s controlling Pawn:%s (if any of these is None then there's your problem"),
			*GetNameSafe(NavSys), *GetNameSafe(Controller), Controller ? *GetNameSafe(Controller->GetPawn()) : TEXT("NULL"));
		return false;
	}

	FNavLocation Destination;

	if (NavSys->GetRandomReachablePointInRadius(Origin, Radius, Destination))
	{
		ResultLocation = Destination.Location;
		return true;
	}

	return false;
}

bool UHiUtilsFunctionLibrary::GetRandomPointInNavigableRadius(AController* Controller, const FVector& Origin, float Radius, FVector& ResultLocation)
{
	const UNavigationSystemV1* NavSys = Controller ? FNavigationSystem::GetCurrent<UNavigationSystemV1>(Controller->GetWorld()) : nullptr;
	if (NavSys == nullptr || Controller == nullptr || Controller->GetPawn() == nullptr)
	{
		UE_LOG(LogNavigation, Warning, TEXT("UHiUtilsFunctionLibrary::GetRandomPointInNavigableRadius called for NavSys:%s Controller:%s controlling Pawn:%s (if any of these is None then there's your problem"),
			*GetNameSafe(NavSys), *GetNameSafe(Controller), Controller ? *GetNameSafe(Controller->GetPawn()) : TEXT("NULL"));
		return false;
	}

	FNavLocation Destination;

	if (NavSys->GetRandomPointInNavigableRadius(Origin, Radius, Destination))
	{
		ResultLocation = Destination.Location;
		return true;
	}

	return false;
}

bool UHiUtilsFunctionLibrary::IsWorldStartup(UObject* WorldContextObject)
{
	if (!IsValid(WorldContextObject))
	{
		return false;
	}

	auto World = WorldContextObject->GetWorld();
	if (!IsValid(World))
	{
		return false;
	}
	
	return World->bStartup; 
}

ULevelSequencePlayer* UHiUtilsFunctionLibrary::GetSequencePlayer(UMovieSceneTrackInstance* TrackInstance, const FSequencerTrackInstanceInput& Input)
{
	const UE::MovieScene::FInstanceRegistry* InstanceRegistry = TrackInstance->GetLinker()->GetInstanceRegistry();
	const UE::MovieScene::FSequenceInstance& SequenceInstance = InstanceRegistry->GetInstance(Input.InstanceHandle);
	return Cast<ULevelSequencePlayer>(SequenceInstance.GetPlayer()->AsUObject());
}

void UHiUtilsFunctionLibrary::GetMontageSectionStartAndEndTime(UAnimMontage* Montage, FName SectionName, float& OutStartTime, float& OutEndTime)
{
	if (!IsValid(Montage))
	{
		OutStartTime = 0.0f;
		OutEndTime = 0.0f;
		return;
	}
	
	const int32 SectionID = Montage->GetSectionIndex(SectionName);
	Montage->GetSectionStartAndEndTime(SectionID, OutStartTime, OutEndTime);
}

float UHiUtilsFunctionLibrary::GetNearestDistanceToActor(const FVector& Point, const AActor* Target, ECollisionChannel TraceChannel, FVector& ClosestPointOnCollision, UPrimitiveComponent*& OutPrimitiveComponent)
{
	if (! Target || !IsValid(Target))
	{
		return 0.0;
	}

	return Target->ActorGetDistanceToCollision(Point, TraceChannel, ClosestPointOnCollision, &OutPrimitiveComponent);
}

float UHiUtilsFunctionLibrary::GetNearestDistanceToComponent(const FVector& Point, const UPrimitiveComponent* TargetComp, FVector& ClosestPointOnCollision)
{
	if (!TargetComp || !IsValid(TargetComp))
	{
		return 0.0;
	}
	
	return TargetComp->GetDistanceToCollision(Point,ClosestPointOnCollision);
}

bool UHiUtilsFunctionLibrary::WasRecentlyRenderedWithoutShadow(UPrimitiveComponent *Comp, float Tolerance)
{
	if (! IsValid(Comp))
	{
		return false;
	}
	
	if (const UWorld* const World = Comp->GetWorld())
	{
		// Adjust tolerance, so visibility is not affected by bad frame rate / hitches.
		const float RenderTimeThreshold = FMath::Max(Tolerance, World->DeltaTimeSeconds + KINDA_SMALL_NUMBER);

		// If the current cached value is less than the tolerance then we don't need to go look at the components
		return World->TimeSince(Comp->GetLastRenderTimeOnScreen()) <= RenderTimeThreshold;
	}
	
	return false;
}

TArray<UObject*> UHiUtilsFunctionLibrary::GetAkAudioTypeUserDatas(const UAkAudioType* Instance, const UClass* Type)
{
	TArray<TObjectPtr<UObject>> Result;
     	for (auto entry : Instance->UserData)
     	{
     		if (entry)
     		{
     			UClass* entryClass = entry->GetClass();
     			if (UBlueprint* BlueprintObj = Cast<UBlueprint>(entry))
     			{				
     				if (TSubclassOf<UObject> BlueprintParent = BlueprintObj->ParentClass)
     				{
     					entryClass = BlueprintParent.Get();
     				}
     			}
     			if (entryClass->IsChildOf(Type))
     			{
     				Result.Add(entry);
     			}	
     		}		
     	}
	return Result;
}

bool UHiUtilsFunctionLibrary::AddBlueprintTypeToCache(FString Path, UObject* LoadedObject)
{
	if (BlueprintTypeCache.Contains(Path))
	{
		return false;
	}
	BlueprintTypeCache.Emplace(Path, LoadedObject);
	LoadedObject->AddToRoot();
	return true;
}

void UHiUtilsFunctionLibrary::SetGameQualityLevel(int32 Level)
{
	UE_LOG(LogTemp, Warning, TEXT("HiGame Scalability::FQualityLevels Set To Level[%d]"), Level);


	// 0:low, 1:med, 2:high, 3:epic, 4:cinematic
	Scalability::FQualityLevels QualityLevel = Scalability::GetQualityLevels();
	QualityLevel.SetFromSingleQualityLevel(Level);
	Scalability::SetQualityLevels(QualityLevel, true);
}


bool UHiUtilsFunctionLibrary::RemoveBlueprintTypeToCache(FString Path)
{
	if (!BlueprintTypeCache.Contains(Path))
	{
		return false;
	}
	BlueprintTypeCache[Path]->RemoveFromRoot();
	BlueprintTypeCache.Remove(Path);
	return true;
}

UObject* UHiUtilsFunctionLibrary::GetCachedBlueprintType(FString Path)
{
	if (!BlueprintTypeCache.Contains(Path))
	{
		return nullptr;
	}
	return BlueprintTypeCache[Path];
}

FVector2D UHiUtilsFunctionLibrary::ClampScreenPositionInEllipse(double EllipseAxisX, double EllipseAxisY, const FVector2D& ScreenPosition, bool bForceToEdge)
{
	ensure(EllipseAxisX > 0 && EllipseAxisY > 0);
	if (!bForceToEdge && FVector2D(ScreenPosition.X / EllipseAxisX, ScreenPosition.Y / EllipseAxisY).SizeSquared() < 1.0)
	{
		return ScreenPosition;
	}
	FVector2D Result;
	if (FMath::Abs(ScreenPosition.X) <= UE_KINDA_SMALL_NUMBER)
	{
		Result.X = 0;
		if (ScreenPosition.Y >= 0)
		{
			Result.Y = EllipseAxisY;
		}
		else
		{
			Result.Y = -EllipseAxisY;
		}
	}
	else
	{
		double K = ScreenPosition.Y / ScreenPosition.X;
		// x = EllipseAxisX * EllipseAxisY / sqrt(EllipseAxisX^2 * K^2 + EllipseAxisY^2)
		Result.X = EllipseAxisX * EllipseAxisY / FVector2D(EllipseAxisX * K, EllipseAxisY).Size();
		if (ScreenPosition.X < 0)
		{
			Result.X = -Result.X;
		}
		Result.Y = Result.X * K;
	}
	return Result;
}

bool UHiUtilsFunctionLibrary::IsAssetSkeletonCompatible(USkeleton* Skeleton, UAnimMontage* AnimMontage)
{
	if (!Skeleton || !AnimMontage)
	{
		return false;
	}
	return Skeleton->IsCompatible(AnimMontage->GetSkeleton());
}

bool UHiUtilsFunctionLibrary::MarkActorDirty(AActor* InActor)
{
	if (IsValid(InActor))
	{
		return InActor->MarkPackageDirty();
	}
	return false;
}

bool UHiUtilsFunctionLibrary::AIRegisterPerceptionSource(AActor* SourceActor)
{
	if (!IsValid(SourceActor))
	{
		return false;
	}
	
	UAIPerceptionSystem* AIPerceptionSystem = UAIPerceptionSystem::GetCurrent(SourceActor);
	if (!IsValid(AIPerceptionSystem))
	{
		return false;
	}
	
	AIPerceptionSystem->RegisterSource(*SourceActor);
	return true;
}

bool UHiUtilsFunctionLibrary::AIUnregisterPerceptionSource(AActor* SourceActor)
{
	if (!IsValid(SourceActor))
	{
		return false;
	}
	
	UAIPerceptionSystem* AIPerceptionSystem = UAIPerceptionSystem::GetCurrent(SourceActor);
	if (!IsValid(AIPerceptionSystem))
	{
		return false;
	}
	
	AIPerceptionSystem->UnregisterSource(*SourceActor);
	return true;
}

void UHiUtilsFunctionLibrary::CreateHiGameplayDebuggerCategoryReplicator(AHiPlayerController* OwnerPC)
{
#if WITH_GAMEPLAY_DEBUGGER
	if (IGameplayDebugger::IsAvailable() && IsValid(OwnerPC))
	{
		auto World = OwnerPC->GetWorld();
		if (!IsValid(World))
		{
			return;
		}
		AHiGameplayDebuggerCategoryReplicator* Replicator = World->SpawnActorDeferred<AHiGameplayDebuggerCategoryReplicator>(AHiGameplayDebuggerCategoryReplicator::StaticClass(), FTransform::Identity);
		if (!IsValid(Replicator))
		{
			return;
		}
		Replicator->SetReplicatorOwner(OwnerPC);
		Replicator->FinishSpawning(FTransform::Identity, true);
	}
#endif // WITH_GAMEPLAY_DEBUGGER
}

TArray<AHiTriggerVolume*> UHiUtilsFunctionLibrary::GetActorInWhichHiTriggerVolumes(AActor* InActor)
{
	TArray<AHiTriggerVolume*> OutVolumes;
	if (IsValid(InActor))
	{
		for (TActorIterator<AHiTriggerVolume> It(InActor->GetWorld()); It; ++It)
		{
			AHiTriggerVolume* HiTriggerVolume = *It;
			if (HiTriggerVolume->EncompassesPoint(InActor->GetActorLocation()))
			{
				OutVolumes.Add(HiTriggerVolume);			
			}
		}	
	}	
	return OutVolumes;
}


void UHiUtilsFunctionLibrary::RemovePostProcessBlendable(APostProcessVolume* PPV, TScriptInterface<IBlendableInterface> InBlendableObject) {
	if (PPV) {
		PPV->Settings.RemoveBlendable(InBlendableObject);
	}
}

bool UHiUtilsFunctionLibrary::IsLocalAdapter()
{
	return FDistributedDSUtils::IsUseLocalAdapter();
}

ESSInstanceType UHiUtilsFunctionLibrary::GetSSInstanceType()
{
	return Aether::GetSSInstanceType();
}

bool UHiUtilsFunctionLibrary::IsSSInstanceGame()
{
	return Aether::GetSSInstanceType() == ESSInstanceType::Game;
}

bool UHiUtilsFunctionLibrary::IsSSInstanceClient()
{
	return Aether::GetSSInstanceType() == ESSInstanceType::Client;
}

bool UHiUtilsFunctionLibrary::IsSSInstanceGate()
{
	return Aether::GetSSInstanceType() == ESSInstanceType::Gate;
}

bool UHiUtilsFunctionLibrary::IsWindowsPlatform()
{
#if PLATFORM_WINDOWS
	return true;
#else
	return false;
#endif
}

bool UHiUtilsFunctionLibrary::IsLinuxPlatform()
{
#if PLATFORM_LINUX
	return true;
#else
	return false;
#endif
}

bool UHiUtilsFunctionLibrary::IsServerPackage()
{
#if UE_SERVER
	return true;
#else
	return false;
#endif
}

bool UHiUtilsFunctionLibrary::IsClientPackage()
{
#if !UE_SERVER && !WITH_EDITOR
	return true;
#else
	return false;
#endif
}


const UGameServerSettings* UHiUtilsFunctionLibrary::GetGameServerSettings()
{
	return GetDefault<UGameServerSettings>();
}

FString UHiUtilsFunctionLibrary::GetDefaultLoginHost()
{
	const auto& Settings = *GetDefault<UGameServerSettings>();
	FString LoginHost;
	if (!FParse::Value(FCommandLine::Get(), TEXT("LoginHost="), LoginHost))
	{
		LoginHost = Settings.DefaultLoginHost;
	}
	return LoginHost;
}

bool UHiUtilsFunctionLibrary::IsInPIE()
{
	return GIsEditor;
}

bool UHiUtilsFunctionLibrary::IsWithEditor()
{
#if WITH_EDITOR
	return true;
#endif
	return false;
}

int32 UHiUtilsFunctionLibrary::GetClientEnterSpaceID()
{
	FSpaceID FirstSpaceID = FDistributedDSUtils::GetGPIEFirstSpaceID();
	if (FirstSpaceID == 0)
	{
		FirstSpaceID = 1;
	}
	return static_cast<int32>(FirstSpaceID);
}

int32 UHiUtilsFunctionLibrary::GetClientPlayMode()
{
	EDDSPlayMode PlayMode = FDistributedDSUtils::GetDSPlayMode();
	return static_cast<int32>(PlayMode);
}


TArray<UAssetUserData*> UHiUtilsFunctionLibrary::GetAnimationAssetUserData(const class UAnimationAsset* AnimationAsset, const UClass* Type)
{
	return GetAssetUserData(AnimationAsset, Type);
}

TArray<UAssetUserData*> UHiUtilsFunctionLibrary::GetAssetUserData(const UObject* Object, const UClass* Type)
{
	TArray<TObjectPtr<UAssetUserData>> Result;
	const IInterface_AssetUserData * Asset = Cast<IInterface_AssetUserData>(Object);
	if (!Asset)
	{
		return Result;
	}
	const TArray<UAssetUserData*> AssetUserData = *Asset->GetAssetUserDataArray();
	for (int32 DataIdx = 0; DataIdx <AssetUserData.Num(); DataIdx++)
	{
		UAssetUserData* Datum = AssetUserData[DataIdx];
		if (Datum)
		{
			UClass* entryClass = Datum->GetClass();
			if (UBlueprint* BlueprintObj = Cast<UBlueprint>(Datum))
			{				
				if (TSubclassOf<UObject> BlueprintParent = BlueprintObj->ParentClass)
				{
					entryClass = BlueprintParent.Get();
				}
			}
			if (entryClass->IsChildOf(Type))
			{
				Result.Add(Datum);
			}	
		}		
	}
	return Result;
}

UAssetUserData* UHiUtilsFunctionLibrary::AddAssetUserData(UObject* Object, TSubclassOf<UAssetUserData> ClassType)
{
	if(IInterface_AssetUserData * Asset = Cast<IInterface_AssetUserData>(Object))
	{
		UAssetUserData * UserData = NewObject<UAssetUserData>(GetTransientPackage(), ClassType);
		if(UserData)
		{
			Asset->AddAssetUserData(UserData);
			return UserData;
		}
	}
	return nullptr;
}

FGameplayTag UHiUtilsFunctionLibrary::GetDirectParentGameplayTag(FGameplayTag InGameplayTag) 
{
	return InGameplayTag.RequestDirectParent();
}

bool UHiUtilsFunctionLibrary::WithEditor()
{
#if WITH_EDITOR
	return true;
#else
	return false;
#endif
}

static bool StaticBool = false;
bool FFI_GetStaticBool()
{
	return StaticBool;
}

static double StaticNumber = 0.0f;
double FFI_GetStaticNumber()
{
	return StaticNumber;
}

static char _sz[128] = {0};
const char* FFI_GetStaticString()
{
	return _sz;
}

const char* FFI_GetObjName(lua_Integer Obj_Addr)
{
	static char name[128] = { 0 };
	memset(name, 0, 64);

	auto Object = (UObject*)Obj_Addr;
	if(IsValid(Object))
	{
		strcpy(name, TCHAR_TO_UTF8(*UKismetSystemLibrary::GetObjectName(Object)));
	}
	
	return name;
}

const char* FFI_GetDisplayName(lua_Integer Obj_Addr)
{
	static char name[128] = { 0 };
	memset(name, 0, 64);

	auto Object = (UObject*)Obj_Addr;
	if(IsValid(Object))
	{
		strcpy(name, TCHAR_TO_UTF8(*UKismetSystemLibrary::GetDisplayName(Object)));
	}
	
	return name;
}

int64_t FFI_GetFrameCount()
{
	return UKismetSystemLibrary::GetFrameCount();
}

int64_t FFI_GetNowTimestampMs()
{
	return UHiUtilsFunctionLibrary::GetNowTimestampMs();
}

int64_t FFI_GetGameplayAbilityFromSpecHandle(lua_Integer AbilitySystem_Addr, lua_Integer SpecHandle_Addr)
{
	auto AbilitySystem = (UAbilitySystemComponent*)AbilitySystem_Addr;
	auto AbilitySpecHandle = (FGameplayAbilitySpecHandle*)SpecHandle_Addr;
	
	return (lua_Integer)UAbilitySystemBlueprintLibrary::GetGameplayAbilityFromSpecHandle(AbilitySystem, *AbilitySpecHandle, StaticBool);
}

int64_t FFI_GetHiAbilitySystemComponent(lua_Integer Obj_Addr)
{
	auto Character = Cast<AHiCharacter>((AHiCharacter*)Obj_Addr);
	if(!IsValid(Character))
	{
		return 0;
	}
	
	return (lua_Integer)Character->GetHiAbilitySystemComponent();
}

int64_t FFI_GetPlayerCharacter(lua_Integer Context_Addr, int32_t PlayerIndex)
{
	auto WorldContextObject = (UObject*)Context_Addr;
	if(!IsValid(WorldContextObject))
	{
		return 0;
	}
	
	return (lua_Integer)UGameplayStatics::GetPlayerCharacter(WorldContextObject, PlayerIndex);
}
