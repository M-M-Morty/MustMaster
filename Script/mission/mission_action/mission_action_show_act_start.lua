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

---@type BP_MissionAction_ShowActStart_C
local MissionActionShowActStart = Class(MissionActionOnActorBase)

function MissionActionShowActStart:GenerateActionParam()
    local Param = {
        MissionActID = self.MissionActID
    }
    return json.encode(Param)
end

function MissionActionShowActStart:Run(Actor, ActionParamStr)
    Super(MissionActionShowActStart).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor.MissionAvatarComponent == nil then
        G.log:error("[MissionActionShowActStart:Run]", "Actor %s not has MissionAvatarComponent", Actor:GetName())
        return
    end
    Actor.MissionAvatarComponent:Client_ShowMissionActStart(Param.MissionActID)
end

function MissionActionShowActStart:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionShowActStart
