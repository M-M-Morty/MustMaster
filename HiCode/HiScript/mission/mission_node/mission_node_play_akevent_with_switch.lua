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


local MissionNodePlayAkEventWithSwitch = Class(MissionNodeBase)

function MissionNodePlayAkEventWithSwitch:K2_InitializeInstance()
    Super(MissionNodePlayAkEventWithSwitch).K2_InitializeInstance(self)
end

function MissionNodePlayAkEventWithSwitch:K2_ExecuteInput(PinName)
    Super(MissionNodePlayAkEventWithSwitch).K2_ExecuteInput(self, PinName)

    -- G.log:error("yjjj", "MissionNodePlayAkEventWithSwitch:K2_ExecuteInput %s %s", 
    --     G.GetDisplayName(self.AkEvent), G.GetDisplayName(self.AkSwitch))
    
    -- 暂时只支持单机模式
	local Player = G.GetPlayerCharacter(self, 0)
	-- 要加个延时，否则UE.UAkGameplayStatics.PostEvent和UE.UAkGameplayStatics.SetSwitch接口调用无效，太太太神奇了
	-- TODO，得空再来查一下
    utils.DoDelay(Player, 0.1, function( ... )
		Player:SendMessage("PlayAkEventWithSwitch", self.AkEvent, self.AkSwitch, true)
    end)

    self:TriggerOutput(self.SuccessPin, true, false)
end


return MissionNodePlayAkEventWithSwitch