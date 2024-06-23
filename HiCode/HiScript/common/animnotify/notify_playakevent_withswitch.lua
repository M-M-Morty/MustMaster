
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

---@type Notify_PlayAkEventWithSwitch
local Notify_PlayAkEventWithSwitch = Class()

function Notify_PlayAkEventWithSwitch:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsServer() then 
        return false 
    end


    Owner:SendMessage("PlayAkEventWithSwitch", self.AkEvent, self.AkSwitch, self.bOnPlayer)

    return true
end

return Notify_PlayAkEventWithSwitch