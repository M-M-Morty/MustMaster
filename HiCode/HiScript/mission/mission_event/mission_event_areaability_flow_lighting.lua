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

---@type MissionEventAreaAbilityFlowLighting_C
local MissionEventAreaAbilityFlowLighting = Class(MissionEventOnActorBase)


function MissionEventAreaAbilityFlowLighting:GenerateEventRegisterParam()
    local Param = {
    }
    self.EditorIds = {}
    return json.encode(Param)
end

function MissionEventAreaAbilityFlowLighting:OnEvent(EventParamStr)
    Super(MissionEventAreaAbilityFlowLighting).OnEvent(self, EventParamStr)
    self.EditorIds[EventParamStr] = true
    local bOk = true
    for i = 1, self.TargetActorIDList:Length() do
        local NeedEditorId = self.TargetActorIDList[i]
        if not self.EditorIds[NeedEditorId] then
            bOk = false
        end
    end
    self:HandleOnceComplete(EventParamStr)
    if bOk then
        self:HandleComplete(EventParamStr)
    end
end

function MissionEventAreaAbilityFlowLighting:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventAreaAbilityFlowLighting).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
end

function MissionEventAreaAbilityFlowLighting:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventAreaAbilityFlowLighting:UnregisterOnTarget(Actor)
    Super(MissionEventAreaAbilityFlowLighting).UnregisterOnTarget(self, Actor)
end

return MissionEventAreaAbilityFlowLighting
