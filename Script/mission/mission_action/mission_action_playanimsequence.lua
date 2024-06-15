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
    local AnimPath = UE.UKismetSystemLibrary.GetPathName(self.AnimSequ)
    --G.log:debug("zsf", "[mission_event_playmontgae] %s %s %s", self.bLoop, AnimPath, LoadObject(AnimPath))
    local Param = {
        bLoop = self.bLoop,
        AnimPath = AnimPath,
    }
    return json.encode(Param)
end

function M:Run(Actor, ActionParamStr)
    Super(M).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor and Actor.MissionPlayAnimSequence then
        Actor:MissionPlayAnimSequence(Param.AnimPath, Param.bLoop)
    end
end

function M:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end


return M
