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

local MissionEventPlayerBeginPlay = Class(MissionEventOnActorBase)

function MissionEventPlayerBeginPlay:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventPlayerBeginPlay:OnEvent(EventParamStr)
    Super(MissionEventPlayerBeginPlay).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventPlayerBeginPlay:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventPlayerBeginPlay).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    utils.DoDelay(self, 0.3, function()
        self:JudgePlayerBeginPlay()
    end)
end

function MissionEventPlayerBeginPlay:UnregisterOnTarget(Actor)
    Super(MissionEventPlayerBeginPlay).UnregisterOnTarget(self, Actor)
end

function MissionEventPlayerBeginPlay:JudgePlayerBeginPlay()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player and Player:GetRemoteRole() == UE.ENetRole.ROLE_AutonomousProxy then
        self:DispatchEvent(self:GenerateEventParam())
    else
        utils.DoDelay(self, 0.3, function()
            self:JudgePlayerBeginPlay()
        end)
    end
end

function MissionEventPlayerBeginPlay:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventPlayerBeginPlay