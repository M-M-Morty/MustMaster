// Copyright Epic Games, Inc. All Rights Reserved.


using System.IO;
using UnrealBuildTool;

public class HiGameLauncher : ModuleRules
{
	public HiGameLauncher(ReadOnlyTargetRules Target) : base(Target)
	{
        bEnableUndefinedIdentifierWarnings = false;
        ShadowVariableWarningLevel = WarningLevel.Off;

        bEnableExceptions = true;

        PublicIncludePathModuleNames.Add("Launch");

        string ThirdPartyDir = Path.Combine(ModuleDirectory, "Private", "ThirdParty");

        PublicIncludePaths.Add(ThirdPartyDir);

        PrivateDependencyModuleNames.AddRange(new string[] {
            "Core",
            "Json",
            "Projects",
            "RSA",
            "PakFile",
            "ApplicationCore", 
            "StandaloneRenderer", "Slate",
            "JsonUtilities",
            "HDiffPatch",
            "PakPatchUtilities",
        });

        if (Target.IsInPlatformGroup(UnrealPlatformGroup.Linux))
        {
            PrivateDependencyModuleNames.AddRange(
                new string[] {
                    "UnixCommonStartup"
                }
            );
        }

        PrivateDefinitions.Add("_IS_NEED_MAIN=0");
    }

}
