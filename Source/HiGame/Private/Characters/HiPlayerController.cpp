// Fill out your copyright notice in the Description page of Project Settings.

#include "Characters/HiPlayerController.h"

#include "DistributedDSComponent.h"
#include "DistributedEntityType.h"
#include "EnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputMappingContext.h"
#include "Engine/LocalPlayer.h"
#include "Characters/HiPlayerCameraManager.h"
#include "Component/HiCharacterDebugComponent.h"
#include "Kismet/GameplayStatics.h"
#include "HiUtilsUnlua.h"
#include "Blueprint/SlateBlueprintLibrary.h"
#include "Engine/ChildConnection.h"
#include "EngineUtils.h"
#include "InteractSystem/InteractManagerComponent.h"
#include "PartialWorld/DebugPartialWorldSubsystem.h"
#include "Engine/LevelStreaming.h"
#include "Engine/ChildConnection.h"
#include "GameFramework/PlayerState.h"

DEFINE_LOG_CATEGORY_STATIC(LogHiPlayerController, Log, All)

AHiPlayerController::AHiPlayerController()
{
	InteractManager = CreateDefaultSubobject<UInteractManagerComponent>(TEXT("InteractManagerComponent"));
}

void AHiPlayerController::Destroyed()
{
	Super::Destroyed();
	InteractManager = nullptr;
}

void AHiPlayerController::OnPossess(APawn* NewPawn)
{
	Super::OnPossess(NewPawn);
	PossessedCharacter = Cast<AHiCharacter>(NewPawn);
	bIsPossessPawnCalled = false;
	OnPossessPawnReady();

	SetupInputs();
}

void AHiPlayerController::OnPossessPawnReady()
{
	if (bIsPossessPawnCalled || !PossessedCharacter)
	{
		return;
	}
	bIsPossessPawnCalled = true;

	//if (!IsRunningDedicatedServer())
	{
		// Servers want to setup camera only in listen servers.
		SetupCamera();
	}
	SetupInputs();

	PossessedCharacter->OnPossessedBy(this);

	// Todo: Move to Component
	//UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
	//if (DebugComp)
	//{
	//	DebugComp->OnPlayerControllerInitialized(this);
	//}

	if (OnPossessEvent.IsBound())
	{
		OnPossessEvent.Broadcast(PossessedCharacter, true);
	}
}

void AHiPlayerController::OnUnPossess()
{
	Super::OnUnPossess();
	//if (!IsRunningDedicatedServer())
	{
		// Servers want to setup camera only in listen servers.
		UnbindCamera();
	}
	if (PossessedCharacter)
	{
		// SET_ASSOCIATED_LEADER(PossessedCharacter, nullptr, EEntityAssociateSource::Geo, EEntityAssociateType::Public);
		PossessedCharacter->OnUnPossessedBy(this);
		if (OnPossessEvent.IsBound())
		{
			OnPossessEvent.Broadcast(PossessedCharacter, false);
		}
		PossessedCharacter = nullptr;
	}
}

void AHiPlayerController::OnRep_Pawn()
{
	Super::OnRep_Pawn();
	AHiCharacter* NewPossessedCharacter = Cast<AHiCharacter>(GetPawn());
	if (NewPossessedCharacter == PossessedCharacter)
	{
		return;
	}
	if (PossessedCharacter)
	{
		PossessedCharacter->OnUnPossessedBy(this);
		if (OnPossessEvent.IsBound())
		{
			OnPossessEvent.Broadcast(PossessedCharacter, false);
		}
	}
	PossessedCharacter = NewPossessedCharacter;
	if (PossessedCharacter)
	{
		bIsPossessPawnCalled = false;
		if (PossessedCharacter->GetLocalRole() == GetLocalRole())
		{
			OnPossessPawnReady();
		}
	}
}

void AHiPlayerController::SetupInputComponent()
{
	Super::SetupInputComponent();

	UEnhancedInputComponent* EnhancedInputComponent = Cast<UEnhancedInputComponent>(InputComponent);
	if (EnhancedInputComponent)
	{
		EnhancedInputComponent->ClearActionEventBindings();
		EnhancedInputComponent->ClearActionValueBindings();
		EnhancedInputComponent->ClearDebugKeyBindings();

		BindActions(DefaultInputMappingContext);
		BindActions(DebugInputMappingContext);
	}
	else
	{
		UE_LOG(LogTemp, Fatal, TEXT("HiPlayerController Community requires Enhanced Input System to be activated in project settings to function properly"));
	}
}

void AHiPlayerController::BindActions(UInputMappingContext* Context)
{
	if (Context)
	{
		const TArray<FEnhancedActionKeyMapping>& Mappings = Context->GetMappings();
		UEnhancedInputComponent* EnhancedInputComponent = Cast<UEnhancedInputComponent>(InputComponent);
		if (EnhancedInputComponent)
		{
			// There may be more than one keymapping assigned to one action. So, first filter duplicate action entries to prevent multiple delegate bindings
			TSet<const UInputAction*> UniqueActions;
			for (const FEnhancedActionKeyMapping& Keymapping : Mappings)
			{
				UniqueActions.Add(Keymapping.Action);
			}
			for (const UInputAction* UniqueAction : UniqueActions)
			{
				EnhancedInputComponent->BindAction(UniqueAction, ETriggerEvent::Triggered, Cast<UObject>(this), UniqueAction->GetFName());
			}
		}
	}
}

FString AHiPlayerController::LuaConsoleCommand(const FString& Cmd, bool bWriteToLog)
{
	const TCHAR* CmdStart = *Cmd;
	const TCHAR* CmdEnd = CmdStart + Cmd.Len() - 1;
		
	while(*CmdStart == ' ') ++CmdStart;
	while(*CmdEnd == ' ') --CmdEnd;

	if (CmdEnd < CmdStart)
	{
		return TEXT("ERROR Command");
	}

	const FString NewCmd(CmdEnd - CmdStart + 1, CmdStart);

	if (MultiCmdMgr.CurMutilCmdRule == nullptr)
	{
		for(auto iter = MultiCmdMgr.MutilCmdRuleSet.begin(); iter != MultiCmdMgr.MutilCmdRuleSet.end(); ++iter)
		{
			auto& Rule = *iter;
			if (Rule->IsBegin(NewCmd) && !Rule->IsEnd(NewCmd))
			{
				MultiCmdMgr.CurMutilCmdRule = Rule;
				return MultiCmdMgr.MultiChunkBegin(NewCmd);
			}
		}
	}

	if (MultiCmdMgr.CurMutilCmdRule == nullptr)
	{
		const FString NewCommand = "lua.do " + NewCmd;
		return Super::ConsoleCommand(NewCommand, bWriteToLog);
	}
	else
	{
		if(MultiCmdMgr.CurMutilCmdRule->IsSkipEnd(NewCmd))
		{
			MultiCmdMgr.CurMutilCmdRule->AddSkipEnd();
		}

		if (MultiCmdMgr.CurMutilCmdRule->IsEnd(NewCmd))
		{
			const auto& MultiChunk = MultiCmdMgr.MultiChunkEnd(NewCmd);
			const FString NewCommand = "lua.do " + MultiChunk;
			return Super::ConsoleCommand(NewCommand, bWriteToLog);
		}
		else
		{
			return MultiCmdMgr.MultiChunkContinue(NewCmd);
		}
	}
}

bool AHiPlayerController::ProjectWorldLocationToScreenPositionWithDirection(FVector WorldLocation, bool bPlayerViewportRelative, FVector2D& ScreenPosition, bool& bFront)
{
	FVector ScreenPosition3D;
	
	FVector PixelLocation;
	bool bProjected = false;
	ULocalPlayer const* const LP = GetLocalPlayer();
	if (LP && LP->ViewportClient)
	{
		// get the projection data
		FSceneViewProjectionData ProjectionData;
		if (LP->GetProjectionData(LP->ViewportClient->Viewport, /*out*/ ProjectionData))
		{
			FMatrix const ViewProjectionMatrix = ProjectionData.ComputeViewProjectionMatrix();
			const FIntRect& ViewRect = ProjectionData.GetConstrainedViewRect();

			const FPlane Result = ViewProjectionMatrix.TransformFVector4(FVector4(WorldLocation, 1.f));
			bFront = Result.W > 0.0f ? true : false;
			// UE_LOG(LogTemp, Log, TEXT("ProjectWorldToScreenWithDirection %f,%f,%f,%f"), Result.X, Result.Y, Result.Z, Result.W);
			const double AbsW = abs(Result.W);
	
			// the result of this will be x and y coords in -1..1 projection space
			const float RHW = 1.0f / AbsW;
			const FPlane PosInScreenSpace = FPlane(Result.X * RHW, Result.Y * RHW, Result.Z * RHW, Result.W);

			// Move from projection space to normalized 0..1 UI space
			const float NormalizedX = ( PosInScreenSpace.X / 2.f ) + 0.5f;
			const float NormalizedY = 1.f - ( PosInScreenSpace.Y / 2.f ) - 0.5f;

			const FVector2D RayStartViewRectSpace(
				( NormalizedX * static_cast<float>(ViewRect.Width()) ),
				( NormalizedY * static_cast<float>(ViewRect.Height()) )
				);

			FVector2D ScreenPosition2D = RayStartViewRectSpace + FVector2D(static_cast<float>(ViewRect.Min.X), static_cast<float>(ViewRect.Min.Y));
			

			if ( bPlayerViewportRelative )
			{
				ScreenPosition2D -= FVector2D(ProjectionData.GetConstrainedViewRect().Min);
			}

			PixelLocation = FVector(ScreenPosition2D.X, ScreenPosition2D.Y, FVector::Dist(ProjectionData.ViewOrigin, WorldLocation));
			PostProcessWorldToScreen(WorldLocation, ScreenPosition2D, bPlayerViewportRelative);
			bProjected = true;
		}
	}
	
	if ( bProjected )
	{
		ScreenPosition3D.X = FMath::RoundToInt(PixelLocation.X);
		ScreenPosition3D.Y = FMath::RoundToInt(PixelLocation.Y);
		ScreenPosition3D.Z = PixelLocation.Z;
	}
	else
	{
		ScreenPosition3D = FVector::ZeroVector;
	}
	
	ScreenPosition = FVector2D(ScreenPosition3D.X, ScreenPosition3D.Y);
	return bProjected;
}

void AHiPlayerController::SetRenderPrimitiveComponents(bool bEnabled) {
	bRenderPrimitiveComponents = bEnabled;
}

bool AHiPlayerController::IsRenderPrimitiveComponents() {
	return bRenderPrimitiveComponents;
}

void AHiPlayerController::SetRenderShowOnlyPrimitiveComponents(bool bEnabled) {
	bRenderShowOnlyPrimitiveComponents = bEnabled;
}

bool AHiPlayerController::IsRenderShowOnlyPrimitiveComponents() {
	return bRenderShowOnlyPrimitiveComponents;
}

void AHiPlayerController::SetShowOnlyActors(TArray<AActor*> Actors) {
	ShowOnlyActors = Actors;
}

bool AHiPlayerController::GetStreamingSourcesInternal(TArray<FWorldPartitionStreamingSource>& OutStreamingSources) const
{
	if(const auto* PPawn = GetPawn())
	{
		FWorldPartitionStreamingSource& StreamingSource = OutStreamingSources.AddDefaulted_GetRef();
		StreamingSource.Location = PPawn->GetActorLocation();
		StreamingSource.Rotation = PPawn->GetActorRotation();
		StreamingSource.Name = GetFName();
		StreamingSource.TargetState = StreamingSourceShouldActivate() ? EStreamingSourceTargetState::Activated : EStreamingSourceTargetState::Loaded;
		StreamingSource.bBlockOnSlowLoading = StreamingSourceShouldBlockOnSlowStreaming();
		StreamingSource.DebugColor = StreamingSourceDebugColor;
		StreamingSource.Priority = GetStreamingSourcePriority();
		StreamingSource.bRemote = !IsLocalController();
		GetStreamingSourceShapes(StreamingSource.Shapes);
		return true;
	}
	return false;
}

void AHiPlayerController::AddShowOnlyActor(AActor* Actor) {
	ShowOnlyActors.Add(Actor);
}

void AHiPlayerController::DoLuaString_Implementation(const FString& LuaStr)
{
}

void AHiPlayerController::SetupInputs()
{
	if (PossessedCharacter)
	{
		if (UEnhancedInputLocalPlayerSubsystem* Subsystem = ULocalPlayer::GetSubsystem<UEnhancedInputLocalPlayerSubsystem>(GetLocalPlayer()))
		{
			FModifyContextOptions Options;
			Options.bForceImmediately = 1;
			Subsystem->AddMappingContext(DefaultInputMappingContext, 1, Options);
			UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
			if (DebugComp)
			{
				// Do only if we have debug component
				Subsystem->AddMappingContext(DebugInputMappingContext, 0, Options);
			}
		}
	}
}

void AHiPlayerController::SetupCamera()
{
	// Call "OnPossess" in Player Camera Manager when possessing a pawn
	AHiPlayerCameraManager* CastedMgr = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (PossessedCharacter && CastedMgr)
	{
		CastedMgr->OnPossess(PossessedCharacter);
	}
}

void AHiPlayerController::UnbindCamera()
{
	AHiPlayerCameraManager* CastedMgr = Cast<AHiPlayerCameraManager>(PlayerCameraManager);
	if (CastedMgr)
	{
		CastedMgr->OnUnPossess();
	}
}

void AHiPlayerController::ForwardMovementAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->ForwardMovementAction(Value.GetMagnitude());
	}
}

void AHiPlayerController::RightMovementAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->RightMovementAction(Value.GetMagnitude());
	}
}

void AHiPlayerController::CameraUpAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->CameraUpAction(Value.GetMagnitude());
	}
}

void AHiPlayerController::CameraRightAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->CameraRightAction(Value.GetMagnitude());
	}
}

void AHiPlayerController::CameraScaleAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->CameraScaleAction(Value.GetMagnitude());
	}
}

void AHiPlayerController::JumpAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->JumpAction(Value.Get<bool>());
	}
}

void AHiPlayerController::SprintAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->SprintAction(Value.Get<bool>());
	}
}

void AHiPlayerController::AimAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->AimAction(Value.Get<bool>());
	}
}

void AHiPlayerController::AttackAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
    {
    	PossessedCharacter->AttackAction(Value.Get<bool>());
    }
}

void AHiPlayerController::StanceAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		PossessedCharacter->StanceAction();
	}
}

void AHiPlayerController::WalkAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		PossessedCharacter->WalkAction();
	}
}

void AHiPlayerController::RagdollAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		PossessedCharacter->RagdollAction();
	}
}

void AHiPlayerController::VelocityDirectionAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		PossessedCharacter->VelocityDirectionAction();
	}
}

void AHiPlayerController::LookingDirectionAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		PossessedCharacter->LookingDirectionAction();
	}
}

void AHiPlayerController::DebugToggleHudAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleHud();
		}
	}
}

void AHiPlayerController::DebugToggleDebugViewAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleDebugView();
		}
	}
}

void AHiPlayerController::DebugToggleTracesAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleTraces();
		}
	}
}

void AHiPlayerController::DebugToggleShapesAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleDebugShapes();
		}
	}
}

void AHiPlayerController::DebugToggleLayerColorsAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleLayerColors();
		}
	}
}

void AHiPlayerController::DebugToggleCharacterInfoAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleCharacterInfo();
		}
	}
}

void AHiPlayerController::DebugToggleSlomoAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleSlomo();
		}
	}
}

void AHiPlayerController::DebugFocusedCharacterCycleAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->FocusedDebugCharacterCycle(Value.GetMagnitude() > 0);
		}
	}
}

void AHiPlayerController::DebugToggleMeshAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter && Value.Get<bool>())
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->ToggleDebugMesh();
		}
	}
}

void AHiPlayerController::DebugOpenOverlayMenuAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->OpenOverlayMenu(Value.Get<bool>());
		}
	}
}

void AHiPlayerController::DebugOverlayMenuCycleAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		UHiCharacterDebugComponent* DebugComp = Cast<UHiCharacterDebugComponent>(PossessedCharacter->GetComponentByClass(UHiCharacterDebugComponent::StaticClass()));
		if (DebugComp)
		{
			DebugComp->OverlayMenuCycle(Value.GetMagnitude() > 0);
		}
	}
}

void AHiPlayerController::ClientSetGeoSpaceInfo_Implementation(const FGeoWorldConfig& WorldConfig, const TArray<FGeoRegionInfo>& RegionInfoList)
{
#if WITH_EDITOR
	UDebugPartialWorldSubsystem* DebugPartialWorldSubsystem = GetWorld()->GetSubsystem<UDebugPartialWorldSubsystem>();
	if (DebugPartialWorldSubsystem)
	{
		DebugPartialWorldSubsystem->SetGeoSpaceInfo(WorldConfig, RegionInfoList);
	}
#endif
}

void AHiPlayerController::PlayerReplicateStreamingStatus()
{
	UWorld* MyWorld = GetWorld();

	if (MyWorld->GetWorldSettings()->bUseClientSideLevelStreamingVolumes)
	{
		// Client will itself decide what to stream
		return;
	}

	// Don't do this for local players or players after the first on a splitscreen client
	if (Cast<ULocalPlayer>(Player) == nullptr && Cast<UChildConnection>(Player) == nullptr)
	{
		// If we've loaded levels via CommitMapChange() that aren't normally in the StreamingLevels array, tell the client about that
		if (MyWorld->CommittedPersistentLevelName != NAME_None)
		{
			ClientPrepareMapChange(MyWorld->CommittedPersistentLevelName, true, true);
			// Tell the client to commit the level immediately
			ClientCommitMapChange();
		}

		SentStreamingStatusIdx = 0;
		InternalPlayerReplicateStreamingStatus();
	}
}

void AHiPlayerController::InternalPlayerReplicateStreamingStatus()
{
	UWorld* MyWorld = GetWorld();
	if (MyWorld->GetStreamingLevels().Num() > 0)
	{
		const int MaxLevelOneTime = 50;
		TArray<FUpdateLevelStreamingLevelStatus> LevelStatuses;
		int32 StartIdx = SentStreamingStatusIdx;
		int32 EndIdx = FMath::Min(SentStreamingStatusIdx + MaxLevelOneTime, MyWorld->GetStreamingLevels().Num());
		for (int32 IterIdx = StartIdx; IterIdx < EndIdx; ++IterIdx)
		{
			ULevelStreaming* TheLevel = MyWorld->GetStreamingLevels()[IterIdx];
			if (TheLevel != nullptr)
			{
				const ULevel* LoadedLevel = TheLevel->GetLoadedLevel();

				const bool bTheLevelShouldBeVisible = TheLevel->ShouldBeVisible();
				const bool bTheLevelShouldBeLoaded = TheLevel->ShouldBeLoaded();

				UE_LOG(LogHiPlayerController, Verbose, TEXT("ReplicateStreamingStatus: %s %i %i %i %s %i"),
					*TheLevel->GetWorldAssetPackageName(),
					bTheLevelShouldBeVisible,
					LoadedLevel && LoadedLevel->bIsVisible,
					bTheLevelShouldBeLoaded,
					*GetNameSafe(LoadedLevel),
					TheLevel->HasLoadRequestPending());

				FUpdateLevelStreamingLevelStatus& LevelStatus = *new( LevelStatuses ) FUpdateLevelStreamingLevelStatus();
				LevelStatus.PackageName = NetworkRemapPath(TheLevel->GetWorldAssetPackageFName(), false);
				LevelStatus.bNewShouldBeLoaded = bTheLevelShouldBeLoaded;
				LevelStatus.bNewShouldBeVisible = bTheLevelShouldBeVisible;
				LevelStatus.bNewShouldBlockOnLoad = TheLevel->bShouldBlockOnLoad;
				LevelStatus.LODIndex = TheLevel->GetLevelLODIndex();
			}
		}
		SentStreamingStatusIdx = EndIdx;
		if(LevelStatuses.Num() > 0)
		{
			ClientUpdateMultipleLevelsStreamingStatus( LevelStatuses );
		}

		if (SentStreamingStatusIdx >= MyWorld->GetStreamingLevels().Num())
		{
			ClientFlushLevelStreaming();
			SentStreamingStatusIdx = 0;
		}
	}

	if (SentStreamingStatusIdx == 0 || SentStreamingStatusIdx >= MyWorld->GetStreamingLevels().Num())
	{
		// If we're preparing to load different levels using PrepareMapChange() inform the client about that now
		if (MyWorld->PreparingLevelNames.Num() > 0)
		{
			for (int32 LevelIndex = 0; LevelIndex < MyWorld->PreparingLevelNames.Num(); LevelIndex++)
			{
				ClientPrepareMapChange(MyWorld->PreparingLevelNames[LevelIndex], LevelIndex == 0, LevelIndex == MyWorld->PreparingLevelNames.Num() - 1);
			}
			// DO NOT commit these changes yet - we'll send that when we're done preparing them
		}
	}
}

void AHiPlayerController::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME_CONDITION(AHiPlayerController, PlayerGuid, COND_OwnerOnly);
	DOREPLIFETIME_CONDITION(AHiPlayerController, PlayerProxyID, COND_OwnerOnly);
	DOREPLIFETIME_CONDITION(AHiPlayerController, PlayerRoleId, COND_InitialOnly);
}

void AHiPlayerController::GetInVehicleAction_Implementation(const FInputActionValue& Value)
{
	if (PossessedCharacter)
	{
		PossessedCharacter->GetInVehicleAction(Value.Get<bool>());
	}
}

void AHiPlayerController::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (SentStreamingStatusIdx > 0 && HasAuthority())
	{
		InternalPlayerReplicateStreamingStatus();
	}
}

void AHiPlayerController::AddSwitchPlayer(AHiCharacter* InHiCharacter)
{
	if (IsValid(InHiCharacter))
	{
		if (!SwitchPlayers.ContainsByPredicate([InHiCharacter](const TObjectPtr<AHiCharacter>& Element)
		{
			return Element.Get() == InHiCharacter;
		}))
		{
			SwitchPlayers.Emplace(InHiCharacter);
			if (IsValid(PlayerState.Get()))
			{
				SET_ASSOCIATED_LEADER(InHiCharacter, PlayerState.Get(), EEntityAssociateSource::Geo, EEntityAssociateType::Public);
			}
		}
		else
		{
			UE_LOG(LogHiPlayerController, Error, TEXT("AHiPlayerController::AddSwitchPlayer Character(%s) already exists"), *InHiCharacter->GetName());
		}
	}
}

void AHiPlayerController::RemoveSwitchPlayer(AHiCharacter* InHiCharacter)
{
	if (IsValid(InHiCharacter))
	{
		int32 ElementIndex = SwitchPlayers.IndexOfByPredicate([InHiCharacter](const TObjectPtr<AHiCharacter>& Element)
		{
			return Element.Get() == InHiCharacter;
		});
		if (ElementIndex != INDEX_NONE)
		{
			SwitchPlayers.RemoveAt(ElementIndex);
			SET_ASSOCIATED_LEADER(InHiCharacter, nullptr, EEntityAssociateSource::Geo, EEntityAssociateType::Public);
		}
		else
		{
			UE_LOG(LogHiPlayerController, Error, TEXT("AHiPlayerController::RemoveSwitchPlayer Character(%s) not exists"), *InHiCharacter->GetName());
		}
	}
}
