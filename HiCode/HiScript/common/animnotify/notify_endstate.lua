require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local Notify_EndState = Class()

function Notify_EndState:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local actor = MeshComp:GetOwner()
    if actor.AppearanceComponent:HasMovementInput() then
        actor:SendMessage("EndState", check_table[self.State], true)
    end
    return true
end


return Notify_EndState