--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ConstText = require("CP0032305_GH.Script.common.text_const")
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@class WBP_Common_SecondTextConfirm : WBP_Common_SecondTextConfirm_C

---@class WBP_Common_SecondTextConfirm_C
local WBP_Common_SecondTextConfirm = Class(UIWindowBase)


function WBP_Common_SecondTextConfirm:Construct()
    self.WBP_Common_Popup_Small:SetOwnerWidget(self)
    self:SetCloseBtnVisibility(UE.ESlateVisibility.Collapsed)
end

---@param TitleKey string
---@param ContentKey string
function WBP_Common_SecondTextConfirm:SetTitleAndContent(TitleKey, ContentKey)
    self.WBP_Common_Popup_Small:SetTitle(TitleKey)
    if ContentKey then
        local Content = ConstText.GetConstText(ContentKey)
        self.TextContent:SetText(Content)
    end
end

function WBP_Common_SecondTextConfirm:OnShow()
    ---@type WBP_Common_Popup_Small
    local WBP_Common_Popup_Small = self.WBP_Common_Popup_Small
    WBP_Common_Popup_Small:PlayInAnim()
end

function WBP_Common_SecondTextConfirm:SetCloseBtnVisibility(bShow)
    ---@type WBP_Common_Popup_Small
    local WBP_Common_Popup_Small = self.WBP_Common_Popup_Small
    WBP_Common_Popup_Small.WBP_Btn_SmallPopUpClose:SetVisibility(bShow)
end

return WBP_Common_SecondTextConfirm

