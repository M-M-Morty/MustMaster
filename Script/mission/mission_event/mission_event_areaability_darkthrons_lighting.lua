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

---@type MissionEventAreaAbilityDarkThronsLighting_C
local MissionEventAreaAbilityDarkThronsLighting = Class(MissionEventOnActorBase)


function MissionEventAreaAbilityDarkThronsLighting:GenerateEventRegisterParam()
    local Param = {
    }
    self.EditorIds = {}
    return json.encode(Param)
end

function MissionEventAreaAbilityDarkThronsLighting:OnEvent(EventParamStr)
    Super(MissionEventAreaAbilityDarkThronsLighting).OnEvent(self, EventParamStr)
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

function MissionEventAreaAbilityDarkThronsLighting:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventAreaAbilityDarkThronsLighting).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = self:ParseActionParam(EventRegisterParamStr)
end

function MissionEventAreaAbilityDarkThronsLighting:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventAreaAbilityDarkThronsLighting:UnregisterOnTarget(Actor)
    Super(MissionEventAreaAbilityDarkThronsLighting).UnregisterOnTarget(self, Actor)
end

return MissionEventAreaAbilityDarkThronsLighting
