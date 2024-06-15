--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local BPConst = require ("common.const.blueprint_const")
local SubsystemUtils = require("common.utils.subsystem_utils")
local MissionUtils = require ("mission.mission_utils")
local GameConstData = require("common.data.game_const_data").data


---@type BP_MissionDataComponent_C
local MissionDataComponent = UnLua.Class()

function MissionDataComponent:Initialize(Initializer)
    self.Subscribers = {}
end

function MissionDataComponent:OnLoadFromDatabase(GameplayProperties)
    G.log:debug("xaelpeng", "MissionDataComponent:OnLoadFromDatabase %s", self:GetName())
    self:GenerateActiveMissionMap()
end

function MissionDataComponent:AddSubscriber(SubscriberInfo)
    self.Subscribers[SubscriberInfo.ActorID] = SubscriberInfo
    -- 同步任务数据
    self:SyncMissionActs(SubscriberInfo.ActorID)
    self:SyncMissionRecords(SubscriberInfo.ActorID)
    self:SyncActiveMissions(SubscriberInfo.ActorID)
end

function MissionDataComponent:RemoveSubscriber(ActorID)
    self.Subscribers[ActorID] = nil
end

function MissionDataComponent:GetMissionGroupRecord(MissionGroupID)
    return self.MissionGroupRecords:FindRef(MissionGroupID)
end

function MissionDataComponent:CreateMissionGroupRecord(MissionGroupID)
    local Class = BPConst.GetMissionGroupRecordClass()
    local Record = Class()
    Record.State = Enum.EHiMissionState.Initialize
    self.MissionGroupRecords:Add(MissionGroupID, Record)
    return self.MissionGroupRecords:FindRef(MissionGroupID)
end

function MissionDataComponent:GetMissionActRecord(MissionActID)
    return self.MissionActRecords:FindRef(MissionActID)
end

function MissionDataComponent:CreateMissionActRecord(MissionActID)
    local Class = BPConst.GetMissionActRecordClass()
    local Record = Class()
    Record.State = Enum.EMissionActState.Initialize
    Record.MissionActID = MissionActID
    Record.InitTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    self.MissionActRecords:Add(MissionActID, Record)
    return self.MissionActRecords:FindRef(MissionActID)
end

function MissionDataComponent:GetMissionRecord(MissionID)
    return self.MissionRecords:FindRef(MissionID)
end

function MissionDataComponent:CreateMissionRecord(MissionID)
    local Class = BPConst.GetMissionRecordClass()
    local Record = Class()
    Record.State = Enum.EHiMissionState.Initialize
    self.MissionRecords:Add(MissionID, Record)
    return self.MissionRecords:FindRef(MissionID)
end

function MissionDataComponent:GetMissionEventRecord(MissionEventID)
    return self.MissionEventRecords:FindRef(MissionEventID)
end

function MissionDataComponent:CreateMissionEventRecord(MissionEventID)
    local Class = BPConst.GetMissionEventRecordClass()
    local Record = Class()
    Record.State = Enum.EHiMissionState.Initialize
    Record.Progress = 0
    self.MissionEventRecords:Add(MissionEventID, Record)
    return self.MissionEventRecords:FindRef(MissionEventID)
end

function MissionDataComponent:OnMissionGroupStart(MissionIdentifier)
    if MissionIdentifier.MissionGroupID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionGroupStart Invalid MissionGroupID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionGroupStart MissionGroupID:%d", MissionIdentifier.MissionGroupID)
    local MissionGroupRecord = self:GetMissionGroupRecord(MissionIdentifier.MissionGroupID)
    if MissionGroupRecord == nil then
        MissionGroupRecord = self:CreateMissionGroupRecord(MissionIdentifier.MissionGroupID)
    end
    if MissionGroupRecord.State == Enum.EHiMissionState.Initialize then
        MissionGroupRecord.State = Enum.EHiMissionState.Start
        self:BroadcastMissionGroupStateChange(MissionIdentifier, Enum.EHiMissionState.Start)
    else
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionGroupStart MissionGroupID:%d State:%s Mismatch", MissionIdentifier.MissionGroupID, MissionGroupRecord.State)
    end
end

function MissionDataComponent:OnMissionGroupFinish(MissionIdentifier)
    if MissionIdentifier.MissionGroupID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionGroupFinish Invalid MissionGroupID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionGroupFinish MissionGroupID:%d", MissionIdentifier.MissionGroupID)
    local MissionGroupRecord = self:GetMissionGroupRecord(MissionIdentifier.MissionGroupID)
    if MissionGroupRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionGroupFinish MissionGroupID:%d not found", MissionIdentifier.MissionGroupID)
        return
    end
    if MissionGroupRecord.State == Enum.EHiMissionState.Complete then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionGroupFinish MissionGroupID:%d is already finish", MissionIdentifier.MissionGroupID)
        return
    end
    MissionGroupRecord.State = Enum.EHiMissionState.Complete
    self:BroadcastMissionGroupStateChange(MissionIdentifier, Enum.EHiMissionState.Complete)
end

function MissionDataComponent:OnMissionActStart(MissionIdentifier)
    if MissionIdentifier.MissionActID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionActStart Invalid MissionActID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionActStart MissionActID:%d", MissionIdentifier.MissionActID)
    if self:GetMissionActRecord(MissionIdentifier.MissionActID) ~= nil then
        G.log:error("hangyuewang", "MissionDataComponent:OnMissionActStart MissionActID:(%d) already exists", MissionIdentifier.MissionActID)
        return
    end

    local MissionActRecord = self:CreateMissionActRecord(MissionIdentifier.MissionActID)
    -- 通知MissionAvatarComponent
    self:BroadcastAddMissionAct(MissionIdentifier.MissionActID)
    self:BroadcastMissionActStateChange(MissionIdentifier, MissionActRecord.State)
end

function MissionDataComponent:OnMissionActFinish(MissionIdentifier)
    if MissionIdentifier.MissionActID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionActFinish Invalid MissionActID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionActFinish MissionActID:%d", MissionIdentifier.MissionActID)
    local MissionActRecord = self:GetMissionActRecord(MissionIdentifier.MissionActID)
    if MissionActRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionActFinish MissionActID:%d not found", MissionIdentifier.MissionActID)
        return
    end
    if MissionActRecord.State == Enum.EMissionActState.Complete then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionActFinish MissionActID:%d is already finish", MissionIdentifier.MissionActID)
        return
    end
    MissionActRecord.State = Enum.EMissionActState.Complete
    self:BroadcastMissionActStateChange(MissionIdentifier, MissionActRecord.State)
end

function MissionDataComponent:OnMissionStart(MissionIdentifier)
    if MissionIdentifier.MissionID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionStart Invalid MissionID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionStart MissionID:%d", MissionIdentifier.MissionID)
    if self:GetMissionRecord(MissionIdentifier.MissionID) ~= nil then
        G.log:error("hangyuewang", "MissionDataComponent:OnMissionStart MissionID:(%d) already exists", MissionIdentifier.MissionID)
        return
    end

    local MissionRecord = self:CreateMissionRecord(MissionIdentifier.MissionID)
    MissionRecord.State = Enum.EHiMissionState.Start
    self:AddActiveMission(MissionIdentifier.MissionID)
    self:BroadcastAddActiveMission(MissionIdentifier.MissionID)
    self:BroadcastMissionStateChange(MissionIdentifier, Enum.EHiMissionState.Start)
end

function MissionDataComponent:OnMissionFinish(MissionIdentifier)
    if MissionIdentifier.MissionID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionFinish Invalid MissionID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionFinish MissionID:%d", MissionIdentifier.MissionID)
    local MissionRecord = self:GetMissionRecord(MissionIdentifier.MissionID)
    if MissionRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionFinish MissionID:%d not found", MissionIdentifier.MissionID)
        return
    end
    if MissionRecord.State == Enum.EHiMissionState.Complete then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionFinish MissionID:%d is already finish", MissionIdentifier.MissionID)
        return
    end
    MissionRecord.State = Enum.EHiMissionState.Complete
    self:BroadcastMissionStateChange(MissionIdentifier, Enum.EHiMissionState.Complete)
    self:RemoveActiveMission(MissionIdentifier.MissionID)
    self:BroadcastRemoveActiveMission(MissionIdentifier.MissionID, true)
end

function MissionDataComponent:OnMissionEventStart(MissionIdentifier, MissionEventID)
    if MissionEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventStart Invalid MissionEventID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionEventStart MissionEventID:%d", MissionEventID)
    local MissionEventRecord = self:GetMissionEventRecord(MissionEventID)
    if MissionEventRecord == nil then
        MissionEventRecord = self:CreateMissionEventRecord(MissionEventID)
    end
    if MissionEventRecord.State == Enum.EHiMissionState.Initialize then
        MissionEventRecord.State = Enum.EHiMissionState.Start
        self:AddActiveMissionEvent(MissionEventID)
        self:BroadcastAddActiveMissionEvent(MissionIdentifier.MissionID, MissionEventID)
        self:BroadcastMissionEventStateChange(MissionIdentifier, MissionEventID, Enum.EHiMissionState.Start)
    else
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventStart MissionEventID:%d State:%s Mismatch", MissionEventID, MissionEventRecord.State)
    end
end

function MissionDataComponent:OnMissionEventResume(MissionIdentifier, MissionEventID)
    if MissionEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventResume Invalid MissionEventID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionEventResume MissionEventID:%d", MissionEventID)
    local MissionEventRecord = self:GetMissionEventRecord(MissionEventID)
    if MissionEventRecord == nil then
        MissionEventRecord = self:CreateMissionEventRecord(MissionEventID)
    end
    if MissionEventRecord.State == Enum.EHiMissionState.Initialize then
        MissionEventRecord.State = Enum.EHiMissionState.Start
        self:AddActiveMissionEvent(MissionEventID)
        self:BroadcastAddActiveMissionEvent(MissionIdentifier.MissionID, MissionEventID)
        self:BroadcastMissionEventStateChange(MissionIdentifier, MissionEventID, Enum.EHiMissionState.Start)
    else
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventResume MissionEventID:%d State:%s Mismatch", MissionEventID, MissionEventRecord.State)
    end
end

function MissionDataComponent:OnMissionEventFinish(MissionIdentifier, MissionEventID)
    if MissionEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventFinish Invalid MissionEventID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionEventFinish MissionEventID:%d", MissionEventID)
    local MissionEventRecord = self:GetMissionEventRecord(MissionEventID)
    if MissionEventRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventFinish MissionEventID:%d not found", MissionEventID)
        return
    end
    if MissionEventRecord.State == Enum.EHiMissionState.Complete then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventFinish MissionEventID:%d is already finish", MissionEventID)
        return
    end
    MissionEventRecord.State = Enum.EHiMissionState.Complete
    -- self.MissionEventTrackTargets:Remove(MissionEventID)
    self:BroadcastMissionEventStateChange(MissionIdentifier, MissionEventID, Enum.EHiMissionState.Complete)
    self:RemoveActiveMissionEvent(MissionEventID)
    self:BroadcastRemoveActiveMissionEvent(MissionIdentifier.MissionID, MissionEventID)
end

function MissionDataComponent:OnMissionEventProgressUpdate(MissionIdentifier, MissionEventID, Progress)
    if MissionEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventProgressUpdate Invalid MissionEventID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionEventProgressUpdate MissionEventID:%d Progress:%d", MissionEventID, Progress)
    local MissionEventRecord = self:GetMissionEventRecord(MissionEventID)
    if MissionEventRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionProgressUpdate MissionEventID:%d not found", MissionEventID)
        return
    end
    MissionEventRecord.Progress = Progress
    if MissionUtils.IsMissionStateActive(MissionEventRecord.State) then
        self:UpdateActiveMissionEventProgress(MissionEventID, Progress)
        self:BroadcastUpdateActiveMissionEventProgress(MissionIdentifier.MissionID, MissionEventID, Progress)
    end
end

function MissionDataComponent:OnMissionEventTrackTargetUpdate(MissionIdentifier, MissionEventID, RawEventID, TrackTargetList)
    if MissionEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventTrackTargetUpdate Invalid MissionEventID 0")
        return
    end
    if RawEventID == 0 then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventTrackTargetUpdate Invalid RawEventID 0")
        return
    end

    G.log:debug("xaelpeng", "MissionDataComponent:OnMissionEventTrackTargetUpdate MissionEventID:%d", MissionEventID)
    local MissionEventRecord = self:GetMissionEventRecord(MissionEventID)
    if MissionEventRecord == nil then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventTrackTargetUpdate MissionEventID:%d not found", MissionEventID)
        return
    end
    if MissionEventRecord.State == Enum.EHiMissionState.Complete then
        G.log:error("xaelpeng", "MissionDataComponent:OnMissionEventTrackTargetUpdate MissionEventID:%d is already finish", MissionEventID)
        return
    end
    -- self.MissionEventTrackTargets:Add(MissionEventID, TrackTarget)
    if MissionUtils.IsMissionStateActive(MissionEventRecord.State) then
        self:UpdateActiveMissionEventTrackTarget(MissionEventID, RawEventID, TrackTargetList)
        self:BroadcastUpdateActiveMissionEventTrackTarget(MissionIdentifier.MissionID, MissionEventID, RawEventID, TrackTargetList)
    end
end

function MissionDataComponent:GenerateActiveMissionMap()
    self.ActiveMissionMap:Clear()

    local MissionIDs = self.MissionRecords:Keys()
    for i = 1, MissionIDs:Length() do
        local MissionID = MissionIDs:Get(i)
        if MissionID == 0 then
            G.log:error("xaelpeng", "MissionDataComponent:GenerateActiveMissionMap Invalid MissionID 0")
        else
            self:AddActiveMission(MissionID)
        end
    end

    -- 先去掉ActiveMissionEvent的恢复
    -- local MissionEventIDs = self.MissionEventRecords:Keys()
    -- for i = 1, MissionEventIDs:Length() do
    --     local MissionEventID = MissionEventIDs:Get(i)
    --     self:AddActiveMissionEvent(MissionEventID)
    -- end
    -- G.log:debug("xaelpeng", "MissionDataComponent:GenerateActiveMissionMap MissionIDs:%d MissionEventIDs:%s", MissionIDs:Length(), MissionEventIDs:Length())
end

function MissionDataComponent:AddActiveMission(MissionID)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local MissionDataClass = BPConst.GetMissionDataClass()
    local MissionRecord = self.MissionRecords:Find(MissionID)
    G.log:debug("xaelpeng", "MissionDataComponent:AddActiveMission MissionID:%d State:%s %s", MissionID, MissionRecord.State, Enum.EHiMissionState.Start)
    if MissionUtils.IsMissionStateActive(MissionRecord.State) then
        local MissionData = MissionDataClass()
        MissionData.Identifier = MissionFlowSubsystem:GetMissionIdentifier(MissionID)
        MissionData.TrackIconType = MissionFlowSubsystem:GetMissionTrackIconType(MissionID)
        MissionData.Record = MissionRecord
        MissionData.bEventStarted = false
        self.ActiveMissionMap:Add(MissionID, MissionData)
    end
end

function MissionDataComponent:RemoveActiveMission(MissionID)
    self.ActiveMissionMap:Remove(MissionID)
end

function MissionDataComponent:AddActiveMissionEvent(MissionEventID)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local MissionIdentifier = MissionFlowSubsystem:GetMissionEventIdentifier(MissionEventID)
    local MissionEventRecord = self.MissionEventRecords:FindRef(MissionEventID)
    local MissionEventDataClass = BPConst.GetMissionEventDataClass()
    local MissionData = self.ActiveMissionMap:FindRef(MissionIdentifier.MissionID)
    G.log:debug("xaelpeng", "MissionDataComponent:AddActiveMissionEvent MissionEventID:%d State:%s", MissionEventID, MissionEventRecord.State)
    if MissionUtils.IsMissionStateActive(MissionEventRecord.State) then
        if MissionData ~= nil then
            MissionData.bEventStarted = true
            local MissionEventData = MissionEventDataClass()
            MissionEventData.MissionEventID = MissionEventID
            MissionEventData.Record = MissionEventRecord
            -- local TrackTarget = self.MissionEventTrackTargets:FindRef(MissionEventID)
            -- if TrackTarget ~= nil then
            --     MissionEventData.TrackTarget = TrackTarget
            -- else
            --     MissionEventData.TrackTarget.TrackTargetType = Enum.ETrackTargetType.None
            -- end
            MissionData.ActiveEvents:Add(MissionEventData)
        else
            G.log:error("xaelpeng", "MissionDataComponent:AddActiveMissionEvent MissionEventID:%d MissionID:%d not found", MissionEventID, MissionIdentifier.MissionID)
        end
    
    end
end

function MissionDataComponent:RemoveActiveMissionEvent(MissionEventID)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local MissionIdentifier = MissionFlowSubsystem:GetMissionEventIdentifier(MissionEventID)
    local MissionData = self.ActiveMissionMap:FindRef(MissionIdentifier.MissionID)
    if MissionData ~= nil then
        for i = 1, MissionData.ActiveEvents:Length() do
            local MissionEventData = MissionData.ActiveEvents:GetRef(i)
            if MissionEventData.MissionEventID == MissionEventID then
                MissionData.ActiveEvents:Remove(i)
                break
            end
        end
    else
        G.log:error("xaelpeng", "MissionDataComponent:RemoveActiveMissionEvent MissionEventID:%d MissionID:%d not found", MissionEventID, MissionIdentifier.MissionID)
    end
end

function MissionDataComponent:UpdateActiveMissionEventProgress(MissionEventID, Progress)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local MissionIdentifier = MissionFlowSubsystem:GetMissionEventIdentifier(MissionEventID)
    local MissionData = self.ActiveMissionMap:FindRef(MissionIdentifier.MissionID)
    if MissionData ~= nil then
        for i = 1, MissionData.ActiveEvents:Length() do
            local MissionEventData = MissionData.ActiveEvents:GetRef(i)
            if MissionEventData.MissionEventID == MissionEventID then
                MissionEventData.Record.Progress = Progress
                break
            end
        end
    else
        G.log:error("xaelpeng", "MissionDataComponent:UpdateActiveMissionEventProgress MissionEventID:%d MissionID:%d not found", MissionEventID, MissionIdentifier.MissionID)
    end
end

function MissionDataComponent:UpdateActiveMissionEventTrackTarget(MissionEventID, RawEventID, TrackTargetList)
    local MissionFlowSubsystem = SubsystemUtils.GetMissionFlowSubsystem(self:GetOwner())
    local MissionIdentifier = MissionFlowSubsystem:GetMissionEventIdentifier(MissionEventID)
    local MissionData = self.ActiveMissionMap:FindRef(MissionIdentifier.MissionID)
    if MissionData ~= nil then
        for i = 1, MissionData.ActiveEvents:Length() do
            local MissionEventData = MissionData.ActiveEvents:GetRef(i)
            if MissionEventData.MissionEventID == MissionEventID then
                MissionUtils.UpdateTrackTargetList(MissionEventData.TrackTargetList, RawEventID, TrackTargetList)
                break
            end
        end
    else
        G.log:error("xaelpeng", "MissionDataComponent:UpdateActiveMissionEventTrackTarget MissionEventID:%d MissionID:%d not found", MissionEventID, MissionIdentifier.MissionID)
    end
end

function MissionDataComponent:SyncMissionRecords(SubscriberID)
    if self.MissionRecords:Length() == 0 then
        return
    end

    local MissionDataClass = BPConst.GetMissionRecordClass()
    local MissionDataList = UE.TArray(MissionDataClass)
    local MissionIDs = self.MissionRecords:Keys()
    for i = 1, MissionIDs:Length() do 
        local MissionID = MissionIDs:Get(i)
        local MissionData = self.MissionRecords:FindRef(MissionID)
        MissionData.MissionID = MissionID
        MissionDataList:Add(MissionData)
    end

    G.log:debug("MissionDataComponent", "SyncMissionRecords Num=%s", MissionDataList:Num())
    local SubscriberInfo = self.Subscribers[SubscriberID]
    SubscriberInfo.Dispatcher:SyncMissionRecords(SubscriberID, MissionDataList)
end

function MissionDataComponent:SyncActiveMissions(SubscriberID)
    local MissionDataClass = BPConst.GetMissionDataClass()
    local MissionDataList = UE.TArray(MissionDataClass)
    local MissionIDs = self.ActiveMissionMap:Keys()
    local SubscriberInfo = self.Subscribers[SubscriberID]
    for i = 1, MissionIDs:Length() do
        local MissionID = MissionIDs:Get(i)
        local MissionData = self.ActiveMissionMap:FindRef(MissionID)
        G.log:debug("xaelpeng", "MissionDataComponent:SyncActiveMissions MissionData:%d,%d,%d", MissionData.Identifier.MissionGroupID, MissionData.Identifier.MissionActID, MissionData.Identifier.MissionID)
        MissionDataList:Add(MissionData)
    end
    G.log:debug("xaelpeng", "MissionDataComponent:SyncActiveMissions finish")

    SubscriberInfo.Dispatcher:SyncActiveMissions(SubscriberID, MissionDataList)
end

function MissionDataComponent:SyncMissionActs(SubscriberID)
    if self.MissionActRecords:Length() == 0 then
        return
    end

    local MissionActDataClass = BPConst.GetMissionActRecordClass()
    local MissionActDataList = UE.TArray(MissionActDataClass)
    local MissionActIDs = self.MissionActRecords:Keys()
    for i = 1, MissionActIDs:Length() do 
        local MissionActID = MissionActIDs:Get(i)
        local MissionActData = self.MissionActRecords:FindRef(MissionActID)
        MissionActDataList:Add(MissionActData)
    end

    G.log:debug("MissionDataComponent", "SyncMissionActs Num=%s", MissionActDataList:Num())
    local SubscriberInfo = self.Subscribers[SubscriberID]
    SubscriberInfo.Dispatcher:SyncMissionActs(SubscriberID, MissionActDataList)
end

function MissionDataComponent:BroadcastAddMissionAct(MissionActID)
    local MissionActData = self.MissionActRecords:FindRef(MissionActID)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncAddMissionAct(SubscriberID, MissionActID, MissionActData)
    end
end

function MissionDataComponent:BroadcastAddActiveMission(MissionID)
    local MissionData = self.ActiveMissionMap:FindRef(MissionID)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncAddActiveMission(SubscriberID, MissionID, MissionData)
    end
end

function MissionDataComponent:BroadcastRemoveActiveMission(MissionID, bFinish)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncRemoveActiveMission(SubscriberID, MissionID, bFinish)
    end
end

function MissionDataComponent:BroadcastAddActiveMissionEvent(MissionID, MissionEventID)
    local MissionData = self.ActiveMissionMap:FindRef(MissionID)
    if MissionData == nil then
        return
    end
    for i = 1, MissionData.ActiveEvents:Length() do
        local MissionEventData = MissionData.ActiveEvents:GetRef(i)
        if MissionEventData.MissionEventID == MissionEventID then
            for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
                SubscriberInfo.Dispatcher:SyncAddActiveMissionEvent(SubscriberID, MissionID, MissionEventData)
            end
            break
        end
    end
end

function MissionDataComponent:BroadcastRemoveActiveMissionEvent(MissionID, MissionEventID)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncRemoveActiveMissionEvent(SubscriberID, MissionID, MissionEventID)
    end
end

function MissionDataComponent:BroadcastUpdateActiveMissionEventProgress(MissionID, MissionEventID, Progress)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncUpdateActiveMissionEventProgress(SubscriberID, MissionID, MissionEventID, Progress)
    end
end

function MissionDataComponent:BroadcastUpdateActiveMissionEventTrackTarget(MissionID, MissionEventID, RawEventID, TrackTargetList)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncUpdateActiveMissionEventTrackTarget(SubscriberID, MissionID, MissionEventID, RawEventID, TrackTargetList)
    end
end

function MissionDataComponent:BroadcastMissionGroupStateChange(MissionIdentifier, State)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:NotifyMissionGroupStateChange(SubscriberID, MissionIdentifier, State)
    end
end

function MissionDataComponent:BroadcastMissionActStateChange(MissionIdentifier, State)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:NotifyMissionActStateChange(SubscriberID, MissionIdentifier, State)
    end
end

function MissionDataComponent:BroadcastMissionStateChange(MissionIdentifier, State)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:NotifyMissionStateChange(SubscriberID, MissionIdentifier, State)
    end
end

function MissionDataComponent:BroadcastMissionEventStateChange(MissionIdentifier, MissionEventID, State)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:NotifyMissionEventStateChange(SubscriberID, MissionIdentifier, MissionEventID, State)
    end
end

function MissionDataComponent:AddMissionActDialogueRecord(MissionActID, DialogueRecord)
    local MissionActRecord = self.MissionActRecords:FindRef(MissionActID)
    if not MissionActRecord then
        G.log:warn("[AddMissionActDialogueRecord]", "MissionActRecord not found, MissionActID=%s", MissionActID)
        return
    end

    if MissionActRecord.Dialogues:Num() > GameConstData.MAX_DIALOGUE_NUM_PER_MISSION_ACT.IntValue then
        G.log:warn("[AddMissionActDialogueRecord]", "MissionActRecord length exceeds, MissionActID=%s, Num=%s", 
            MissionActID, MissionActRecord.Dialogues:Num())
        return
    end
    MissionActRecord.Dialogues:Add(DialogueRecord)
    self:BroadcastAddMissionActDialogue(MissionActID, DialogueRecord)
end

function MissionDataComponent:BroadcastAddMissionActDialogue(MissionActID, DialogueRecord)
    for SubscriberID, SubscriberInfo in pairs(self.Subscribers) do
        SubscriberInfo.Dispatcher:SyncAddMissionActDialogueRecord(SubscriberID, MissionActID, DialogueRecord)
    end
end

function MissionDataComponent:SetMissionActState(MissionIdentifier, NewState)
    local MissionActID = MissionIdentifier.MissionActID
    local MissionActRecord = self:GetMissionActRecord(MissionActID)
    if MissionActRecord == nil then
        G.log:error("[MissionDataComponent:SetMissionActState]", "MissionActID:%d not found", MissionActID)
        return
    end
    if MissionActRecord.State == NewState then
        G.log:error("[MissionDataComponent:SetMissionActState]", "MissionActID:%d is already in (%d) state", MissionActID, NewState)
        return
    end
    -- 目前限制任务幕状态改变每次只能向后一步
    if NewState ~= MissionActRecord.State + 1 then
        G.log:error("[MissionDataComponent:SetMissionActState]", "MissionActID:%d state check failed OldState:(%d) NewState:(%d)", 
            MissionActID, MissionActRecord.State, NewState)
        return
    end

    MissionActRecord.State = NewState
    if NewState == Enum.EMissionActState.Initialize then
        -- 记录激活任务的时间
        MissionActRecord.InitTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    elseif NewState == Enum.EMissionActState.Start then
        -- 记录接取任务的时间
        MissionActRecord.StartTime = UE.UHiUtilsFunctionLibrary.GetNowTimestamp()
    end

    self:BroadcastMissionActStateChange(MissionIdentifier, MissionActRecord.State)
end

return MissionDataComponent
