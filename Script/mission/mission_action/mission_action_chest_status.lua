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
        ActionChestStatus = self.ActionChestStatus
    }
    return json.encode(Param)
end

function M:Run(Actor, ActionParamStr)
    Super(M).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    G.log:debug("zsf", "[chest_status] action chest status %s %s, %s", self, ActionParamStr, Actor.Server_MissionAction_ChestStatus)
    if Actor.Server_MissionAction_ChestStatus then
        Actor:Server_MissionAction_ChestStatus(Param.ActionChestStatus)
    end
end

function M:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end


return M
