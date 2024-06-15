// Fill out your copyright notice in the Description page of Project Settings.

#pragma once
#include "lua.h"
#include "Characters/HiPlayerController.h"
#include "Kismet/GameplayStatics.h"

#include "HiUtilsUnlua.generated.h"

struct FMultiCmdRule
{
	FMultiCmdRule() = delete;
	FMultiCmdRule(const FString& _Begin, const FString& _End, const TArray<FString>& _SkipEndCmds) : Begin(_Begin), End(_End), SkipEndCmds(_SkipEndCmds) {}

	virtual ~FMultiCmdRule() {}

	virtual bool IsBegin(const FString& Cmd) const = 0;
	virtual bool IsEnd(const FString& Cmd) const;
	virtual bool IsSkipEnd(const FString& Cmd) const;
	virtual void AddSkipEnd();

	FString Begin;
	FString End;
	TArray<FString> SkipEndCmds;

	mutable int8 SkipEnd = 0;
};

struct FMultiCmdRuleLeft : public FMultiCmdRule
{
	FMultiCmdRuleLeft(const FString& _Begin, const FString& _End, const TArray<FString>& _SkipEndCmds) : FMultiCmdRule(_Begin, _End, _SkipEndCmds) {}
	virtual ~FMultiCmdRuleLeft() {}

	bool IsBegin(const FString& Cmd) const;
};

struct FMultiCmdRuleRight : public FMultiCmdRule
{
	FMultiCmdRuleRight(const FString& _Begin, const FString& _End, const TArray<FString>& _SkipEndCmds) : FMultiCmdRule(_Begin, _End, _SkipEndCmds) {}
	virtual ~FMultiCmdRuleRight() {}

	bool IsBegin(const FString& Cmd) const;
};

class FMultiCmdMgr
{
public:
	FMultiCmdMgr();
	
	virtual ~FMultiCmdMgr() {}
	
	FString MultiChunkBegin(const FString& Command);
	
	FString MultiChunkContinue(const FString& Command);

	FString MultiChunkEnd(const FString& Command);
	
	TArray<TSharedPtr<FMultiCmdRule>> MutilCmdRuleSet;
	TSharedPtr<FMultiCmdRule> CurMutilCmdRule;
	FString MultiCmdString = "";
};

extern FMultiCmdMgr MultiCmdMgr;


/**
 * 
 */
UCLASS()
class UHiUtilsUnLuaLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
public:
	UFUNCTION(BlueprintCallable)
    static void DoLuaString(const FString& LuaStr)
	{
		AHiPlayerController* control = Cast<AHiPlayerController>(UGameplayStatics::GetPlayerController(GEngine->GameViewport->GetWorld(), 0));
		if (IsValid(control))
		{
			control->DoLuaString(LuaStr);
		}
	}
	
	UFUNCTION(BlueprintCallable)
	static int GetLuaVersion()
	{
		return LUA_VERSION_NUM;
	}

	UFUNCTION(BlueprintCallable)
	static int bnot(const int& v1)
	{
		return ~v1;
	}

	UFUNCTION(BlueprintCallable)
	static int band(const int& v1, const int& v2)
	{
		return v1 & v2;
	}

	UFUNCTION(BlueprintCallable)
	static int bor(const int& v1, const int& v2)
	{
		return v1 | v2;
	}

	UFUNCTION(BlueprintCallable)
	static int lshift(const int& v1, const int& shift)
	{
		return v1 << shift;
	}

	UFUNCTION(BlueprintCallable)
	static int rshift(const int& v1, const int& shift)
	{
		return v1 >> shift;
	}
};
