require "UnLua"

local G = require("G")

local Actor = require("common.actor")

--@class GameMode
local GameState = Class(Actor)



function GameState:ReceiveBeginPlay()
    G.log:info("devin", "GameState:ReceiveBeginPlay")
    Super(GameState).ReceiveBeginPlay(self)
end

function GameState:ReceiveEndPlay(Reason)
    G.log:info("devin", "GameState:ReceiveEndPlay")
    Super(GameState).ReceiveEndPlay(self, Reason)
end

function GameState:LerpingInWeatherMananger()
    local WeatherManager = require("actors.client.WeatherManager")
    WeatherManager:OnLerpingToTarget()
end

function GameState:TickInTreeBlastingMananger()
    local BlastingTreeManager = require("actors.common.BlastingTreeManager")
    BlastingTreeManager:Tick()
end

function GameState:PlayerStartAimingMode(AimingModeType)
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)

    if self.AimingModeType ~= Enum.E_AimingModeType.None then
        self:PlayerStopAimingMode()
    end

    Player:SendMessage("StartAimingMode", AimingModeType)
    if not self:GetAimingMode() then
        return false
    end

    self.AimingModeType = AimingModeType

    if AimingModeType ~= Enum.E_AimingModeType.Normal then
        self:PlayerStartLockMode()
    end
    return true
end

function GameState:PlayerStopAimingMode()
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)
    Player:SendMessage("StopAimingMode", self.AimingModeType)

    if self.AimingModeType ~= Enum.E_AimingModeType.Normal then
        self:PlayerStopLockMode()
    end

    self.AimingModeType = Enum.E_AimingModeType.None
end

function GameState:PlayerStartLockMode()
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)
    Player:SendMessage("StartLockMode")
    if self.bLockMode then
        return true
    end
    return false
end

function GameState:PlayerStopLockMode()
    local WorldContext = self:GetWorld()
    local Player = G.GetPlayerCharacter(WorldContext, 0)
    if Player then
        Player:SendMessage("StopLockMode")
    end
end

return RegisterActor(GameState)
