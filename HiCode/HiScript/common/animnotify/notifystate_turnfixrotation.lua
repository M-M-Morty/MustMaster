require "UnLua"
local utils = require("common.utils")
local G = require("G")

local NotifyState_TurnFixRotation = Class()

function NotifyState_TurnFixRotation:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	return true
    end

    self.TurnSpeed = self.Angle / TotalDuration

    -- G.log:debug("yj", "NotifyState_TurnFixRotation:Received_NotifyBegin %s TurnSpeed.%s", TotalDuration, self.TurnSpeed)

    return true
end

function NotifyState_TurnFixRotation:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
    	return true
    end

    local Rotation = Owner:K2_GetActorRotation()
    local DeltaYaw = DeltaTime * self.TurnSpeed
	Rotation.Yaw = Rotation.Yaw + DeltaYaw
	Owner:K2_SetActorRotation(Rotation, true)

    return true
end

return NotifyState_TurnFixRotation
