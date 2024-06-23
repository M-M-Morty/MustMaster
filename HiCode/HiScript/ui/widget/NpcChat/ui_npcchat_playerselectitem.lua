--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local Actor = require("common.actor")
local M = Component(ComponentBase)
local G = require('G')

local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')


function M:InitItem(itemData, chatPanel)
    self.chatPanel = chatPanel
    self.BranchId = itemData.BranchId
    self.ItemId = itemData.Id
    self.ItemInfo = itemData.DataInfo
    self:SetResponseText(self.ItemInfo)
end


function M:ClickReply()
    local player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    PlayerChatManager.HandleChoice(self.BranchId,self.ItemId,self.ItemInfo)
    self.chatPanel:UpdateHistoryList()
end


return M
