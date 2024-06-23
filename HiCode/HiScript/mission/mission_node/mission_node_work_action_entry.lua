--
-- Work Action Entry Node.
--
-- @COMPANY **
-- @AUTHOR virgilzhuge
-- @DATE 2024-06-11
--

local G = require("G")

---@type BP_MissionNode_WorkActionEntry_C
local WorkActionEntryNode = Class()

function WorkActionEntryNode:K2_ExecuteInput(PinName)
    self:TriggerFirstOutput(true)
end

return WorkActionEntryNode