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
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local PlayerChatManager = require('CP0102309_MG.Script.ui.ingame.dialog.PlayerChatManager')
local G = require('G')
local PicConst = require("CP0032305_GH.Script.common.pic_const")


local M = Component(ComponentBase)

function M:InitItem(VM)
    self.VM = VM
    self.ChannelId = VM.ChannelId
    self.Imgkey = VM.Imgkey
    self.MissionActId = VM.MissionActId
    self.BranchId = VM.BranchId

    self:SetUITextActor(self.NameText, VM.Text_Name.FieldValue)
    local profile = PicConst.GetPicResource(VM.UpdatePlayerProfile.FieldValue)
    self:SetSpriteOrTexture(self:GetIcon(), profile)

    self:SetActorActive(self.ImageItem, false)
    self:SetActorActive(self.MissionItem, false)
    self:SetActorActive(self.TextItem, false)

    if VM.ItemType == 0 then
        self:SetActorActive(self.TextItem, true)
        self:SetUITextActor(self.ContentText, VM.UpdateNoteInfo.FieldValue)
    elseif VM.ItemType == 1 then
        self:SetActorActive(self.ImageItem, true)
        local image = PicConst.GetPicResource(VM.Imgkey)
        if image ~= nil then
            self:SetSpriteOrTexture(self:GetImage(), image)
        end
    elseif VM.ItemType == 2 then
        self:SetActorActive(self.MissionItem, true)
        local image = PicConst.GetPicResource(VM.Imgkey)
        if image ~= nil then
            self:SetSpriteOrTexture(self:GetMissionImage(), image)
        end
        if VM.WS_MissionState.FieldValue == 0 then
            self:SetActorActive(self.AcceptBtn, true)
            self:SetActorActive(self.FinishBtn, false)
            self:SetUITextActor(self.MissionBtnText, VM.Text_AcceptInfo.FieldValue)
        else
            self:SetActorActive(self.FinishBtn, true)
            self:SetActorActive(self.AcceptBtn, false)
        end
        self:SetUITextActor(self.MissionContentText, VM.UpdateNoteInfo.FieldValue)
    end
end

function M:SetSpriteOrTexture(spriteTexturSwitcher, pic)
    if pic.SourceDimension then
        spriteTexturSwitcher:SetSprite(pic)
    else---UTexture2D
        spriteTexturSwitcher:SetTexture(pic)
    end
end

function M:OnAcceptMission()
    local player = G.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)

    PlayerChatManager.ContentUIState = 0

    self.VM.UpdateMissionState:SetFieldValue(1)

    self:SetActorActive(self.AcceptBtn, false)
    self:SetActorActive(self.FinishBtn, true)
    
    -- UIManager:OpenUI(UIDef.UIInfo["UI_MainInterfaceHUD"])
    player.MissionAvatarComponent:HandleDialogueChoice(self.VM.ChannelId, 0)
    player.TeleportComponent:Server_TeleportToOffice_RPC()
end


function M:ClickImage()
    local ImageKeys = {self.Imgkey}
    local WBPImg = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_ViewImg)
    WBPImg:SetImages(ImageKeys)
end

return M
