#pragma once

#include "CoreMinimal.h"
#include "ReplicationGraph.h"
#include "BasicReplicationGraph.h"
#include "HiGameReplicationGraph.generated.h"

UCLASS(transient, config=Engine)
class UHiGameReplicationGraph : public UReplicationGraph
{
	GENERATED_BODY()

public:
	UHiGameReplicationGraph();

	virtual void InitGlobalActorClassSettings() override;
	virtual void InitGlobalGraphNodes() override;
	virtual void InitConnectionGraphNodes(UNetReplicationGraphConnection* RepGraphConnection) override;
	virtual void RouteAddNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo, FGlobalActorReplicationInfo& GlobalInfo) override;
	virtual void RouteRemoveNetworkActorToNodes(const FNewReplicatedActorInfo& ActorInfo) override;

	virtual int32 ServerReplicateActors(float DeltaSeconds) override;

	UPROPERTY()
	TObjectPtr<UReplicationGraphNode_GridSpatialization2D> GridNode;

	UPROPERTY()
	TObjectPtr<UReplicationGraphNode_ActorList> AlwaysRelevantNode;

	UPROPERTY()
	TArray<FConnectionAlwaysRelevantNodePair> AlwaysRelevantForConnectionList;

	/** Actors that are only supposed to replicate to their owning connection, but that did not have a connection on spawn */
	UPROPERTY()
	TArray<TObjectPtr<AActor>> ActorsWithoutNetConnection;

	TMap<AActor*, UReplicationGraphNode*> ActorToAlwaysRelevantConnectionMap;


	UReplicationGraphNode_AlwaysRelevant_ForConnection* GetAlwaysRelevantNodeForConnection(UNetConnection* Connection);

private:
	void UpdateGlobalActorClassSettings(AActor* Actor, FGlobalActorReplicationInfo& GlobalInfo);
};
