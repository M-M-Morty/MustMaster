// Copyright Epic Games, Inc. All Rights Reserved.
using System;
using System.IO;
using UnrealBuildTool;

public class HiGameEditor : ModuleRules
{
    public HiGameEditor(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        OverridePackageType = PackageOverrideType.GameUncookedOnly;

        PublicDependencyModuleNames.AddRange(new string[] {
            "Core",
            "CoreUObject",
            "Engine",
            "BlueprintGraph",
            "Kismet",
            "VisionerEngine",
            "VisionerGraph",
            "AnimGraph",
            "HiGame",
            "UnrealEd",
            "ToolMenus",
            "SlateCore"
        });
    }
}
