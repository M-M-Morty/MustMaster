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
local PicConst = require("CP0032305_GH.Script.common.pic_const")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

local M = Component(ComponentBase)

function M:InitItem(VM)
    self.Imgkey = VM.Imgkey
    self:SetUITextActor(self.NameText, VM.Text_Name.FieldValue)
    local profile = PicConst.GetPicResource(VM.UpdatePlayerProfile.FieldValue)
    self:SetSpriteOrTexture(self:GetIcon(), profile)

    if VM.WS_NoteSwitcher.FieldValue == 0 then
        self:SetActorActive(self.TextItem, true)
        self:SetActorActive(self.ImageItem, false)

        self:SetUITextActor(self.ContentText, VM.UpdateNoteInfo.FieldValue)
    else
        self:SetActorActive(self.ImageItem, true)
        self:SetActorActive(self.TextItem, false)

        local sprite = PicConst.GetPicResource(self.Imgkey)
        if sprite ~= nil then
            self:SetSpriteOrTexture(self:GetImage(), sprite)
        end
    end
end

function M:SetSpriteOrTexture(spriteTexturSwitcher, pic)
    if pic.SourceDimension then
        spriteTexturSwitcher:SetSprite(pic)
    else---UTexture2D
        spriteTexturSwitcher:SetTexture(pic)
    end
end

function M:OnClickImage()
    local ImageKeys = {self.Imgkey}
    local WBPImg = UIManager:OpenUI(UIDef.UIInfo.UI_Knapsack_ViewImg)
    WBPImg:SetImages(ImageKeys)
end

return M
