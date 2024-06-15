--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
---@type NpcChatMainPanel_C
local M = Component(ComponentBase)


function M:InitPanel(npcChatManager)
    self.npcChatManager = npcChatManager
end

function M:ClosePanel()
    self.npcChatManager:CloseVideoChatingPanel()
end

return M
