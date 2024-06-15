--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local M = Component(ComponentBase)
local G = require("G")
local DialogueObjectModule = require("mission.dialogue_object")

local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')


function M:InitPanel(npcid, npcChatManager)
    self.npcChatManager = npcChatManager
    self.npcId = npcid
    PlayerChatManager.CurrentTab = 1

    local chatData = PlayerChatManager.ChatData[npcid]

    self.historyItemDataList = {}

    self.replyItemList = {}

    if chatData ~= nil then
        PlayerChatManager.CurrentChannel = npcid
        self:SetUITextActor(self.TimeText, os.date("%H:%M", os.time()))
        self:SetUITextActor(self.TitleText, chatData.ChatName)
    end
    self:UpdateHistoryList()
    local player = UE.UGameplayStatics.GetPlayerPawn(self, 0)
    if player ~= nil and player.MissionAvatarComponent ~= nil then
        player.MissionAvatarComponent.OnDialogueUpdate:Add(self, self.OnDialogueUpdate)
    end
end

-- client
function M:OnDialogueUpdate(SmsActorID)
    self:UpdateHistoryList()
end

function M:SetHistoryItemsContentPos()
    self:MoveContentToBottom()
end

function M:SetHistoryItemsContentSize()
    self:SetScrollviewHeight()
end

function M:UpdateHistoryList()
    local historyDatas = PlayerChatManager.ChatData[self.npcId].ChatHistoryData
    if historyDatas ~= nil then
        for Index, Item in ipairs(historyDatas) do
            if self.historyItemDataList[Index] ~= Item then
                local historyItem = self:CreateHistoryItem()
                historyItem:InitViewModel(Item)
                self.historyItemDataList[Index] = Item
            end
        end
    end
    self:RemoveReplyList()
    local replyOptions = PlayerChatManager.OptionData[self.npcId]
    if replyOptions ~= nil then
        for Index, Item in ipairs(replyOptions) do
            if Item.BranchId ~= DialogueObjectModule.DialogueType.FINISHED then
                local replyitem = self:CreateReplyItem()
                replyitem:InitItem(Item, self)
                self.replyItemList[Index] = replyitem
            end
        end
    end
    self:SetHistoryItemsContentSize()
end

function M:RemoveReplyList()
    for Index, Item in ipairs(self.replyItemList) do
        self.replyItemList[Index]:DestroyItem()
    end
    self.replyItemList = {}
end

function M:ClosePanel()
    self:RemoveReplyList()
    self.npcChatManager:CloseChatingPanel()
end

return M
