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

---@type MissionEventMonsterHit_C
local MissionEventMonsterHit = Class(MissionEventOnActorBase)

function MissionEventMonsterHit:OnActive()
    Super(MissionEventMonsterHit).OnActive(self)
    --self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventMonsterHit:OnInactive()
    --self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventMonsterHit).OnInactive(self)
end

function MissionEventMonsterHit:GenerateEventRegisterParam()
    local Param = {
        HitTag = tostring(self.HitTag.TagName)
    }
    return json.encode(Param)
end

function MissionEventMonsterHit:OnEvent(EventParamStr)
    Super(MissionEventMonsterHit).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventMonsterHit:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventMonsterHit).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local data = json.decode(EventRegisterParamStr)
    local HitTag = data["HitTag"]
    if  HitTag ~= nil then
        self.HitTag = UE.UHiEdRuntime.RequestGameplayTag(HitTag)
    end
    if Actor.Event_MonsterHit then
        self.OldCharCamp = Actor.CharCamp
        self.Actor = Actor
        Actor.CharCamp = Enum.Enum_CharCamp.CampMonster_Common
        Actor.Event_MonsterHit:Add(self, self.HandleMonsterHit)
    end
end

function MissionEventMonsterHit:HandleMonsterHit(HitTag)
    if self.HitTag then
        local TagName0 = tostring(self.HitTag.TagName)
        local Len0 = string.len(TagName0)
        local TagName1 = tostring(HitTag.TagName)
        local Len1 = string.len(TagName1)
        if Len0 <= Len1 then
            local TagName1Sub = TagName1:sub(1, Len0)
            if TagName0 == TagName1Sub  then
                self.Actor.CharCamp = self.OldCharCamp
                self:DispatchEvent(self:GenerateEventParam())
            end
        end
    end
end

function MissionEventMonsterHit:GenerateEventParam()
    local Param = {
    }
    return json.encode(Param)
end

function MissionEventMonsterHit:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventMonsterHit:UnregisterOnTarget(Actor)
    if Actor.Event_MonsterHit then
        Actor.Event_MonsterHit:Remove(self, self.HandleMonsterHit)
    end
    Super(MissionEventMonsterHit).UnregisterOnTarget(self, Actor)
end

return MissionEventMonsterHit
