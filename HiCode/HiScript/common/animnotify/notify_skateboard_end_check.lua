--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")

---@type Notify_SkateBoard_End_Check_C
---
local Notify_SkateBoard_End_Check = Class()


function Notify_SkateBoard_End_Check:Received_Notify(MeshComp, Animation, EventReference)
    G.log:info_obj(self, "Notify_SkateBoard_End_Check", "Received_Notify %s %s %s", tostring(MeshComp), tostring(Animation), tostring(EventReference))
    local Actor = MeshComp:GetOwner()
    local anim_instance = MeshComp:GetAnimInstance()
   
    if Actor and Actor:IsValid() then -- and Actor:IsClient() then
        local montage = Actor:GetCurrentMontage()
        G.log:info_obj(self,"Notify_SkateBoard_End_Check", "Montage %s", G.GetObjectName(montage))
        G.log:info_obj(self,"Notify_SkateBoard_End_Check", "MovementState %s", anim_instance.MovementState)
        if anim_instance.MovementState == UE.EHiMovementState.InAir then
            G.log:info_obj(self,"Notify_SkateBoard_End_Check", "Montage_Stop")
            anim_instance:Montage_Stop(0, montage)
            return false
        end
    end
    return true
end

function Notify_SkateBoard_End_Check:PrintDebugMessage()
end

return Notify_SkateBoard_End_Check
