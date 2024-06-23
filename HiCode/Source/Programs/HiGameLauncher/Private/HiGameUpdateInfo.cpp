//HiGame

#include "HiGameUpdateInfo.h"
#include "Ticker.h"
#include "SyncPatchThread.h"
#include "Paths.h"


TArray<FString> FHiGameVersionInfo::GetAllFileNames() const
{
	TArray<FString> FileNames;

	for (const FHiGameFileInfo& It: FileList)
	{
		FileNames.Add(It.Name);
	}

	return FileNames;
}

const FHiGameFileInfo* FHiGameVersionInfo::GetFileItemInfoByName(const FString& InFileName) const
{
	const FHiGameFileInfo* RetValue = nullptr;

	for (int32 idx = FileList.Num() - 1; idx >= 0; --idx)
	{
		if (FileList[idx].Name == InFileName)
		{
			RetValue = &FileList[idx];
			break;
		}
	}

	return RetValue;
}