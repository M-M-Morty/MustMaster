// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;
[SupportedPlatforms(UnrealPlatformClass.Server)]
public class HiGameServerTarget : TargetRules
{
	public HiGameServerTarget( TargetInfo Target) : base(Target)
	{
		Type = TargetType.Server;
		bWithLQTAetherPlugins=true;
		bForceEnableExceptions = true;
		ProjectDefinitions.Add("HAVE_IRPC_IMPL=1");
		ExtraModuleNames.Add("HiGame");

        // Logs are still useful to print the results
		bUseLoggingInShipping = true;
        bUseGameplayDebugger = Target.Configuration != UnrealTargetConfiguration.Shipping;

        bWarningsAsErrors = false;

		//DefaultWarningLevel = WarningLevel.Warning;

    }
}
