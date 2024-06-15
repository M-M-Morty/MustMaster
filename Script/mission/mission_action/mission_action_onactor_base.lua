--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")
local json = require("thirdparty.json")
local MissionActionBase = require("mission.mission_action.mission_action_base")

---@type BP_MissionActionOnActor_Base_C
local MissionActionOnActorBase = Class(MissionActionBase)

function MissionActionOnActorBase:OnActive()
    Super(MissionActionOnActorBase).OnActive(self)
    if self.TargetActorID ~= "" then
        self:RunActionOnActorByID(self.TargetActorID, self:GenerateActionParam())
    elseif self.TargetTag ~= "" then
        self:RunActionOnActorByTag(self.TargetTag, self:GenerateActionParam())
    elseif UE.UBlueprintGameplayTagLibrary.IsGameplayTagValid(self.TargetGameplayTag) then
        self:RunActionOnActorByTag(self.TargetGameplayTag.TagName, self:GenerateActionParam())
    elseif self.TargetActorIDList:Length() ~= 0 then
        for i = 1, self.TargetActorIDList:Length() do
            local TargetActorID = self.TargetActorIDList:Get(i)
            self:RunActionOnActorByID(TargetActorID, self:GenerateActionParam())
        end
    end
end

return MissionActionOnActorBase
