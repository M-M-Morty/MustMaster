require "UnLua"

local G = require("G")

local NotifyState_GameplayEffect = Class()


function NotifyState_GameplayEffect:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    Owner:SendMessage("GoldenBody", true)
    return true
end

function NotifyState_GameplayEffect:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    Owner:SendMessage("GoldenBody", false)
    return true
end

return NotifyState_GameplayEffect
