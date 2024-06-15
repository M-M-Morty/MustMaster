--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"
-- local utils = require("common.utils")
-- local G = require("G")
---@type notifystate_set_capsule_response_to_channel
local notifystate_set_capsule_response_to_channel = Class()

local function GetOwnerCapsule(MeshComp)
    local Owner = MeshComp:GetOwner()
    return Owner and Owner.CapsuleComponent
end

local function GetOwnerMovementComp(MeshComp)
    local Owner = MeshComp:GetOwner()
    return Owner and Owner:GetMovementComponent()
end

function notifystate_set_capsule_response_to_channel:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
    local MapInfo = self.MapInfo
    local Keys = MapInfo:Keys()
    local CapsuleComp = GetOwnerCapsule(MeshComp)
    for _, Channel in pairs(Keys:ToTable()) do
        local NewResponse = MapInfo:Find(Channel)
        MeshComp:SetCollisionResponseToChannel(Channel,NewResponse)
        if CapsuleComp then
            CapsuleComp:SetCollisionResponseToChannel(Channel,NewResponse)
        end
    end
    if self.bUpdateMovementMode then
        local MovementComp = GetOwnerMovementComp(MeshComp)
        if MovementComp then
            MovementComp:SetMovementMode(self.EnterMovementMode)
        end
    end
    return true
end

-- function notifystate_set_capsule_response_to_channel:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime)
-- end

function notifystate_set_capsule_response_to_channel:Received_NotifyEnd(MeshComp, Animation)
    MeshComp:SetCollisionProfileName(self.MeshRecoverProfileName, true)
    local CapsuleComp = GetOwnerCapsule(MeshComp)
    if CapsuleComp then
        CapsuleComp:SetCollisionProfileName(self.CapsuleRecoverProfileName, true)         
    end
    if self.bUpdateMovementMode then
        local MovementComp = GetOwnerMovementComp(MeshComp)
        if MovementComp then
            MovementComp:SetMovementMode(self.OutMovementMode)
        end
    end
    return true
end

return notifystate_set_capsule_response_to_channel