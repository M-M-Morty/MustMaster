// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;
[SupportedPlatforms(UnrealPlatformClass.Desktop)]
public class HiGameClientTarget : TargetRules
{
	public HiGameClientTarget( TargetInfo Target) : base(Target)
	{
		bForceEnableExceptions = true;
		Type = TargetType.Client;
        bWithLQTAetherPlugins = true;
        ProjectDefinitions.Add("HAVE_IRPC_IMPL=1");
		ExtraModuleNames.Add("HiGame");

        // Logs are still useful to print the results
		bUseLoggingInShipping = true;
        bUseGameplayDebugger = Target.Configuration != UnrealTargetConfiguration.Shipping;
	}
}
