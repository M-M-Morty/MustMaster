--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
local SkillUtils = require("common.skill_utils")

local G = require("G")

---@type AnimNotify_AkEvent_C
---
local Notify_AkEvent = Class()


function Notify_AkEvent:Received_Notify(MeshComp, Animation, EventReference)
    G.log:debug("Notify_AkEvent", "Received_Notify %s %s %s", tostring(MeshComp), SkillUtils.IsSkillAnimation(Animation), tostring(EventReference))    
    local Actor = MeshComp:GetOwner()
    if Actor and Actor:IsValid() and Actor:IsClient() then
        Actor:SendMessage("PlayAkAudioEvent", self.Event, self.Follow, self.PlayMode)
        Actor:SendMessage("OnAkEventByAnimNotify", self.Event, self.StopEvent)        
        --if SkillUtils.IsSkillAnimation(Animation) then
        --    Actor:SendMessage("OnAkEventByAnimNotify", self.Event, self.StopEvent)        
        --end
        return true
    else
        return false
    end    
end

return Notify_AkEvent
