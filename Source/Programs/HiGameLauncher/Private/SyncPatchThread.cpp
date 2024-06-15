

#include "SyncPatchThread.h"

#include "JsonObjectConverter.h"
#include "Misc/FileHelper.h"
#include "Async.h"
#include "TaskGraphInterfaces.h"
#include "PlatformFileManager.h"
#include "Paths.h"
#include "GenericPlatform/GenericPlatformAtomics.h"
#include "HAL/FileManager.h"
#if PLATFORM_WINDOWS
#include "Windows/AllowWindowsPlatformTypes.h"
#endif

#include "libhsync/sync_client/sync_client_type_private.h"
#include "libhsync/sync_client/sync_client_private.h"
#include "file_for_patch.h"
#include "xxhash/xxh3.h"

#if PLATFORM_WINDOWS
#include "Windows/HideWindowsPlatformTypes.h"
#endif

static bool IsAllowedChar(UTF8CHAR LookupChar)
{
	static char AllowedChars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~/:";
	static bool bTableFilled = false;
	static bool AllowedTable[256] = { false };

	if (!bTableFilled)
	{
		for (int32 Idx = 0; Idx < UE_ARRAY_COUNT(AllowedChars) - 1; ++Idx)	// -1 to avoid trailing 0
		{
			uint8 AllowedCharIdx = static_cast<uint8>(AllowedChars[Idx]);
			check(AllowedCharIdx < UE_ARRAY_COUNT(AllowedTable));
			AllowedTable[AllowedCharIdx] = true;
		}

		bTableFilled = true;
	} 

	return AllowedTable[LookupChar];
}

//Checksum

static const char* _xxh128_checksumType(void) {
	static const char* type = "xxh128";
	return type;
}
static size_t _xxh128_checksumByteSize(void) {
	return 16;
}
static hpatch_checksumHandle _xxh128_open(hpatch_TChecksum* plugin) {
	return XXH3_createState();
}
static void _xxh128_close(hpatch_TChecksum* plugin, hpatch_checksumHandle handle) {
	if (handle) {
		XXH_errorcode ret = XXH3_freeState((XXH3_state_t*)handle);
		assert(ret == XXH_OK);
	}
}
static void _xxh128_begin(hpatch_checksumHandle handle) {
	XXH_errorcode ret = XXH3_128bits_reset((XXH3_state_t*)handle);
	assert(ret == XXH_OK);
}
static void _xxh128_append(hpatch_checksumHandle handle,
	const unsigned char* part_data, const unsigned char* part_data_end) {
	XXH_errorcode ret = XXH3_128bits_update((XXH3_state_t*)handle, part_data, part_data_end - part_data);
	assert(ret == XXH_OK);
}
static void _xxh128_end(hpatch_checksumHandle handle,
	unsigned char* checksum, unsigned char* checksum_end) {
	assert(16 == checksum_end - checksum);
	XXH128_hash_t h128 = XXH3_128bits_digest((XXH3_state_t*)handle);
	XXH_writeLE64(checksum, h128.low64);
	XXH_writeLE64(checksum + 8, h128.high64);
}

class TSyncDownloadPlugin
{
public:
	//download range of file
	hpatch_BOOL(*download_range_open) (IReadSyncDataListener* out_listener,
		const char* file_url, size_t kStepRangeNumber, FDownloadProgressCallback ProgressCallback);
	hpatch_BOOL(*download_range_close)(IReadSyncDataListener* listener);
	//download file
	hpatch_BOOL(*download_file)      (const char* file_url, const hpatch_TStreamOutput* out_stream,
		hpatch_StreamPos_t continueDownloadPos, FDownloadProgressCallback ProgressCallback);
};

TSyncClient_resultType DownloadFile(const TSyncDownloadPlugin* downloadPlugin, const char* file_url, const char* out_file, bool isUsedDownloadContinue, FDownloadProgressCallback InProgressCallback)
{
	FString DestFile = UTF8_TO_TCHAR(out_file);
	FPlatformFileManager::Get().GetPlatformFile().CreateDirectoryTree(*FPaths::GetPath(DestFile));

	TSyncClient_resultType result = kSyncClient_ok;
	hpatch_TFileStreamOutput out_stream;
	hpatch_TFileStreamOutput_init(&out_stream);
	if (isUsedDownloadContinue && hpatch_isPathExist(out_file)) { // download continue
		printf("  download continue ");
		if (!hpatch_TFileStreamOutput_reopen(&out_stream, out_file, (hpatch_StreamPos_t)(-1)))
			return kSyncClient_newSyncInfoCreateError;
		printf("at file pos: %" PRIu64 "\n", out_stream.out_length);
	}
	else {
		if (!hpatch_TFileStreamOutput_open(&out_stream, out_file, (hpatch_StreamPos_t)(-1)))
			return kSyncClient_newSyncInfoCreateError;
	}
	//hpatch_TFileStreamOutput_setRandomOut(&out_stream,hpatch_TRUE);
	hpatch_StreamPos_t continueDownloadPos = out_stream.out_length;
	if (downloadPlugin->download_file(file_url, &out_stream.base, continueDownloadPos, InProgressCallback))
		out_stream.base.streamSize = out_stream.out_length;
	else
		result = kSyncClient_newSyncInfoDownloadError;
	if (!hpatch_TFileStreamOutput_close(&out_stream)) {
		if (result == kSyncClient_ok)
			result = kSyncClient_newSyncInfoCloseError;
	}
	return result;
}


FSyncPatchThread::FSyncPatchThread(const FString& InVersionServerURL, const FString& InRootDir)
{
	VersionServerURL = InVersionServerURL;
	RootDir = InRootDir;
	WorkingState = EUpdaterState::None;

	Thread = FRunnableThread::Create(this, TEXT("SyncPatchThread"));
}

FSyncPatchThread::~FSyncPatchThread()
{
	StopThread();
}

bool FSyncPatchThread::TransitionWorkingState(EUpdaterState InNewState)
{
	bool bValidState = (((int32)WorkingState + 1 == (int32)InNewState) 
		|| (WorkingState == EUpdaterState::None) 
		|| (InNewState == EUpdaterState::None)
		|| (InNewState == EUpdaterState::UpdateCompleted));
	if (bValidState)
	{
		WorkingState = InNewState;
		return true;
	}
	else
	{
		return false;
	}
}

uint32 FSyncPatchThread::Run()
{
	int64 NeedDownloadSize = -1;
	TSyncClient_resultType retType = TSyncClient_resultType::kSyncClient_ok;
	FHiGameVersionInfo PatchInfo;

	EUpdaterCommand NextCmd;

	//本地比CDN更新
	bool bNewerThanCDN = false;

	while (!bRequestStop)
	{
		FUpdaterEventData NextEvent;

		NextEvent.State = WorkingState;

		switch (WorkingState)
		{
		case EUpdaterState::None:
			if (PenndingCommandList.Dequeue(NextCmd))
			{
				TransitionWorkingState(EUpdaterState::DownloadVersionInfo);
			}
			break;

		case EUpdaterState::DownloadVersionInfo:	
			bNewerThanCDN = false;
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = DownloadVersionInfo();
			//执行成功才能转换到下一个状态
			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::AnalyzeChangedFiles);
			}
			break;
		case EUpdaterState::AnalyzeChangedFiles:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = AnalyzeChangedFiles(PatchInfo);
			//执行成功才能转换到下一个状态,不过一般应该不会失败？
			if(retType == kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::DownloadIndexFiles);
			}
			if(retType == kSyncClient_optionsError)
			{
				bNewerThanCDN = true;
				TransitionWorkingState(EUpdaterState::UpdateCompleted);
			}
			break;

		case EUpdaterState::DownloadIndexFiles:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			NextEvent.LocalVersion = CachedLocalVersion;
			NextEvent.ServerVersion = CachedServerVersion;
			EventList.Enqueue(NextEvent);

			retType = DownloadIndexFiles(PatchInfo);
			//执行成功才能转换到下一个状态
			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::AnalyzePatchInfo);
			}
			break;

		case EUpdaterState::AnalyzePatchInfo:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = AnalyzePatchInfo(PatchInfo);
			//执行成功才能转换到下一个状态
			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::DownloadPatch);
			}
			break;

		case EUpdaterState::DownloadPatch:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = DownloadPatch(PatchInfo);
			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::ApplyPatch);
			}
			break;

		case EUpdaterState::ApplyPatch:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = ApplyPatch(PatchInfo);
			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::VerifyAndMoveFile);
			}
			break;

		case EUpdaterState::VerifyAndMoveFile:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			retType = VerifyAndMoveFile(PatchInfo);

			NextEvent.SubEvent = FUpdaterEventData::SubEvent_End;
			NextEvent.ServerVersion = PatchInfo.VersionStr;
			EventList.Enqueue(NextEvent);

			if (retType == TSyncClient_resultType::kSyncClient_ok)
			{
				TransitionWorkingState(EUpdaterState::UpdateCompleted);
			}
			break;

		case EUpdaterState::UpdateCompleted:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_End;
			NextEvent.ServerVersion = PatchInfo.VersionStr;
			if (bNewerThanCDN)
			{
				NextEvent.ErrorInfo = FString(L"本地版本比CDN上版本更新，无需更新");
			}
			EventList.Enqueue(NextEvent);
			TransitionWorkingState(EUpdaterState::None);

			break;

		default:
			break;

		}
		FPlatformProcess::Sleep(0.1f);
	}

	return 0;
}

void FSyncPatchThread::StopThread()
{
	bRequestStop = true;

	if (Thread != nullptr)
	{
		Thread->Kill(true);
		Thread = nullptr;
	}
}

TSyncClient_resultType FSyncPatchThread::DownloadVersionInfo()
{
	TSyncDownloadPlugin DownloadPlugin;
	GetSyncDataDownloadPlugin(&DownloadPlugin);

	TSyncClient_resultType ret = kSyncClient_newSyncInfoDownloadError;

	if (RootDir.IsEmpty())
	{
		return ret;
	}

	//获取最新版本号
	FString OnlineVersionNum;
	{
		FString DownloadURL = VersionServerURL / FString("OnlineVersionNum.txt");
		FString EncodedURL = HttpUrlEncode(DownloadURL);
		FString SavedPath = RootDir / FString("OnlineVersionNum.txt");
		ret = DownloadFile(&DownloadPlugin, TCHAR_TO_UTF8(*EncodedURL), TCHAR_TO_UTF8(*SavedPath), false, nullptr);

		if (ret == kSyncClient_ok)
		{
			FFileHelper::LoadFileToString(OnlineVersionNum, *SavedPath);
			if (OnlineVersionNum.Len() < 1 || OnlineVersionNum.Len() > 32 || !OnlineVersionNum.IsNumeric())
			{
				OnlineVersionNum.Reset();
			}
		}
	}

	//获取最新版本号对应的文件列表
	if(!OnlineVersionNum.IsEmpty())
	{
		FString DownloadURL = VersionServerURL / OnlineVersionNum / FString("OnlineVersion.json");
		FString EncodedURL = HttpUrlEncode(DownloadURL);
		FString SavedPath = RootDir / FString("HiGameClient/OnlineVersion.json");
		ret = DownloadFile(&DownloadPlugin, TCHAR_TO_UTF8(*EncodedURL), TCHAR_TO_UTF8(*SavedPath), false, nullptr);
	}
	
	return ret;
}

TSyncClient_resultType FSyncPatchThread::DownloadIndexFiles(FHiGameVersionInfo InPatchInfo)
{
	TSyncClient_resultType RetValue = kSyncClient_ok;

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	TSyncDownloadPlugin DownloadPlugin;
	GetSyncDataDownloadPlugin(&DownloadPlugin);

	for (int32 idx = 0; idx < InPatchInfo.FileList.Num(); ++idx)
	{
		if (EventList.IsEmpty())
		{
			FUpdaterEventData NextEvent;
			NextEvent.State = WorkingState;
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Update;
			NextEvent.ProcessingFileName = InPatchInfo.FileList[idx].Name;
			NextEvent.CurrentSize = idx;
			NextEvent.TotalSize = InPatchInfo.FileList.Num();
			EventList.Enqueue(NextEvent);
		}
		
		FHiGameFileInfo FileInfo = InPatchInfo.FileList[idx];

		FString DownloadURL = VersionServerURL / InPatchInfo.VersionStr / FileInfo.Name + HSYNC_INDEX_SUFFIX;
		FString EncodedURL = HttpUrlEncode(DownloadURL);
		FString SavedPath = RootDir / FileInfo.Name + HSYNC_INDEX_SUFFIX;
		
		PlatformFile.CreateDirectoryTree(*FPaths::GetPath(SavedPath));

		RetValue = DownloadFile(&DownloadPlugin, TCHAR_TO_UTF8(*EncodedURL), TCHAR_TO_UTF8(*SavedPath), false, nullptr);

		if (RetValue != kSyncClient_ok)
		{
			break;
		}

	}

	return RetValue;
}

TSyncClient_resultType FSyncPatchThread::AnalyzeChangedFiles(FHiGameVersionInfo& PatchInfo)
{
	TSyncClient_resultType RetValue = TSyncClient_resultType::kSyncClient_ok;

	FString OnlineVersionStr = GetVersionInfoStr(true);
	FString LocalVersionStr = GetVersionInfoStr(false);

	FHiGameVersionInfo OnlineVersionInfo;
	FHiGameVersionInfo LocalVersionInfo;

	FJsonObjectConverter::JsonObjectStringToUStruct<FHiGameVersionInfo>(OnlineVersionStr, &OnlineVersionInfo);
	OnlineVersionInfo.GenerateFileNameToListIndex();

	FJsonObjectConverter::JsonObjectStringToUStruct<FHiGameVersionInfo>(LocalVersionStr, &LocalVersionInfo);
	LocalVersionInfo.GenerateFileNameToListIndex();

	CachedLocalVersion = LocalVersionInfo.VersionStr;
	CachedServerVersion = OnlineVersionInfo.VersionStr;

	int64 VersionInt = FCString::Atoi64(*CachedLocalVersion);
	int64 VersionInt2 = FCString::Atoi64(*CachedServerVersion);

	if(VersionInt2 > 0 && VersionInt > VersionInt2)
	{
		return TSyncClient_resultType::kSyncClient_optionsError;
	}
	
	TSet<FString> TargetFileNames(OnlineVersionInfo.GetAllFileNames());
	TSet<FString> SourceFileNames(LocalVersionInfo.GetAllFileNames());

	//add
	TArray<FString> AddedFileNames = TargetFileNames.Difference(SourceFileNames).Array();

	//remove
	TArray<FString> RemovedFileNames = SourceFileNames.Difference(TargetFileNames).Array();

	//changed
	TArray<FString> ChangedFileNames;
	TSet<FString> Intersection = SourceFileNames.Intersect(TargetFileNames);

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	for (FString ExistFileName : Intersection)
	{
		const FHiGameFileInfo* SourceFileInfo = LocalVersionInfo.GetFileItemInfoByName(ExistFileName);
		const FHiGameFileInfo* TargetFileInfo = OnlineVersionInfo.GetFileItemInfoByName(ExistFileName);
		if (SourceFileInfo != nullptr && TargetFileInfo != nullptr)
		{
			FString LocalFileName = RootDir / ExistFileName;

			//if (LocalFileName.EndsWith("HiGame-WindowsClient.pak"))
			{
				//UE_DEBUG_BREAK();
			}

			int64 LocalFileSize = PlatformFile.FileSize(*LocalFileName);
			FString LocalFileTimeStampStr = FPlatformFileManager::Get().GetPlatformFile().GetTimeStamp(*LocalFileName).ToString(TEXT("%Y%m%d%H%M%S"));
			int64 LocalFileTimeStamp = FCString::Atoi64(*LocalFileTimeStampStr);
			if (LocalFileSize != SourceFileInfo->Size
				|| LocalFileTimeStamp != SourceFileInfo->TimeStamp
				|| SourceFileInfo->Hash != TargetFileInfo->Hash)
			{
				ChangedFileNames.Add(ExistFileName);
			}
		}

	}

	TArray<FString> PatchFileList = AddedFileNames;
	PatchFileList.Append(ChangedFileNames);

	for (const FString& It : PatchFileList)
	{
		const FHiGameFileInfo* FileItem = OnlineVersionInfo.GetFileItemInfoByName(It);
		check(FileItem != nullptr);
		PatchInfo.FileList.Add(*FileItem);
	}

	PatchInfo.VersionDesc = OnlineVersionInfo.VersionDesc;
	PatchInfo.VersionStr = OnlineVersionInfo.VersionStr;

	return RetValue;
}

struct FHiGameSyncInfoListener: public ISyncInfoListener
{
public:
	TFunction<void(int64)> CallbackFunc = nullptr;

	//ISyncInfoListener::needSyncInfo
	//拿到了下载信息，需要记录下来，并展示到界面上
	static void OnNeedSyncInfo_V2(ISyncInfoListener* listener, const TNeedSyncInfos* needSyncInfo)
	{
		if (listener)
		{
			FHiGameSyncInfoListener* CallbackWrapper = static_cast<FHiGameSyncInfoListener*>(listener);
			if (CallbackWrapper->CallbackFunc)
			{
				CallbackWrapper->CallbackFunc(needSyncInfo->needSyncSumSize);
			}
		}
	}
};


struct FReadDataStream : public hpatch_TStreamInput
{
public:

	FReadDataStream(const FString& InFileName)
	{
		FileName = InFileName;
		FileHandle = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*FileName);
		if (FileHandle != nullptr)
		{

			FileSize = FileHandle->Size();
			streamSize = (hpatch_StreamPos_t)FileSize;
		}
	}

	~FReadDataStream()
	{
		if (FileHandle)
		{
			delete FileHandle;
			FileHandle = nullptr;
		}
	}
	
	//read() must read (out_data_end-out_data), otherwise error return hpatch_FALSE
	//hpatch_BOOL            (*read)(const struct hpatch_TStreamInput* stream,hpatch_StreamPos_t readFromPos,
								   //unsigned char* out_data,unsigned char* out_data_end);
	static hpatch_BOOL OnRead_V2(const struct hpatch_TStreamInput* stream,hpatch_StreamPos_t readFromPos,
		unsigned char* out_data,unsigned char* out_data_end)
	{
		int64 RetValue = hpatch_FALSE;
		int64 ReadSize = out_data_end - out_data;			
		const FReadDataStream* DataStream = static_cast<const FReadDataStream*>(stream);
		if (DataStream->FileHandle != nullptr)
		{
			DataStream->FileHandle->Seek(readFromPos);
			if((int64)readFromPos < DataStream->FileSize && ((int64)readFromPos + ReadSize) <= DataStream->FileSize)
			{
				bool bRet = DataStream->FileHandle->Read(out_data, out_data_end - out_data);
				if (bRet)
				{
					RetValue = hpatch_TRUE;
				}
			}
			else
			{
					UE_DEBUG_BREAK();
			}
		}
		
		bool bContinue = true;
		if (DataStream->ProgressCallback != nullptr)
		{
			bContinue = DataStream->ProgressCallback(readFromPos);
		}
		if (!bContinue)
		{
			RetValue = hpatch_FALSE;
		}

		return RetValue;
	}

	//进度广播，若返回false则停止写入操作
	TFunction<bool(int64)> ProgressCallback = nullptr;

protected:
	IFileHandle* FileHandle = nullptr;
	FString FileName;
	int64 FileSize = 0;
};


TSyncClient_resultType FSyncPatchThread::AnalyzePatchInfo(FHiGameVersionInfo& InPatchInfo)
{
	TSyncClient_resultType RetValue = TSyncClient_resultType::kSyncClient_ok;

	FullyDownloadFileList.Reset();

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	for (int32 Idx = 0; Idx < InPatchInfo.FileList.Num(); ++Idx)
	{
		FString FileName = RootDir / InPatchInfo.FileList[Idx].Name;
		FString NewFileIndex = FileName + HSYNC_INDEX_SUFFIX;
		FString DiffFileName = FileName + HSYNC_DIFF_SUFFIX;
		FString PatchedFileName = FileName + HSYNC_PATCHED_SUFFIX;

		FString OldFile = FileName;
		if (!PlatformFile.FileExists(*OldFile))
		{
			OldFile.Reset();
			FullyDownloadFileList.Add(InPatchInfo.FileList[Idx].Name);
			
			int64 ExistsSize = ContinueDownloadAtSize(PatchedFileName, InPatchInfo.FileList[Idx].Hash);
			InPatchInfo.FileList[Idx].DownloadedSize = ExistsSize;
			InPatchInfo.FileList[Idx].PatchSize = InPatchInfo.FileList[Idx].Size;
		}

		int64 TempDiffSize = -1;

		FHiGameSyncInfoListener SyncInfoListener;
		FMemory::Memzero(&SyncInfoListener, sizeof(SyncInfoListener));
		{
			SyncInfoListener.infoImport = nullptr;
			SyncInfoListener.findChecksumPlugin = FindChecksumPlugin;
			SyncInfoListener.findDecompressPlugin = nullptr;
			SyncInfoListener.onLoadedNewSyncInfo = nullptr;
			SyncInfoListener.onNeedSyncInfo = FHiGameSyncInfoListener::OnNeedSyncInfo_V2;

			SyncInfoListener.CallbackFunc = [this, &TempDiffSize, PatchInfo = &InPatchInfo.FileList[Idx], Idx](int64 InNeedDownloadSize) {
				TempDiffSize = InNeedDownloadSize;
				PatchInfo->PatchSize = InNeedDownloadSize;
			};
		}

		IReadSyncDataListener ReadSyncDataListener;
		FMemory::Memzero(&ReadSyncDataListener, sizeof(ReadSyncDataListener));

		//差异下载情况才需要执行分析差异
		if( !OldFile.IsEmpty())
		{
			hpatch_TFileStreamOutput out_diffData;
			hpatch_TFileStreamOutput_init(&out_diffData);
			hpatch_TFileStreamOutput_open(&out_diffData, TCHAR_TO_UTF8(*DiffFileName), -1);
			
			hpatch_TFileStreamInput diffContinueData;
			hpatch_TFileStreamInput_init(&diffContinueData);
			hpatch_TFileStreamInput_open(&diffContinueData, TCHAR_TO_UTF8(*DiffFileName));

			FReadDataStream OldDataStream(OldFile);
			OldDataStream.read = FReadDataStream::OnRead_V2;
			OldDataStream.ProgressCallback = [this, PatchInfo = InPatchInfo.FileList[Idx]](int64 InReadPosition)
			{
				if (EventList.IsEmpty())
				{
					FUpdaterEventData NextEvent;
					NextEvent.State = WorkingState;
					NextEvent.CurrentSize = InReadPosition;
					NextEvent.TotalSize = PatchInfo.Size;
					NextEvent.SubEvent = FUpdaterEventData::SubEvent_Update;
					NextEvent.ProcessingFileName = PatchInfo.Name;

					EventList.Enqueue(NextEvent);
				}
				
				return !bRequestStop;
			};

			TNewDataSyncInfo newSyncInfo;
			sync_private::TNewDataSyncInfo_init(&newSyncInfo);
			TNewDataSyncInfo_open_by_file(&newSyncInfo, TCHAR_TO_UTF8(*NewFileIndex), &SyncInfoListener);

			UE_LOG(LogTemp, Display, TEXT("FSyncPatchThread::AnalyzePatchInfo, %s"), *FileName);

			RetValue = sync_local_diff(&SyncInfoListener, &ReadSyncDataListener, &OldDataStream, &newSyncInfo, &out_diffData.base, kSyncDiff_info, &diffContinueData.base, 4);

			hpatch_TFileStreamOutput_close(&out_diffData);
			TNewDataSyncInfo_close(&newSyncInfo);
			hpatch_TFileStreamInput_close(&diffContinueData);
		}
	
		if (RetValue == kSyncClient_ok && TempDiffSize == 0)
		{
			//此处代码不易维护，后续考虑反向循环
			//InPatchInfo.FileList.RemoveAt(Idx);
			//--Idx;
		}

		if (RetValue != kSyncClient_ok)
		{
			break;
		}
	}

	return RetValue;
}

TSyncClient_resultType FSyncPatchThread::DownloadPatch(FHiGameVersionInfo InPatchInfo)
{
	TSyncClient_resultType RetValue = TSyncClient_resultType::kSyncClient_ok;

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	for (int32 Idx = 0; Idx < InPatchInfo.FileList.Num(); ++Idx)
	{
		FString FileName = RootDir / InPatchInfo.FileList[Idx].Name;
		FString NewFileIndex = FileName + HSYNC_INDEX_SUFFIX;
		FString DiffFileName = FileName + HSYNC_DIFF_SUFFIX;
		FString PatchedFileName = FileName + HSYNC_PATCHED_SUFFIX;
		FString FileURL = VersionServerURL / InPatchInfo.VersionStr / InPatchInfo.FileList[Idx].Name;

		ISyncInfoListener SyncInfoListener;
		FMemory::Memzero(&SyncInfoListener, sizeof(SyncInfoListener));
		{
			SyncInfoListener.infoImport = this;
			SyncInfoListener.findChecksumPlugin = FindChecksumPlugin;
			SyncInfoListener.findDecompressPlugin = nullptr;
			SyncInfoListener.onLoadedNewSyncInfo = nullptr;
			SyncInfoListener.onNeedSyncInfo = nullptr;
		}

		IReadSyncDataListener ReadSyncDataListener;
		FMemory::Memzero(&ReadSyncDataListener, sizeof(ReadSyncDataListener));
		
		TSyncDownloadPlugin DownloadPlugin;
		GetSyncDataDownloadPlugin(&DownloadPlugin);

		FDownloadProgressCallback ProgressCallback = [this, PatchInfo = &InPatchInfo.FileList[Idx]](int64 InCurrentSize, int64 InTotalSize)
			{
				PatchInfo->DownloadedSize += InCurrentSize;
				if (EventList.IsEmpty())
				{
					FUpdaterEventData NextEvent;
					NextEvent.State = WorkingState;
					NextEvent.SubEvent = FUpdaterEventData::SubEvent_Update;
					NextEvent.ProcessingFileName = PatchInfo->Name;
					NextEvent.CurrentSize = PatchInfo->DownloadedSize;
					NextEvent.TotalSize = PatchInfo->PatchSize;
					EventList.Enqueue(NextEvent);
				}

				return !bRequestStop;
			};


		FString OldFile = FileName;

		//如果是全量下载模式，那么次文件在先前AnalyzePatchInfo步骤一定要加入到FullyDownloadFileList
		//否则就可能出现了流程异常！！！
		bool bCheckFullyDownload = PlatformFile.FileExists(*FileName) || FullyDownloadFileList.Contains(InPatchInfo.FileList[Idx].Name);
		check(bCheckFullyDownload);

		if (FullyDownloadFileList.Contains(InPatchInfo.FileList[Idx].Name))
		{
			OldFile = FString("");
		}

		if (PlatformFile.FileExists(*DiffFileName))
		{
			//本地反复调试，可跳过下载
			//continue;
		}

		//sync patch模式（差异更新）
		if (!OldFile.IsEmpty())
		{
			//TODO：关于Diff文件的断点续传，需要计算本次差异信息和之前的部分diff文件是不是对应
			//hsynz内部有校验hdiff和hsyni的一致性，无需业务层处理
			DownloadPlugin.download_range_open(&ReadSyncDataListener, TCHAR_TO_UTF8(*FileURL), 1, ProgressCallback);

			FReadDataStream OldDataStream(OldFile);
			OldDataStream.read = FReadDataStream::OnRead_V2;
			OldDataStream.ProgressCallback = [this, PatchInfo = InPatchInfo.FileList[Idx]](int64 InReadPosition)
				{
					if (EventList.IsEmpty())
					{
						FUpdaterEventData NextEvent;
						NextEvent.State = WorkingState;
						NextEvent.CurrentSize = InReadPosition;
						NextEvent.TotalSize = PatchInfo.Size;
						NextEvent.SubEvent = FUpdaterEventData::SubEvent_DownloadPrepare;
						NextEvent.ProcessingFileName = PatchInfo.Name;

						EventList.Enqueue(NextEvent);
					}

					return !bRequestStop;
				};

			TNewDataSyncInfo newSyncInfo;
			sync_private::TNewDataSyncInfo_init(&newSyncInfo);
			TNewDataSyncInfo_open_by_file(&newSyncInfo, TCHAR_TO_UTF8(*NewFileIndex), &SyncInfoListener);

			hpatch_TFileStreamOutput out_diffData;
			hpatch_TFileStreamOutput_init(&out_diffData);
			hpatch_TFileStreamOutput_open(&out_diffData, TCHAR_TO_UTF8(*DiffFileName), -1);

			hpatch_TFileStreamInput diffContinueData;
			hpatch_TFileStreamInput_init(&diffContinueData);
			hpatch_TFileStreamInput_open(&diffContinueData, TCHAR_TO_UTF8(*DiffFileName));

			RetValue = sync_local_diff(&SyncInfoListener, &ReadSyncDataListener, &OldDataStream, &newSyncInfo, &out_diffData.base, kSyncDiff_default, &diffContinueData.base, 4);
			DownloadPlugin.download_range_close(&ReadSyncDataListener);

			TNewDataSyncInfo_close(&newSyncInfo);
			hpatch_TFileStreamOutput_close(&out_diffData);
			hpatch_TFileStreamInput_close(&diffContinueData);
		}
		//全量下载
		else
		{
			bool bValidExistFile = false;
			int64 CanContinueDownload = 0;

			if (PlatformFile.FileExists(*PatchedFileName))
			{
				int64 FileSize = PlatformFile.FileSize(*PatchedFileName);
				if (FileSize == InPatchInfo.FileList[Idx].Size)
				{
					uint64 PatchedFileHash = XXHashFile(PatchedFileName);
					FString PatchedFileHashStr = FString::Printf(TEXT("%016llx"), PatchedFileHash);
					if (PatchedFileHashStr == InPatchInfo.FileList[Idx].Hash)
					{
						bValidExistFile = true;
					}
				}
				else
				{
					//断点续传需要比较下之前下载文件的目标hash和当前下载目标hash是否一样
					//此判断方法较为建议，能应对绝大部分情况了
					CanContinueDownload = ContinueDownloadAtSize(PatchedFileName, InPatchInfo.FileList[Idx].Hash);
				}
			}
			if (!bValidExistFile)
			{
				if (CanContinueDownload < 1)
				{
					SaveContinueDownloadFlag(PatchedFileName, *InPatchInfo.FileList[Idx].Hash);
					PlatformFile.DeleteFile(*PatchedFileName);
				}
				RetValue = DownloadFile(&DownloadPlugin, TCHAR_TO_UTF8(*FileURL), TCHAR_TO_UTF8(*PatchedFileName), CanContinueDownload > 0, ProgressCallback);
				if (RetValue == kSyncClient_ok)
				{
					DeleteContinueDownloadFlag(PatchedFileName);
				}
			}
		}

		if (RetValue != kSyncClient_ok)
		{
			break;
		}
	}

	return RetValue;
}


struct FWtireNewDataStream : public hpatch_TStreamOutput
{
public:

	FWtireNewDataStream(const FString& InFileName)
	{
		FileName = InFileName;
		FileHandle = FPlatformFileManager::Get().GetPlatformFile().OpenWrite(*FileName, true, true);
		CachedSize = FileHandle != nullptr ? FileHandle->Size() : 0;
	}

	~FWtireNewDataStream()
	{
		if (FileHandle)
		{
			delete FileHandle;
			FileHandle = nullptr;
		}
	}

	int64 GetFileSize() const
	{
		return CachedSize;
	}

	//write() must return (out_data_end-out_data), otherwise error
		//   first writeToPos==0; the next writeToPos+=(data_end-data)
	static hpatch_BOOL OnWrite_V2(const struct hpatch_TStreamOutput* stream, hpatch_StreamPos_t writeToPos,
		const unsigned char* data, const unsigned char* data_end)
	{
		int64 RetValue = hpatch_FALSE;
		const FWtireNewDataStream* DataStream = static_cast<const FWtireNewDataStream*>(stream);
		if (DataStream->FileHandle != nullptr)
		{
			DataStream->FileHandle->Seek(writeToPos);
			bool bRet = DataStream->FileHandle->Write(data, data_end - data);
			if (bRet)
			{
				RetValue = data_end - data;
			}
		}

		bool bContinue = true;
		if (DataStream->ProgressCallback != nullptr)
		{
			bContinue = DataStream->ProgressCallback(writeToPos);
		}
		if (!bContinue)
		{
			RetValue = hpatch_FALSE;
		}

		return RetValue;
	}

	//进度广播，若返回false则停止写入操作
	TFunction<bool(int64)> ProgressCallback = nullptr;

protected:
	IFileHandle* FileHandle = nullptr;
	FString FileName;
	int64 CachedSize = 0;
};

TSyncClient_resultType FSyncPatchThread::ApplyPatch(FHiGameVersionInfo InPatchInfo)
{
	TSyncClient_resultType RetValue = TSyncClient_resultType::kSyncClient_ok;

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	for (int32 Idx = 0; Idx < InPatchInfo.FileList.Num(); ++Idx)
	{
		FString FileName = RootDir / InPatchInfo.FileList[Idx].Name;
		FString DiffFileName = FileName + HSYNC_DIFF_SUFFIX;
		FString NewFileIndex = FileName + HSYNC_INDEX_SUFFIX;
		FString PatchedFileName = FileName + HSYNC_PATCHED_SUFFIX;

		ISyncInfoListener SyncInfoListener;
		FMemory::Memzero(&SyncInfoListener, sizeof(SyncInfoListener));
		{
			SyncInfoListener.infoImport = this;
			SyncInfoListener.findChecksumPlugin = FindChecksumPlugin;
			SyncInfoListener.findDecompressPlugin = nullptr;
			SyncInfoListener.onLoadedNewSyncInfo = nullptr;
			SyncInfoListener.onNeedSyncInfo = nullptr;
		}

		FString OldFile = FileName;
		if (FullyDownloadFileList.Contains(*InPatchInfo.FileList[Idx].Name))
		{
			OldFile = FString("");
		}

		//如果本地没有旧文件，并且不存在diff文件，可能是下载diff阶段按全量文件下载好了
		if (!OldFile.IsEmpty() && PlatformFile.FileExists(*DiffFileName))
		{
			//RetValue = sync_local_patch_file2file(&SyncInfoListener, TCHAR_TO_UTF8(*DiffFileName), TCHAR_TO_UTF8(*OldFile), TCHAR_TO_UTF8(*NewFileIndex), TCHAR_TO_UTF8(*PatchedFileName), hpatch_TRUE, 1);

			hpatch_TFileStreamInput in_diffData;
			hpatch_TFileStreamInput_init(&in_diffData);
			hpatch_TFileStreamInput_open(&in_diffData, TCHAR_TO_UTF8(*DiffFileName));

			hpatch_TFileStreamInput in_oldData;
			hpatch_TFileStreamInput_init(&in_oldData);
			hpatch_TFileStreamInput_open(&in_oldData, TCHAR_TO_UTF8(*OldFile));

			TNewDataSyncInfo newSyncInfo;
			sync_private::TNewDataSyncInfo_init(&newSyncInfo);
			TNewDataSyncInfo_open_by_file(&newSyncInfo, TCHAR_TO_UTF8(*NewFileIndex), &SyncInfoListener);

			FWtireNewDataStream NewFileStream(PatchedFileName);
			NewFileStream.streamImport = &NewFileStream;
			NewFileStream.streamSize = 0;
			NewFileStream.write = &FWtireNewDataStream::OnWrite_V2;
			NewFileStream.ProgressCallback = [this, PatchInfo = InPatchInfo.FileList[Idx]](int64 InWritePos)
				{

					if (EventList.IsEmpty())
					{
						FUpdaterEventData NextEvent;
						NextEvent.State = WorkingState;
						NextEvent.SubEvent = FUpdaterEventData::SubEvent_Update;
						NextEvent.ProcessingFileName = PatchInfo.Name;
						NextEvent.CurrentSize = InWritePos;
						NextEvent.TotalSize = PatchInfo.Size;
						EventList.Enqueue(NextEvent);
					}

					return !bRequestStop;
				};

			RetValue = sync_local_patch(&SyncInfoListener, &in_diffData.base, &in_oldData.base, &newSyncInfo, &NewFileStream, nullptr, 4);

			hpatch_TFileStreamInput_close(&in_diffData);
			hpatch_TFileStreamInput_close(&in_oldData);
			TNewDataSyncInfo_close(&newSyncInfo);
		}
		else if (!PlatformFile.FileExists(*PatchedFileName))
		{
			RetValue = kSyncClient_diffFileOpenError;
			//TODO: error
		}

		if (RetValue != kSyncClient_ok)
		{
			break;
		}
	}

	return RetValue;
}

TSyncClient_resultType FSyncPatchThread::VerifyAndMoveFile(FHiGameVersionInfo InPatchInfo)
{
	TSyncClient_resultType RetValue = kSyncClient_ok;

	IPlatformFile& PlatformFile = FPlatformFileManager::Get().GetPlatformFile();

	FString LocalVersionStr = GetVersionInfoStr(false);
	FHiGameVersionInfo LocalVersionInfo;

	FJsonObjectConverter::JsonObjectStringToUStruct<FHiGameVersionInfo>(LocalVersionStr, &LocalVersionInfo);
	LocalVersionInfo.GenerateFileNameToListIndex();

	for (int32 Idx = 0; Idx < InPatchInfo.FileList.Num(); ++Idx)
	{
		FString FileName = RootDir / InPatchInfo.FileList[Idx].Name;
		FString DiffFileName = FileName + HSYNC_DIFF_SUFFIX;
		FString NewFileIndex = FileName + HSYNC_INDEX_SUFFIX;
		FString PatchedFileName = FileName + HSYNC_PATCHED_SUFFIX;

		//TODO：计算hash

		//先备份旧文件
		FString BackupFileName = FileName + FString(".backup");
		PlatformFile.DeleteFile(*BackupFileName);
		bool bMoveOldFile = (!PlatformFile.FileExists(*FileName)) || PlatformFile.MoveFile(*BackupFileName, *FileName);
		
		if (!bMoveOldFile )
		{
			RetValue = kSyncClient_tempFileError;

			UE_LOG(LogTemp, Warning, TEXT("failed to backup old file: %s->%s"), *FileName, *BackupFileName);
			continue;
		}

		//使新版文件生效
		bool bMoveNewFile = PlatformFile.MoveFile(*FileName, *PatchedFileName);

		//删除旧版备份,或恢复旧版文件，很重要，更新失败要及时回退
		if (bMoveNewFile)
		{
			PlatformFile.DeleteFile(*BackupFileName);
			PlatformFile.DeleteFile(*NewFileIndex);
#if UE_BUILD_SHIPPING
			PlatformFile.DeleteFile(*DiffFileName);
#endif
			FString LocalFileTimeStampStr = FPlatformFileManager::Get().GetPlatformFile().GetTimeStamp(*FileName).ToString(TEXT("%Y%m%d%H%M%S"));
			int64 LocalFileTimeStamp = FCString::Atoi64(*LocalFileTimeStampStr);
			FHiGameFileInfo* FileInfo = const_cast<FHiGameFileInfo*>(LocalVersionInfo.GetFileItemInfoByName(InPatchInfo.FileList[Idx].Name));
			if (FileInfo == nullptr)
			{
				FileInfo = &LocalVersionInfo.FileList.AddZeroed_GetRef();
			}
			FileInfo->Name = InPatchInfo.FileList[Idx].Name;
			FileInfo->TimeStamp = LocalFileTimeStamp;
			FileInfo->Size = InPatchInfo.FileList[Idx].Size;
			FileInfo->Hash = InPatchInfo.FileList[Idx].Hash;
		}
		else
		{
			//启动器运行期间如何自更新，之后再处理
			bool bIsHiGameLauncher = FPaths::GetBaseFilename(FileName).Contains("HiGameLauncher.exe");

			if (!bIsHiGameLauncher)
			{
				RetValue = kSyncClient_writeNewDataError;
				bool bRecove = PlatformFile.MoveFile(*FileName, *BackupFileName);
			}
		}
	}

	if (RetValue == kSyncClient_ok)
	{
		LocalVersionInfo.VersionDesc = InPatchInfo.VersionDesc;
		LocalVersionInfo.VersionStr = InPatchInfo.VersionStr;

		FString RemoveVersionStr = GetVersionInfoStr(true);
		FHiGameVersionInfo RemoteVersionInfo;

		FJsonObjectConverter::JsonObjectStringToUStruct<FHiGameVersionInfo>(RemoveVersionStr, &RemoteVersionInfo);
		RemoteVersionInfo.GenerateFileNameToListIndex();

		for (int32 Idx = 0; Idx < RemoteVersionInfo.FileList.Num(); ++Idx)
		{
			FString FileName = RootDir / RemoteVersionInfo.FileList[Idx].Name;
			FHiGameFileInfo* FileInfo = const_cast<FHiGameFileInfo*>(LocalVersionInfo.GetFileItemInfoByName(RemoteVersionInfo.FileList[Idx].Name));
			if (FileInfo == nullptr)
			{
				FileInfo = &LocalVersionInfo.FileList.AddZeroed_GetRef();
			}
			
			FString LocalFileTimeStampStr = FPlatformFileManager::Get().GetPlatformFile().GetTimeStamp(*FileName).ToString(TEXT("%Y%m%d%H%M%S"));
			int64 LocalFileTimeStamp = FCString::Atoi64(*LocalFileTimeStampStr);

			FileInfo->Name = RemoteVersionInfo.FileList[Idx].Name;
			FileInfo->TimeStamp = LocalFileTimeStamp;
			FileInfo->Size = RemoteVersionInfo.FileList[Idx].Size;
			FileInfo->Hash = RemoteVersionInfo.FileList[Idx].Hash;
		}

		FString LocalVersionInfoStr;
		if (FJsonObjectConverter::UStructToJsonObjectString(FHiGameVersionInfo::StaticStruct(), &LocalVersionInfo, LocalVersionInfoStr))
		{
			RefreshLocalVersionInfoStr(LocalVersionInfoStr);
		}
		else
		{
			//TODO: error
		}
	}

	return RetValue;
}

FString FSyncPatchThread::GetVersionInfoStr(bool InOnlineVersion) const
{
	FString JsonPath = RootDir / FString("HiGameClient/OnlineVersion.json");
	if (!InOnlineVersion)
	{
		JsonPath = RootDir / FString("HiGameClient/LocalVersion.json");
	}
	FString JsonStr;
	FFileHelper::LoadFileToString(JsonStr, *JsonPath);
	return JsonStr;
}

bool FSyncPatchThread::RefreshLocalVersionInfoStr(const FString& InVersionStr) const
{
	FString JsonPath = RootDir / FString("HiGameClient/LocalVersion.json");

	FFileHelper::SaveStringToFile(InVersionStr, *JsonPath);

	return true;
}

int64 FSyncPatchThread::ContinueDownloadAtSize(const FString& InFileName, const FString& InExpectedHash)
{
	int64 RetValue = 0;

	FString DownloadInfoFile = InFileName + FString(".dlinfo");
	FString ContinueDownloadInfo;
	FFileHelper::LoadFileToString(ContinueDownloadInfo, *DownloadInfoFile);
	RetValue = (!ContinueDownloadInfo.IsEmpty()) && (ContinueDownloadInfo == InExpectedHash);
	if (RetValue != 0)
	{
		RetValue = FPlatformFileManager::Get().GetPlatformFile().FileSize(*InFileName);
	}
	return RetValue;
}

bool FSyncPatchThread::SaveContinueDownloadFlag(const FString& InFileName, const FString& InExpectedHash)
{
	bool RetValue = false;
	FString DownloadInfoFile = InFileName + FString(".dlinfo");
	RetValue = FFileHelper::SaveStringToFile(InExpectedHash, *DownloadInfoFile);

	return RetValue;
}

void FSyncPatchThread::DeleteContinueDownloadFlag(const FString& InFileName)
{
	FString DownloadInfoFile = InFileName + FString(".dlinfo");
	FPlatformFileManager::Get().GetPlatformFile().DeleteFile(*DownloadInfoFile);
}


hpatch_TChecksum* FSyncPatchThread::FindChecksumPlugin(ISyncInfoListener* listener, const char* strongChecksumType)
{
	assert((strongChecksumType != 0) && (strlen(strongChecksumType) > 0));
	hpatch_TChecksum* strongChecksumPlugin = 0;
#if true //_ChecksumPlugin_xxh128

	static hpatch_TChecksum xxh128ChecksumPlugin = { _xxh128_checksumType,_xxh128_checksumByteSize,_xxh128_open,
												   _xxh128_close,_xxh128_begin,_xxh128_append,_xxh128_end };

	if ((!strongChecksumPlugin) && (0 == strcmp(strongChecksumType, xxh128ChecksumPlugin.checksumType())))
		strongChecksumPlugin = &xxh128ChecksumPlugin;
#endif

	return strongChecksumPlugin; //ok
}


uint64 FSyncPatchThread::XXHashFile(const FString& InFileName)
{
	uint64 HashValue = 0;

	IFileHandle* file = FPlatformFileManager::Get().GetPlatformFile().OpenRead(*InFileName);
	if (file == nullptr)
	{
		return HashValue;
	}

	//256KB
	static const int64 BLOCK_SIZE = 256 * 1024;

	uint8 BlockData[BLOCK_SIZE] = { 0 };

	int64 TotalSize = file->Size();
	int64 Progress = 0;

	XXH64_state_s State;
	XXH64_reset(&State, 0);

	while (Progress < TotalSize)
	{
		int32 NextBlockSize = FMath::Min<int64>(BLOCK_SIZE, TotalSize - Progress);
		FMemory::Memzero(BlockData, NextBlockSize);
		file->Read(BlockData, NextBlockSize);

		XXH64_update(&State, BlockData, NextBlockSize);

		Progress += NextBlockSize;
	}

	HashValue = XXH64_digest(&State);

	delete file;
	file = nullptr;

	return HashValue;
}

hpatch_BOOL FSyncPatchThread::GetSyncDataDownloadPlugin(TSyncDownloadPlugin* OutDownloadPlugin)
{
	OutDownloadPlugin->download_range_open = download_range_by_http_open;
	OutDownloadPlugin->download_range_close = download_range_by_http_close;
	OutDownloadPlugin->download_file = download_file_by_http;

	return hpatch_TRUE;
}

bool FSyncPatchThread::PushCmd_DownloadVersionInfo()
{
	if(PenndingCommandList.IsEmpty())
	{
		PenndingCommandList.Enqueue(EUpdaterCommand::DownloadVersionInfo);
		return true;
	}
	else
	{
		return false;
	}
}

FUpdaterEventData FSyncPatchThread::FetchUpdaterEvent()
{
	FUpdaterEventData RetValue;

	EventList.Dequeue(RetValue);

	return RetValue;

}

FString FSyncPatchThread::HttpUrlEncode(const FStringView UnencodedString)
{
	FString EncodedString;
	EncodedString.Reserve(UnencodedString.Len()); // This is a minimum bound. Some characters might be outside the ascii set and require %hh encoding. Some characters might be multi-byte and require several %hh%hh%hh

	UTF8CHAR Utf8ConvertedChar[4] = {};
	TCHAR HexChars[3] = { TCHAR('%') };

	for (const TCHAR& InChar : UnencodedString)
	{
		verify(FPlatformString::Convert(Utf8ConvertedChar, sizeof(Utf8ConvertedChar), &InChar, 1));
		for (int32 ByteIdx = 0; ByteIdx < sizeof(Utf8ConvertedChar); ++ByteIdx)
		{
			UTF8CHAR ByteToEncode = Utf8ConvertedChar[ByteIdx];
			Utf8ConvertedChar[ByteIdx] = UTF8CHAR('\0');
			if (ByteToEncode == '\0')
			{
				break;
			}
			else if (IsAllowedChar(ByteToEncode))
			{
				// We use InChar here as it is the same value ByteToEncode would convert back to anyway
				// Note this relies on the fact that IsAllowedChar is only possible to be true for single-byte UTF8 characters.
				EncodedString.AppendChar(InChar);
			}
			else
			{
				UE::String::BytesToHex(MakeArrayView((uint8*)&ByteToEncode, 1), &HexChars[1]);
				EncodedString.AppendChars(HexChars, 3);
			}
		}
	}

	return EncodedString;
}
