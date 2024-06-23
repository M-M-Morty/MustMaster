--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local MissionObjectClass = require("mission.mission_object")
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local HudTrackVMModule = require('CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm')
local MissionEventTable = require("common.data.event_description_data")
local MissionEventDataTable = require("common.data.event_description_data").data
local MissionParamTable = require("common.data.event_param_data").data
local GuideTextTable = require("common.data.guide_text_data").data
local MissionTable = require("common.data.mission_data").data
local DialogueObjectModule = require("mission.dialogue_object")
local MissionUtils = require("mission.mission_utils")
local MonoLogueUtils = require("common.utils.monologue_utils")
local EdUtils = require("common.utils.ed_utils")
local GlobalActorConst = require("common.const.global_actor_const")
local MissionActTable = require ("common.data.mission_act_data").data
local UIConstData = require("common.data.ui_const_data").data
local ItemBaseTable = require("common.data.item_base_data").data

---@type BP_MissionAvatarComponent_C
local MissionAvatarComponent = Component(ComponentBase)

local decorator = MissionAvatarComponent.decorator

function MissionAvatarComponent:Initialize(Initializer)
    Super(MissionAvatarComponent).Initialize(self, Initializer)
    self.MissionObjectDict = {} -- client
    self.MissionDataLookupTable = {} -- client & server
    self.MissionRecordLookupTable = {} -- client & server
    self.ActorPositionRequesting = {} -- client
    self.MissionQueryingActors = {} -- client
    self.LocalTrackingMissionID = 0 -- client, 客户端缓存的任务追踪ID
    self.AutoTrackTimer = nil  -- client
    self.TrackingMissionWrapperList = {} -- client
    self.TrackingActorIDs = UE.TSet(UE.FString) -- client
    self.TrackingTargetParticle = nil -- client
    self.TrackingTargetParticleSmall = nil -- client
    self.TrackingTargetParticlePosition = nil -- client
    self.TrackingTargetParticleEventID = 0 -- client
    self.DisplayControlTipsTimer = nil -- client
    self.ScreenTrackIconTimer = nil -- client
    self.CurrentMonologueID = 0 -- client
    self.SmsDialogues = {} -- server & client, 正在进行的短信对话
    self.HistorySmsDialogues = {} -- blueprint, server & client
end

function MissionAvatarComponent:GetActorID()
    local MutableActorComponentClass = UE.UClass.Load(BPConst.MutableActorComponent)
    local MutableActorComponent = self:GetOwner():GetComponentByClass(MutableActorComponentClass)
    return MutableActorComponent:GetActorID()
end

-- client
function MissionAvatarComponent:InitializeMissionObjectDict()
    self.MissionObjectDict = {}
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        local MissionID = MissionData.Identifier.MissionID
        local MissionObject = MissionObjectClass.new(self, MissionID, false)
        self.MissionObjectDict[MissionObject:GetMissionID()] = MissionObject
    end
end

-- server & client
function MissionAvatarComponent:BuildMissionDataLookupTable()
    self.MissionDataLookupTable = {}
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        local MissionID = MissionData.Identifier.MissionID
        self.MissionDataLookupTable[MissionID] = i
    end
end

-- server & client
function MissionAvatarComponent:BuildMissionRecordLookupTable()
    self.MissionRecordLookupTable = {}
    for i = 1, self.MissionRecordList:Length() do
        local MissionRecord = self.MissionRecordList:GetRef(i)
        local MissionID = MissionRecord.MissionID
        self.MissionRecordLookupTable[MissionID] = i
    end
end

-- client
function MissionAvatarComponent:GetMissionList()
    local MissionList = {}
    for _, MissionObject in pairs(self.MissionObjectDict) do
        table.insert(MissionList, MissionObject)
    end
    return MissionList
end

-- client & server
function MissionAvatarComponent:GetMissionRecord(MissionID)
    local Index = self.MissionRecordLookupTable[MissionID]
    if Index == nil then
        return nil
    end
    if Index > self.MissionRecordList:Length() then
        return nil
    end
    return self.MissionRecordList:GetRef(Index)
end

function MissionAvatarComponent:GetMissionActList()
    return self.MissionActDataList
end

function MissionAvatarComponent:GetMissionActData(MissionActID)
    for i = 1, self.MissionActDataList:Num() do
        local MissionActData = self.MissionActDataList:GetRef(i)
        if MissionActData.MissionActID == MissionActID then
            return MissionActData
        end
    end
    return nil
end

-- client
function MissionAvatarComponent:GetTrackMissionObject()
  return self.MissionObjectDict[self.LocalTrackingMissionID]
end

-- server & client
function MissionAvatarComponent:FindMissionData(MissionID)
    local Index = self.MissionDataLookupTable[MissionID]
    if Index == nil then
        return nil
    end
    if Index > self.MissionDataList:Length() then
        return nil
    end
    return self.MissionDataList:GetRef(Index)
end

function MissionAvatarComponent:ReceiveBeginPlay()
    Super(MissionAvatarComponent).ReceiveBeginPlay(self)
    if not self:GetOwner():IsClient() then
        SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):RegisterMissionSubscriber(self:GetActorID(), self:GetOwner())
    end
    self:BuildMissionDataLookupTable()
    self:BuildMissionRecordLookupTable()
end

decorator.message_receiver()
function MissionAvatarComponent:PostBeginPlay()
    if self:GetOwner():IsClient() then
        G.log:debug("xaelpeng", "MissionAvatarComponent:ReceiveBeginPlay Actor:%s", self:GetActorID())
        self:InitializeMissionObjectDict()

        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
        TaskMainVM:InitMissionSystem(self)
        ---@type TaskActVM
        local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
        TaskActVM:InitMissionSystem(self)
        
        self:StartListenActorCreateOrDestroy()
        self:ApplyTrackingMissionID()
        self:UpdateClientTrackStates()

        if self.SelfDialogueID ~= 0 then
            self:StartSelfDialogue(self.SelfDialogueID)
        end
    end
end

function MissionAvatarComponent:ReceiveEndPlay()
    if not self:GetOwner():IsClient() then
        SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):UnregisterMissionSubscriber(self:GetActorID(), self:GetOwner())
    end
    if self:GetOwner():IsClient() then
        self:StopListenActorCreateOrDestroy()
        for _, TrackingWrapper in pairs(self.TrackingMissionWrapperList) do
            TrackingWrapper:Destroy()
        end
        self.TrackingMissionWrapperList = {}
    end
    Super(MissionAvatarComponent).ReceiveEndPlay(self)
end

-- server
function MissionAvatarComponent:SyncMissionRecords(MissionRecordList)
    G.log:debug("MissionAvatarComponent", "SyncMissionRecords Actor:%s MissionRecordNum:%d", self:GetActorID(), MissionRecordList:Length())
    self:InnerSyncMissionRecords(MissionRecordList)
    self:Client_SyncMissionRecords(MissionRecordList)
end

-- server
function MissionAvatarComponent:SyncActiveMissions(MissionDataList)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncActiveMissions Actor:%s MissionNum:%d", self:GetActorID(), MissionDataList:Length())
    self:InnerSyncActiveMissions(MissionDataList)
    self:ValidateTrackingMissionID()
    self:Client_SyncActiveMissions(MissionDataList)
end

-- server
function MissionAvatarComponent:SyncMissionActs(MissionActDataList)
    G.log:debug("MissionAvatarComponent", "SyncMissionActs Actor:%s MissionActNum:%d", self:GetActorID(), MissionActDataList:Length())
    self:InnerSyncMissionActs(MissionActDataList)
    self:Client_SyncMissionActs(MissionActDataList)
end

-- server
function MissionAvatarComponent:SyncSmsDialogues(SmsDialogueRecordList)
    self:InnerSyncSmsDialogues(SmsDialogueRecordList)
    self:Client_SyncSmsDialogues(SmsDialogueRecordList)
end

-- server
function MissionAvatarComponent:ValidateTrackingMissionID()
    if self.TrackingMissionID == 0 then
        return
    end
    if self:FindMissionData(self.TrackingMissionID) == nil then
        self.TrackingMissionID = 0
    end
end

-- client
function MissionAvatarComponent:Client_SyncMissionRecords_RPC(MissionRecordList)
    -- client RPC will be called on server before Pawn ProcessBy Controller
    if self:GetOwner():IsClient() then
        self:InnerSyncMissionRecords(MissionRecordList)
    end
end

function MissionAvatarComponent:InnerSyncMissionRecords(MissionRecordList)
    self.MissionRecordList = MissionRecordList
    self:BuildMissionRecordLookupTable()
end

-- client
function MissionAvatarComponent:Client_SyncActiveMissions_RPC(MissionDataList)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncActiveMissions Actor:%s MissionNum:%d IsClient:%s", self:GetActorID(), MissionDataList:Length(), self:GetOwner():IsClient()
)
    -- client RPC will be called on server before Pawn ProcessBy Controller
    if self:GetOwner():IsClient() then
        self:InnerSyncActiveMissions(MissionDataList)
        self:InitializeMissionObjectDict()
        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
        TaskMainVM:InitMissionTree(self:GetMissionList())
        self:ApplyTrackingMissionID()
    end
end

function MissionAvatarComponent:InnerSyncActiveMissions(MissionDataList)
    self.MissionDataList:Clear()
    for i = 1, MissionDataList:Length() do
        local MissionData = MissionDataList:GetRef(i)
        self.MissionDataList:Add(MissionData)
        G.log:debug("xaelpeng", "MissionAvatarComponent:InnerSyncActiveMissions Actor:%s AddMission:%d", self:GetActorID(), MissionData.Identifier.MissionID)
    end
    self:BuildMissionDataLookupTable()
end

function MissionAvatarComponent:Client_SyncMissionActs_RPC(MissionActDataList)
    -- client RPC will be called on server before Pawn ProcessBy Controller
    if self:GetOwner():IsClient() then
        self:InnerSyncMissionActs(MissionActDataList)
    end
end

function MissionAvatarComponent:InnerSyncMissionActs(MissionActDataList)
    self.MissionActDataList = MissionActDataList
end

function MissionAvatarComponent:Client_SyncSmsDialogues_RPC(SmsDialogueRecordList)
    -- client RPC will be called on server before Pawn ProcessBy Controller
    if self:GetOwner():IsClient() then
        self:InnerSyncSmsDialogues(SmsDialogueRecordList)
    end
end

function MissionAvatarComponent:InnerSyncSmsDialogues(SmsDialogueRecordList)
    for i = 1, SmsDialogueRecordList:Length() do
        local DialogueRecord = SmsDialogueRecordList:GetRef(i)
        local NpcID = DialogueRecord.NpcID
        if DialogueRecord.StepRecords.Length() ~= 0 then
            local StartDialogueID = DialogueRecord.StepRecords:GetRef(1).DialogueID
            local DialogueObject = MissionUtils.ResumeDialogue(StartDialogueID, DialogueRecord)
            self.SmsDialogues[NpcID] = DialogueObject
        end
    end
end


-- server
function MissionAvatarComponent:SyncAddMissionAct(MissionActID, MissionActData)
    self:InnerSyncAddMissionAct(MissionActID, MissionActData)
    self:Client_SyncAddMissionAct(MissionActID, MissionActData)
end

-- client
function MissionAvatarComponent:Client_SyncAddMissionAct_RPC(MissionActID, MissionActData)
    self:InnerSyncAddMissionAct(MissionActID, MissionActData)
end

function MissionAvatarComponent:InnerSyncAddMissionAct(MissionActID, MissionActData)
    self.MissionActDataList:Add(MissionActData)
end


-- server
function MissionAvatarComponent:SyncAddActiveMission(MissionID, MissionData)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncAddActiveMission Actor:%s AddMission:%d", self:GetActorID(), MissionID)
    self:InnerSyncAddActiveMission(MissionID, MissionData)
    self:Client_SyncAddActiveMission(MissionID, MissionData)
end

-- client
function MissionAvatarComponent:Client_SyncAddActiveMission_RPC(MissionID, MissionData)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncAddActiveMission Actor:%s AddMission:%d", self:GetActorID(), MissionID)
    self:InnerSyncAddActiveMission(MissionID, MissionData)
    local MissionObject = MissionObjectClass.new(self, MissionID, true)
    self.MissionObjectDict[MissionObject:GetMissionID()] = MissionObject

    -- show in mission main ui
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:AddMission(MissionObject)
end

function MissionAvatarComponent:InnerSyncAddActiveMission(MissionID, MissionData)
    self.MissionDataList:Add(MissionData)
    self:BuildMissionDataLookupTable()
    MissionData.Record.MissionID = MissionID
    self.MissionRecordList:Add(MissionData.Record)
    self.MissionRecordLookupTable[MissionID] = self.MissionRecordList:Length()
end

-- server
function MissionAvatarComponent:SyncRemoveActiveMission(MissionID, bFinish)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncRemoveActiveMission Actor:%s RemoveMission:%d", self:GetActorID(), MissionID)
    self:InnerSyncRemoveActiveMission(MissionID)
    self:Client_SyncRemoveActiveMission(MissionID, bFinish)
end

-- client
function MissionAvatarComponent:Client_SyncRemoveActiveMission_RPC(MissionID, bFinish)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncRemoveActiveMission Actor:%s RemoveMission:%d %s", self:GetActorID(), MissionID, bFinish)
    local MissionObject = self.MissionObjectDict[MissionID]
    if MissionObject ~= nil then
        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
        TaskMainVM:RemoveMission(MissionObject)
        self.MissionObjectDict[MissionID] = nil
    else
        G.log:error("xaelpeng", "MissionAvatarComponent:Client_SyncRemoveActiveMission RemoveMission:%d MissionObject not exist", MissionID)
    end
    self:InnerSyncRemoveActiveMission(MissionID)
end

function MissionAvatarComponent:InnerSyncRemoveActiveMission(MissionID)
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        if MissionData.Identifier.MissionID == MissionID then
            self.MissionDataList:Remove(i)
            break
        end
    end
    self:BuildMissionDataLookupTable()
end

-- server
function MissionAvatarComponent:SyncAddActiveMissionEvent(MissionID, MissionEventData)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncAddActiveMissionEvent Actor:%s MissionID:%d MissionEventID:%d",
        self:GetActorID(), MissionID, MissionEventData.MissionEventID)
    self:InnerSyncAddActiveMissionEvent(MissionID, MissionEventData)
    self:Client_SyncAddActiveMissionEvent(MissionID, MissionEventData)
end

-- client
function MissionAvatarComponent:Client_SyncAddActiveMissionEvent_RPC(MissionID, MissionEventData)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncAddActiveMissionEvent Actor:%s MissionID:%d MissionEventID:%d", self:GetActorID(), MissionID,
        MissionEventData.MissionEventID)
    self:InnerSyncAddActiveMissionEvent(MissionID, MissionEventData)
    -- update ui
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local MissionObject = self.MissionObjectDict[MissionID]

    if MissionObject ~= nil then
        TaskMainVM:UpdateMissionProgress(MissionObject)
        if MissionID == self.TrackingMissionID then
            self:UpdateClientTrackStates()
        end
    end
    self:NotifyMissionObjectEventUpdated(MissionID)
end

function MissionAvatarComponent:InnerSyncAddActiveMissionEvent(MissionID, MissionEventData)
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        if MissionData.Identifier.MissionID == MissionID then
            MissionData.ActiveEvents:Add(MissionEventData)
            break
        end
    end
end

-- server
function MissionAvatarComponent:SyncRemoveActiveMissionEvent(MissionID, MissionEventID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncRemoveActiveMissionEvent Actor:%s MissionID:%d MissionEventID:%d", self:GetActorID(), MissionID, MissionEventID)
    self:InnerSyncRemoveActiveMissionEvent(MissionID, MissionEventID)
    self:Client_SyncRemoveActiveMissionEvent(MissionID, MissionEventID)
end

-- client
function MissionAvatarComponent:Client_SyncRemoveActiveMissionEvent_RPC(MissionID, MissionEventID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncRemoveActiveMissionEvent Actor:%s MissionID:%d MissionEventID:%d", self:GetActorID(), MissionID, MissionEventID)
    self:InnerSyncRemoveActiveMissionEvent(MissionID, MissionEventID)
    if MissionID == self.TrackingMissionID then
        self:UpdateClientTrackStates()
    end
    self:NotifyMissionObjectEventUpdated(MissionID)
end

function MissionAvatarComponent:InnerSyncRemoveActiveMissionEvent(MissionID, MissionEventID)
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        if MissionData.Identifier.MissionID == MissionID then
            for j = 1, MissionData.ActiveEvents:Length() do
                local MissionEventData = MissionData.ActiveEvents:GetRef(j)
                if MissionEventData.MissionEventID == MissionEventID then
                    MissionData.ActiveEvents:Remove(j)
                    break
                end
            end
            break
        end
    end
end

-- server
function MissionAvatarComponent:SyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncUpdateActiveMissionEventProgress Actor:%s MissionID:%d MissionEventID:%d Progress:%d",
        self:GetActorID(), MissionID, MissionEventID, Progress)
    self:InnerSyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    self:Client_SyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
end

-- client
function MissionAvatarComponent:Client_SyncUpdateActiveMissionEventProgress_RPC(MissionID, MissionEventID, Progress)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncUpdateActiveMissionEventProgress Actor:%s MissionID:%d MissionEventID:%d Progress:%d", self:GetActorID(), MissionID,
        MissionEventID, Progress)
    self:InnerSyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    -- update ui
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    local MissionObject = self.MissionObjectDict[MissionID]
    if MissionObject ~= nil then
        TaskMainVM:UpdateMissionProgress(MissionObject)
    end
    self:NotifyMissionObjectEventUpdated(MissionID)
end

function MissionAvatarComponent:InnerSyncUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        if MissionData.Identifier.MissionID == MissionID then
            for j = 1, MissionData.ActiveEvents:Length() do
                local MissionEventData = MissionData.ActiveEvents:GetRef(j)
                if MissionEventData.MissionEventID == MissionEventID then
                    MissionEventData.Record.Progress = Progress
                    break
                end
            end
            break
        end
    end
end

-- server
function MissionAvatarComponent:SyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SyncUpdateActiveMissionEventTrackTarget Actor:%s MissionID:%d MissionEventID:%d RawEventID:%d %s",
        self:GetActorID(), MissionID, MissionEventID, RawEventID, TrackTargetList)
    self:InnerSyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    self:Client_SyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
end

-- client
function MissionAvatarComponent:Client_SyncUpdateActiveMissionEventTrackTarget_RPC(MissionID, MissionEventID, RawEventID, TrackTargetList)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_SyncUpdateActiveMissionEventTrackTarget Actor:%s MissionID:%d MissionEventID:%d", self:GetActorID(), MissionID,
        MissionEventID)
    self:InnerSyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    if self.TrackingMissionID == MissionID then
        self:UpdateClientTrackStates()
    end
    self:NotifyMissionObjectEventUpdated(MissionID)
end

function MissionAvatarComponent:InnerSyncUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    for i = 1, self.MissionDataList:Length() do
        local MissionData = self.MissionDataList:GetRef(i)
        if MissionData.Identifier.MissionID == MissionID then
            for j = 1, MissionData.ActiveEvents:Length() do
                local MissionEventData = MissionData.ActiveEvents:GetRef(j)
                if MissionEventData.MissionEventID == MissionEventID then
                    G.log:debug("xaelpeng", "MissionAvatarComponent:InnerSyncUpdateActiveMissionEventTrackTarget MissionEventID:%d", MissionEventID)
                    MissionUtils.UpdateTrackTargetList(MissionEventData.TrackTargetList, RawEventID, TrackTargetList)
                    break
                end
            end
            break
        end
    end
end

-- client
function MissionAvatarComponent:NotifyMissionObjectEventUpdated(MissionID)
    local MissionObject =self.MissionObjectDict[MissionID]
    if MissionObject ~= nil then
        MissionObject:OnMissionEventUpdated()
    end
end

-- server
function MissionAvatarComponent:NotifyMissionGroupStateChange(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:NotifyMissionGroupStateChange Actor:%s MissionGroupID:%d State:%s", self:GetActorID(), MissionIdentifier.MissionGroupID, State)
    self:Client_NotifyMissionGroupStateChange(MissionIdentifier, State)
end

-- server
function MissionAvatarComponent:NotifyMissionActStateChange(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:NotifyMissionActStateChange Actor:%s MissionActID:%d State:%s", self:GetActorID(), MissionIdentifier.MissionActID, State)
    self:InnerUpdateMissionActState(MissionIdentifier.MissionActID, State)
    self.OnMissionActStateChange:Broadcast(MissionIdentifier.MissionActID, State, MissionIdentifier.MissionID)
    self:Client_NotifyMissionActStateChange(MissionIdentifier, State)
end

-- server
function MissionAvatarComponent:NotifyMissionStateChange(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:NotifyMissionStateChange Actor:%s MissionID:%d State:%s", self:GetActorID(), MissionIdentifier.MissionID, State)
    local MissionRecord = self:GetMissionRecord(MissionIdentifier.MissionID)
    if not MissionRecord then
        G.log:error("MissionAvatarComponent:NotifyMissionStateChange", "MissionID(%s) not exist", MissionIdentifier.MissionID)
        return
    end
    MissionRecord.State = State
    self.OnMissionStateChange:Broadcast(MissionIdentifier.MissionID, State)
    self:Client_NotifyMissionStateChange(MissionIdentifier, State)
    if MissionIdentifier.MissionID == self.TrackingMissionID  and State == Enum.EHiMissionState.Complete then
        -- 任务完成了，追踪任务关闭
        self.TrackingMissionID = 0
    end
end

-- server
function MissionAvatarComponent:NotifyMissionEventStateChange(MissionIdentifier, MissionEventID, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:NotifyMissionEventStateChange Actor:%s MissionEventID:%d State:%s", self:GetActorID(), MissionEventID, State)
    self.OnMissionEventStateChange:Broadcast(MissionEventID, State, MissionIdentifier.MissionID)
    self:Client_NotifyMissionEventStateChange(MissionIdentifier, MissionEventID, State)
end

-- server
function MissionAvatarComponent:SyncAddMissionActDialogueRecord(MissionActID, DialogueRecord)
    self:Client_SyncAddMissionActDialogueRecord(MissionActID, DialogueRecord)
end


-- client
function MissionAvatarComponent:Client_NotifyMissionGroupStateChange_RPC(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_NotifyMissionGroupStateChange MissionGroupID:%d State:%s", MissionIdentifier.MissionGroupID, State)
end

-- client
function MissionAvatarComponent:Client_NotifyMissionActStateChange_RPC(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_NotifyMissionActStateChange MissionActID:%d State:%s", MissionIdentifier.MissionActID, State)
    if MissionIdentifier.MissionActID == 0 then
        return
    end

    self:InnerUpdateMissionActState(MissionIdentifier.MissionActID, State)

    -- 任务幕开始的UI弹窗由任务编辑器Action节点来控制, 结束由代码来控制
    if State == Enum.EMissionActState.Complete then
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        if HudMessageCenterVM then
            local DisplayInfo = MissionUtils.MissionActDisplayInfo.new(MissionIdentifier.MissionActID, State)
            HudMessageCenterVM:ShowChapterDisplay(DisplayInfo)
        end
    end
    self.OnMissionActStateChange:Broadcast(MissionIdentifier.MissionActID, State, MissionIdentifier.MissionID)
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:OnNotifyMissionActStateChange(MissionIdentifier.MissionActID, State)
end

function MissionAvatarComponent:InnerUpdateMissionActState(MissionActID, NewState)
    for i = 1, self.MissionActDataList:Num() do
        local MissionActData = self.MissionActDataList:GetRef(i)
        if MissionActData.MissionActID == MissionActID then
            MissionActData.State = NewState
            return
        end
    end
end

-- client
function MissionAvatarComponent:Client_NotifyMissionStateChange_RPC(MissionIdentifier, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_NotifyMissionStateChange MissionID:%d State:%s", MissionIdentifier.MissionID, State)
    local MissionRecord = self:GetMissionRecord(MissionIdentifier.MissionID)
    if not MissionRecord then
        G.log:error("MissionAvatarComponent:Client_NotifyMissionStateChange", "MissionID(%s) not exist", MissionIdentifier.MissionID)
        return
    end
    MissionRecord.State = State

    if MissionIdentifier.MissionID ~= 0 then
        self.OnMissionStateChange:Broadcast(MissionIdentifier.MissionID, State)
    end
end

-- client
function MissionAvatarComponent:Client_NotifyMissionEventStateChange_RPC(MissionIdentifier, MissionEventID, State)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_NotifyMissionEventStateChange MissionEventID:%d State:%s", MissionEventID, State)
    self.OnMissionEventStateChange:Broadcast(MissionEventID, State, MissionIdentifier.MissionID)
    if self:CanStartAutoTrack(MissionIdentifier, MissionEventID) then
        self:StartAutoTrackTimer(MissionIdentifier.MissionID)
    end
end

function MissionAvatarComponent:Client_SyncAddMissionActDialogueRecord_RPC(MissionActID, DialogueRecord)
    for Index = 1, self.MissionActDataList:Length() do
        local MissionAct = self.MissionActDataList:GetRef(Index)
        if MissionAct.MissionActID == MissionActID then
            MissionAct.Dialogues:Add(DialogueRecord)
            return
        end
    end
end

function MissionAvatarComponent:Client_ShowMissionActStart_RPC(MissionActID)
    if MissionActID == 0 or MissionActID == nil then
        G.log:warn("MissionAvatarComponent:Client_ShowMissionActStart", "MissionActID wrong, ID=%s", MissionActID)
        return
    end
    local State = Enum.EMissionActState.Start
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        local DisplayInfo = MissionUtils.MissionActDisplayInfo.new(MissionActID, State)
        HudMessageCenterVM:ShowChapterDisplay(DisplayInfo)
    end
end

-- server
function MissionAvatarComponent:Server_FinishMissionDialogueWithNpc_RPC(Npc, DialogueID, ResultID, DialogueRecord)
    if Npc and Npc:IsValid() then
        if Npc.DialogueComponent then
            Npc.DialogueComponent:Server_OnMissionDialogueFinish(DialogueID, ResultID, DialogueRecord)
        else
            G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishMissionDialogueWithNpc Actor:%s Npc:%s not has DialogueComponent", self:GetActorID(), Npc:GetName())
        end
    else
        G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishMissionDialogueWithNpc Actor:%s Invalid Npc:%s", self:GetActorID(), Npc)
    end
end

-- server
function MissionAvatarComponent:Server_FinishDefaultDialogueWithNpc_RPC(Npc)
    if Npc and Npc:IsValid() then
        if Npc.DialogueComponent then
            Npc.DialogueComponent:Server_OnDefaultDialogueFinish()
        else
            G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishDefaultDialogueWithNpc Actor:%s Npc:%s not has DialogueComponent", self:GetActorID(), Npc:GetName())
        end
    else
        G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishDefaultDialogueWithNpc Actor:%s Invalid Npc:%s", self:GetActorID(), Npc)
    end
end

-- server
function MissionAvatarComponent:Server_FinishInteractWithNpc_RPC(Npc, InteractID)
    if Npc and Npc:IsValid() then
        if Npc.NpcBehaviorComponent then
            Npc.NpcBehaviorComponent:Server_OnPlayerFinishInteract_RPC(InteractID)
        else
            G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishInteractWithNpc Actor:%s Npc:%s not has NpcBehaviorComponent", self:GetActorID(), Npc:GetName())
        end
    else
        G.log:error("xaelpeng", "MissionAvatarComponent:Server_FinishInteractWithNpc Actor:%s Invalid Npc:%s", self:GetActorID(), Npc)
    end
end



--------- track mission start ------------------------------------------------------------------------------------------

function MissionAvatarComponent:CanStartAutoTrack(MissionIdentifier, MissionEventID)
    if MissionIdentifier.MissionID == self.TrackingMissionID then
        -- 当前已经在追踪了
        return false
    end

    if MissionUtils.GetBlockReason(MissionIdentifier.MissionID, self) ~= 0 then
        -- 任务被前置条件阻塞
        return false
    end

    local AutoTrackType = MissionEventDataTable[MissionEventID].autotrack
    if AutoTrackType == MissionEventTable.TrackAllTime then
        -- 强制打断所有任务
        return true
    elseif AutoTrackType == MissionEventTable.TrackOnlyAct then
        -- 只打断同个MissionAct下的其他任务
        if self.TrackingMissionID == 0 then
            return true
        end
        local MissionData = self:FindMissionData(self.TrackingMissionID)
        if not MissionData then
            return true
        end
        return MissionIdentifier.MissionActID == MissionData.Identifier.MissionActID
    elseif AutoTrackType == MissionEventTable.TrackOnlyNomission then
        -- 无追踪任务时，可以自动追踪
        return self.TrackingMissionID == 0
    end

    return false
end

-- client
function MissionAvatarComponent:StartAutoTrackTimer(MissionID)
    if self.AutoTrackTimer then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.AutoTrackTimer)
        self.AutoTrackTimer = nil
    end
    self.AutoTrackTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, function() self:OnStartAutoTrackEnd(MissionID) end}, 
        UIConstData.MISSION_TRACK_TIP_DURATION.FloatValue, false)
end

function MissionAvatarComponent:OnStartAutoTrackEnd(MissionID)
    self.AutoTrackTimer = nil
    self:SetMissionTracking(MissionID, true)
end

-- client
function MissionAvatarComponent:SetMissionTracking(MissionID, bTracking)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SetMissionTracking %d %s", MissionID, bTracking)
    if bTracking then
        self:Server_StartTrackMission(MissionID)
    else
        if self.TrackingMissionID == MissionID then
            self:Server_CancelTrackMission(MissionID)
        end
    end
end

-- server
function MissionAvatarComponent:Server_StartTrackMission_RPC(MissionID)
    if MissionID == 0 then
        return
    end
    self.TrackingMissionID = MissionID
end

-- server
function MissionAvatarComponent:Server_CancelTrackMission_RPC(MissionID)
    if self.TrackingMissionID == MissionID then
        self.TrackingMissionID = 0
    end
end

-- client
function MissionAvatarComponent:IsScreenTracking()
    return self.ScreenTrackIconTimer ~= nil
end

-- client
function MissionAvatarComponent:OnRep_TrackingMissionID()
    if not self.enabled then
        return
    end
    G.log:debug("xaelpeng", "MissionAvatarComponent:OnRep_TrackingMissionID %d LocalTrackingMissionID:%d", self.TrackingMissionID, self.LocalTrackingMissionID)
    self:ApplyTrackingMissionID()
    self:UpdateClientTrackStates()
    self.OnTrackingMissionChange:Broadcast()
end

-- client
function MissionAvatarComponent:ApplyTrackingMissionID()
    G.log:debug("xaelpeng", "MissionAvatarComponent:ApplyTrackingMissionID %d LocalTrackingMissionID:%d", self.TrackingMissionID, self.LocalTrackingMissionID)
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    if self.LocalTrackingMissionID ~= 0 then
        self:DoUntrackMissionInTrackPanel(self.LocalTrackingMissionID)
    end
    self.LocalTrackingMissionID = self.TrackingMissionID
    if self.TrackingMissionID ~= 0 then
        self:DoTrackMissionInTrackPanel(self.TrackingMissionID)
    end
end

-- client 更新任务追踪面板
function MissionAvatarComponent:DoTrackMissionInTrackPanel(MissionID)
    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    if MissionObject ~= nil then
        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
        TaskMainVM:UpdateMissionTrackState(MissionObject)
        TaskMainVM:BindMission(MissionObject, MissionObject:IsNewMission())
        G.log:debug("xaelpeng", "MissionAvatarComponent:DoTrackMissionInTrackPanel MissionID:%d", MissionID)
    else
        G.log:debug("xaelpeng", "MissionAvatarComponent:DoTrackMissionInTrackPanel MissionID:%d MissionObject not exsit", MissionID)
    end
end

-- client 任务追踪面板取消追踪
function MissionAvatarComponent:DoUntrackMissionInTrackPanel(MissionID)
    if self.LocalTrackingMissionID ~= MissionID then
        G.log:debug("xaelpeng", "MissionAvatarComponent:DoUntrackMissionInTrackPanel MissionID Mismatch %d :%d", self.LocalTrackingMissionID, MissionID)
        return
    end
    local MissionObject = self.MissionObjectDict[self.LocalTrackingMissionID]
    local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
    TaskMainVM:UnbindMission()
    if MissionObject ~= nil then
        TaskMainVM:UpdateMissionTrackState(MissionObject)
    end
    self.LocalTrackingMissionID = 0
end

-- client
function MissionAvatarComponent:ClearScreenTrackUI()
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        for _, TrackingWrapper in pairs(self.TrackingMissionWrapperList) do
            HudTrackVM:RemoveTrackActor(TrackingWrapper)
        end
    end
    self.TrackingMissionWrapperList = {}
    if self.ScreenTrackIconTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ScreenTrackIconTimer)
        self.ScreenTrackIconTimer = nil
        self:StopScreenTrack()
    end
end

-- client
function MissionAvatarComponent:ApplyScreenTrackUI()
    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    if MissionObject == nil then
        return
    end
    local ActiveMissionEventData = MissionObject:GetMissionEventData()
    if ActiveMissionEventData == nil then
        return
    end
    local TrackTargetList = ActiveMissionEventData.TrackTargetList
    for i = 1, TrackTargetList:Length() do
        local TrackTarget = TrackTargetList:GetRef(i)
        if TrackTarget.TrackTargetType ~= Enum.ETrackTargetType.None then
            local TrackingWrapper = HudTrackVMModule.MissionTrackTargetWrapper.new(self, i)
            table.insert(self.TrackingMissionWrapperList, TrackingWrapper)
            local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
            if HudTrackVM then
                HudTrackVM:AddTrackActor(TrackingWrapper)
            end
        end
    end
    -- 设定结束计时器
    if self.ScreenTrackIconTimer then
        G.log:warn("[ApplyScreenTrackUI]", "ScreenTrackIconTimer already exist")
        return
    end
    self.ScreenTrackIconTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnScreenTrackEnd}, 
        UIConstData.SCREEN_MISSION_TRACK_DURATION.FloatValue, false)

end

-- client
function MissionAvatarComponent:RefreshScreenTrackUI()
    self:ClearScreenTrackUI()
    self:ApplyScreenTrackUI()
end

--------- track mission finish ------------------------------------------------------------------------------------------


--------- mission track target start -----------------------------------------------------------------------------------
-- client
function MissionAvatarComponent:QueryActorPositionByMissionID(ActorID, MissionID)
    local Position = self:QueryActorPosition(ActorID)
    if Position == nil then
        if self.MissionQueryingActors[ActorID] == nil then
            self.MissionQueryingActors[ActorID] = {}

            local Callback = function()
                if self.MissionQueryingActors[ActorID] == nil then
                    return
                end
                for MissionID, _ in pairs(self.MissionQueryingActors[ActorID]) do
                    local MissionObject = self.MissionObjectDict[MissionID]
                    if MissionObject ~= nil then
                        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
                        TaskMainVM:UpdateMissionDistance(MissionObject)
                    end
                end
                self.MissionQueryingActors[ActorID] = nil
            end

            table.insert(self.ActorPositionRequesting[ActorID], Callback)
        end
        self.MissionQueryingActors[ActorID][MissionID] = true
    end
    return Position
end

-- client
function MissionAvatarComponent:QueryActorPositionWithCallback(ActorID, Callback)
    local Position = self:QueryActorPosition(ActorID)
    if Position == nil then
        table.insert(self.ActorPositionRequesting[ActorID], Callback)
    end
    return Position
end

-- client
function MissionAvatarComponent:QueryActorPosition(ActorID)
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        if self.ActorPositionRequesting[ActorID] ~= nil then
            -- G.log:debug("xaelpeng", "MissionAvatarComponent:QueryActorPosition %d requesting actor position for %s", self.TrackingMissionID, TrackTarget.ActorID)
            return nil
        end
        if self.ActorPositionCache:FindRef(ActorID) == nil then
            self:Server_RequestActorPosition(ActorID)
            G.log:debug("xaelpeng", "MissionAvatarComponent:QueryActorPosition request actor position for %s", ActorID)
            self.ActorPositionRequesting[ActorID] = {}
            return nil
        end
        return self.ActorPositionCache:FindRef(ActorID)
    else
        -- TODO 读表获取坐标偏移
        if Actor.TrackTargetAnchor == nil then
            return Actor:K2_GetActorLocation()
        else
            return Actor.TrackTargetAnchor:K2_GetComponentLocation()
        end
    end
end

-- client
function MissionAvatarComponent:GetTrackTargetPositionAndDistanceByIndex(Index)
    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    if MissionObject == nil then
        return
    end
    local Position = MissionObject:GetTrackTargetPositionByIndex(Index)
    if Position == nil then
        return nil
    end
    local PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self.actor:GetWorld(), 0)
    local Distance = UE.UKismetMathLibrary.Vector_Distance(PlayerPawn:K2_GetActorLocation(), Position)
    return Position, Distance
end

-- server
function MissionAvatarComponent:Server_RequestActorPosition_RPC(ActorID)
    local Position = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetMutableActorPosition(ActorID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Server_RequestActorPosition %s %s", ActorID, Position)
    if Position ~= nil then
        self:Client_OnRequestActorPosition(ActorID, Position)
    end
    -- todo fix up for distributed ds
end

-- client
function MissionAvatarComponent:Client_OnRequestActorPosition_RPC(ActorID, Position)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Client_OnRequestActorPosition %s %s", ActorID, Position)
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        self.ActorPositionCache:Add(ActorID, Position)
        local Callbacks = self.ActorPositionRequesting[ActorID]
        self.ActorPositionRequesting[ActorID] = nil
        if Callbacks ~= nil then
            for _, Callback in ipairs(Callbacks) do
                Callback()
            end
        end
    end
end

-- client
function MissionAvatarComponent:StartListenActorCreateOrDestroy()
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):ListenClientActorSpawnOrDestroy(self, self.OnActorCreateOrDestroy)
end

-- client
function MissionAvatarComponent:StopListenActorCreateOrDestroy()
    SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):UnlistenClientActorSpawnOrDestroy(self, self.OnActorCreateOrDestroy)
end

function MissionAvatarComponent:GetTrackMissionTypeAndState()
    if self.TrackingMissionID == 0 then
        return nil, nil
    end
    local MissionData = self:FindMissionData(self.TrackingMissionID)
    if not MissionData then
        return nil, nil
    end
    local MissionActID = MissionData.Identifier.MissionActID
    local MissionActData = MissionActTable[MissionActID]
    if not MissionActData then
        return nil, nil
    end
    return MissionActData.Type, MissionData.TrackIconType
end

-- client
function MissionAvatarComponent:OnActorCreateOrDestroy(ActorID, bCreateOrDestroy)
    if bCreateOrDestroy then
        self.ActorPositionCache:Remove(ActorID)
        local Callbacks = self.ActorPositionRequesting[ActorID]
        self.ActorPositionRequesting[ActorID] = nil
        if Callbacks ~= nil then
            for _, Callback in ipairs(Callbacks) do
                Callback()
            end
        end
        
        if self.TrackingActorIDs:Contains(ActorID) then
            local MissionType, MissionState = self:GetTrackMissionTypeAndState()
            self:MarkTrackingActor(ActorID, MissionType, MissionState)
        end
    end
end

-- client
function MissionAvatarComponent:UpdateClientTrackStates()
    self:ClearScreenTrackUI()                   -- 清空屏幕上的任务指针（这个需要放在最前, 恢复旧追踪npc头顶billboard的显示）
    self:UpdateTrackingActorMark()              -- 更新追踪NPC的头顶图标
    self:UpdateTrackingTargetParticle()         -- 更新任务地点的大光柱
    self:StartScreenTrack()                     -- 自动追踪（这个需要放在最后, 隐藏新追踪npc头顶billboard）
end

-- client 更新追踪NPC头顶图标
function MissionAvatarComponent:UpdateTrackingActorMark()
    local NewActorIDs = self:GetTrackingActorIDs()
    local OldArray = self.TrackingActorIDs:ToArray()
    for i = 1, OldArray:Length() do
        local ActorID = OldArray:Get(i)
        if not NewActorIDs:Contains(ActorID) then
            self:UnMarkTrackingActor(ActorID)
        end
    end
    local NewArray = NewActorIDs:ToArray()
    local MissionType, MissionState = self:GetTrackMissionTypeAndState()
    for i = 1, NewArray:Length() do
        local ActorID = NewArray:Get(i)
        if not self.TrackingActorIDs:Contains(ActorID) then
            self:MarkTrackingActor(ActorID, MissionType, MissionState)
        end
    end
    self.TrackingActorIDs = NewActorIDs
end

-- client 隐藏追踪NPC的头顶任务Icon
function MissionAvatarComponent:UnmarkTrackingActorList()
    local TrackingActorArray = self.TrackingActorIDs:ToArray()
    for i = 1, TrackingActorArray:Length() do
        local ActorID = TrackingActorArray:Get(i)
        self:UnMarkTrackingActor(ActorID)
    end
end


-- client 显示追踪NPC的整个billboard
function MissionAvatarComponent:MarkTrackingActorBillboardList()
    local TrackingActorArray = self.TrackingActorIDs:ToArray()
    for i = 1, TrackingActorArray:Length() do
        local ActorID = TrackingActorArray:Get(i)
        self:MarkTrackingActorBillboard(ActorID)
    end
end

-- client 隐藏追踪NPC的整个billboard
function MissionAvatarComponent:UnmarkTrackingActorBillboardList()
    local TrackingActorArray = self.TrackingActorIDs:ToArray()
    for i = 1, TrackingActorArray:Length() do
        local ActorID = TrackingActorArray:Get(i)
        self:UnMarkTrackingActorBillboard(ActorID)
    end
end

-- client
function MissionAvatarComponent:GetTrackingActorIDs()
    local ActorIDs = UE.TSet(UE.FString)
    if self.TrackingMissionID == 0 then
        return ActorIDs
    end

    if self.MissionObjectDict[self.TrackingMissionID] == nil then
        return ActorIDs
    end

    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    local ActiveMissionEventData = MissionObject:GetMissionEventData()
    if ActiveMissionEventData == nil then
        return ActorIDs
    end

    local TrackTargetList = ActiveMissionEventData.TrackTargetList
    for i = 1, TrackTargetList:Length() do
        local TrackTarget = TrackTargetList:GetRef(i)
        if TrackTarget.TrackTargetType == Enum.ETrackTargetType.Actor then
            ActorIDs:Add(TrackTarget.ActorID)
        end
    end
    return ActorIDs

end

-- client
function MissionAvatarComponent:MarkTrackingActor(ActorID, MissionType, MissionState)
    if MissionType == nil then
        G.log:warn("MarkTrackingActor", "Params error, MissionType=%s, MissionState=%s", MissionType, MissionState)
        return
    end
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        return
    end
    if Actor.GetBillboardComponent == nil then
        return
    end
    local BillboardComponent = Actor:GetBillboardComponent()
    if BillboardComponent == nil then
        return
    end

    BillboardComponent:MarkTracked(MissionType, MissionState)
    if self:IsScreenTracking() then
        -- 屏幕追踪指针生效的时候，actor上的billboard隐藏
        BillboardComponent:SetBillboardVisibility(false)
    end
end

-- client
function MissionAvatarComponent:UnMarkTrackingActor(ActorID)
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        return
    end
    if Actor.GetBillboardComponent == nil then
        return
    end
    local BillboardComponent = Actor:GetBillboardComponent()
    if BillboardComponent == nil then
        return
    end
    BillboardComponent:UnMarkTracked()
end

-- client
function MissionAvatarComponent:MarkTrackingActorBillboard(ActorID)
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        G.log:warn("MissionAvatarComponent", "MarkTrackingActorBillboard, actor(%s) not exist", ActorID)
        return
    end
    if Actor.GetBillboardComponent == nil then
        return
    end
    local BillboardComponent = Actor:GetBillboardComponent()
    if BillboardComponent == nil then
        return
    end
    BillboardComponent:SetBillboardVisibility(true)
end

-- client
function MissionAvatarComponent:UnMarkTrackingActorBillboard(ActorID)
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(ActorID)
    if Actor == nil then
        G.log:warn("MissionAvatarComponent", "UnMarkTrackingActorBillboard, actor(%s) not exist", ActorID)
        return
    end
    if Actor.GetBillboardComponent == nil then
        return
    end
    local BillboardComponent = Actor:GetBillboardComponent()
    if BillboardComponent == nil then
        return
    end
    BillboardComponent:SetBillboardVisibility(false)
end

-- client 更新任务地点大光柱
function MissionAvatarComponent:UpdateTrackingTargetParticle()
    local MissionEventID = self:GetTrackingMissionEventID()
    G.log:debug("xaelpeng", "MissionAvatarComponent:UpdateTrackingTargetParticle %d, %d", MissionEventID, self.TrackingTargetParticleEventID)
    if self.TrackingTargetParticleEventID ~= MissionEventID then
        if self.TrackingTargetParticleEventID ~= 0 then
            self.TrackingTargetParticleEventID = 0
            self.TrackingTargetParticlePosition = nil
            self:DestroyTrackingTargetParticle(false)
        end
        if MissionEventID ~= 0  then
            local MissionEventData = MissionEventDataTable[MissionEventID]
            if MissionEventData.show_tracking_particle or MissionEventData.show_tracking_smallparticle then
                self.TrackingTargetParticleEventID = MissionEventID
            end
        end
    end
    -- FIXME(hangyuewang): 下面这段代码往往不生效，此时GetFirstTrackTargetPosition为nil，现在暂时在tick中生成光柱。
    if self.TrackingTargetParticleEventID ~= 0 and self.TrackingTargetParticlePosition == nil then
        local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
        if MissionObject == nil then
            return
        end
        self.TrackingTargetParticlePosition = MissionObject:GetFirstTrackTargetPosition()
        if self.TrackingTargetParticlePosition ~= nil then
            local MissionEventData = MissionEventDataTable[self.TrackingTargetParticleEventID]
            self:CreateTrackingTargetParticle(self.TrackingTargetParticlePosition, MissionEventData)
        end
    end
end

-- client
function MissionAvatarComponent:GetTrackingMissionEventID()
    if self.TrackingMissionID == 0 then
        return 0
    end

    if self.MissionObjectDict[self.TrackingMissionID] == nil then
        return 0
    end

    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    return MissionObject:GetMissionEventID()
end


-- client
function MissionAvatarComponent:CreateTrackingTargetParticle(Position, MissionEventData)
    G.log:debug("xaelpeng", "MissionAvatarComponent:CreateTrackingTargetParticle")
    if MissionEventData.show_tracking_particle then
        local SpawnParameters = UE.FActorSpawnParameters()
        SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
        local ExtraData = {bOpenTrigger = true}
        local Class = BPConst.GetMissionTargetParticleClass()
        local Transform = UE.UKismetMathLibrary.MakeTransform(Position, UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))
        self.TrackingTargetParticle = GameAPI.SpawnActor(self.actor:GetWorld(), Class, Transform, SpawnParameters, ExtraData)
    end
    if MissionEventData.show_tracking_smallparticle then
        local SpawnParameters = UE.FActorSpawnParameters()
        SpawnParameters.SpawnCollisionHandlingOverride = UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn
        local TrackMissionType, TrackMissionState = self:GetTrackMissionTypeAndState()
        local Class = EdUtils:GetUE5ObjectClass(BPConst.MissionActorGlowSmall)
        local Transform = UE.UKismetMathLibrary.MakeTransform(Position, UE.FRotator(0, 0, 0), UE.FVector(1, 1, 1))
        self.TrackingTargetParticleSmall = GameAPI.SpawnActor(self.actor:GetWorld(), Class, Transform, SpawnParameters)
        self:MarkTargetParticle(TrackMissionType, TrackMissionState)
    end
end

-- client
function MissionAvatarComponent:MarkTargetParticle(TrackMissionType, TrackMissionState)
    if not self.TrackingTargetParticleSmall then
        return
    end
    self.TrackingTargetParticleSmall:MarkMissionIcon(TrackMissionType, TrackMissionState)
    if self:IsScreenTracking() then
        self:UnmarkTargetParticle()
    end
end

-- client
function MissionAvatarComponent:UnmarkTargetParticle()
    if not self.TrackingTargetParticleSmall then
        return
    end
    self.TrackingTargetParticleSmall:UnmarkMissionIcon()
end


-- client
function MissionAvatarComponent:DestroyTrackingTargetParticle(bFadeOut)
    G.log:debug("xaelpeng", "MissionAvatarComponent:DestroyTrackingTargetParticle")
    if self.TrackingTargetParticle ~= nil then
        self.TrackingTargetParticle:FadeOut(bFadeOut)
        self.TrackingTargetParticle = nil
    end
    if self.TrackingTargetParticleSmall ~= nil then
        self.TrackingTargetParticleSmall:FadeOut(bFadeOut)
        self.TrackingTargetParticleSmall = nil
    end
end

-- client
function MissionAvatarComponent:TickTrackingTargetParticle()
    if self.TrackingTargetParticleEventID == 0 or self.TrackingTargetParticleEventID ~= self:GetTrackingMissionEventID() then
        return
    end

    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    if MissionObject == nil then
        return
    end

    if self.TrackingTargetParticlePosition == nil then
        self.TrackingTargetParticlePosition = MissionObject:GetFirstTrackTargetPosition()
        if self.TrackingTargetParticlePosition ~= nil then
            local MissionEventData = MissionEventDataTable[self.TrackingTargetParticleEventID]
            self:CreateTrackingTargetParticle(self.TrackingTargetParticlePosition, MissionEventData)
        end
        
    -- 策划暂时不考虑追踪目标会移动的情况
    -- elseif UE.UKismetMathLibrary.Vector_Distance(self.TrackingTargetParticlePosition, Position) / 100.0 > 500 then
    --     -- 偏移指定范围重新创建指引特效
    --     self:DestroyTrackingTargetParticle(false)
    --     self.TrackingTargetParticlePosition = Position
    --     self:CreateTrackingTargetParticle(Position)
    end
end

-- client
function MissionAvatarComponent:GetUniqueTrackingTarget()
    if self.TrackingMissionID == 0 then
        return nil
    end

    if self.MissionObjectDict[self.TrackingMissionID] == nil then
        return nil
    end

    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    -- TODO: 先默认选择第一个Target做为追踪面板的距离显示和大光柱的显示目标
    return MissionObject:GetFirstTrackTarget()
end

-- client
function MissionAvatarComponent:UpdateTrackingMissionDistance()
    if self.TrackingMissionID == 0 then
        return
    end
    local MissionObject = self.MissionObjectDict[self.TrackingMissionID]
    if MissionObject == nil then
        return
    end
    if self.LocalTrackingMissionID ~= 0 and self.LocalTrackingMissionID == self.TrackingMissionID then
        local TaskMainVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskMainVM.UniqueName)
        TaskMainVM:UpdateMissionDistance(MissionObject)
    end
end

function MissionAvatarComponent:StartScreenTrack()
    if self.TrackingMissionID == 0 then
        return
    elseif self.ScreenTrackIconTimer then
        -- 已经在追踪, 计时器重新计时
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ScreenTrackIconTimer)
        self.ScreenTrackIconTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnScreenTrackEnd}, 
            UIConstData.SCREEN_MISSION_TRACK_DURATION.FloatValue, false)
        return
    else
        -- 开始屏幕指针追踪, 关闭Toplogo上的任务Icon
        self:UnmarkTrackingActorBillboardList()
        self:ApplyScreenTrackUI()
        self:UnmarkTargetParticle()
    end
end

function MissionAvatarComponent:OnScreenTrackEnd()
    if self.TrackingMissionID == 0 then
        G.log:error("[OnScreenTrackEnd]", "No Tracking Mission")
        return
    end
    if not self.ScreenTrackIconTimer then
        G.log:error("[OnScreenTrackEnd]", "ScreenTrackIconTimer is nil")
    end
    self.ScreenTrackIconTimer = nil
    self:StopScreenTrack()
end

function MissionAvatarComponent:StopScreenTrack()
    -- 关闭屏幕指针，恢复追踪目标和光柱的任务icon
    self:ClearScreenTrackUI()
    self:MarkTrackingActorBillboardList()
    self:MarkTargetParticle()
end


function MissionAvatarComponent:ReceiveTick(DeltaSeconds)
    if self:GetOwner():IsClient() then
        self:UpdateTrackingMissionDistance()

        self:TickTrackingTargetParticle()
    end
end
--------- mission track target finish -----------------------------------------------------------------------------------


--------- mission self dialogue start -----------------------------------------------------------------------------------
-- server
function MissionAvatarComponent:SetSelfDialogue(DialogueID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:SetSelfDialogue %d", DialogueID)
    self.SelfDialogueID = DialogueID
end

-- server
function MissionAvatarComponent:ResetSelfDialogue(DialogueID)
    if self.SelfDialogueID == DialogueID then
        self.SelfDialogueID = 0
    end
end

-- client
function MissionAvatarComponent:OnRep_SelfDialogueID()
    if not self.enabled then
        return
    end
    G.log:debug("xaelpeng", "MissionAvatarComponent:OnRep_SelfDialogueID %d", self.SelfDialogueID)
    if self.SelfDialogueID ~= 0 then
        self:StartSelfDialogue(self.SelfDialogueID)
    end
end

-- client
function MissionAvatarComponent:StartSelfDialogue(DialogueID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:StartSelfDialogue %d", DialogueID)
    local DialogueObject = self:CreateSelfDialogueObject(DialogueID)
    if self.actor.PawnPrivate.PlayerUIInteractComponent ~= nil then
        self.actor.PawnPrivate.PlayerUIInteractComponent:StartDialogue(DialogueObject)
    end
end

-- client
function MissionAvatarComponent:CreateSelfDialogueObject(DialogueID)
    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID, self)
    local FinishCallback = function()
        local StartDialogueID = DialogueObject:GetStartDialogueID()
        local FinishDialogueID = DialogueObject:GetFinishDialogueID()
        self:OnSelfDialogFinish(DialogueID, FinishDialogueID)
    end
    DialogueObject:SetFinishCallback(FinishCallback)
    return DialogueObject
end

-- client
function MissionAvatarComponent:OnSelfDialogFinish(DialogueID, FinishDialogueID)
    self:Server_FinishSelfDialogue(DialogueID, FinishDialogueID)
end

-- client
function MissionAvatarComponent:GetTalkerName(TalkerID)
    if TalkerID == DialogueObjectModule.DialogueStepOwnerType.PLAYER then
        return "Player"
    end
    local Actor = SubsystemUtils.GetMutableActorSubSystem(self:GetOwner()):GetClientMutableActor(tostring(TalkerID))
    if Actor ~= nil then
        if Actor.GetNpcDisplayName ~= nil then
            return Actor:GetNpcDisplayName()
        end
    end
end

-- client
function MissionAvatarComponent:GetDefaultTalkerName()
    return "Player"
end

-- server
function MissionAvatarComponent:Server_FinishSelfDialogue_RPC(DialogueID, FinishDialogueID)
    G.log:debug("xaelpeng", "MissionAvatarComponent:Server_FinishSelfDialogue %d ResultID:%d", DialogueID, FinishDialogueID)
    self.SelfDialogFinished:Broadcast(DialogueID, FinishDialogueID)
end
--------- mission self dialogue end -----------------------------------------------------------------------------------


--------- control tips start -----------------------------------------------------------------------------------
-- client
function MissionAvatarComponent:Client_DisplayControlTips_RPC(ControlKey, ControllDescriptionID, ExitTime)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        local Callback = function ()
            self:CancelDisplayControlTipsTimer()
            self:HideControlTips()
        end

        self:CancelDisplayControlTipsTimer()
        self.DisplayControlTipsTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimerDisplayControlTips}, ExitTime, false)
        HudMessageCenterVM:ShowControlTips(GuideTextTable[ControllDescriptionID].Content, ControlKey, Callback)
    end
end

-- client
function MissionAvatarComponent:OnTimerDisplayControlTips()
    self.DisplayControlTipsTimer = nil
    self:HideControlTips()
end

-- client
function MissionAvatarComponent:HideControlTips()
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        HudMessageCenterVM:HideControlTips()
    end
end

-- client
function MissionAvatarComponent:CancelDisplayControlTipsTimer()
    if self.DisplayControlTipsTimer ~= nil then
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DisplayControlTipsTimer)
        self.DisplayControlTipsTimer = nil
    end
end

--------- control tips end -----------------------------------------------------------------------------------


-- 玩家自言自语 Start --------------------------------------------------------------------------------
decorator.message_receiver()
function MissionAvatarComponent:StartMonologue(MonologueID)
    local MonologueData, ContentID = MonoLogueUtils.GenerateMonologueData(MonologueID)
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    self.CurrentMonologueID = MonologueID
    if HudMessageCenterVM and MonologueData ~= nil then
        HudMessageCenterVM:ShowNagging(MonologueData)
    end
    return ContentID
end

decorator.message_receiver()
function MissionAvatarComponent:StopMonologue(MonologueID)
    if self.CurrentMonologueID == MonologueID then
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        if HudMessageCenterVM then
            HudMessageCenterVM:HideNagging()
        end
        self.CurrentMonologueID = 0
    end
end

-- 玩家自言自语 End --------------------------------------------------------------------------------


-- 短信 Start --------------------------------------------------------------------------------
-- server
function MissionAvatarComponent:StartSmsDialogue(DialogueID, NpcID, MissionActID)
    G.log:debug("[StartSmsDialogue]", "DialogueID=%s, NpcID=%s, MissionActID=%s", DialogueID, NpcID, MissionActID)
    local SmsDialogue = self.SmsDialogues[NpcID]
    if SmsDialogue and SmsDialogue:GetStartDialogueID() == DialogueID then
        -- 当前的Dialogue是存盘恢复的, 直接返回注册成功
        return true
    end

    if not self:CanStartSmsDialogue(DialogueID, NpcID, MissionActID) then
        -- 不能马上开始的对话，先存到WaitSmsDialogues里面
        local WaitDialogueClass = EdUtils:GetUE5ObjectClass(BPConst.WaitDialogueData, true)
        local WaitDialogue = WaitDialogueClass()
        WaitDialogue.DialogueID = DialogueID
        WaitDialogue.NpcID = NpcID
        WaitDialogue.MissionActID = MissionActID
        self.WaitSmsDialogues:Add(WaitDialogue)
        return true
    end
    
    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID, nil)
    DialogueObject:SetEnableSaveHistory(true)
    DialogueObject:SetMissionActID(MissionActID)
    DialogueObject:GetNextDialogueStep(0)  -- 自动开始对话
    self.SmsDialogues[NpcID] = DialogueObject

    -- 通知客户端
    self:Client_StartSmsDialogue(DialogueID, NpcID, MissionActID)
    return true
end

function MissionAvatarComponent:CanStartSmsDialogue(DialogueID, NpcID, MissionActID)
    if self.SmsDialogues[NpcID] ~= nil then
        return false
    end
    -- 遍历MissionAct，如果存在NpcID关联的MissionAct且状态在Initialize，说明该Npc的短信对话被其他任务幕占用，返回flase
    for i = 1, self.MissionActDataList:Length() do
        local MissionActData = self.MissionActDataList:GetRef(i)
        if MissionActData.MissionActID ~= MissionActID and MissionActData.State == Enum.EMissionActState.Initialize then
            if MissionActTable[MissionActData.MissionActID].Message_NPC == NpcID then
                return false
            end
        end
    end

    return true
end

-- server
function MissionAvatarComponent:WakeupWaitSmsDialogue(NpcID)
    -- 从等待的短信对话中，尝试激活一个符合条件的对话
    if self.WaitSmsDialogues:Length() == 0 then
        return
    end

    for i = 1, self.WaitSmsDialogues:Length() do
        local SmsDialogue = self.WaitSmsDialogues:GetRef(i)
        if SmsDialogue.NpcID == NpcID then
            self:StartSmsDialogue(SmsDialogue.DialogueID, SmsDialogue.NpcID, SmsDialogue.MissionActID)
            self.WaitSmsDialogues:Remove(i)
            return
        end
    end
end

function MissionAvatarComponent:Client_StartSmsDialogue_RPC(DialogueID, NpcID, MissionActID)
    G.log:debug("[MissionAvatarComponent:Client_StartSmsDialogue]", "Start sms dialogue, NpcID=%s, DialogueID=%s, MissionActID=%s", 
        NpcID, DialogueID, MissionActID)
    if self.SmsDialogues[NpcID] ~= nil then
        G.log:error("hangyuewang", "[Client_StartSmsDialogue] NPC already has sms dialogue, NpcID=%s, DialogueID=%s", NpcID, DialogueID)
        return
    end
    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID, nil)
    DialogueObject:SetEnableSaveHistory(true)
    DialogueObject:SetMissionActID(MissionActID)
    DialogueObject:GetNextDialogueStep(0)  -- 自动开始对话
    self.SmsDialogues[NpcID] = DialogueObject
    -- 通知ui来取数据
    self.OnDialogueUpdate:Broadcast(NpcID)
end

function MissionAvatarComponent:GetCurrentSmsDialogueStep(NpcID)
    local DialogueObject = self.SmsDialogues[NpcID]
    if not DialogueObject then
        G.log:error("[GetCurrentSmsDialogueStep]", "NPC does not have sms dialogue, NpcID=%s", NpcID)
        return nil
    end
    return DialogueObject.CurrentDialogueStepObject
end

-- client
function MissionAvatarComponent:HandleDialogueChoice(NpcID, CurrentChoice)
    local DialogueObject = self.SmsDialogues[NpcID]
    if not DialogueObject then
        G.log:error("[HandleDialogueChoice]", "Npc does not have sms dialogue, NpcID=%s", NpcID)
        return nil
    end
    DialogueObject:GetNextDialogueStep(CurrentChoice)
    -- 上报服务端，记录此次选择
    -- FIXME(hangyuewang): 这里有点问题，如果这个RPC丢了，后续Step顺序就对不上了
    self:Server_HandleDialogueChoice(NpcID, CurrentChoice)
    -- 通知ui来取最新的Step数据
    self.OnDialogueUpdate:Broadcast(NpcID)
end

function MissionAvatarComponent:Server_HandleDialogueChoice_RPC(NpcID, CurrentChoice)
    local DialogueObject = self.SmsDialogues[NpcID]
    if not DialogueObject then
        G.log:error("[Server_HandleDialogueChoice]", "Npc does not have sms dialogue, NpcID=%s", NpcID)
        return
    end
    DialogueObject:GetNextDialogueStep(CurrentChoice)
    if DialogueObject:IsFinished() then
        -- 对话已经结束,将记录移到History中，移除当前Dialogue
        DialogueObject.HistoryRecord.NpcID = NpcID
        self.HistorySmsDialogues:Add(DialogueObject.HistoryRecord)
        self.SmsDialogueFinished:Broadcast(NpcID, DialogueObject:GetStartDialogueID(), DialogueObject:GetFinishDialogueID())
        self.SmsDialogues[NpcID] = nil
        -- 尝试拉起一个新短信对话
        self:WakeupWaitSmsDialogue(NpcID)
    end
end

-- client
function MissionAvatarComponent:FinishDialogue(NpcID)
    G.log:debug("[MissionAvatarComponent:FinishDialogue]", "Sms FinishDialogue, NpcID=%s", NpcID)
    local DialogueObject = self.SmsDialogues[NpcID]
    if not DialogueObject or not DialogueObject:IsFinished() then
        G.log:error("hangyuewang", "[FinishDialogue] Dialogue is not finished, NpcID=%s", NpcID)
        return
    end
    self.SmsDialogues[NpcID] = nil
end

function MissionAvatarComponent:OnRep_HistorySmsDialogues()
    -- TODO(hangyuewang): 通知UI
end
-- 短信 End --------------------------------------------------------------------------------

function MissionAvatarComponent:Server_AcceptMissionAct_RPC(MissionActID)
    -- TODO(hangyuewang): 判断玩家是否在自己的世界, 不在自己世界不能接取任务
    local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
    if not MissionManager then
        G.log:error("[Server_AcceptMissionAct_RPC]", "Can't find MissionManager")
        return
    end

    local MissionActRecord = MissionManager:GetDataBPComponent():GetMissionActRecord(MissionActID)
    if not MissionActRecord then
        G.log:error("[Server_AcceptMissionAct_RPC]", "MissionActID:(%d) not found", MissionActID)
        return
    end

    if MissionActRecord.State ~= Enum.EMissionActState.Initialize then
        G.log:error("[Server_AcceptMissionAct_RPC]", "MissionActID:(%d) CurrState:(%d) error", MissionActID, MissionActRecord.State)
        return
    end

    local CostItemData = MissionActTable[MissionActID].OpenCost
    if CostItemData then
        local ItemManager = self:GetOwner().ItemManager
        local ItemID = CostItemData[1]
        local ItemNum = CostItemData[2]
        local CurNum = ItemManager:GetItemCountByExcelID(ItemID)
        if CurNum < ItemNum then
            G.log:warn("[Server_AcceptMissionAct_RPC]", "No enough cost item, ItemID=%d, ReqNum=%d, CurNum=%d", ItemID, ItemNum, CurNum)
            return
        end
        ItemManager:ReduceItemByExcelID(ItemID, ItemNum)
    end
    G.log:info("[Server_AcceptMissionAct_RPC]", "MissionActID=%d Accept Success", MissionActID)
    self.OnAcceptMissionAct:Broadcast(MissionActID)
end

function MissionAvatarComponent:Server_ReceiveMissionActRewards_RPC(MissionActID)
    -- TODO(hangyuewang): 判断玩家是否在自己的世界, 不在自己世界不能领取奖励
    local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
    if not MissionManager then
        G.log:error("[Server_ReceiveMissionActRewards]", "Can't find MissionManager")
        return
    end
    
    local MissionActRecord = MissionManager:GetDataBPComponent():GetMissionActRecord(MissionActID)
    if not MissionActRecord then
        G.log:error("[Server_ReceiveMissionActRewards]", "MissionActID:(%d) not found", MissionActID)
        return
    end

    -- 判断任务幕是否可以领取奖励
    if MissionActRecord.State ~= Enum.EMissionActState.Complete then
        G.log:error("[Server_ReceiveMissionActRewards]", "MissionAct state:(%d) wrong", MissionActRecord.State)
        return
    end

    -- 切换任务幕状态
    local MissionIdentifier = UE.FHiMissionIdentifier()
    MissionIdentifier.MissionActID = MissionActID
    MissionManager:GetDataBPComponent():SetMissionActState(MissionIdentifier, Enum.EMissionActState.RewardReceived)
    local MissionActReward = MissionActTable[MissionActID].Mission_Act_Reward
    if MissionActReward then
        local ItemManager = self:GetOwner().ItemManager
        for ItemId, ItemNum in pairs(MissionActReward) do
            ItemManager:AddItemByExcelID(ItemId, ItemNum)
            -- TODO(hangyuewang): 加不进背包就进邮箱
        end
        self.LastReceiveRewardMissionActID = MissionActID
    end
end

-- server
function MissionAvatarComponent:AddDialogueSubmitItemInfo(DialogueId, SubmitItemInfo)
    if self.DialogueSubmitItemInfoMap:FindRef(DialogueId) then
        G.log:error("NpcMissionComponent:AddDialogueSubmitItemInfo", "DialogueId(%s) is already exist", DialogueId)
        return
    end
    self.DialogueSubmitItemInfoMap:Add(DialogueId, SubmitItemInfo)
    -- 通知客户端
    self:Client_AddDialogueSubmitItemInfo(DialogueId, SubmitItemInfo)
end

function MissionAvatarComponent:Server_DialogueSubmitItems_RPC(DialogueId, ItemList)
    local Ret = self:CheckDialogueSubmitItemInfo(DialogueId, ItemList)
    if not Ret then
        G.log:warn("Server_DialogueSubmitItems", "CheckDialogueSubmitItemInfo Check Failed")
        return
    end

    -- 背包扣除
    local ItemMap = {}
    for Index = 1, ItemList:Num() do
        local ItemInfo = ItemList:GetRef(Index)
        if ItemMap[ItemInfo.ItemID] then
            ItemMap[ItemInfo.ItemID] = ItemMap[ItemInfo.ItemID] + ItemInfo.ItemNum
        else
            ItemMap[ItemInfo.ItemID] = ItemInfo.ItemNum
        end
    end
    Ret = self:GetOwner().ItemManager:ReduceItems(ItemMap)
    if not Ret then
        G.log:warn("Server_DialogueSubmitItems", "ReduceItems Check Failed")
        return
    end

    self.EventOnDialogueSubmitItems:Broadcast(DialogueId)
    self:Client_RemoveDialogueSubmitItemInfo(DialogueId)
end

function MissionAvatarComponent:Client_AddDialogueSubmitItemInfo_RPC(DialogueId, SubmitItemInfo)
    if self.DialogueSubmitItemInfoMap:FindRef(DialogueId) ~= nil then
        G.log:error("Client_AddDialogueSubmitItemInfo", "DialogueId(%s) already exist", DialogueId)
        return
    end
    self.DialogueSubmitItemInfoMap:Add(DialogueId, SubmitItemInfo)
end

function MissionAvatarComponent:Client_RemoveDialogueSubmitItemInfo_RPC(DialogueId)
    if self.DialogueSubmitItemInfoMap:FindRef(DialogueId) == nil then
        G.log:error("Client_RemoveDialogueSubmitItemInfo", "DialogueId(%s) not exist", DialogueId)
        return
    end
    self.DialogueSubmitItemInfoMap:Remove(DialogueId)
end

function MissionAvatarComponent:CheckDialogueSubmitItemInfo(DialogueId, ItemList)
    local DialogueSubmitItemInfo = self.DialogueSubmitItemInfoMap:FindRef(DialogueId)
    if not DialogueSubmitItemInfo then
        G.log:warn("CheckDialogueSubmitItemInfo", "DialogueId(%s) not exist", DialogueId)
        return false
    end

    local SubmitType = DialogueSubmitItemInfo.SubmitType
    if SubmitType == Enum.ESubmitType.SpecificItem then
        if ItemList:Num() ~= DialogueSubmitItemInfo.ItemMapKey:Num() then
            -- 道具总类对不上
            G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemList=%s, ItemMapKey=%s", SubmitType, ItemList:Num(), DialogueSubmitItemInfo.ItemMapKey:Num())
            return false
        end
        for Index = 1, ItemList:Num() do
            local ItemInfo = ItemList:GetRef(Index)
            local ItemIndex = DialogueSubmitItemInfo.ItemMapKey:Find(ItemInfo.ItemID)
            if ItemIndex <= 0 then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemInfo.ItemID=%s, ItemIndex=%s", SubmitType, ItemInfo.ItemID, ItemIndex)
                return false
            end

            local ItemValue = DialogueSubmitItemInfo.ItemMapValue:Get(ItemIndex)
            if not ItemValue or ItemValue ~= ItemInfo.ItemNum then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemInfo.ItemNum=%s, ItemValue=%s", SubmitType, ItemInfo.ItemNum, ItemValue)
                return false
            end
        end
        return true
    elseif SubmitType == Enum.ESubmitType.ItemSet then
        if ItemList:Num() ~= DialogueSubmitItemInfo.ItemSetNum then
            -- 道具数量对不上
            G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemList=%s, ItemSetNum=%s", SubmitType, ItemList:Num(), DialogueSubmitItemInfo.ItemSetNum)
            return false
        end
        for Index = 1, ItemList:Num() do
            local ItemInfo = ItemList:GetRef(Index)
            if ItemInfo.ItemNum ~= 1 then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemID=%s, ItemNum=%s", SubmitType, ItemInfo.ItemID, ItemInfo.ItemNum)
                return false
            end
            if not DialogueSubmitItemInfo.ItemSet:Contains(ItemInfo.ItemID) then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemID=%s, Not in set", SubmitType, ItemInfo.ItemID)
                return false
            end
        end
        return true
    elseif SubmitType == Enum.ESubmitType.ItemType then
        if ItemList:Num() ~= DialogueSubmitItemInfo.ItemTypeNumList:Num() then
            -- 道具数量对不上
            G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemList=%s, ItemTypeNumList=%s", SubmitType, ItemList:Num(), DialogueSubmitItemInfo.ItemTypeNumList:Num())
            return false
        end
        for Index = 1, ItemList:Num() do
            local ItemInfo = ItemList:GetRef(Index)
            local ItemData = ItemBaseTable[ItemInfo.ItemID]
            if not ItemData then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemID=%s not in table", SubmitType, ItemInfo.ItemID)
                return false
            end
            local ItemType = ItemData.category_ID
            if ItemType ~= DialogueSubmitItemInfo.ItemType then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemType=%s, DialogueSubmitItemInfo.ItemType=%s", SubmitType, ItemType, DialogueSubmitItemInfo.ItemType)
                return false
            end
            if ItemInfo.ItemNum ~= DialogueSubmitItemInfo.ItemTypeNumList:GetRef(Index) then
                G.log:warn("CheckDialogueSubmitItemInfo", "SubmitType=%s, ItemNum=%s, ItemTypeNumList.ItemNum=%s", SubmitType, ItemInfo.ItemNum, DialogueSubmitItemInfo.ItemTypeNumList:GetRef(Index))
                return false
            end
        end
        return true
    end

    return false
end

return MissionAvatarComponent
