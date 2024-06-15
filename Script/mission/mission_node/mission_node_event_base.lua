--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")

local MissionNodeBase = require ("mission.mission_node.mission_node_base")
local BPConst = require("common.const.blueprint_const")


---@type BP_MissionNode_EventBase_C
local MissionNodeEventBase = Class(MissionNodeBase)

function MissionNodeEventBase:K2_InitializeInstance()
    Super(MissionNodeEventBase).K2_InitializeInstance(self)
    self.TrackingTargetEvents = {}
end

function MissionNodeEventBase:OnNodeStart()
    G.log:debug("xaelpeng", "MissionNodeEventBase:OnNodeStart MissionEventID:%d|%d|%d|%d",
        self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), self.MissionEventID)
    if self.MissionEventID ~= 0 then
        self:GetDataComponent():OnMissionEventStart(self:GetMissionIdentifier(), self.MissionEventID)
    end
end

function MissionNodeEventBase:OnNodeResume()
    G.log:debug("MissionNodeEventBase", "OnNodeResume MissionEventID:%d|%d|%d|%d",
        self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), self.MissionEventID)
    if self.MissionEventID ~= 0 then
        self:GetDataComponent():OnMissionEventResume(self:GetMissionIdentifier(), self.MissionEventID)
    end
end

function MissionNodeEventBase:K2_ExecuteInput(PinName)
    if not self.bHasEnter then
        self.bHasEnter = true
    else
        if self.bResetOnReEnter then
            self:ResetEvents()
        end
    end
    Super(MissionNodeEventBase).K2_ExecuteInput(self, PinName)
end

function MissionNodeEventBase:OnNodeFinish()
    G.log:debug("xaelpeng", "MissionNodeEventBase:OnNodeFinish MissionEventID:%d|%d|%d|%d",
        self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), self.MissionEventID)
    -- clear track targets
    if self:GetOuterMissionEventID() ~= 0 then
        local TrackTargetList = UE.TArray(BPConst.GetTrackTargetClass())
        for EventID, _ in pairs(self.TrackingTargetEvents) do
            self:GetDataComponent():OnMissionEventTrackTargetUpdate(self:GetMissionIdentifier(), self:GetOuterMissionEventID(), EventID, TrackTargetList)
        end
    end
    if self.MissionEventID ~= 0 then
        self:GetDataComponent():OnMissionEventFinish(self:GetMissionIdentifier(), self.MissionEventID)
    end
end

function MissionNodeEventBase:OnLoad(EventSaveData)
    self.bHasEnter = true
end

function MissionNodeEventBase:ResetEvents()
    local EventKeys = self.Events:Keys()
    for i = 1, EventKeys:Length() do
        local EventKey = EventKeys:Get(i)
        local Event = self.Events:Find(EventKey)
        Event:StopWaitEvent()
        Event:ResetEventRecord()
    end
    self:OnResetEvents()
end

function MissionNodeEventBase:OnResetEvents()
    self.Overridden.OnResetEvents(self)
end

function MissionNodeEventBase:GetOuterMissionEventID()
    if self.MissionEventID ~= 0 then
        return self.MissionEventID
    end
    return self:GetMissionFragmentID()
end


function MissionNodeEventBase:UpdateMissionEventProgress(Progress)
    G.log:debug("xaelpeng", "MissionNodeEventBase:UpdateMissionEventProgress MissionEventID:%d|%d|%d|%d Progress:%d",
        self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), self.MissionEventID, Progress)
    if self.MissionEventID ~= 0 then
        self:GetDataComponent():OnMissionEventProgressUpdate(self:GetMissionIdentifier(), self.MissionEventID, Progress)
    end
end

function MissionNodeEventBase:UpdateMissionEventTrackTarget(TrackTarget, EventName)
    local OuterMissionEventID = self:GetOuterMissionEventID()
    G.log:debug("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTarget MissionEventID:%d|%d|%d|%d",
        self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), OuterMissionEventID)
    local Event = self:GetEvent(EventName)
    if Event == nil then
        G.log:error("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTarget MissionEventID:%d|%d|%d|%d Event:%s not found", 
            self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), OuterMissionEventID, EventName)
        return
    end
    if Event:GetEventID() == 0 then
        G.log:error("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTarget MissionEventID:%d|%d|%d|%d Event:%s not active", 
            self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(), OuterMissionEventID, EventName)
        return
    end
    if OuterMissionEventID == 0 then
        return
    end
    TrackTarget.RawEventID = Event:GetEventID()
    local TrackTargetList = UE.TArray(BPConst.GetTrackTargetClass())
    TrackTargetList:Add(TrackTarget)
    self.TrackingTargetEvents[Event:GetEventID()] = true
    self:GetDataComponent():OnMissionEventTrackTargetUpdate(self:GetMissionIdentifier(), OuterMissionEventID, Event:GetEventID(), TrackTargetList)
end

function MissionNodeEventBase:UpdateMissionEventTrackTargetList(TrackTargetList, EventName)
    local OuterMissionEventID = self:GetOuterMissionEventID()
    G.log:debug("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTargetList MissionEventID:%d|%d|%d|%d", self:GetMissionGroupID(), self:GetMissionActID(), self:GetMissionID(),
        OuterMissionEventID)
    local Event = self:GetEvent(EventName)
    if Event == nil then
        G.log:error("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTargetList MissionEventID:%d|%d|%d|%d Event:%s not found", self:GetMissionGroupID(),
            self:GetMissionActID(), self:GetMissionID(), OuterMissionEventID, EventName)
        return
    end
    if Event:GetEventID() == 0 then
        G.log:error("xaelpeng", "MissionNodeEventBase:UpdateMissionEventTrackTargetList MissionEventID:%d|%d|%d|%d Event:%s not active", self:GetMissionGroupID(),
            self:GetMissionActID(), self:GetMissionID(), OuterMissionEventID, EventName)
        return
    end
    for i = 1, TrackTargetList:Length() do
        local TrackTarget = TrackTargetList:GetRef(i)
        TrackTarget.RawEventID = Event:GetEventID()
    end
    self.TrackingTargetEvents[Event:GetEventID()] = true
    self:GetDataComponent():OnMissionEventTrackTargetUpdate(self:GetMissionIdentifier(), OuterMissionEventID, Event:GetEventID(), TrackTargetList)
end

function MissionNodeEventBase:GetLightOnActorList()
    return nil
end


return MissionNodeEventBase