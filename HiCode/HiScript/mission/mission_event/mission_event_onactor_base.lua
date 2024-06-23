--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local MissionEventBase = require("mission.mission_event.mission_event_base")

---@type BP_MissionEvent_OnActorBase_C

local MissionEventOnActorBase = Class(MissionEventBase)

function MissionEventOnActorBase:OnActive()
    Super(MissionEventOnActorBase).OnActive(self)
    if self.TargetActorID ~= "" then
        self:RegisterEventOnActorByID(self.TargetActorID, self:GenerateEventRegisterParam())
    elseif self.TargetTag ~= "" then
        self:RegisterEventOnActorByTag(self.TargetTag, self:GenerateEventRegisterParam())
    elseif UE.UBlueprintGameplayTagLibrary.IsGameplayTagValid(self.TargetGameplayTag) then
        self:RegisterEventOnActorByTag(self.TargetGameplayTag.TagName, self:GenerateEventRegisterParam())
    elseif self.TargetActorIDList:Length() ~= 0 then
        for i = 1, self.TargetActorIDList:Length() do
            local TargetActorID = self.TargetActorIDList:Get(i)
            self:RegisterEventOnActorByID(TargetActorID, self:GenerateEventRegisterParam())
        end
    end
end

function MissionEventOnActorBase:OnInactive()
    if self.TargetActorID ~= "" then
        self:UnregisterEventOnActorByID(self.TargetActorID)
    elseif self.TargetTag ~= "" then
        self:UnregisterEventOnActorByTag(self.TargetTag)
    elseif self.TargetActorIDList:Length() ~= 0 then
        for i = 1, self.TargetActorIDList:Length() do
            local TargetActorID = self.TargetActorIDList:Get(i)
            self:UnregisterEventOnActorByID(TargetActorID)
        end
    end
    Super(MissionEventOnActorBase).OnInactive(self)
end


return MissionEventOnActorBase