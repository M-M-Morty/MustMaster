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
	const int32* IdxPtr = FileNameToListIndex.Find(InFileName);
	if (IdxPtr != nullptr)
	{
		return &FileList[*IdxPtr];
	}
	else
	{
		return nullptr;
	}
}

void FHiGameVersionInfo::GenerateFileNameToListIndex()
{
	FileNameToListIndex.Empty();

	for (int32 Idx = 0; Idx < FileList.Num(); ++Idx)
	{
		FileNameToListIndex.Add(FileList[Idx].Name, Idx);
	}

}
