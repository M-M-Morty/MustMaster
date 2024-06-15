local _M = {}

_M.BPACharacterBase = "/Game/Blueprints/Character/BPA_CharacterBase.BPA_CharacterBase_C"

function _M.GetBPACharacterBaseClass()
    return UE.UClass.Load(_M.BPACharacterBase)
end

_M.BPAMonsterBase = "/Game/Blueprints/Character/BPA_MonsterBase.BPA_MonsterBase_C"
function _M.GetMonsterClass()
    return UE.UClass.Load(_M.BPAMonsterBase)
end

_M.BPPlayerController = "/Game/Blueprints/BP_PlayerController.BP_PlayerController_C"

function _M.GetBPPlayerControllerClass()
    return UE.UClass.Load(_M.BPPlayerController)
end

_M.HiEditorDataComp = "/Game/Blueprints/Actor/base/HiEditorDataComp.HiEditorDataComp_C"

function _M.GetHiEditorDataCompClass()
    return UE.UClass.Load(_M.BPPlayerController)
end

_M.MutableActorProxy = "/Game/Blueprints/ActorManagement/BP_MutableActorProxy.BP_MutableActorProxy_C"

function _M.GetMutableActorProxyClass()
    return UE.UClass.Load(_M.MutableActorProxy)
end

_M.MutableActorProxySaveData = "/Game/Blueprints/ActorManagement/MutableActorProxySaveData.MutableActorProxySaveData"

_M.MutableActorComponent = "/Game/Blueprints/ActorManagement/BP_MutableActorComponent.BP_MutableActorComponent_C"

function _M.GetMutableActorComponentClass()
    return UE.UClass.Load(_M.MutableActorComponent)
end

_M.MutableActorRegisterInfo = "/Game/Blueprints/ActorManagement/MutableActorRegisterInfo.MutableActorRegisterInfo"


_M.MutableActorSubsystem = "/Game/Blueprints/ActorManagement/BP_MutableActorSubsystem.BP_MutableActorSubsystem_C"

function _M.GetMutableActorSubsystemClass()
    if _M.MutableActorSubsystemClass == nil then
        _M.MutableActorSubsystemClass = UE.UObject.Load(_M.MutableActorSubsystem)
        UE.UHiUtilsFunctionLibrary.AddBlueprintTypeToCache(_M.MutableActorSubsystem, _M.MutableActorSubsystemClass)
    end
    return _M.MutableActorSubsystemClass
end

_M.OfficeDecorationDataProxyActorClass = '/Game/Blueprints/Office/BPA_OfficeDecorationDataProxy.BPA_OfficeDecorationDataProxy_C'
_M.OfficeSubsystem = '/Game/Blueprints/Office/BP_OfficeSubsystem.BP_OfficeSubsystem_C'
function _M.GetOfficeSubsystemClass()
    if _M.OfficeSubsystemClass == nil then
        _M.OfficeSubsystemClass = UE.UObject.Load(_M.OfficeSubsystem)
        UE.UHiUtilsFunctionLibrary.AddBlueprintTypeToCache(_M.OfficeSubsystem, _M.OfficeSubsystemClass)
    end
    return _M.OfficeSubsystemClass
end

_M.MutableActorOperation = "/Game/Blueprints/ActorManagement/MutableActorOperation.MutableActorOperation"

_M.GameplayEntitySubsystem = "/Game/Blueprints/ActorManagement/BP_GameplayEntitySubsystem.BP_GameplayEntitySubsystem_C"

function _M.GetGameplayEntitySubsystemClass()
    if _M.GameplayEntitySubsystemClass == nil then
        _M.GameplayEntitySubsystemClass = UE.UObject.Load(_M.GameplayEntitySubsystem)
        UE.UHiUtilsFunctionLibrary.AddBlueprintTypeToCache(_M.GameplayEntitySubsystem, _M.GameplayEntitySubsystemClass)
    end
    return _M.GameplayEntitySubsystemClass
end

_M.MissionComponent = "/Game/Blueprints/Components/BP_MissionComponent.BP_MissionComponent_C"

function _M.GetMissionComponentClass()
    return UE.UClass.Load(_M.MissionComponent)
end

_M.BaseNPCSaveData = "/Game/Blueprints/SaveGame/BP_BaseNPC_SaveData.BP_BaseNPC_SaveData_C"
function _M.GetBaseNPCSaveDataClass()
    return UE.UClass.Load(_M.BaseNPCSaveData)
end
_M.TestMissionNPCSaveData = "/Game/Blueprints/SaveGame/BP_TestMissionNPC_SaveData.BP_TestMissionNPC_SaveData_C"
function _M.GetTestMissionNPCSaveDataClass()
    return UE.UClass.Load(_M.TestMissionNPCSaveData)
end

_M.NPCBaseSaveData = "/Game/Blueprints/SaveGame/BP_NPCBase_SaveData.BP_NPCBase_SaveData_C"
function _M.GetNPCBaseSaveDataClass()
    return UE.UClass.Load(_M.NPCBaseSaveData)
end

_M.ConstPicDataTablePath = "/Game/Data/Datatable/DT_Resource_Pic.DT_Resource_Pic"
_M.Resource_Pic_Structure = "/Game/Data/Struct/BPS_Resource_Pic.BPS_Resource_Pic"

_M.MissionGroupRecord = "/Game/Blueprints/Mission/MissionRecordData/MissionGroupRecord.MissionGroupRecord"
function _M.GetMissionGroupRecordClass()
    return UE.UObject.Load(_M.MissionGroupRecord)
end
_M.MissionActRecord = "/Game/Blueprints/Mission/MissionRecordData/MissionActRecord.MissionActRecord"
function _M.GetMissionActRecordClass()
    return UE.UObject.Load(_M.MissionActRecord)
end
_M.MissionRecord = "/Game/Blueprints/Mission/MissionRecordData/MissionRecord.MissionRecord"
function _M.GetMissionRecordClass()
    return UE.UObject.Load(_M.MissionRecord)
end
_M.MissionEventRecord = "/Game/Blueprints/Mission/MissionRecordData/MissionEventRecord.MissionEventRecord"
function _M.GetMissionEventRecordClass()
    return UE.UObject.Load(_M.MissionEventRecord)
end


_M.MissionData = "/Game/Blueprints/Mission/MissionRecordData/MissionData.MissionData"
function _M.GetMissionDataClass()
    return UE.UObject.Load(_M.MissionData)
end
_M.MissionEventData = "/Game/Blueprints/Mission/MissionRecordData/MissionEventData.MissionEventData"
function _M.GetMissionEventDataClass()
    return UE.UObject.Load(_M.MissionEventData)
end

_M.MissionAvatarComponent = "/Game/Blueprints/Mission/BP_MissionAvatarComponent.BP_MissionAvatarComponent_C"
function _M.GetMissionAvatarComponentClass()
    return UE.UClass.Load(_M.MissionAvatarComponent)
end

_M.MissionDialogueItem = "/Game/Blueprints/Mission/MissionDialogueItem.MissionDialogueItem"
function _M.GetMissionDialogueItemClass()
    return UE.UObject.Load(_M.MissionDialogueItem)
end

_M.MissionInteractItem = "/Game/Blueprints/Mission/MissionInteractItem.MissionInteractItem"
function _M.GetMissionInteractItemClass()
    return UE.UObject.Load(_M.MissionInteractItem)
end


_M.MissionTargetParticle = "/Game/Blueprints/Mission/MissionTargetParticle.MissionTargetParticle_C"
function _M.GetMissionTargetParticleClass()
    return UE.UClass.Load(_M.MissionTargetParticle)
end

_M.TrackTarget = "/Game/Blueprints/Mission/TrackTarget.TrackTarget"
function _M.GetTrackTargetClass()
    return UE.UObject.Load(_M.TrackTarget)
end

function _M.GetMissionEventRegisterInfo()
    return UE.UObject.Load("/Game/Blueprints/Mission/MissionEvent/MissionEventRegisterInfo.MissionEventRegisterInfo")
end


_M.UILogicSubSystem = "/Game/Blueprints/UI/BP_UILogicSubsystem.BP_UILogicSubsystem_C"
function _M.GetUILogicSubsystemClass()
    if _M.UILogicSubsystemClass == nil then
        _M.UILogicSubsystemClass = UE.UObject.Load(_M.UILogicSubSystem)
        UE.UHiUtilsFunctionLibrary.AddBlueprintTypeToCache(_M.UILogicSubSystem, _M.UILogicSubsystemClass)
    end
    return _M.UILogicSubsystemClass
end

--- HiGameEdtior Begin ---
_M.EditorGroupActor = "700136"
--- HiGameEdtior End ---

_M.MissionActionInfo = "300001"
_M.MissionEventRegisterInfo = "300002"
_M.MissionTrackTarget = "300003"
_M.DialogueStepRecord = "300004"
_M.DialogueRecord = "300005"
_M.WaitDialogueData = "300006"
_M.NpcWaitEnterOfficeInfo = "300007"

_M.MissionActionSpawnMonster = "310000"
_M.MissionActionStopMontage = "310001"
_M.MissionActionDisplayNpcBubble = "310002"
_M.MissionActionPlayAnimSequence = "310003"
_M.MissionActionSetActorVisibility = "310004"
_M.MissionActionSetNpcToplogo = "310005"
_M.MissionActionCompleteTimeCapsule = "310006"
_M.MissionActionLog = "310007"
_M.MissionActionShowActStart = "310008"
_M.MissionActionChangeHour = "310009"
_M.MissionActionCallStatusFlow = "310016"

_M.MissionEventKillMonster = "311000"
_M.MissionEventKillMultiMonster = "311001"
_M.MissionEventPlayMontage = "311002"
_M.MissionEventTimeCapsule = "311003"
_M.MissionEventArriveCircleRegion = "311004"
_M.MissionEventDestroyActorByTags = "311005"
_M.MissionEventInteractedNPC = "311006"
_M.MissionEventAreaAbilityFlowLighting = "311007"
_M.MissionEventAreaAbilityDarkThronsLighting = "311008"
_M.MissionEventCompleteCp001 = "311019"
_M.MissionEventChestStatus = "311020"
_M.MissionEventArriveTrapBase = "311026"
_M.MissionEventMonsterHit = "311027"

---- Item Begin --
_M.MissionActionItemsAdd = "310011"
_M.MissionEventItemEnough = "311009"
_M.MissionEventItemOpenDetails = "311010"
---- Item End --
_M.MissionEventNpcEnterOffice = "311012"
_M.MissionEventPlayDialogueFlow = "311013"
_M.MissionEventCheckMissionStart = "311014"
_M.MissionEventDialogueSubmitItem = "311015"
_M.MissionEventPlayerBeginPlay = "311017"
_M.MissionEventPlayerEnterBattle = "311018"
_M.MissionEventLogicTrigger = "311024"

_M.MissionActorGlowSmall = "700092"

_M.AreaAbilityItemLightID = 190006

---- MG Begin ----
_M.MissionEventChaseChicken = "311021"
_M.MissionEventChaseLock = "311022"
_M.MissionEventPetStart = "311023"
---- MG End----
--
---- GH Begin ----
_M.MissionEventMusicGameComplete = "311025"
---- GH Begin ----

return _M
