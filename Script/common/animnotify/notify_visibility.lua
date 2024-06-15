require "UnLua"

local G = require("G")

local Notify_Visibility = Class()


function Notify_Visibility:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)        
    G.log:debug("hycoldrain", "Notify_Visibility:Received_NotifyBegin: %s", UE.UHiUtilsFunctionLibrary.IsServer(self))
    local actor = MeshComp:GetOwner()
    if not actor:HasAuthority() then
        actor:SendMessage("SetVisibility", false)
    end
    return true
end

function Notify_Visibility:Received_NotifyEnd(MeshComp, Animation, EventReference)    
    G.log:debug("hycoldrain", "Notify_Visibility:Received_NotifyEnd: %s", UE.UHiUtilsFunctionLibrary.IsServer(self))
    local actor = MeshComp:GetOwner()
    if not actor:HasAuthority() then
        actor:SendMessage("SetVisibility", true)
        actor:SendMessage("AfterSetVisibility", true)
    end
    return true
end

return Notify_Visibility