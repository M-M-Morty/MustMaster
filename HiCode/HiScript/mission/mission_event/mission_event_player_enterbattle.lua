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

local MissionEventPlayerEnterBattle = Class(MissionEventOnActorBase)

function MissionEventPlayerEnterBattle:GenerateEventRegisterParam()
    local Param = {}
    return json.encode(Param)
end

function MissionEventPlayerEnterBattle:OnEvent(EventParamStr)
    Super(MissionEventPlayerEnterBattle).OnEvent(self, EventParamStr)
    self:HandleOnceComplete(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventPlayerEnterBattle:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventPlayerEnterBattle).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    utils.DoDelay(self, 0.3, function()
        self:JudgePlayerEnterBattle()
    end)
end

function MissionEventPlayerEnterBattle:UnregisterOnTarget(Actor)
    Super(MissionEventPlayerEnterBattle).UnregisterOnTarget(self, Actor)
end

function MissionEventPlayerEnterBattle:JudgePlayerEnterBattle()
    local Player = G.GetPlayerCharacter(self, 0)
    if Player and Player.BattleStateComponent.InBattle == true then
        self:DispatchEvent(self:GenerateEventParam())
    else
        utils.DoDelay(self, 0.3, function()
            self:JudgePlayerEnterBattle()
        end)
    end
end

function MissionEventPlayerEnterBattle:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end


return MissionEventPlayerEnterBattle