--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"

local G = require("G")

---@type AnimNotify_AkEvent_C
---
local Notify_StopCurBTNode = Class()


function Notify_StopCurBTNode:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    -- G.log:error("Notify_StopCurBTNode", "Received_Notify %s IsServer.%s", G.GetDisplayName(Animation), Owner:IsServer())
    Owner.AIComp.bCanBreakCurBTNode = true

    return true
end

return Notify_StopCurBTNode
