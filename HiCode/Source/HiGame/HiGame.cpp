// Copyright Epic Games, Inc. All Rights Reserved.

#include "HiGame.h"

#include "Modules/ModuleManager.h"
#include "lua.hpp"
#include "UnLuaDelegates.h"
#include "ActorManagement/MutableActorComponent.h"
#include "ActorManagement/MutableActorSubsystem.h"

class FHiGameModuleImpl: public FDefaultGameModuleImpl
{
public:
	
	virtual void StartupModule() override
	{
		UnLuaStateCreatedHandle = FUnLuaDelegates::OnLuaStateCreated.AddStatic(FHiGameModuleImpl::OnUnLuaStateCreated);
		if (UnLua::IsEnabled())
		{
			lua_State* L = UnLua::GetState();
		}
		UnLuaUStructRegisteredHandle = FUnLuaDelegates::OnUStructRegistered.AddStatic(FHiGameModuleImpl::OnUnLuaUStructRegistered);
	}
	
	virtual void ShutdownModule() override
	{
		FUnLuaDelegates::OnLuaStateCreated.Remove(UnLuaStateCreatedHandle);
		FUnLuaDelegates::OnUStructRegistered.Remove(UnLuaUStructRegisteredHandle);
	}

	static void OnUnLuaStateCreated(lua_State* L)
	{
		
	}

	static void OnUnLuaUStructRegistered(lua_State* L, const UStruct* Class, const FString& MetatableName)
	{
		if (Class->IsChildOf(UMutableActorComponent::StaticClass()))
		{
			UMutableActorComponent::ExtendLuaMetatable(L, Class, MetatableName);
		}
	}
	
private:
	FDelegateHandle UnLuaStateCreatedHandle;
	FDelegateHandle UnLuaUStructRegisteredHandle;
};

IMPLEMENT_PRIMARY_GAME_MODULE( FHiGameModuleImpl, HiGame, "HiGame");
