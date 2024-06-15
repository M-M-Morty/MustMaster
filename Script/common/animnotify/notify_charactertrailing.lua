require "UnLua"
local utils = require("common.utils")

local G = require("G")


local Notify_CharactTrailing = Class()


function Notify_CharactTrailing:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)        
    local actor = MeshComp:GetOwner()
    if not actor:HasAuthority() then    
        actor:EnableComponent("TrailingComponent", true)
        actor:SendMessage("SetTrailParameters", self.TrailingClass, self.FadeoutTime, self.ShadowCount, self.StartDis, self.MaterialInst)
    end    
    return true
end

function Notify_CharactTrailing:Received_NotifyEnd(MeshComp, Animation, EventReference)        
    local actor = MeshComp:GetOwner()
    if not actor:HasAuthority() then   
        actor:EnableComponent("TrailingComponent", false)
    end    
    return true
end



return Notify_CharactTrailing