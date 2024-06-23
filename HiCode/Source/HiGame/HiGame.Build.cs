// Copyright Epic Games, Inc. All Rights Reserved.
using System;
using System.IO;
using UnrealBuildTool;

public class HiGame : ModuleRules
{
    public HiGame(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

        PublicDependencyModuleNames.AddRange(new string[] {
        "Core",
        "CoreUObject",
        "NetCore",
        "Engine",
        "Projects",
        "HeadMountedDisplay",
        "MotionWarping",
        "Niagara",
        "AIModule",
        "GameFeatures",
        "EnhancedInput",
        "ModularGameplay",
        "LevelSequence",
        "PoseSearch",
        "AnimGraphRuntime",
        "CustomizableSequencerTracks",
        "NavigationSystem",
        "Flow",
        "SimpleSaveGameExtension",
        "FieldSystemEngine",
        "GeometryCollectionEngine",
        "PhysicsCore",
        "HiGlobalActor",
        "AkAudio",
        "GameServerSettings",
        "AetherSystemsCommon",
        "AetherReplicationGraph",
        "AetherView",
        "AetherGameFramework",
        "AetherGamePlay", 
        "AetherSystemsEntityCommon", 
        "AetherGameInstance",
        "AetherNet", 
        "AetherGEO", 
        "AetherCluster", 
        "AetherInteractSubsystem", 
        "Protobuf",
        "IRPC",
        "LuaIRPC",
        "DistributedDSServiceAdapter",
        "TemplateSequence",
        "VisionerTop",
        "VisionerEngine",
        "VisionerGraphRuntime",
        "Landscape",
        "GameplayDebugger",
        "ShakespeareCommon",
        "CProtobuf",
        "GameplayEntitySystem",
        "HiMission",
        "HiSound",
        "GASAttachEditor",
        });

        // 剔除一些插件
        if (File.Exists(Path.Combine(ModuleDirectory, "../../Plugins/UnLua/UnLua.uplugin")))
        {
            PublicDefinitions.Add("WITH_PLUGINS_UNLUA=1");
            PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "UnLua",
                "Lua",
            });
        }
        else
        {
            PublicDefinitions.Add("WITH_PLUGINS_UNLUA=0");
        }
        if (File.Exists(Path.Combine(ModuleDirectory, "../../Plugins/ModularGameplayActors/ModularGameplayActors.uplugin")))
        {
            PublicDefinitions.Add("WITH_PLUGINS_MODULARGAMEPLAYACTORS=1");
            PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "ModularGameplayActors",
            });
        }
        else
        {
            PublicDefinitions.Add("WITH_PLUGINS_MODULARGAMEPLAYACTORS=0");
        }
        if (Directory.Exists(Path.Combine(ModuleDirectory, "../../Plugins/MovieScene")))
        {
            PublicDefinitions.Add("WITH_PLUGINS_MOVIESCENE=1");
            PublicDependencyModuleNames.AddRange(
            new string[]
            {
                "MovieScene",
            });
        }
        else
        {
            PublicDefinitions.Add("WITH_PLUGINS_MOVIESCENE=0");
        }
        if (Directory.Exists(Path.Combine(ModuleDirectory, "../../Plugins/Animation/PoseSearch")))
        {
            PublicDefinitions.Add("WITH_PLUGINS_POSESEARCH=1");
        }
        else
        {
            PublicDefinitions.Add("WITH_PLUGINS_POSESEARCH=0");
        }
        if (Directory.Exists(Path.Combine(ModuleDirectory, "../../Plugins/Cameras/VisionerManager")))
        {
            PublicDefinitions.Add("WITH_PLUGINS_VISIONER=1");
        }
        else
        {
            PublicDefinitions.Add("WITH_PLUGINS_VISIONER=0");
        }

        if (Target.Type == TargetRules.TargetType.Server)
        {
            if (Target.Platform == UnrealTargetPlatform.Linux)
            {
                PublicDependencyModuleNames.Add("CrashSight");
            }
        }

        PrivateDependencyModuleNames.AddRange(new string[] {
            "InputCore",
            "GameplayAbilities",
            "GameplayTags",
            "GameplayTasks",
            "EngineSettings",
            "Json",
            "JsonUtilities",
            "PerfCounters",
            "JsonBlueprintUtilities",
            "HiDatabaseCache",
            "SkeletalMerging",
            "GFur",
        });

        OptimizeCode = CodeOptimization.InShippingBuildsOnly;
        if (Target.Type == TargetType.Editor)
        {
            PrivateDependencyModuleNames.Add("UnrealEd");
            PrivateDependencyModuleNames.Add("BSPUtils");
            PrivateDependencyModuleNames.Add("Blutility");
            PrivateDependencyModuleNames.Add("DetailCustomizations");
            PrivateDependencyModuleNames.Add("ComponentVisualizers");
        }

        if (Target.Type != TargetType.Server)
        {
            PublicDependencyModuleNames.AddRange(new string[] {
                "GCloud",
                "TSF4GClientAdapter"
            });
        }
        if (Target.Type != TargetType.Client)
        {
            PublicDependencyModuleNames.AddRange(new string[] {
                "TSF4GDSServiceAdapter"
            });
        }

        PrivateIncludePaths.AddRange(new string[]
        {
            "HiGame",
        });
        RuntimeDependencies.Add(Path.Combine(ModuleDirectory, "../../Config", "tsf4g2_linux.yaml"));
        RuntimeDependencies.Add(Path.Combine(ModuleDirectory, "../../Config", "tsf4g2.yaml"));
        RuntimeDependencies.Add(Path.Combine(ModuleDirectory, "../../Config", "approuter_log.xml"));

        // RuntimeDependencies.Add(Path.Combine(ModuleDirectory, "../../Config", "DefaultUnLua.ini"));
        // RuntimeDependencies.Add(Path.Combine(ModuleDirectory, "../../Config", "SuperMeta.ini"));

        // Uncomment if you are using Slate UI
        // PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore" });

        // Uncomment if you are using online features
        // PrivateDependencyModuleNames.Add("OnlineSubsystem");

        // To include OnlineSubsystemSteam, add it to the plugins section in your uproject file with the Enabled attribute set to true
    }
}
