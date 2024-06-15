

#pragma once

//把文件下载，更新功能尽可能集中到这个类，方便后续复用；启动器和游戏内下载都使用此下载模块，便于维护


#include "CoreMinimal.h"
//为了使用反射系统序列化json到结构体，依赖UObject！
#include "HiGameUpdateInfo.h"
#include "Runnable.h"
#include "libhsync/sync_client/sync_client.h"
#include "Queue.h"

//hsync index file
static const FString HSYNC_INDEX_SUFFIX = FString(".hindex");
static const FString HSYNC_DIFF_SUFFIX = FString(".hdiff");
static const FString HSYNC_PATCHED_SUFFIX = FString(".hpatched");

class FSyncPatchThread : public FRunnable
{
public:

	FSyncPatchThread(const FString& InVersionServerURL, const FString& InRootDir);

	virtual ~FSyncPatchThread();


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

	static FString HttpUrlEncode(const FStringView UnencodedString);

	//InOnlineVersion, true for OnlineVersionStr, false for LocalVersionStr
	FString GetVersionInfoStr(bool InOnlineVersion) const;

	bool RefreshLocalVersionInfoStr(const FString& InVersionStr) const;

	static int64 ContinueDownloadAtSize(const FString& InFileName, const FString& InExpectedHash);

	static bool SaveContinueDownloadFlag(const FString& InFileName, const FString& InExpectedHash);

	static void DeleteContinueDownloadFlag(const FString& InFileName);

protected:

	TSyncClient_resultType DownloadVersionInfo();

	TSyncClient_resultType DownloadIndexFiles(FHiGameVersionInfo InPatchInfo);

	TSyncClient_resultType AnalyzeChangedFiles(FHiGameVersionInfo& PatchInfo);

	TSyncClient_resultType AnalyzePatchInfo(FHiGameVersionInfo& InPatchInfo);

	TSyncClient_resultType DownloadPatch(FHiGameVersionInfo InPatchInfo);

	TSyncClient_resultType ApplyPatch(FHiGameVersionInfo InPatchInfo);

	TSyncClient_resultType VerifyAndMoveFile(FHiGameVersionInfo InPatchInfo);

	static hpatch_BOOL GetSyncDataDownloadPlugin(class TSyncDownloadPlugin* OutDownloadPlugin);

	//ISyncInfoListener::findChecksumPlugin
	static hpatch_TChecksum* FindChecksumPlugin(ISyncInfoListener* listener, const char* strongChecksumType);

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