// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Reply.h"
#include "SlateFontInfo.h"


class FHiGameLauncher
{
public:
	int RunHiGameLauncher(const TCHAR* CommandLine);

	static FString GetBuildDateTime();
protected:

	void HandleUpdaterEvent(const struct FUpdaterEventData* InEvent) const;

	FReply HandleButtonClicked_CheckVersion();

	FReply HandleButtonClicked_LaunchHiGame();
	
	TSharedPtr<SWindow> RestoreSlate();

	TSharedPtr<class SWindow> MainWindow = nullptr;
	TSharedPtr<class STextBlock> TextVersionStr = nullptr;
	TSharedPtr<class STextBlock> TextProgress = nullptr;
	TSharedPtr<class STextBlock> TextWorkState = nullptr;
	TSharedPtr<class SProgressBar> ProgressBar = nullptr;

	TSharedPtr<class SWidgetSwitcher> MainButtonContainer = nullptr;

	TSharedPtr<class SButton> ButtonCheckVersion = nullptr;

	TSharedPtr<class FSyncPatchThread> SyncPatchThread = nullptr;
	//TSharedPtr<class FHiGamePatchThread> HiGamePatchThread = nullptr;

	FString ClientRootDir;

	void* ReadPipeForLaunchGame = nullptr;
	void* WritePipeForLaunchGame = nullptr;

	FSlateFontInfo NormalFont_12;
	FSlateFontInfo LargeFont_32;
};
