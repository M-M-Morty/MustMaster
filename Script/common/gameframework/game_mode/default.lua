require "UnLua"

local G = require("G")

local character_table = require("common.data.hero_initial_data")

local Actor = require("common.actor")

--@class GameMode
local GameMode = Class(Actor)

function GameMode:ReceiveBeginPlay()
    G.log:info("devin", "GameMode:ReceiveBeginPlay")
    Super(GameMode).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("GameMode(actor: %s, server: %s)", G.GetObjectName(self), self:IsServer())
end

function GameMode:ReceiveEndPlay(Reason)
    G.log:info("devin", "GameMode:ReceiveEndPlay")
    Super(GameMode).ReceiveEndPlay(self, Reason)
end

function GameMode:GetDefaultPawnClassForController(Controller)
    if self.SpawnCharType == nil then
        local TeamInfo = Controller.ControllerSwitchPlayerComponent.TeamInfo
        self.SpawnCharType = TeamInfo[1]
    end

    if self.SpawnCharType == 0 then
        G.log:debug("devin", "GameMode:GetDefaultPawnClassForController Use Default Pawn Class")
        return self.DefaultPawnClass
    end
    local path = character_table.data[self.SpawnCharType]["hero_path"]
    G.log:debug("devin", "GameMode:GetDefaultPawnClassForController %d %s", self.SpawnCharType, path)
    local player_class = UE.UClass.Load(path)
    if not player_class then
        G.log:error("yj", "GetDefaultPawnClassForController error: player_class nil path.%s", path)
        return self.DefaultPawnClass
    else
        return player_class
    end
end

function GameMode:SpawnDefaultPawnAtTransform(Controller, SpawnTransform, ExtraData)
    local SpawnParameters = UE.FActorSpawnParameters()
    SpawnParameters.Instigator = self:GetInstigator()
    -- SpawnParameters.ObjectFlags = SpawnParameters.ObjectFlags | UE.EObjectFlags.RF_Transient
    local Class = self:GetDefaultPawnClassForController(Controller)
    if not ExtraData then
        ExtraData = {CharType = self.SpawnCharType}
    end

    ExtraData["CacheController"] = Controller
    local PD = Controller.PlayerState
    local NewPlayer = GameAPI.SpawnActor(self:GetWorld(), Class, SpawnTransform, SpawnParameters, ExtraData)
    Controller:AddSwitchPlayer(NewPlayer)
    return NewPlayer
end

function GameMode:EnableCheats(Player)
    G.log:info("devin", "GameMode:EnableCheats")
    return true
end

function GameMode:SpawnNewPlayerBySwitchPlayer(Controller, CharType, Transform)
    self.SpawnCharType = CharType
    local ExtraData = {CharType = self.SpawnCharType, bSwitchPlayer = true}
    return self:SpawnDefaultPawnAtTransform(Controller, Transform, ExtraData)
end

function GameMode:K2_OnRestartPlayer(PC)
    G.log:debug(self.__TAG__, "K2_OnRestartPlayer")
    PC:SendMessage("AfterFirstPlayerLogin")
end

return RegisterActor(GameMode)
