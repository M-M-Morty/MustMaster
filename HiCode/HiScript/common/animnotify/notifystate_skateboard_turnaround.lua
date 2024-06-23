require "UnLua"
local utils = require("common.utils")
local equip_const = require("common.const.equip_const")
local G = require("G")

local NotifyState_SkateBoard_TurnAround = Class()


function NotifyState_SkateBoard_TurnAround:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local actor = MeshComp:GetOwner()
    if not actor or not actor._GetComponent then
        return false
    end
    if actor.SendMessage then
        actor:SendMessage("ANS_SkateBoard_TurnAround_Begin")
    end
    return true
end


function NotifyState_SkateBoard_TurnAround:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()
    if not actor or not actor._GetComponent then
        return false
    end
    if actor.SendMessage then
        actor:SendMessage("ANS_SkateBoard_TurnAround_End")
    end
    return true
end

return NotifyState_SkateBoard_TurnAround
