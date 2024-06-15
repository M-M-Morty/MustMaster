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
local MissionActionOnActorBase = require("mission.mission_action.mission_action_onactor_base")

---@type BP_MissionAction_SetActorVisibility_C
local MissionActionSetActorVisibility = Class(MissionActionOnActorBase)

function MissionActionSetActorVisibility:GenerateActionParam()
    local Param = {
        bHidden = self.bHidden,
    }
    return json.encode(Param)
end

function MissionActionSetActorVisibility:Run(Actor, ActionParamStr)
    Super(MissionActionSetActorVisibility).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor.VisibilityManagementComponent ~= nil then
        Actor.VisibilityManagementComponent:SetGameplayVisibility(not Param.bHidden)
    else
        G.log:error("xaelpeng", "MissionActionSetActorVisibility:Run Actor:%s has no VisibilityManagementComponent", Actor:GetName())
    end
end

function MissionActionSetActorVisibility:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end


return MissionActionSetActorVisibility
