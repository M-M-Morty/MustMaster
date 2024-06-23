require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local NotifyState_SkateBoardJump = Class()


function NotifyState_SkateBoardJump:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local actor = MeshComp:GetOwner()
   
    local PlayRate = MeshComp:GetAnimInstance():Montage_GetPlayRate(Animation)
    --G.log:info_obj(self,"SkateBoardJump", "NotifyBegin %s, %f, %f, %s", G.GetObjectName(Animation), TotalDuration, PlayRate, Animation)
    
    if actor.SendMessage then
        actor:SendMessage("ANS_SkateBoardJump_Begin", TotalDuration/PlayRate, self.JumpTopZ, self.JumpDistanceXY)
    end
    return true
end

function NotifyState_SkateBoardJump:Received_NotifyTick(MeshComp, Animation, FrameDeltaTime, EventReference)
    local actor = MeshComp:GetOwner()
    if actor.SendMessage then
        actor:SendMessage("ANS_SkateBoardJump_Tick", FrameDeltaTime)
    end
    return true
end

function NotifyState_SkateBoardJump:Received_NotifyEnd(MeshComp, Animation, EventReference)
    local actor = MeshComp:GetOwner()
    if actor.SendMessage then
        actor:SendMessage("ANS_SkateBoardJump_End")
    end
    return true
end


return NotifyState_SkateBoardJump
