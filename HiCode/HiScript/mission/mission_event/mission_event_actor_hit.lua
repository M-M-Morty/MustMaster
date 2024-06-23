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

---@type MissionEventActorHit_C
local MissionEventActorHit = Class(MissionEventOnActorBase)

function MissionEventActorHit:OnActive()
    Super(MissionEventActorHit).OnActive(self)
    --self:RegisterEventOnActorByTag("HiGamePlayer", self:GenerateEventRegisterParam())
end

function MissionEventActorHit:OnInactive()
    --self:UnregisterEventOnActorByTag("HiGamePlayer")
    Super(MissionEventActorHit).OnInactive(self)
end

function MissionEventActorHit:GenerateEventRegisterParam()
    local Param = {
        HitTag = tostring(self.HitTag.TagName)
    }
    return json.encode(Param)
end

function MissionEventActorHit:OnEvent(EventParamStr)
    Super(MissionEventActorHit).OnEvent(self, EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventActorHit:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventActorHit).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local data = json.decode(EventRegisterParamStr)
    local HitTag = data["HitTag"]
    if  HitTag ~= nil then
        self.HitTag = UE.UHiEdRuntime.RequestGameplayTag(HitTag)
    end
    if Actor.Event_ActorHit then
        --self.OldCharCamp = Actor.CharCamp
        self.Actor = Actor
        --Actor.CharCamp = Enum.Enum_CharCamp.CampMonster_Common
        Actor.Event_ActorHit:Add(self, self.HandleActorHit)
        local tbAttachedActors = Actor:GetAttachedActors()
        local Num = tbAttachedActors:Length()
        for i = 1, Num do
            local ChildActor = tbAttachedActors:Get(i)
            if ChildActor.Event_ActorHit then
                ChildActor.Event_ActorHit:Add(self, self.HandleActorHit)
            end
        end
    end
end

function MissionEventActorHit:HandleActorHit(HitTag)
    if self.HitTag then
        local TagName0 = tostring(self.HitTag.TagName)
        local Len0 = string.len(TagName0)
        local TagName1 = tostring(HitTag.TagName)
        local Len1 = string.len(TagName1)
        if Len0 <= Len1 then
            local TagName1Sub = TagName1:sub(1, Len0)
            if TagName0 == TagName1Sub  then
                --self.Actor.CharCamp = self.OldCharCamp
                self:DispatchEvent(self:GenerateEventParam())
            end
        end
    end
end

function MissionEventActorHit:GenerateEventParam()
    local Param = {
    }
    return json.encode(Param)
end

function MissionEventActorHit:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

function MissionEventActorHit:UnregisterOnTarget(Actor)
    if Actor.Event_ActorHit then
        Actor.Event_ActorHit:Remove(self, self.HandleActorHit)
    end
    Super(MissionEventActorHit).UnregisterOnTarget(self, Actor)
end

return MissionEventActorHit
