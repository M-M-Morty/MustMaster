// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class HiGameEditorTarget : TargetRules
{
	public HiGameEditorTarget( TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		bWithLQTAetherPlugins=true;
		DefaultBuildSettings = BuildSettingsVersion.V2;
		ProjectDefinitions.Add("HAVE_IRPC_IMPL=1");
		ExtraModuleNames.AddRange( new string[] { "HiGame", "HiGameEditor" } );
		HiGameTarget.ApplySharedHiGameTargetSettings(this);
	}
}
