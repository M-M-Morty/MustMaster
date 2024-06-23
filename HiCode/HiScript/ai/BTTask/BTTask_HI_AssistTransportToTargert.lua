--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local ai_utils = require("common.ai_utils")


local BTTask_Base = require("ai.BTCommon.BTTask_Base")
---@type BTTask_AssistTransportToTarget_C
local BTTask_AssistTransportToTarge = Class(BTTask_Base)


function BTTask_AssistTransportToTarge:Execute(Controller, Pawn)
    -- 废弃
    -- G.log:info("yb", "BT assist monster transport call IsClient %s", Pawn:IsClient())
    -- Pawn:Multicast_TransportToTarget()

    return ai_utils.BTTask_Succeeded
end


return BTTask_AssistTransportToTarge
