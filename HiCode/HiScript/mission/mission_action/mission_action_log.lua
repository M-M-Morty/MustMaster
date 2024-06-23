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
local BPConst = require("common.const.blueprint_const")

---@type BP_MissionAction_Log_C
local MissionActionLog = Class(MissionActionBase)

function MissionActionLog:GenerateActionParam()
    local Param = {
        Message = self.Message,
        Verbosity = self.Verbosity,
        bPrintToScreen = self.bPrintToScreen,
        Duration = self.Duration,
        TextColorR = self.TextColor.R,
        TextColorG = self.TextColor.G,
        TextColorB = self.TextColor.B,
        TextColorA = self.TextColor.A
    }

    return json.encode(Param)
end

function MissionActionLog:OnActive()
    Super(MissionActionLog).OnActive(self)
    self:RunActionOnActorByTag("HiGamePlayer", self:GenerateActionParam())
end

function MissionActionLog:Run(Actor, ActionParamStr)
    Super(MissionActionLog).Run(self, Actor, ActionParamStr)
    -- Actor是PlayerState
    local MissionComponentClass = BPConst.GetMissionComponentClass()
    local PlayerController = Actor:GetPlayerController()
    local MissionComponent = PlayerController:GetComponentByClass(MissionComponentClass)
    if MissionComponent ~= nil then
        -- Send message to the client actor(Player)
        MissionComponent:Client_PrintLog(ActionParamStr)
    end
end

function MissionActionLog:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionLog
