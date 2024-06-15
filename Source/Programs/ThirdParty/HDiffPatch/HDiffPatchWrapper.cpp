// Copyright Epic Games, Inc. All Rights Reserved.

#include "HDiffPatchWrapper.h"
#include "libHDiffPatch/HPatch/patch.h"
#include "libhsync/sync_client/sync_client.h"


hpatch_BOOL FHDiffPatchWrapper::patch_stream_with_cache(const hpatch_TStreamOutput* out_newData, /*sequential write */ const hpatch_TStreamInput* oldData, /*random read */ const hpatch_TStreamInput* serializedDiff, /*random read */ unsigned char* temp_cache, unsigned char* temp_cache_end)
{
	return ::patch_stream_with_cache(out_newData, oldData, serializedDiff, temp_cache, temp_cache_end);
}

hpatch_BOOL FHDiffPatchWrapper::getCompressedDiffInfo(hpatch_compressedDiffInfo* out_diffInfo, const hpatch_TStreamInput* compressedDiff)
{
	return ::getCompressedDiffInfo(out_diffInfo, compressedDiff);
}

hpatch_BOOL FHDiffPatchWrapper::patch_decompress_with_cache(const hpatch_TStreamOutput* out_newData, /*sequential write */ const hpatch_TStreamInput* oldData, /*random read */ const hpatch_TStreamInput* compressedDiff, /*random read */ hpatch_TDecompress* decompressPlugin, unsigned char* temp_cache, unsigned char* temp_cache_end)
{
	return ::patch_decompress_with_cache(out_newData, oldData, compressedDiff, decompressPlugin, temp_cache, temp_cache_end);
}

TSyncClient_resultType FHDiffPatchWrapper::sync_patch(ISyncInfoListener* listener, IReadSyncDataListener* syncDataListener, const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo, const hpatch_TStreamOutput* out_newStream, const hpatch_TStreamInput* newDataContinue, const hpatch_TStreamOutput* out_diffInfoStream, const hpatch_TStreamInput* diffInfoContinue, int threadNum)
{
	return ::sync_patch(listener, syncDataListener, oldStream, newSyncInfo, out_newStream, newDataContinue, out_diffInfoStream, diffInfoContinue, threadNum);
}

TSyncClient_resultType FHDiffPatchWrapper::sync_local_diff(ISyncInfoListener* listener, IReadSyncDataListener* syncDataListener, const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo, const hpatch_TStreamOutput* out_diffStream, TSyncDiffType diffType, const hpatch_TStreamInput* diffContinue, int threadNum)
{
	return ::sync_local_diff(listener, syncDataListener, oldStream, newSyncInfo, out_diffStream, diffType, diffContinue, threadNum);
}

TSyncClient_resultType FHDiffPatchWrapper::sync_local_patch(ISyncInfoListener* listener, const hpatch_TStreamInput* in_diffStream, const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo, const hpatch_TStreamOutput* out_newStream, const hpatch_TStreamInput* newDataContinue, int threadNum)
{
	return ::sync_local_patch(listener, in_diffStream, oldStream, newSyncInfo, out_newStream, newDataContinue, threadNum);
}
