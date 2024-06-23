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
local M = Class(MissionActionOnActorBase)

function M:GenerateActionParam()
    local Param = {
    }
    return json.encode(Param)
end

function M:Run(Actor, ActionParamStr)
    Super(M).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    --G.log:debug("zsf", "[mission_action_stopmontage] %s %s", G.GetDisplayName(Actor), ActionParamStr)
    if Actor and Actor.MissionStopMontage then
        Actor:MissionStopMontage()
    end
end

function M:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end


return M
