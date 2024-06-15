require "UnLua"
local utils = require("common.utils")

local G = require("G")

local NotifyState_PassParam = Class()

function NotifyState_PassParam:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    Owner.Param1 = self.Param1
    return true
end

return NotifyState_PassParam
