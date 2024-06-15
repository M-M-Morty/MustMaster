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

---@type BP_MissionEventArriveCircleRegion_C
local MissionEventArriveCircleRegion = Class(MissionEventOnActorBase)

function MissionEventArriveCircleRegion:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventArriveCircleRegion:OnEvent(EventParamStr)
    Super(MissionEventArriveCircleRegion).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventArriveCircleRegion:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventArriveCircleRegion).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    Actor.Sphere.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap)
    local OverlappedActors = UE.TArray(UE.AActor)
    Actor.Sphere:GetOverlappingActors(OverlappedActors)
    for Index = 1, OverlappedActors:Length() do
        local Other = OverlappedActors[Index]
        if Other.IsAvatar ~= nil and Other:IsAvatar() then
            self:DispatchEvent(self:GenerateEventParam())
            break
        end
    end
end

function MissionEventArriveCircleRegion:UnregisterOnTarget(Actor)
    Super(MissionEventArriveCircleRegion).UnregisterOnTarget(self, Actor)
    Actor.Sphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap)
end

function MissionEventArriveCircleRegion:OnBeginOverlap(OverlappedComp, Other, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if Other.IsAvatar ~= nil and Other:IsAvatar() then
        G.log:debug("xaelpeng", "MissionEventArriveCircleRegion:OnBeginOverlap %s", Other:GetName())
        self:DispatchEvent(self:GenerateEventParam())
    end
end

function MissionEventArriveCircleRegion:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventArriveCircleRegion