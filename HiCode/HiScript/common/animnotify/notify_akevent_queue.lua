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
local Notify_AkEventQueue = Class()


function Notify_AkEventQueue:Received_Notify(MeshComp, Animation, EventReference)
    --G.log:debug("Notify_AkEventQueue", "Received_Notify %s %s %s", tostring(MeshComp), tostring(Animation), tostring(EventReference))    
    local Actor = MeshComp:GetOwner()
    if Actor and Actor:IsValid() and Actor:IsClient() then
        for idx, Event in pairs(self.EventArray) do
            Actor:SendMessage("PlayAkAudioEvent", Event, self.Follow, Enum.Enum_AkAudioPlayMode.Queue)
        end
        return true
    else
        return false
    end    
end

return Notify_AkEventQueue
