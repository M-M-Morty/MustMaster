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

---@type BP_MissionEventArriveTrapBase_C
local MissionEventArriveTrapBase = Class(MissionEventOnActorBase)

function MissionEventArriveTrapBase:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventArriveTrapBase:OnEvent(EventParamStr)
    Super(MissionEventArriveTrapBase).OnEvent(self, EventParamStr)

    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventArriveTrapBase:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventArriveTrapBase).RegisterOnTarget(self, Actor, EventRegisterParamStr)
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

function MissionEventArriveTrapBase:UnregisterOnTarget(Actor)
    Super(MissionEventArriveTrapBase).UnregisterOnTarget(self, Actor)
    Actor.Sphere.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap)
end

function MissionEventArriveTrapBase:OnBeginOverlap(OverlappedComp, Other, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if Other.IsAvatar ~= nil and Other:IsAvatar() then
        self:DispatchEvent(self:GenerateEventParam())
    end
end

function MissionEventArriveTrapBase:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventArriveTrapBase