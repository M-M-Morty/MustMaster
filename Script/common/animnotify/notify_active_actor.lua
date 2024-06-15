
--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR PanZiBin
-- @DATE ${date} ${time}
--

require "UnLua"

-- local utils = require("common.utils")
-- local G = require("G")

---@type notify_active_actor
local notify_active_actor = Class()

function notify_active_actor:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsServer() then 
        return false 
    end

    local Actors = GameAPI.GetActorsWithTag(Owner, self.RouteActorTag)
    if not Actors then 
        return false 
    end

    for _, Actor in ipairs(Actors) do
        Actor:Active(self.bActive, self.bActiveStiffness)
    end

    return true
end

return notify_active_actor