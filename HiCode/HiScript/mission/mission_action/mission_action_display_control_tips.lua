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

---@type BP_MissionAction_DisplayControlTips_C
local MissionActionDisplayControlTips = Class(MissionActionBase)

function MissionActionDisplayControlTips:OnActive()
    Super(MissionActionDisplayControlTips).OnActive(self)
    self:RunActionOnActorByTag("HiGamePlayer", self:GenerateActionParam())
end

function MissionActionDisplayControlTips:GenerateActionParam()
    local Param = {
        ControlKey = G.GetObjectName(self.ControlKey),
        ControllDescriptionID = self.ControllDescriptionID,
        ExitTime = self.ExitTime,
    }
    return json.encode(Param)
end

function MissionActionDisplayControlTips:Run(Actor, ActionParamStr)
    Super(MissionActionDisplayControlTips).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor.MissionAvatarComponent ~= nil then
        Actor.MissionAvatarComponent:Client_DisplayControlTips(Param.ControlKey, Param.ControllDescriptionID, Param.ExitTime)
    end
end

function MissionActionDisplayControlTips:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionDisplayControlTips
