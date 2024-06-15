--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local G = require("G")
local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')


local M = UnLua.Class()

function M:InitPanel(npcChatManager)
    self.npcChatManager = npcChatManager
    --self.bFromMenuPanel = bFromMenuPanel
    self.chatItemList = {}

    local player = UE.UGameplayStatics.GetPlayerPawn(self, 0)
    if player ~= nil and player.MissionAvatarComponent ~= nil then
        player.MissionAvatarComponent.OnDialogueUpdate:Add(self, self.OnDialogueUpdate)
    end

    self:InitViewModel()
    self:OnShow()
end

function M:OnDialogueUpdate(SmsActorID)
    local player = UE.UGameplayStatics.GetPlayerPawn(self, 0)

    local npcid = SmsActorID
    local dialogue = player.MissionAvatarComponent.SmsDialogues[SmsActorID]
    self:UpdateChatItemsList(PlayerChatManager.VM_Player.ChatList:GetFieldValue())
end

function M:InitViewModel()

    if self.bFromMenuPanel then
        --todo 主菜单按钮入口
    end
    --PlayerChatManager.TabData[2].ChannelIdArr
    --PlayerChatManager.InitChannelList()
    self.chatListVM = PlayerChatManager.VM_Player.ChatList:GetFieldValue()
end

function M:OnShow()
    self:UpdateChatItemsList(self.chatListVM)
    self:SetUITextActor(self.TimeText, os.date("%H:%M", os.time()))
end


function M:UpdateChatItemsList(chatItemList)
    for Index, Item in ipairs(chatItemList) do
        if self.chatItemList[Index] == nil then
            local chatitem = self:CreateMessageItem()
            chatitem:SetData(Item, self)
            self.chatItemList[Index] = Item
        end
    end
end


function M:ClosePanel()
    --关闭自己 显示HUD
    self.npcChatManager:CloseMessagePanel()
end

return M
