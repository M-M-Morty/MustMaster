require "UnLua"
local utils = require("common.utils")

local G = require("G")


local Notify_SkateBoard_JumpStart = Class()


function Notify_SkateBoard_JumpStart:Received_Notify(MeshComp, Animation, EventReference)
    local Actor = MeshComp:GetOwner()
    if Actor and Actor:IsValid() and Actor.SendMessage then
        Actor:SendMessage("Notify_SkateBoard_JumpStart")
    end
    return true
end


return Notify_SkateBoard_JumpStart
