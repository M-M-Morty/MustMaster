--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")

---@type ANS_Footstep_C
local Notify_FootStep = Class()

function Notify_FootStep:Received_Notify_Custom(MeshComp, HitResult, FootstepFX)
    --G.log:debug("Notify_FootStep", "Received_Notify_Custom %s %s %s", tostring(MeshComp), tostring(HitResult), tostring(self.bLeftFoot))
    if HitResult.bBlockingHit then 
        local Actor = MeshComp:GetOwner()
        if Actor and Actor:IsValid() then
            Actor:SendMessage("OnReceiveFootStep", self.bLeftFoot, HitResult.ImpactPoint)        
        end        
    end
    return true
end


function Notify_FootStep:Received_Notify_WwiseDataAsset(InCharacter, HitResult)        
    G.log:debug("Notify_FootStep", "Received_Notify_WwiseDataAsset %s  %s", G.GetDisplayName(InCharacter), tostring(self.MovementTag.TagName))
    if InCharacter and InCharacter:IsValid() then
        InCharacter:SendClientMessage("OnReceived_Notify_WwiseDataAsset", self.MovementTag, HitResult.PhysMaterial.SurfaceType)
    end
    return true
end
return Notify_FootStep