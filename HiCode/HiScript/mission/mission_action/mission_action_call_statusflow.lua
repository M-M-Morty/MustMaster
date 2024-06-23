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
    local Param = {}
    for Ind=1,self.TargetActorIDList:Length() do
        local ID = self.TargetActorIDList:Get(Ind)
        local enum, enumRaw = 0, 0
        if Ind <= self.eStatusFlows:Length() then
            enum = self.eStatusFlows:Get(Ind)
        end
        if Ind <= self.eStatusFlowsRaw:Length() then
            enumRaw = self.eStatusFlowsRaw:Get(Ind)
        end
        Param[ID] = {enum, enumRaw}
    end
    return json.encode(Param)
end

function M:Run(Actor, ActionParamStr)
    Super(M).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    if Actor and Actor.GetEditorID then
        local EditorID = Actor:GetEditorID()
        local enum, enumRaw = Param[EditorID][1], Param[EditorID][2]
        if Actor.Mission_Call_StatusFlow_Func then
            Actor:Mission_Call_StatusFlow_Func(enum, enumRaw)
        end
    end
end

function M:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return M
