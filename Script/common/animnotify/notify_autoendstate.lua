require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local Notify_AutoEndState = Class()

function Notify_AutoEndState:Received_Notify(MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()
    actor:SendMessage("EndState", check_table[self.State], true)
    return true
end


return Notify_AutoEndState