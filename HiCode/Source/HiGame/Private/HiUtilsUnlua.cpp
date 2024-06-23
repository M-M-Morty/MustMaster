// Fill out your copyright notice in the Description page of Project Settings.

#include "HiUtilsUnlua.h"


bool FMultiCmdRule::IsEnd(const FString& Cmd) const
{
	if (FCString::Strncmp(*Cmd.Right(End.Len()), *End, End.Len()) == 0)
	{
		if (SkipEnd > 0)
		{
			--SkipEnd;
		}
		else
		{
			return true;
		}
	}
		
	return false;
}
	
bool FMultiCmdRule::IsSkipEnd(const FString& Cmd) const
{
	for (auto iter = SkipEndCmds.begin(); iter != SkipEndCmds.end(); ++iter)
	{
		auto& SkipEndCmd = *iter;
		if (FCString::Strncmp(*Cmd.Left(End.Len()), *SkipEndCmd, SkipEndCmd.Len()) == 0)
		{
			return true;
		}
	}

	return false;
}

void FMultiCmdRule::AddSkipEnd()
{
	++SkipEnd;
}

bool FMultiCmdRuleLeft::IsBegin(const FString& Cmd) const
{
	return FCString::Strncmp(*Cmd.Left(Begin.Len()), *Begin, Begin.Len()) == 0;
}

bool FMultiCmdRuleRight::IsBegin(const FString& Cmd) const
{
	return FCString::Strncmp(*Cmd.Right(Begin.Len()), *Begin, Begin.Len()) == 0;
}

FMultiCmdMgr::FMultiCmdMgr()
{
	MutilCmdRuleSet.Add(TSharedPtr<FMultiCmdRuleLeft>(new FMultiCmdRuleLeft("function", "end", TArray<FString>({"if", "for"}))));  // function
	MutilCmdRuleSet.Add(TSharedPtr<FMultiCmdRuleRight>(new FMultiCmdRuleRight("{", "}", TArray<FString>())));  // table
}

FString FMultiCmdMgr::MultiChunkBegin(const FString& Command)
{
	MultiCmdString = Command;
	MultiCmdString += ' ';
	return TEXT("");
}

FString FMultiCmdMgr::MultiChunkContinue(const FString& Command)
{
	MultiCmdString += Command;
	MultiCmdString += ' ';
	return TEXT("");
}

FString FMultiCmdMgr::MultiChunkEnd(const FString& Command)
{
	MultiCmdString += Command;
	const FString NewCommand = MultiCmdString;
	MultiCmdString = "";
	CurMutilCmdRule->SkipEnd = 0;
	CurMutilCmdRule = nullptr;
	return NewCommand;
}


FMultiCmdMgr MultiCmdMgr;
