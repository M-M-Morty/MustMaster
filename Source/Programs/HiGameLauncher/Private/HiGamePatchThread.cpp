

#include "HiGamePatchThread.h"

#include "JsonObjectConverter.h"
#include "Misc/FileHelper.h"
#include "Async.h"
#include "TaskGraphInterfaces.h"
#include "PlatformFileManager.h"
#include "Paths.h"
#include "GenericPlatform/GenericPlatformAtomics.h"
#include "PakPatchUtilities.h"

#if PLATFORM_WINDOWS
#include "Windows/AllowWindowsPlatformTypes.h"
#endif

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


FHiGamePatchThread::FHiGamePatchThread(const FString& InVersionServerURL, const FString& InRootDir)
{
	VersionServerURL = InVersionServerURL;
	RootDir = InRootDir;
	WorkingState = EUpdaterState::None;

	Thread = FRunnableThread::Create(this, TEXT("HiGamePatchThread"));
}

FHiGamePatchThread::~FHiGamePatchThread()
{
	StopThread();
}

bool FHiGamePatchThread::TransitionWorkingState(EUpdaterState InNewState)
{
	bool bValidState = (((int32)WorkingState + 1 == (int32)InNewState) || (WorkingState == EUpdaterState::None) || (InNewState == EUpdaterState::None));
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

uint32 FHiGamePatchThread::Run()
{
	int64 NeedDownloadSize = -1;
	int32 retType = 0;
	FHiGameVersionInfo PatchInfo;

	EUpdaterCommand NextCmd;

	FUpdaterEventData NextEvent;

	FString OldPak = "D:/Download/HiGameClient_06-03_0955/HiGameClient/HiGame/Content/Paks/HiGame-WindowsClient.pak";
	FString NewPakCsv = "D:/TestPatch/MyData.pak.csv";

	FString AES = "-AES=D6irbbgi+7mmnAFg3Sjkrl9YwDH518x6ffuwKWJwkNQ=";

	FString TestCmd = OldPak + FString(" -List -ExtractToMountPoint -CSV=") + NewPakCsv + FString(" ") + AES;

	ExecutePakPatch(*TestCmd);

	//FPakPatchUtilities::DiffPakByCSV(OldPak, NewPakCsv);

	while (!bRequestStop)
	{
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
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);


			//执行成功才能转换到下一个状态
			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::AnalyzeChangedFiles);
			}
			break;
		case EUpdaterState::AnalyzeChangedFiles:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			//执行成功才能转换到下一个状态,不过一般应该不会失败？
			TransitionWorkingState(EUpdaterState::DownloadIndexFiles);
			break;

		case EUpdaterState::DownloadIndexFiles:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			NextEvent.LocalVersion = CachedLocalVersion;
			NextEvent.ServerVersion = CachedServerVersion;
			EventList.Enqueue(NextEvent);

			//执行成功才能转换到下一个状态
			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::AnalyzePatchInfo);
			}
			break;

		case EUpdaterState::AnalyzePatchInfo:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			//执行成功才能转换到下一个状态
			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::DownloadPatch);
			}
			break;

		case EUpdaterState::DownloadPatch:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::ApplyPatch);
			}
			break;

		case EUpdaterState::ApplyPatch:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::VerifyAndMoveFile);
			}
			break;

		case EUpdaterState::VerifyAndMoveFile:
			NextEvent.SubEvent = FUpdaterEventData::SubEvent_Begin;
			EventList.Enqueue(NextEvent);

			NextEvent.SubEvent = FUpdaterEventData::SubEvent_End;
			NextEvent.ServerVersion = PatchInfo.VersionStr;
			EventList.Enqueue(NextEvent);

			if (retType == 0)
			{
				TransitionWorkingState(EUpdaterState::None);
			}
			break;

		default:
			break;

		}
		FPlatformProcess::Sleep(0.1f);
	}

	return 0;
}

void FHiGamePatchThread::StopThread()
{
	bRequestStop = true;

	if (Thread != nullptr)
	{
		Thread->Kill(true);
		Thread = nullptr;
	}
}

int32 FHiGamePatchThread::DownloadVersionInfo()
{

	return 0;
}

int32 FHiGamePatchThread::DownloadIndexFiles(FHiGameVersionInfo InPatchInfo)
{
		return 0;
}

FHiGameVersionInfo FHiGamePatchThread::AnalyzeChangedFiles()
{
	FHiGameVersionInfo RetValue;

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
		RetValue.FileList.Add(*FileItem);
	}

	RetValue.VersionDesc = OnlineVersionInfo.VersionDesc;
	RetValue.VersionStr = OnlineVersionInfo.VersionStr;

	return RetValue;
}


int32 FHiGamePatchThread::AnalyzePatchInfo(FHiGameVersionInfo& InPatchInfo)
{
	

	return 0;
}

FString FHiGamePatchThread::GetVersionInfoStr(bool InOnlineVersion) const
{
	FString JsonPath = RootDir / FString("OnlineVersion.json");
	if (!InOnlineVersion)
	{
		JsonPath = RootDir / FString("LocalVersion.json");
	}
	FString JsonStr;
	FFileHelper::LoadFileToString(JsonStr, *JsonPath);
	return JsonStr;
}

bool FHiGamePatchThread::RefreshLocalVersionInfoStr(const FString& InVersionStr) const
{
	FString JsonPath = RootDir / FString("LocalVersion.json");

	FFileHelper::SaveStringToFile(InVersionStr, *JsonPath);

	return true;
}

int64 FHiGamePatchThread::ContinueDownloadAtSize(const FString& InFileName, const FString& InExpectedHash)
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

bool FHiGamePatchThread::SaveContinueDownloadFlag(const FString& InFileName, const FString& InExpectedHash)
{
	bool RetValue = false;
	FString DownloadInfoFile = InFileName + FString(".dlinfo");
	RetValue = FFileHelper::SaveStringToFile(InExpectedHash, *DownloadInfoFile);

	return RetValue;
}

void FHiGamePatchThread::DeleteContinueDownloadFlag(const FString& InFileName)
{
	FString DownloadInfoFile = InFileName + FString(".dlinfo");
	FPlatformFileManager::Get().GetPlatformFile().DeleteFile(*DownloadInfoFile);
}



uint64 FHiGamePatchThread::XXHashFile(const FString& InFileName)
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

bool FHiGamePatchThread::PushCmd_DownloadVersionInfo()
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

FUpdaterEventData FHiGamePatchThread::FetchUpdaterEvent()
{
	FUpdaterEventData RetValue;

	EventList.Dequeue(RetValue);

	return RetValue;

}

FString FHiGamePatchThread::HttpUrlEncode(const FStringView UnencodedString)
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
