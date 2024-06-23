#include "ActorManagement/MutableActorComponent.h"

#include "CommonLuaLib.h"
#include "LuaCore.h"
#include "CProtobufLualib.h"
#include "CProtobufMessageTracker.h"
#include "CProtobufUELib.h"
#include "DistributedDSUtils.h"
#include "GEOAssociateComponent.h"
#include "GEOSpaceManager.h"
#include "ActorManagement/MutableActorSubsystem.h"
#include "DistributedEntityType.h"
#include "DSClusterPeerWorldProxyMode.h"
#include "Net/UnrealNetwork.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wdangling"
#endif

UMutableActorComponent::UMutableActorComponent(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void UMutableActorComponent::PostTransfer()
{
	Super::PostTransfer();
	if (FDistributedDSUtils::IsClusterWorldProxyMode())
	{
		// Notify Actor Transfer
		if (AActor* ComponentOwner = GetOwner())
		{
			if (GET_ACTOR_COMPONENT(ComponentOwner, UGeoAssociateComponent))
			{
				UGeoSpaceManager* SpaceManager = GetWorld()->GetSubsystem<UGeoSpaceManager>();
				FSpaceID TransFromSpaceID = SpaceManager->GetSpaceIDByPartID(Component->GetTransFromPartID());
				FSpaceID TransToSpaceID = SpaceManager->GetLocalSpaceID();

				if (!FDistributedDSUtils::IsClientPlayerControlActor(ComponentOwner))
				{
					if (UDSClusterPeerWorldProxyMode* ClusterPeer = GetWorld()->GetSubsystem<UDSClusterPeerWorldProxyMode>())
					{
						ClusterPeer->NotifyActorTransfer(ActorID, TransFromSpaceID, TransToSpaceID);
					}
				}
			}
		}
	}
}

FString UMutableActorComponent::GenerateChildActorID()
{
	if (GameplayEntity == nullptr)
	{
		return "";
	}
	uint32 ActorIndex = GameplayEntity->GenerateChildActorIndex();
	return FString::Printf(TEXT("%s:%d"), *ActorID, ActorIndex);
}

int32 UMutableActorComponent_SetInitialPropertyMessage(lua_State *L)
{
	void* ObjectUD = GetCppInstance(L, 1);
	if (ObjectUD == nullptr)
	{
		return 0;
	}
	// const char* MetatableNameStr = lua_tostring(L, lua_upvalueindex(2));
	// void* ud = Lua_CppCheckUData(L, 1, MetatableNameStr);
	UMutableActorComponent* MutableActorComponent = static_cast<UMutableActorComponent*>(ObjectUD);
	void* MessageUD = Lua_CppCheckUdata(L, 2, HiGame::CPROTOBUF_MESSAGE);
	CProtobufMessageWrapperPtr& MessageWrapperPtr = *static_cast<CProtobufMessageWrapperPtr*>(MessageUD);
	if (!MessageWrapperPtr->IsRoot())
	{
		Lua_ThrowCppError("SetInitialPropertyMessage message is not root");
		return 0;
	}
	if (!MessageWrapperPtr->IsValid())
	{
		// this cannot happen..
		Lua_ThrowCppError("SetInitialPropertyMessage message is invalid");
		return 0;
	}
	MutableActorComponent->SetInitialPropertyMessage(MessageWrapperPtr);
	return 0;
}

int32 UMutableActorComponent_GetEntity(lua_State *L)
{
	void* ObjectUD = GetCppInstance(L, 1);
	if (ObjectUD == nullptr)
	{
		return 0;
	}
	// const char* MetatableNameStr = lua_tostring(L, lua_upvalueindex(2));
	// void* ud = Lua_CppCheckUData(L, 1, MetatableNameStr);
	UMutableActorComponent* MutableActorComponent = static_cast<UMutableActorComponent*>(ObjectUD);
	FUnrealGameplayEntity* GameplayEntity = MutableActorComponent->GetEntity();
	if (GameplayEntity == nullptr)
	{
		lua_pushnil(L);
		return 1;
	}
	void* p = lua_newuserdata(L, sizeof(FUnrealGameplayEntity*));
	*(FUnrealGameplayEntity**)p = GameplayEntity;
	luaL_getmetatable(L, FUnrealGameplayEntity::GAMEPLAY_ENTITY);
	lua_setmetatable(L, -2);
	return 1;
}


void UMutableActorComponent::ExtendLuaMetatable(lua_State* L, const UStruct* Class, const FString& MetatableName)
{
	const char* MetatableNameStr = TCHAR_TO_UTF8(*MetatableName);
#if LUA_VERSION_NUM >= 502
	int Type = luaL_getmetatable(L, MetatableNameStr);
#else
	luaL_getmetatable(L, MetatableNameStr);
	int Type = lua_type(L, -1);
#endif
	if (Type == LUA_TTABLE)
	{
		lua_pushstring(L, "SetInitialPropertyMessage");
		lua_pushcfunction(L, UMutableActorComponent_SetInitialPropertyMessage);
		lua_pushstring(L, MetatableNameStr);
		lua_pushcclosure(L, Lua_CppFunctionWrapper, 2);
		lua_rawset(L, -3);

		lua_pushstring(L, "GetEntity");
		lua_pushcfunction(L, UMutableActorComponent_GetEntity);
		lua_pushstring(L, MetatableNameStr);
		lua_pushcclosure(L, Lua_CppFunctionWrapper, 2);
		lua_rawset(L, -3);
	
		lua_pop(L, 1);
	}
	else
	{
		lua_pop(L, 1);
		UE_LOG(LogMutableActor, Error, TEXT("ExtendLuaMetatable_UMutableActorComponent Class(%s) Metatable(%s) not valid"), *Class->GetName(), *MetatableName);
	}
}

