require "UnLua"
local G = require("G")
local BPConst = require("common.const.blueprint_const")

SubsystemUtils = {}

function SubsystemUtils.GetMutableActorSubSystem(ContextObject)
    local SubSystemClass = BPConst.GetMutableActorSubsystemClass()
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, SubSystemClass)
    return Subsystem
end

function SubsystemUtils.GetDatabaseCacheSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, UE.UDatabaseCacheSubsystem)
    return Subsystem
end

function SubsystemUtils.GetGameplayEntitySubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, UE.UGameplayEntitySubsystem)
    return Subsystem
end

function SubsystemUtils.GetMissionFlowSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(ContextObject, UE.UHiMissionFlowSubsystem)
    return Subsystem
end

function SubsystemUtils.GetDialogueRuntimeSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(ContextObject, UE.USSDialogueRuntimeSubsystem)
    return Subsystem
end

function SubsystemUtils.GetTSF4GClientSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(ContextObject, UE.UTSF4GClientSubsystem)
    return Subsystem
end

function SubsystemUtils.GetUILogicSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, UE.UUILogicSubSystem)
    return Subsystem
end

function SubsystemUtils.GetDSRaptorEngineSubsystem()
    local Subsystem = UE.USubsystemBlueprintLibrary.GetEngineSubsystem(UE.UDSRaptorEngineSubsystem)
    return Subsystem
end

---@return OfficeSubsystem
function SubsystemUtils.GetOfficeSubsystem(ContextObject)
    local SubSystemClass = BPConst.GetOfficeSubsystemClass()
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, SubSystemClass)
    return Subsystem
end

---@return UGlobalActorsSubsystem
function SubsystemUtils.GetGlobalActorSubsystem(ContextObject)
    local Subsystem = UE.USubsystemBlueprintLibrary.GetWorldSubsystem(ContextObject, UE.UGlobalActorsSubsystem)
    return Subsystem
end

return SubsystemUtils
