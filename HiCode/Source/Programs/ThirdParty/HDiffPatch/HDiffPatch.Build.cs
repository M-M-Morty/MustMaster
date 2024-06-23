
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
#if UE_5_0_OR_LATER
using EpicGames.Core;
using UnrealBuildBase;

#else
using Tools.DotNETCommon;
#endif
using UnrealBuildTool;

public class HDiffPatch : ModuleRules
{
    public HDiffPatch(ReadOnlyTargetRules Target) : base(Target)
    {

        bEnableUndefinedIdentifierWarnings = false;
        ShadowVariableWarningLevel = WarningLevel.Off;

        IWYUSupport = IWYUSupport.None;
        bEnableExceptions = true;

        bUseUnity = false;

        PublicIncludePaths = new List<string> { ModuleDirectory  };

        PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "Core",

                //"zstd",
            }
            );

        PrivateDefinitions.Add("_IS_NEED_DEFAULT_CompressPlugin=0");
        PrivateDefinitions.Add("_IS_NEED_DEFAULT_ChecksumPlugin=0");
        PrivateDefinitions.Add("_ChecksumPlugin_xxh128=1");
        PrivateDefinitions.Add("_IS_NEED_DIR_DIFF_PATCH=1");
        PrivateDefinitions.Add("_CompressPlugin_zstd=0");
        PrivateDefinitions.Add("_IS_USED_MULTITHREAD=1");

        //use std sort
        //PrivateDefinitions.Add("_SA_SORTBY=1");
        //PrivateDefinitions.Add("_SA_SORTBY_STD_SORT=1");

    }


}