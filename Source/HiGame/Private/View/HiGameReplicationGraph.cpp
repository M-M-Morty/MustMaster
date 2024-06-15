#include "View/HiGameReplicationGraph.h"
#include "Net/UnrealNetwork.h"
#include "Engine/LevelStreaming.h"
#include "EngineUtils.h"
#include "CoreGlobals.h"
#include "UObject/UObjectIterator.h"
#include "Engine/NetConnection.h"
#include "Engine/ChildConnection.h"

UHiGameReplicationGraph::UHiGameReplicationGraph()
{

}

void UHiGameReplicationGraph::InitGlobalActorClassSettings()
{
	Super::InitGlobalActorClassSettings();

	// ReplicationGraph stores internal associative data for actor classes.
	// We build this data here based on actor CDO values.
	for (TObjectIterator<UClass> It; It; ++It)
	{
		UClass* Class = *It;
		AActor* ActorCDO = Cast<AActor>(Class->GetDefaultObject());
		UE_LOG(LogNet, Log, TEXT("InitGlobalActorClassSettings. Iterator Actor: %s"), *Class->GetName());

		if (!ActorCDO || !ActorCDO->GetIsReplicated())
		{
			continue;
		}

		// Skip SKEL and REINST classes.
		if (Class->GetName().StartsWith(TEXT("SKEL_")) || Class->GetName().StartsWith(TEXT("REINST_")))
		{
			continue;
		}

		FClassReplicationInfo ClassInfo;

		// Replication Graph is frame based. Convert NetUpdateFrequency to ReplicationPeriodFrame based on Server MaxTickRate.
		ClassInfo.ReplicationPeriodFrame = GetReplicationPeriodFrameForFrequency(ActorCDO->NetUpdateFrequency);

		if (ActorCDO->bAlwaysRelevant || ActorCDO->bOnlyRelevantToOwner)
		{
			ClassInfo.SetCullDistanceSquared(0.f);
			UE_LOG(LogNet, Log, TEXT("InitGlobalActorClassSettings. ActorCDO->bAlwaysRelevant || ActorCDO->bOnlyRelevantToOwner. Actor: %s"), *ActorCDO->GetName());
		}
		else
		{
			ClassInfo.SetCullDistanceSquared(ActorCDO->NetCullDistanceSquared);
			UE_LOG(LogNet, Log, TEXT("InitGlobalActorClassSettings. Actor: %s, NetCullDistanceSquared = %.2f"), *ActorCDO->GetName(), ActorCDO->NetCullDistanceSquared);
		}

		GlobalActorReplicationInfoMap.SetClassInfo( Class, ClassInfo );
	}
}

void UHiGameReplicationGraph::InitGlobalGraphNodes()
{
	// -----------------------------------------------
	//	Spatial Actors
	// -----------------------------------------------

	GridNode = CreateNewNode<UReplicationGraphNode_GridSpatialization2D>();
	GridNode->CellSize = 10000.f;
	GridNode->SpatialBias = FVector2D(-100000.0, -100000.0); // 左下角为原点

	AddGlobalGraphNode(GridNode);

	// -----------------------------------------------
	//	Always Relevant (to everyone) Actors
	// -----------------------------------------------
	AlwaysRelevantNode = CreateNewNode<UReplicationGraphNode_ActorList>();
	AddGlobalGraphNode(AlwaysRelevantNode);
}

void UHiGameReplicationGraph::InitConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection)
{
	Super::InitConnectionGraphNodes(RepGraphConnection);

	UReplicationGraphNode_AlwaysRelevant_ForConnection* AlwaysRelevantNodeForConnection = CreateNewNode<UReplicationGraphNode_AlwaysRelevant_ForConnection>();
	AddConnectionGraphNode(AlwaysRelevantNodeForConnection, RepGraphConnection);

	AlwaysRelevantForConnectionList.Emplace(RepGraphConnection->NetConnection, AlwaysRelevantNodeForConnection);
}

void UHiGameReplicationGraph::RouteAddNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo)
{
	// ensureMsgf((ActorInfo.Actor->bAlwaysRelevant && ActorInfo.Actor->bOnlyRelevantToOwner) == false, TEXT("Replicated actor %s is both bAlwaysRelevant and bOnlyRelevantToOwner. Only one can be supported."), *ActorInfo.Actor->GetName());

	UpdateGlobalActorClassSettings(ActorInfo.Actor, GlobalInfo);

	if (ActorInfo.Actor->bAlwaysRelevant)
	{
		AlwaysRelevantNode->NotifyAddNetworkActor(ActorInfo);
		UE_LOG(LogNet, Log, TEXT("UHiGameReplicationGraph::RouteAddNetworkActorToNodes. AlwaysRelevantNode: %s"), *ActorInfo.Actor->GetName());

	}
	else if (ActorInfo.Actor->bOnlyRelevantToOwner)
	{
		UE_LOG(LogNet, Log, TEXT("UHiGameReplicationGraph::RouteAddNetworkActorToNodes. ActorsWithoutNetConnection: %s"), *ActorInfo.Actor->GetName());
		ActorsWithoutNetConnection.Add(ActorInfo.Actor);
	}
	else
	{
		// Note that UReplicationGraphNode_GridSpatialization2D has 3 methods for adding actor based on the mobility of the actor. Since AActor lacks this information, we will
		// add all spatialized actors as dormant actors: meaning they will be treated as possibly dynamic (moving) when not dormant, and as static (not moving) when dormant.
		GridNode->AddActor_Dormancy(ActorInfo, GlobalInfo);

		UE_LOG(LogNet, Log, TEXT("UHiGameReplicationGraph::RouteAddNetworkActorToNodes. GridNode: %s"), *ActorInfo.Actor->GetName());
	}
}

void UHiGameReplicationGraph::RouteRemoveNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo)
{
	if (ActorInfo.Actor->bAlwaysRelevant)
	{
		AlwaysRelevantNode->NotifyRemoveNetworkActor(ActorInfo);
		SetActorDestructionInfoToIgnoreDistanceCulling(ActorInfo.GetActor());
	}
	else if (ActorInfo.Actor->bOnlyRelevantToOwner)
	{
		UReplicationGraphNode* Node = nullptr;
		auto Connection = ActorInfo.Actor->GetNetConnection();

		bool FoundActorInAlwaysRelevantMap = false;
		if (Connection)
		{
			Node = GetAlwaysRelevantNodeForConnection(Connection);
		}
		else
		{
			// 如果Actor当前没有Connection，典型的如PlayerController迁移后Connection被设置为粉蓝
			auto Result = ActorToAlwaysRelevantConnectionMap.Find(ActorInfo.Actor);
			if (Result)
			{
				Node = *Result;
			}
		}

		if (Node)
		{
			Node->NotifyRemoveNetworkActor(ActorInfo);
		}
		else
		{
			UE_LOG(LogNet, Error, TEXT("RouteRemoveNetworkActorToNodes. failed, find connection or GraphNode failed. actor: %s"), *ActorInfo.Actor->GetName());
		}

		ActorToAlwaysRelevantConnectionMap.Remove(ActorInfo.Actor);
	}
	else
	{
		GridNode->RemoveActor_Dormancy(ActorInfo);
	}
}

UReplicationGraphNode_AlwaysRelevant_ForConnection* UHiGameReplicationGraph::GetAlwaysRelevantNodeForConnection(UNetConnection* Connection)
{
	UReplicationGraphNode_AlwaysRelevant_ForConnection* Node = nullptr;
	if (Connection)
	{
		if (FConnectionAlwaysRelevantNodePair* Pair = AlwaysRelevantForConnectionList.FindByKey(Connection))
		{
			if (Pair->Node)
			{
				Node = Pair->Node;
			}
			else
			{
				UE_LOG(LogNet, Warning, TEXT("AlwaysRelevantNode for connection %s is null."), *GetNameSafe(Connection));
			}
		}
		else
		{
			UE_LOG(LogNet, Warning, TEXT("Could not find AlwaysRelevantNode for connection %s. This should have been created in UHiGameReplicationGraph::InitConnectionGraphNodes."), *GetNameSafe(Connection));
		}
	}
	else
	{
		// Basic implementation requires owner is set on spawn that never changes. A more robust graph would have methods or ways of listening for owner to change
		UE_LOG(LogNet, Warning, TEXT("Actor: %s is bOnlyRelevantToOwner but does not have an owning Netconnection. It will not be replicated"));
	}

	return Node;
}

int32 UHiGameReplicationGraph::ServerReplicateActors(float DeltaSeconds)
{
	// Route Actors needing owning net connections to appropriate nodes
	for (int32 idx=ActorsWithoutNetConnection.Num()-1; idx>=0; --idx)
	{
		bool bRemove = false;
		if (AActor* Actor = ActorsWithoutNetConnection[idx])
		{
			if (UNetConnection* Connection = Actor->GetNetConnection())
			{
				bRemove = true;
				if (UReplicationGraphNode_AlwaysRelevant_ForConnection* Node = GetAlwaysRelevantNodeForConnection(Actor->GetNetConnection()))
				{
					Node->NotifyAddNetworkActor(FNewReplicatedActorInfo(Actor));

					ActorToAlwaysRelevantConnectionMap.FindOrAdd(Actor) = Node;
				}
			}
		}
		else
		{
			bRemove = true;
		}

		if (bRemove)
		{
			ActorsWithoutNetConnection.RemoveAtSwap(idx, 1, false);
		}
	}


	return Super::ServerReplicateActors(DeltaSeconds);
}

void UHiGameReplicationGraph::UpdateGlobalActorClassSettings(AActor* Actor, FGlobalActorReplicationInfo& GlobalInfo)
{
	if (!Actor || !Actor->GetIsReplicated())
	{
		return;
	}

	UE_LOG(LogNet, Log, TEXT("UpdateGlobalActorClassSettings. Actor: %s"), *Actor->GetName());

	// Skip SKEL and REINST classes.
	if (Actor->GetName().StartsWith(TEXT("SKEL_")) || Actor->GetName().StartsWith(TEXT("REINST_")))
	{
		return;
	}

	FClassReplicationInfo& ClassInfo = GlobalInfo.Settings;

	// Replication Graph is frame based. Convert NetUpdateFrequency to ReplicationPeriodFrame based on Server MaxTickRate.
	ClassInfo.ReplicationPeriodFrame = GetReplicationPeriodFrameForFrequency(Actor->NetUpdateFrequency);

	if (Actor->bAlwaysRelevant || Actor->bOnlyRelevantToOwner)
	{
		ClassInfo.SetCullDistanceSquared(0.f);
		UE_LOG(LogNet, Log, TEXT("UpdateGlobalActorClassSettings. Actor->bAlwaysRelevant || Actor->bOnlyRelevantToOwner. Actor: %s"), *Actor->GetName());
	}
	else
	{
		ClassInfo.SetCullDistanceSquared(Actor->NetCullDistanceSquared);
		UE_LOG(LogNet, Log, TEXT("UpdateGlobalActorClassSettings. Actor: %s, NetCullDistanceSquared = %.2f"), *Actor->GetName(), Actor->NetCullDistanceSquared);
	}
}
