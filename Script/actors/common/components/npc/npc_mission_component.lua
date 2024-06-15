--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

---@type NpcMissionComponent_C
local NpcMissionComponent = Component(ComponentBase)

function NpcMissionComponent:Initialize(Initializer)
    Super(NpcMissionComponent).Initialize(self, Initializer)
    self.OfficeSequence = nil  -- server
end

return NpcMissionComponent
