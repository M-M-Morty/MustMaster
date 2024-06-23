require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local NotifyState_EnterState = Class()


function NotifyState_EnterState:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local actor = MeshComp:GetOwner()
    -- G.log:debug("yj", "NotifyState_EnterState:Received_NotifyBegin %s", G.GetDisplayName(actor))
    if actor.SendMessage then
	    actor:SendMessage("EnterState", check_table[self.State])
	end
    return true
end

function NotifyState_EnterState:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()
    -- G.log:debug("yj", "NotifyState_EnterState:Received_NotifyEnd %s", G.GetDisplayName(actor))
    if actor.SendMessage then
	    actor:SendMessage("EndState", check_table[self.State])
	end
    return true
end


return NotifyState_EnterState
