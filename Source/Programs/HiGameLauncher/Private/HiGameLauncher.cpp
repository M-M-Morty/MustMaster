// Copyright Epic Games, Inc. All Rights Reserved.

#include "HiGameLauncher.h"
#include "RequiredProgramMainCPPInclude.h"
#include "LaunchEngineLoop.h"

//slate app
#include "StandaloneRenderer.h"
#include "Framework/Docking/TabManager.h"
#include "Framework/Application/SlateApplication.h"
//Slate widget
#include "Widgets/Text/STextBlock.h"
#include "SButton.h"
#include "SConstraintCanvas.h"
#include "Widgets/Layout/SScaleBox.h"
#include "SlateColorBrush.h"
#include "SImage.h"
#include "SWindow.h"
#include "SProgressBar.h"
#include "Widgets/Layout/SWidgetSwitcher.h"
#include "Widgets/Input/SEditableTextBox.h"
//sync patch
#include "SyncPatchThread.h"
//#include "HiGamePatchThread.h"
//main entry
#if PLATFORM_MAC
#include "Mac/MacProgramDelegate.h"
#elif PLATFORM_WINDOWS
#include "Windows/WindowsHWrapper.h"
#endif
#if PLATFORM_LINUX
#include "UnixCommonStartup.h"
#endif


IMPLEMENT_APPLICATION(HiGameLauncher, "HiGameLauncher");

#define LOCTEXT_NAMESPACE "HiGameLauncher"


#if PLATFORM_MAC
int main(int argc, char *argv[])
{
	FHiGameLauncher Launcher;
	return [MacProgramDelegate mainWithArgc:argc argv:argv programMain: Launcher.RunHiGameLauncher programExit:FEngineLoop::AppExit];
}
#elif PLATFORM_LINUX
int main(int argc, char* argv[])
{

	auto RealMain = [](const TCHAR* InCommand) {
		FHiGameLauncher Launcher;
		Launcher.RunHiGameLauncher(InCommand);

		return 0;
	};

	CommonUnixMain(argc, argv, RealMain);

	return 0;
}
#elif PLATFORM_WINDOWS
int WINAPI WinMain( _In_ HINSTANCE hInInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPSTR, _In_ int nCmdShow )
{
	FHiGameLauncher Launcher;
	// do the slate viewer thing
	Launcher.RunHiGameLauncher(GetCommandLineW());
	return 0;
}

#endif




int FHiGameLauncher::RunHiGameLauncher( const TCHAR* CommandLine )
{
	FTaskTagScope TaskTagScope(ETaskTag::EGameThread);	
	
	// start up the main loop
	GEngineLoop.PreInit(CommandLine);

	// Make sure all UObject classes are registered and default properties have been initialized
	ProcessNewlyLoadedUObjects();
	
	// Tell the module manager it may now process newly-loaded UObjects when new C++ modules are loaded
	FModuleManager::Get().StartProcessingNewlyLoadedObjects();


	// crank up a normal Slate application using the platform's standalone renderer
	FSlateApplication::InitializeAsStandaloneApplication(GetStandardStandaloneRenderer());

	FSlateApplication::InitHighDPI(true);

	
	// set the application name
	FGlobalTabmanager::Get()->SetApplicationTitle(LOCTEXT("AppTitle", "HiGameLauncher"));
	
    MainWindow = RestoreSlate();

	FSlateApplication::Get().AddWindow(MainWindow.ToSharedRef());


	FString DefaultVersionServerURL = FString("http://127.0.0.1:8080");
	DefaultVersionServerURL = FString("http://9.135.81.63:8080");

	FString LauncherExePath = FPlatformProcess::ExecutablePath();
	LauncherExePath.ReplaceInline(TEXT("\\"), TEXT("/"));
	UE_LOG(LogTemp, Display, TEXT("LauncherExePath: %s"), *LauncherExePath);

	ClientRootDir = FPaths::Combine(LauncherExePath, "../../../Saved");

	if (LauncherExePath.Contains("/Engine/Binaries/Win64/"))
	{
		ClientRootDir = FPaths::Combine(LauncherExePath, "../../../../../");
	}

	FString TempRootDir;
	if (FParse::Value(CommandLine, TEXT("-ClientRootDir="), TempRootDir))
	{
		ClientRootDir = TempRootDir;
	}

	ClientRootDir = FPaths::ConvertRelativePathToFull(ClientRootDir);

	FString ComputerName = FPlatformProcess::ComputerName();

	SyncPatchThread = MakeShared<FSyncPatchThread>(DefaultVersionServerURL, ClientRootDir);

	//发起版本更新命令
	SyncPatchThread->PushCmd_DownloadVersionInfo();

	//HiGamePatchThread = MakeShared<FHiGamePatchThread>(DefaultVersionServerURL, ClientRootDir);


	// loop while the server does the rest
	while (!IsEngineExitRequested() )
	{
		BeginExitIfRequested();

		FTaskGraphInterface::Get().ProcessThreadUntilIdle(ENamedThreads::GameThread);
		FStats::AdvanceFrame(false);
		FTSTicker::GetCoreTicker().Tick(FApp::GetDeltaTime());
		FSlateApplication::Get().PumpMessages();
		FSlateApplication::Get().Tick();

		//20FPS
		FPlatformProcess::Sleep(0.05);
	
		GFrameCounter++;

		FUpdaterEventData UpdaterEvent = SyncPatchThread->FetchUpdaterEvent();
		HandleUpdaterEvent(&UpdaterEvent);


	}

	SyncPatchThread->StopThread();
	SyncPatchThread = nullptr;

	FCoreDelegates::OnExit.Broadcast();
	FSlateApplication::Shutdown();
	FModuleManager::Get().UnloadModulesAtShutdown();

	GEngineLoop.AppPreExit();
	GEngineLoop.AppExit();

	return 0;

}

class FByteConversion
{
public:
	// 将字节转换为千字节（KB）
	static float ToKiloBytes(int64 Bytes) { return static_cast<float>(Bytes) / 1024.0f; }

	// 将字节转换为兆字节（MB）
	static float ToMegaBytes(int64 Bytes) { return ToKiloBytes(Bytes) / 1024.0f; }

	// 将字节转换为吉字节（GB）
	static float ToGigaBytes(int64 Bytes) { return ToMegaBytes(Bytes) / 1024.0f; }

	static const int64 OneKB = 1024;
	static const int64 OneMB = OneKB * 1024;
	static const int64 OneGB = OneMB * 1024;

	static FString ToFormatedString(int64 InBytes)
	{
		FString RetValue;
		if (InBytes >= OneGB)
		{
			RetValue = FString::Printf(TEXT("%.2fGB"), ToGigaBytes(InBytes));
		}
		else if (InBytes >= OneMB)
		{
			RetValue = FString::Printf(TEXT("%.2fMB"), ToMegaBytes(InBytes));
		}
		else if (InBytes >= OneKB)
		{
			RetValue = FString::Printf(TEXT("%.2fKB"), ToKiloBytes(InBytes));
		}
		else
		{
			RetValue = FString::Printf(TEXT("%lldB"), InBytes);
		}

		return RetValue;
	}
};

void FHiGameLauncher::HandleUpdaterEvent(const FUpdaterEventData* InEvent) const
{
	if (InEvent == nullptr )
	{
		return;
	}

	if(!InEvent->ErrorInfo.IsEmpty())
	{
		TextWorkState->SetText(FText::FromString(InEvent->ErrorInfo));
	}
	
	if (InEvent->State == EUpdaterState::DownloadVersionInfo)
	{
		TextWorkState->SetText(FText::FromString(L"下载版本信息..."));
		return;
	}

	if (InEvent->SubEvent == FUpdaterEventData::SubEvent_Update && InEvent->CurrentSize < InEvent->TotalSize)
	{
		float Pct = 100.f * InEvent->CurrentSize / InEvent->TotalSize;
		ProgressBar->SetPercent(Pct * 0.01f);
	}

	if (InEvent->State == EUpdaterState::DownloadIndexFiles)
	{
		FString DisplayStr = FString::Printf(TEXT("下载索引文件... %lld/%lld %s"), InEvent->CurrentSize, InEvent->TotalSize, *InEvent->ProcessingFileName);
		TextWorkState->SetText(FText::FromString(DisplayStr));
		if (InEvent->SubEvent == FUpdaterEventData::SubEvent_Begin)
		{
			FString LocalVersion = InEvent->LocalVersion;
			FString ServerVersion = InEvent->ServerVersion;
			FString DisplayStr;
			if (LocalVersion.IsEmpty())
			{
				DisplayStr = FString::Printf(TEXT("v%s"), *ServerVersion);	
			}
			else
			{
				DisplayStr = FString::Printf(TEXT("v%s -> v%s"), *LocalVersion, *ServerVersion);
			}
			TextVersionStr->SetText(FText::FromString(DisplayStr));
		}

		return;
	}

	if (InEvent->State == EUpdaterState::AnalyzePatchInfo && InEvent->SubEvent == FUpdaterEventData::SubEvent_Update)
	{
		FString DisplayStr = FString::Printf(TEXT("分析差异信息... %s / %s %s"), 
			*FByteConversion::ToFormatedString(InEvent->CurrentSize), *FByteConversion::ToFormatedString(InEvent->TotalSize), *InEvent->ProcessingFileName);
		TextWorkState->SetText(FText::FromString(DisplayStr));
		return;
	}

	if (InEvent->State == EUpdaterState::DownloadPatch && InEvent->SubEvent == FUpdaterEventData::SubEvent_DownloadPrepare)
	{
		FString DisplayStr = FString::Printf(TEXT("下载准备中... %s"), *InEvent->ProcessingFileName);
		TextWorkState->SetText(FText::FromString(DisplayStr));

		float Pct = 100.f * InEvent->CurrentSize / InEvent->TotalSize;
		ProgressBar->SetPercent(Pct * 0.01f);

		return;
	}

	if ( InEvent->State == EUpdaterState::DownloadPatch && InEvent->SubEvent == FUpdaterEventData::SubEvent_Update)
	{

		FString DisplayStr = FString::Printf(TEXT("下载更新包... %s / %s %s"), 
			*FByteConversion::ToFormatedString(InEvent->CurrentSize), *FByteConversion::ToFormatedString(InEvent->TotalSize), *InEvent->ProcessingFileName);

		TextWorkState->SetText(FText::FromString(DisplayStr));
		return;
	}

	if (InEvent->State == EUpdaterState::ApplyPatch && InEvent->SubEvent == FUpdaterEventData::SubEvent_Update)
	{
		FString DisplayStr = FString::Printf(TEXT("更新... %s / %s %s"), 
					*FByteConversion::ToFormatedString(InEvent->CurrentSize), *FByteConversion::ToFormatedString(InEvent->TotalSize), *InEvent->ProcessingFileName);
		
		TextWorkState->SetText(FText::FromString(DisplayStr));
		return;
	}

	if (InEvent->State == EUpdaterState::UpdateCompleted && InEvent->SubEvent == FUpdaterEventData::SubEvent_End)
	{
		FString DisplayStr = FString::Printf(TEXT("更新完成!"));
		if (!InEvent->ErrorInfo.IsEmpty())
		{
			DisplayStr = InEvent->ErrorInfo;
		}
		TextWorkState->SetText(FText::FromString(DisplayStr));
		ProgressBar->SetPercent(1.f);
		MainButtonContainer->SetActiveWidgetIndex(1);

		if(!InEvent->ServerVersion.IsEmpty())
		{
			DisplayStr = FString::Printf(TEXT("客户端版本: v%s"), *InEvent->ServerVersion);	
			TextVersionStr->SetText(FText::FromString(DisplayStr));
		}

		return;
	}
}

FReply FHiGameLauncher::HandleButtonClicked_CheckVersion()
{
	if (SyncPatchThread.IsValid())
	{
		SyncPatchThread->PushCmd_DownloadVersionInfo();
	}
	else
	{
		//TODO: error
	}
	return FReply::Handled();
}



FReply FHiGameLauncher::HandleButtonClicked_LaunchHiGame()
{
	TArray<FString> HiGameClientExeNames = { TEXT("HiGameClient.exe"), TEXT("HiGameClient-Win64-Test.exe"), TEXT("HiGameClient-Win64-Shipping.exe") };

	bool bClientRunning = false;
	
	/*
	FPlatformProcess::CreatePipe(ReadPipeForLaunchGame, WritePipeForLaunchGame);
	FPlatformProcess::CreateProc(TEXT("cmd.exe"), TEXT("/c tasklist"), false, true, false, nullptr, 0, nullptr, WritePipeForLaunchGame, ReadPipeForLaunchGame);
	FPlatformProcess::Sleep(1.f);
	FString CommandOutput = FPlatformProcess::ReadPipe(ReadPipeForLaunchGame);

	FPlatformProcess::ClosePipe(ReadPipeForLaunchGame, WritePipeForLaunchGame);
	ReadPipeForLaunchGame = WritePipeForLaunchGame = nullptr;

	for (FString Element : HiGameClientExeNames)
	{
		bClientRunning = bClientRunning || CommandOutput.Contains(Element);
	}
	*/
	if(bClientRunning)
	{
		FString DisplayStr = FString::Printf(TEXT("Client is running!"));
		TextWorkState->SetText(FText::FromString(DisplayStr));
		return FReply::Handled(); 
	}
	else
	{
		FString Bat = ClientRootDir / FString("HiGameClient/start_client.bat");
		if(FPlatformFileManager::Get().GetPlatformFile().FileExists(*Bat))
		{
			FString CmdParam = FString::Printf(TEXT("/c %s"), *Bat);
			FString WorkingDir = FPaths::GetPath(Bat);
			FPlatformProcess::CreatePipe(ReadPipeForLaunchGame, WritePipeForLaunchGame);
			FPlatformProcess::CreateProc(TEXT("cmd.exe"), *CmdParam, true, false, false, nullptr, 0, *WorkingDir, WritePipeForLaunchGame, ReadPipeForLaunchGame);
			FPlatformProcess::Sleep(1.f);
			FPlatformProcess::ClosePipe(ReadPipeForLaunchGame, WritePipeForLaunchGame);
			ReadPipeForLaunchGame = WritePipeForLaunchGame = nullptr;
		}
	}

	return FReply::Handled();
}


static FSlateBrush ImageColor;

TSharedPtr<SWindow> FHiGameLauncher::RestoreSlate()
{
	FString LauncherVersionStr = FString::Printf(TEXT("启动器版本: %s"), *GetBuildDateTime());

	NormalFont_12 = FSlateFontInfo(FCoreStyle::GetDefaultFont(), 12);
	LargeFont_32 = FSlateFontInfo(FCoreStyle::GetDefaultFont(), 32);
	
	TSharedPtr<SWindow> RetWindow = nullptr;
	TSharedPtr<SConstraintCanvas> MainCanvas = nullptr;

	FVector2D WindowSize = FVector2D(1280.f, 720.f);
	{
		//TODO: 根据屏幕分辨率缩放窗口大小
	}

	SAssignNew(RetWindow, SWindow)
	.AutoCenter( EAutoCenter::PreferredWorkArea )
	.ClientSize(WindowSize)
	.CreateTitleBar( true )
	.Title(FText::FromString(L"HiGame启动器"))
	.UseOSWindowBorder(true)
	.CreateTitleBar(true)
	.ShouldPreserveAspectRatio(true)
	.MinWidth(1280)
	.MinHeight(720)
	[
		
		SAssignNew(MainCanvas, SConstraintCanvas)
		//背景图片
		+SConstraintCanvas::Slot()
		.Anchors(FAnchors(0.f, 0.f, 1.f, 1.f))
		[
			SNew(SImage)
			.Image(&ImageColor)
		]
		//背景图片(文本代替)
		+ SConstraintCanvas::Slot()
		.Anchors(FAnchors(0.f, 0.f, 0.f, 0.f))
		.Offset(FMargin(200, 100, 250, 30))
		.AutoSize(true)
		[
			SNew(STextBlock)
				.Font(LargeFont_32)
				.Text(FText::FromString(L"HiGame 游戏客户端"))
				.ColorAndOpacity(FSlateColor(FLinearColor::Black))
		]
		//左下角一个文本框展示Launcher版本号
		+ SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(0.f, 1.f, 0.f, 1.f))
		.Offset(FMargin(60, -30, 250, 30))
		.AutoSize(true)
		[
			SNew(STextBlock)
				.Font(NormalFont_12)
				.Text(FText::FromString(LauncherVersionStr))
				.ColorAndOpacity(FSlateColor(FLinearColor::Black))
		]
		//左下角一个文本框展示客户端版本号
		+SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(0.f, 1.f, 0.f, 1.f))
		.Offset(FMargin(60, -60, 200, 40))
		.AutoSize(true)
		[
			SAssignNew(TextVersionStr, STextBlock)
			.Font(NormalFont_12)
			.ColorAndOpacity(FSlateColor(FLinearColor::Black))
		]
		//左下角一个文本框展示工作状态（以及提示语）
		+ SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(0.f, 1.f, 0.f, 1.f))
		.Offset(FMargin(350, -60, 800, 40))
		.AutoSize(true)
		[
			SAssignNew(TextWorkState, STextBlock)
			.Font(NormalFont_12)
			.ColorAndOpacity(FSlateColor(FLinearColor::Black))
		]
		//进度条
		+ SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(0.f, 1.f, 1.f, 1.f))
		.Offset(FMargin(60, -100, 60, 20))
		[
			SAssignNew(ProgressBar, SProgressBar)
			.Style(&FAppStyle::Get().GetWidgetStyle<FProgressBarStyle>("ProgressBar"))
			.Percent(0.f)
		]
		//进度条上面加一个开发中提示语
		+ SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(0.f, 1.f, 0.f, 1.f))
		.Offset(FMargin(60, -200, 900, 160))
		[
			SNew(STextBlock)
			.Font(NormalFont_12)
			.ColorAndOpacity(FSlateColor(FLinearColor::Black))
			.AutoWrapText(true)
			.Text(FText::FromString(""))
		]

		//右下角大按钮状态组合
		+SConstraintCanvas::Slot()
		.Alignment(FVector2D::ZeroVector)
		.Anchors(FAnchors(1.f, 1.f, 1.f, 1.f))
		.Offset(FMargin(-300, -200, 100, 60))
		.AutoSize(true)
		[
			SAssignNew(MainButtonContainer, SWidgetSwitcher)
			//状态0，检查更新
			+SWidgetSwitcher::Slot()
			.HAlign(EHorizontalAlignment::HAlign_Fill)
			.VAlign(EVerticalAlignment::VAlign_Fill)
			[
				SAssignNew(ButtonCheckVersion, SButton)
				.ButtonStyle(&FAppStyle::Get().GetWidgetStyle<FButtonStyle>("Button"))
				.OnClicked_Raw(this, &FHiGameLauncher::HandleButtonClicked_CheckVersion)
				[
					SNew(STextBlock)
						.Font(LargeFont_32)
						.Text(FText::FromString(L"检查更新"))
						.ColorAndOpacity(FSlateColor(FLinearColor::White))
				]
			]
			//状态1，更新结束，可启动影响
			+ SWidgetSwitcher::Slot()
			.HAlign(EHorizontalAlignment::HAlign_Fill)
			.VAlign(EVerticalAlignment::VAlign_Fill)
			[
				SNew(SButton)
					.ButtonStyle(&FAppStyle::Get().GetWidgetStyle<FButtonStyle>("Button"))
					.OnClicked_Raw(this, &FHiGameLauncher::HandleButtonClicked_LaunchHiGame)
					[
						SNew(STextBlock)
							.Font(LargeFont_32)
							.Text(FText::FromString(L"开始游戏"))
							.ColorAndOpacity(FSlateColor(FLinearColor::White))
					]
			]
		]
	];


	return RetWindow;

}


FString FHiGameLauncher::GetBuildDateTime()
{
	FString BuildDate = ANSI_TO_TCHAR(__DATE__);
	FString BuildTime = ANSI_TO_TCHAR(__TIME__);

	FString BuildDateTime = BuildDate + FString(" ") + BuildTime;
	return BuildDateTime;
}