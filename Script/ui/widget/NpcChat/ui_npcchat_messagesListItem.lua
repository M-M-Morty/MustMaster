--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local DialogueObjectModule = require("mission.dialogue_object")

local M = UnLua.Class()


--vm_chat_chatlist_item
function M:SetData(itemData, parentPanel)
    self.parentPanel = parentPanel
    self.npcID = itemData.DataId
    local PlayerChatHistory = PlayerChatManager.ChatData[self.npcID].ChatHistoryData     --里面是四种itemvm
    local name, content =  self:GetLastestChatItem(PlayerChatHistory)
    if name ~= nil then
        self:SetUITextActor(self.ContentText, content)
        self:SetUITextActor(self.NameText, name)
    end

    local bShowRedpoint = PlayerChatManager.RedDotState[2][self.npcID]
    if bShowRedpoint then
        self:SetRedpointPoint(true)
    else
        if PlayerChatHistory ~= nil then
            local isChating = PlayerChatManager.ChatData[self.npcID].ChatHistoryData[#PlayerChatManager.ChatData[self.npcID].
            ChatHistoryData] ~= DialogueObjectModule.DialogueType.FINISHED
            self:SetChatingRedPoint(isChating)
        end
    end

    local profile = PicConst.GetPicResource(itemData.Imgkey)
    self:SetProfileIcon(profile)
end

function M:SetProfileIcon(profile)
    if profile.SourceDimension then
        self:GetIcon():SetSprite(profile)
        self:SetProfileSpriteActor(profile)
    else---UTexture2D
        self:GetIcon():SetTexture(profile)
    end
end

function M:GetNoteContent(note)
    local WrapStr = ""
    local StrArrs = self:GetCharArray(note)
    local LengthCount = 0
    for _, Value in pairs(StrArrs) do
        WrapStr = WrapStr .. Value.Str
        LengthCount = LengthCount + Value.Count
        if LengthCount >= 36.08 then
            WrapStr = WrapStr .. "..."
            break
        end
    end
    return WrapStr
end

-- 转换字符串为字符数组
function M:GetCharArray(Str)
    Str = Str or ""
    local Array = {}
    local Len = string.len(Str)
    while Str do
        local FontUTF = string.byte(Str, 1)
        if FontUTF == nil then
            break
        end
        local ByteCount = 0
        if FontUTF <= 127 then
            ByteCount = 1
        elseif FontUTF >= 192 and FontUTF <= 223 then
            ByteCount = 2
        elseif FontUTF >= 224 and FontUTF <= 239 then
            ByteCount = 3
        elseif FontUTF >= 240 then
            ByteCount = 4
        end
        local Temp = string.sub(Str, 1, ByteCount)
        Array[#Array + 1] = {
            Str = Temp,
            Count = ByteCount >= 3 and 1.64 or 1
        }
        Str = string.sub(Str, ByteCount + 1, Len)
    end
    return Array
end

function M:GetLastestChatItem(chatHistory)
    for i = #chatHistory, 1, -1 do
        if chatHistory[i].WS_ItemType:GetFieldValue() == 0 then
            if chatHistory[i].ItemType == 0 then
                return chatHistory[i].Text_Name.FieldValue, self:GetNoteContent(chatHistory[i].UpdateNoteInfo.FieldValue)
            elseif chatHistory[i].ItemType == 1 then
                return chatHistory[i].Text_Name.FieldValue, "[图片]"
            else
                return chatHistory[i].Text_Name.FieldValue, self:GetNoteContent(chatHistory[i].UpdateNoteInfo.FieldValue)
            end
        elseif  chatHistory[i].WS_ItemType:GetFieldValue() == 1 then
            if chatHistory[i].WS_NoteSwitcher.FieldValue == 0 then
                return chatHistory[i].Text_Name.FieldValue, self:GetNoteContent(chatHistory[i].UpdateNoteInfo.FieldValue)
            else
                return chatHistory[i].Text_Name.FieldValue, "[图片]"
            end
        end
    end
    return nil
end

function M:ClickMessageListItem()
    if PlayerChatManager.RedDotState[2][self.npcID] then
        PlayerChatManager.RedDotState[2][self.npcID] = false
    end
   self.parentPanel.npcChatManager:OpenChatingPanel(self.npcID)
end


return M
