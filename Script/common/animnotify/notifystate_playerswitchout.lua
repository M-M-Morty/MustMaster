require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_PlayerSwitchout = Class()

function NotifyState_PlayerSwitchout:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    return true
end


function NotifyState_PlayerSwitchout:Received_NotifyEnd(MeshComp, Animation, EventReference)
	local Owner = MeshComp:GetOwner()
    Owner:SendMessage("PlayerBeforeSwitchOutByAnimNotify")
	return true
end

return NotifyState_PlayerSwitchout