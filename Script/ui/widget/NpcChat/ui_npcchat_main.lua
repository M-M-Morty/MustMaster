--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')
local M = Component(ComponentBase)




function M:SetPanelData()
    --self:SetUITextActor(self.timeText, )
end


--创建消息列表item
function M:CreateChatItemsList(chatItemList)
    for Index, Item in ipairs(chatItemList) do
        local chatitem = self:CreateMessageItem()
        chatitem:SetData(Item)
    end
end

return M
