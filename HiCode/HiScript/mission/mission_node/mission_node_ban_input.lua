--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local EdUtils = require("common.utils.ed_utils")
local BPConst = require("common.const.blueprint_const")

local MissionNodeBase = require("mission.mission_node.mission_node_base")


local MissionNodeBanInput = Class(MissionNodeBase)

function MissionNodeBanInput:K2_InitializeInstance()
    Super(MissionNodeBanInput).K2_InitializeInstance(self)
end

function MissionNodeBanInput:K2_ExecuteInput(PinName)
    Super(MissionNodeBanInput).K2_ExecuteInput(self, PinName)

    local Player = G.GetPlayerCharacter(self, 0)
    if self.bBanInput then
	    Player:Client_SendMessage("BanInput")
	else
	    Player:Client_SendMessage("UnbanInput")
	end
    
    self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodeBanInput