--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local TeleportComponent = require("actors.common.components.teleport_component")
local Component = require("common.component")
local OfficeConst = require("common.const.office_const")
local json = require("thirdparty.json")
local DataManager = require("common.DataManager")
local GameConstData = require("common.data.game_const_data").data
local SubsystemUtils = require("common.utils.subsystem_utils")

---@type NpcTeleportComponent_C
local NpcTeleportComponent = Component(TeleportComponent)

local decorator = NpcTeleportComponent.decorator
local DefaultRotation = UE.UKismetMathLibrary.MakeRotator(0, 0, 0)

-- server
function NpcTeleportComponent:TeleportToOfficeByMission(MissionActID)
    local Player = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayer()
    local bSucc = Player.PlayerState.OfficeComponent:NpcEnterOffice(self:GetOwner():GetActorID(), MissionActID)
    if bSucc then
        self:Server_TeleportToOffice()
    end
    return bSucc
end

function NpcTeleportComponent:Server_TeleportToOffice_RPC()
    self:Server_TeleportToActor(Enum.Enum_AreaType.Office, OfficeConst.OfficeTeleportPointActorID)
end

function NpcTeleportComponent:CanEnterArea(TargetAreaType)
    return true
end

function NpcTeleportComponent:PreEnterArea(TargetAreaType)
    return true
end

function NpcTeleportComponent:PostEnterArea(TargetAreaType)
    local OldAreaType = self.AreaType
    self.AreaType = TargetAreaType
    if TargetAreaType ~= OldAreaType and OldAreaType == Enum.Enum_AreaType.Office then
        -- 通知事务所 有Npc离开
        local Player = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayer()
        Player.PlayerState.OfficeComponent:NpcLeaveOffice(self:GetOwner())
        self.actor.NpcMissionComponent.OfficeSequence = nil
    end
end

function NpcTeleportComponent:Server_TeleportToActor_RPC(TargetAreaType, TargetActorID)
    if not self:CanEnterArea(TargetAreaType) then
        return false
    end
    self:PreEnterArea(TargetAreaType)
    local ActorLocationData = self:GetActorLocationData(TargetActorID)
    if not ActorLocationData then
        G.log:warn("[NpcTeleportComponent:Server_TeleportToActor_RPC]", "Can't get actor location data, ActorID:%s", TargetActorID)
        return
    end
    self:TeleportTo(ActorLocationData, DefaultRotation, false, nil)
    self:PostEnterArea(TargetAreaType)
end

function NpcTeleportComponent:TeleportToPosition(TargetAreaType, Position)
    if not self:CanEnterArea(TargetAreaType) then
        return false
    end
    self:PreEnterArea(TargetAreaType)
    self:TeleportTo(Position, DefaultRotation, false, nil)
    self:PostEnterArea(TargetAreaType)
end

return NpcTeleportComponent
