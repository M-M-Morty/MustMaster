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

---@type BP_MissionAction_SetNpcToplogo_C
local MissionActionSetNpcToplogo = Class(MissionActionOnActorBase)

function MissionActionSetNpcToplogo:GenerateActionParam()
    local Param = {
        NewToplogo = self.NewToplogo,
        ToplogoImagePath = UE.UKismetSystemLibrary.GetPathName(self.ToplogoImage)
    }
    return json.encode(Param)
end

function MissionActionSetNpcToplogo:Run(Actor, ActionParamStr)
    Super(MissionActionSetNpcToplogo).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    Actor:SetNpcDisplayName(Param.NewToplogo)
    Actor:SetToplogoImgPath(Param.ToplogoImagePath)
end

function MissionActionSetNpcToplogo:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionSetNpcToplogo
