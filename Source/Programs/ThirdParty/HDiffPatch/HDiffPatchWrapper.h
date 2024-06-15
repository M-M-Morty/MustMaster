// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "libHDiffPatch/HPatch/patch_types.h"
#include "libhsync/sync_client/sync_client_type.h"
#include "libhsync/sync_client/sync_info_client.h"


class HDIFFPATCH_API FHDiffPatchWrapper
{
public:

    //HDiff Begin

    //see patch_stream()
    //  can passing more memory for I/O cache to optimize speed
    //  note: (temp_cache_end-temp_cache)>=2048
    static hpatch_BOOL patch_stream_with_cache(const hpatch_TStreamOutput* out_newData,    //sequential write
        const hpatch_TStreamInput* oldData,        //random read
        const hpatch_TStreamInput* serializedDiff, //random read
        unsigned char* temp_cache, unsigned char* temp_cache_end);

    //get compressedDiff info
    //  compressedDiff created by create_compressed_diff() or create_compressed_diff_stream()
    hpatch_BOOL getCompressedDiffInfo(hpatch_compressedDiffInfo* out_diffInfo,
        const hpatch_TStreamInput* compressedDiff);

    //see patch_decompress()
    //  can passing larger memory cache to optimize speed
    //  note: (temp_cache_end-temp_cache)>=2048
    hpatch_BOOL patch_decompress_with_cache(const hpatch_TStreamOutput* out_newData,    //sequential write
        const hpatch_TStreamInput* oldData,        //random read
        const hpatch_TStreamInput* compressedDiff, //random read
        hpatch_TDecompress* decompressPlugin,
        unsigned char* temp_cache, unsigned char* temp_cache_end);

    //HDiff End



    //libsync Begin

    //sync_patch(oldStream+syncDataListener) to out_newStream
    TSyncClient_resultType sync_patch(ISyncInfoListener* listener, IReadSyncDataListener* syncDataListener,
        const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo,
        const hpatch_TStreamOutput* out_newStream, const hpatch_TStreamInput* newDataContinue,
        const hpatch_TStreamOutput* out_diffInfoStream, const hpatch_TStreamInput* diffInfoContinue, int threadNum);

    //sync_patch can split to two steps: sync_local_diff + sync_local_patch


    //download diff data from syncDataListener to out_diffStream
    //  if (diffContinue) then continue download
    TSyncClient_resultType sync_local_diff(ISyncInfoListener* listener, IReadSyncDataListener* syncDataListener,
        const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo,
        const hpatch_TStreamOutput* out_diffStream, TSyncDiffType diffType,
        const hpatch_TStreamInput* diffContinue, int threadNum);

    //patch(oldStream+in_diffStream) to out_newStream
    TSyncClient_resultType sync_local_patch(ISyncInfoListener* listener, const hpatch_TStreamInput* in_diffStream,
        const hpatch_TStreamInput* oldStream, const TNewDataSyncInfo* newSyncInfo,
        const hpatch_TStreamOutput* out_newStream, const hpatch_TStreamInput* newDataContinue, int threadNum);


    //libsync End
};
