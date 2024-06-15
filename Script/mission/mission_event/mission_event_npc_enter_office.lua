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
local SubsystemUtils = require("common.utils.subsystem_utils")

---@type BP_MissionEventNpcEnterOffice_C
local MissionEventNpcEnterOffice = Class(MissionEventOnActorBase)

function MissionEventNpcEnterOffice:GenerateEventRegisterParam()
    local Param = {
        MissionActID = self:GetMissionActID(),
        SequencePath = UE.UKismetSystemLibrary.GetPathName(self.Sequence)
    }
    return json.encode(Param)
end

function MissionEventNpcEnterOffice:OnEvent(EventParamStr)
    Super(MissionEventNpcEnterOffice).OnEvent(self, EventParamStr)
    local Param = json.decode(EventParamStr)
    self:HandleComplete(EventParamStr)
end

function MissionEventNpcEnterOffice:RegisterOnTarget(Actor, EventRegisterParamStr)
    Super(MissionEventNpcEnterOffice).RegisterOnTarget(self, Actor, EventRegisterParamStr)
    local Param = json.decode(EventRegisterParamStr)
    self.NpcActorID = Actor:GetActorID()
    self.MissionActID = Param.MissionActID
    if Param.SequencePath ~= "" then
        local Sequence = UE.UObject.Load(Param.SequencePath)
        if Sequence then
            Actor.NpcMissionComponent.OfficeSequence = Sequence
        end
    end
    local bSucc = Actor.NpcTeleportComponent:TeleportToOfficeByMission(Param.MissionActID)
    if bSucc then
        -- 传送成功了，这个MissionEvent可以结束了
        self:DispatchEvent(self:GenerateEventParam())
    else
        -- 事务所被占用，Event阻塞在这里，监听后续成功事件
        local Player = SubsystemUtils.GetMutableActorSubSystem(self):GetHostPlayer()
        Player.PlayerState.OfficeComponent.OnNpcEnterOffice:Add(self, self.HandleNpcEnterOffice)
    end
end

function MissionEventNpcEnterOffice:HandleNpcEnterOffice(NpcActorID, MissionActID)
    if NpcActorID == self.NpcActorID and MissionActID == self.MissionActID then
        self:DispatchEvent(self:GenerateEventParam())
    end
end

function MissionEventNpcEnterOffice:UnregisterOnTarget(Actor)
    Super(MissionEventNpcEnterOffice).UnregisterOnTarget(self, Actor)
end

function MissionEventNpcEnterOffice:GenerateEventParam()
    local Param = {}
    return json.encode(Param)
end

return MissionEventNpcEnterOffice
