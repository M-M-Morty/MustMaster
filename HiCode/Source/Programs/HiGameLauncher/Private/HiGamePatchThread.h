

#pragma once

//把文件下载，更新功能尽可能集中到这个类，方便后续复用；启动器和游戏内下载都使用此下载模块，便于维护


#include "CoreMinimal.h"
//为了使用反射系统序列化json到结构体，依赖UObject！
#include "HiGameUpdateInfo.h"
#include "Runnable.h"
#include "Queue.h"


class FHiGamePatchThread : public FRunnable
{
public:

	FHiGamePatchThread(const FString& InVersionServerURL, const FString& InRootDir);

	virtual ~FHiGamePatchThread();


	EUpdaterState GetWorkingState() const
	{
		return WorkingState;
	}

	bool TransitionWorkingState(EUpdaterState InNewState);

	// FRunnable functions
	virtual uint32 Run() override;

	virtual void StopThread();

	//发起检查版本
	bool PushCmd_DownloadVersionInfo();

	FUpdaterEventData FetchUpdaterEvent();

	int32 DownloadVersionInfo();

	int32 DownloadIndexFiles(FHiGameVersionInfo InPatchInfo);

	FHiGameVersionInfo AnalyzeChangedFiles();
	
	int32 AnalyzePatchInfo(FHiGameVersionInfo& InPatchInfo);

	static FString HttpUrlEncode(const FStringView UnencodedString);

	//InOnlineVersion, true for OnlineVersionStr, false for LocalVersionStr
	FString GetVersionInfoStr(bool InOnlineVersion) const;

	bool RefreshLocalVersionInfoStr(const FString& InVersionStr) const;

	static int64 ContinueDownloadAtSize(const FString& InFileName, const FString& InExpectedHash);

	static bool SaveContinueDownloadFlag(const FString& InFileName, const FString& InExpectedHash);

	static void DeleteContinueDownloadFlag(const FString& InFileName);



	static uint64 XXHashFile(const FString& InFileName);

protected:

	EUpdaterState WorkingState;

	FString VersionServerURL;
	FString RootDir;

	FString CachedLocalVersion;
	FString CachedServerVersion;

	FRunnableThread* Thread = nullptr;
	bool bRequestStop = false;

	//旧版本文件不存在需要全量下载
	TArray<FString> FullyDownloadFileList;

	//用户输入的指令
	TQueue<EUpdaterCommand> PenndingCommandList;

	//更新程序本身的事件，需要在界面呈现
	TQueue<FUpdaterEventData> EventList;

};