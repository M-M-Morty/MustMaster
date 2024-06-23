--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local GlobalActorConst = require("common.const.global_actor_const")
local BPConst = require("common.const.blueprint_const")
local EdUtils = require("common.utils.ed_utils")

---@type BP_MissionEvent_Base_C
local MissionEventBase = UnLua.Class()

function MissionEventBase:OnInitialize()
    G.log:debug("xaelpeng", "MissionEventBase:OnInitialize %s", self:GetName())
    self.EventID = 0
    self.MissionEventID = self:GetOuterMissionEventID()
    self.Overridden.OnInitialize(self)
end

function MissionEventBase:OnDeinitialize()
    G.log:debug("xaelpeng", "MissionEventBase:OnDeinitialize %s", self:GetName())
    self.Overridden.OnDeinitialize(self)
    if self:IsRegistered() then
        local EventComponent = self:GetBPEventComponent()
        if EventComponent then
            EventComponent:UnregisterEvent(self)
        end
    end
end

function MissionEventBase:OnActive()
    G.log:debug("xaelpeng", "MissionEventBase:OnActive %s", self:GetName())
    local EventComponent = self:GetBPEventComponent()
    EventComponent:RegisterEvent(self)
    self.Overridden.OnActive(self)
end

function MissionEventBase:OnInactive()
    G.log:debug("xaelpeng", "MissionEventBase:OnInactive %s", self:GetName())
    local EventComponent = self:GetBPEventComponent()
    EventComponent:UnregisterEvent(self)
    self.Overridden.OnInactive(self)
end

function MissionEventBase:GenerateEventRegisterParam()
    return ""
end

function MissionEventBase:OnEvent(EventParamStr)
    G.log:debug("xaelpeng", "MissionEventBase:OnEvent %s Param:%s", self:GetName(), EventParamStr)
    self.Overridden.OnEvent(self, EventParamStr)
end

function MissionEventBase:IsRegistered()
    return self.EventID ~= 0
end

function MissionEventBase:GetEventID()
    return self.EventID
end

function MissionEventBase:SetEventID(EventID)
    self.EventID = EventID
end

function MissionEventBase:ResetEventID()
    self.EventID = 0
end

function MissionEventBase:ResetEventRecord()
    G.log:debug("xaelpeng", "MissionEventBase:ResetEventRecord %s", self:GetName())
    self.Overridden.ResetEventRecord(self)
end

function MissionEventBase:RegisterEventOnActorByID(ActorID, EventRegisterParamStr)
    G.log:debug("xaelpeng", "MissionEventBase:RegisterEventOnActorByID %s ActorID:%s Param:%s", self:GetName(), ActorID, EventRegisterParamStr)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RegisterEventOnMutableActorByID(ActorID, self.EventID, self:GenerateEventRegisterInfo(EventRegisterParamStr))
end

function MissionEventBase:UnregisterEventOnActorByID(ActorID)
    G.log:debug("xaelpeng", "MissionEventBase:UnregisterEventOnActorByID %s ActorID:%s EventID:%d", self:GetName(), ActorID, self.EventID)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:UnregisterEventOnMutableActorByID(ActorID, self.EventID)
end

function MissionEventBase:RegisterEventOnActorByTag(Tag, EventRegisterParamStr)
    G.log:debug("xaelpeng", "MissionEventBase:RegisterEventOnActorByTag %s Tag:%s Param:%s", self:GetName(), Tag, EventRegisterParamStr)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:RegisterEventOnMutableActorByTag(Tag, self.EventID, self:GenerateEventRegisterInfo(EventRegisterParamStr))
end

function MissionEventBase:UnregisterEventOnActorByTag(Tag)
    G.log:debug("xaelpeng", "MissionEventBase:UnregisterEventOnActorByTag %s Tag:%s EventID:%d", self:GetName(),
        Tag, self.EventID)
    local MutableActorManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MutableActorManager)
    MutableActorManager:UnregisterEventOnMutableActorByTag(Tag, self.EventID)
end

function MissionEventBase:GenerateEventRegisterInfo(EventRegisterParamStr)
    -- local RegisterInfoClass = EdUtils:GetUE5ObjectClass(BPConst.MissionEventRegisterInfo, true)
    local RegisterInfoClass = BPConst.GetMissionEventRegisterInfo()
    local RegisterInfo = RegisterInfoClass()
    RegisterInfo.EventID = self.EventID
    RegisterInfo.MissionEventID = self.MissionEventID
    RegisterInfo.Timestamp = os.time()
    RegisterInfo.EventType = UE.UHiBlueprintFunctionLibrary.GetObjectClassPath(self)
    RegisterInfo.Param = EventRegisterParamStr
    return RegisterInfo
end

function MissionEventBase:InitializeOnTarget(EventID, MissionEventID)
    self.EventID = EventID
    self.MissionEventID = MissionEventID
end

function MissionEventBase:RegisterOnTarget(Actor, EventRegisterParamStr)
    G.log:debug("xaelpeng", "MissionEventBase:RegisterOnTarget %s Actor:%s Param:%s", self:GetName(), Actor:GetName(), EventRegisterParamStr)
    self.Overridden.RegisterOnTarget(self, Actor, EventRegisterParamStr)
end

function MissionEventBase:UnregisterOnTarget(Actor)
    G.log:debug("xaelpeng", "MissionEventBase:UnregisterOnTarget %s Actor:%s", self:GetName(), Actor:GetName())
    self.Overridden.UnregisterOnTarget(self, Actor)
end

function MissionEventBase:DispatchEvent(EventParamStr)
    G.log:debug("xaelpeng", "MissionEventBase:DispatchEvent %s EventID:%d Param:%s", self:GetName(), self.EventID, EventParamStr)
    local MissionManager = UE.UHiGlobalActorLibrary.GetGlobalActorByName(GlobalActorConst.MissionManager)
    if MissionManager ~= nil then
        MissionManager:GetEventBPComponent():OnEvent(self.EventID, EventParamStr)
    end
end

-- function MissionEventBase:IsActiveOnClient()
--     return false
-- end

-- client
-- function MissionEventBase:RegisterOnTargetClient(Actor, EventRegisterParamStr)
--     G.log:debug("xaelpeng", "MissionEventBase:RegisterOnTargetClient %s Actor:%s Param:%s", self:GetName(), Actor:GetName(), EventRegisterParamStr)
--     self.Overridden.RegisterOnTargetClient(self, Actor, EventRegisterParamStr)
-- end

-- client
-- function MissionEventBase:UnregisterOnTargetClient(Actor)
--     G.log:debug("xaelpeng", "MissionEventBase:UnregisterOnTargetClient %s Actor:%s", self:GetName(), Actor:GetName())
--     self.Overridden.UnregisterOnTargetClient(self, Actor)
-- end


return MissionEventBase