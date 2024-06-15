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
local MissionActionBase = require("mission.mission_action.mission_action_base")
local BPConst = require("common.const.blueprint_const")

---@type BP_MissionAction_TeleportPlayer_C
local MissionActionTeleportPlayer = Class(MissionActionBase)

function MissionActionTeleportPlayer:GenerateActionParam()
    local Param = {
        PosX = self.Pos.X,
        PosY = self.Pos.Y,
        PosZ = self.Pos.Z,
        RotationZ = self.RotationZ
    }
    return json.encode(Param)
end

function MissionActionTeleportPlayer:OnActive()
    Super(MissionActionTeleportPlayer).OnActive(self)
    self:RunActionOnActorByTag("HiGamePlayer", self:GenerateActionParam())
end

function MissionActionTeleportPlayer:Run(Actor, ActionParamStr)
    Super(MissionActionTeleportPlayer).Run(self, Actor, ActionParamStr)
    local Param = self:ParseActionParam(ActionParamStr)
    local MissionComponentClass = BPConst.GetMissionComponentClass()
    local PlayerController = Actor.PlayerState:GetPlayerController()
    local MissionComponent = PlayerController:GetComponentByClass(MissionComponentClass)
    G.log:debug("xaelpeng", "MissionActionTeleportPlayer:Run %s %s %s %s", MissionComponent, Param.PosX, Param.PosY, Param.PosZ)
    if MissionComponent ~= nil then
        local Location = UE.UKismetMathLibrary.MakeVector(Param.PosX, Param.PosY, Param.PosZ)
        local ActorRotation = Actor:K2_GetActorRotation()
        local Rotator = UE.UKismetMathLibrary.MakeRotator(ActorRotation.Roll, ActorRotation.Pitch, Param.RotationZ)
        MissionComponent:TeleportPlayer(Location, Rotator)
    end
end

function MissionActionTeleportPlayer:ParseActionParam(ActionParamStr)
    return json.decode(ActionParamStr)
end

return MissionActionTeleportPlayer
