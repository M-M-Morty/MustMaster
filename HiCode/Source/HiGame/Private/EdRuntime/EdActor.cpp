// Fill out your copyright notice in the Description page of Project Settings.


#include "EdRuntime/EdActor.h"
#include "Net/UnrealNetwork.h"

// Sets default values
AEdActor::AEdActor()
{
 	// Set this actor to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

}

// Called when the game starts or when spawned
void AEdActor::BeginPlay()
{
	Super::BeginPlay();
	
}

#if WITH_EDITOR
void AEdActor::PostEditChangeChainProperty(FPropertyChangedChainEvent& PropertyChangedEvent)
{
	Super::PostEditChangeChainProperty(PropertyChangedEvent);

	FProperty* Property = PropertyChangedEvent.Property;
	if (Property)
	{
		FProperty* MemberProperty = nullptr;
		if (PropertyChangedEvent.PropertyChain.GetActiveMemberNode())
		{
			MemberProperty = PropertyChangedEvent.PropertyChain.GetActiveMemberNode()->GetValue();
			const int32 AddedAtIndex = PropertyChangedEvent.GetArrayIndex(PropertyChangedEvent.Property->GetFName().ToString());
			FString Name = MemberProperty->GetName();
			int32 MemberNodeIndex = PropertyChangedEvent.GetArrayIndex(Name);
			const FName MemberPropertyName = MemberProperty->GetFName();
			/*if (MemberPropertyName != TEXT("StatusFlowChain"))
			{
				return;
			}*/

		}
	}
}

void AEdActor::PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent)
{
	Super::PostEditChangeProperty(PropertyChangedEvent);
}
#endif

// Called every frame
void AEdActor::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

void AEdActor::CallFromPython(const FString& Params)
{
	FromPython(Params);
}

void AEdActor::CallLowLevelRename(FName NewName, UObject* NewOuter)
{
	LowLevelRename(NewName, NewOuter);
}

FString AEdActor::CallGetPathName()
{
	return GetPathName();
}

void AEdActor::SetActorGuid(const FGuid& InGuid)
{
#if WITH_EDITORONLY_DATA
	ActorGuid = InGuid;
#endif
}

FBox AEdActor::GetBodyBounds(const UPrimitiveComponent* PrimitiveComp)
{
	return PrimitiveComp->BodyInstance.GetBodyBounds();
}

FTransform AEdActor::GetMassSpaceToWorldSpace(const UPrimitiveComponent* PrimitiveComp)
{
	return PrimitiveComp->BodyInstance.GetMassSpaceToWorldSpace();
}

void AEdActor::SetBodyTransform(UPrimitiveComponent* PrimitiveComp, const FTransform& NewTransform, ETeleportType Teleport, bool bAutoWake)
{
	PrimitiveComp->BodyInstance.SetBodyTransform(NewTransform, Teleport, bAutoWake);
}

void AEdActor::GetLifetimeReplicatedProps(TArray< FLifetimeProperty >& OutLifetimeProps) const
{
	Super::GetLifetimeReplicatedProps(OutLifetimeProps);
	DOREPLIFETIME_CONDITION(AEdActor, EditorID, COND_InitialOnly);
}

