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
local MissionEventOnActorBase = require("mission.mission_event.mission_event_onactor_base")

---@type MissionEventKillMonster_C
local MissionEventPlayMontage = Class(MissionEventOnActorBase)


function MissionEventPlayMontage:GenerateEventRegisterParam()
    local AnimMontagePath = UE.UKismetSystemLibrary.GetPathName(self.AnimMontage)
    local Param = {
        bLoop = self.bLoop,
        AnimMontagePath = AnimMontagePath
    }
    G.log:debug("zsf", "[mission_event_playmontage] %s %s", self.bLoop, AnimMontagePath)
    return json.encode(Param)
end

function MissionEventPlayMontage:OnEvent(EventParamStr)
    Super(MissionEventPlayMontage).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventPlayMontage:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventPlayMontage).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
    G.log:debug("zsf", "[mission_event_playmontage] %s %s", G.GetDisplayName(Actor), EventRegisterParamStr)
    if Actor and Actor.MissionPlayMontage then
        Actor:MissionPlayMontage(Param.AnimMontagePath, Param.bLoop)
    end
end

function MissionEventPlayMontage:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventPlayMontage:UnregisterOnTarget(Actor)
    Super(MissionEventPlayMontage).UnregisterOnTarget(self, Actor)
end

return MissionEventPlayMontage
