--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

---@class WBP_Common_RightPopupWindow_C
local UICommonRightPopupWindow = Class(UIWidgetBase)

function UICommonRightPopupWindow:OnConstruct()
end

function UICommonRightPopupWindow:SetCloseBtnVisibility(bShow)
    self.WBP_Common_TopContent.CommonButton_Close:SetVisibility(bShow)
end

function UICommonRightPopupWindow:SetTitleText(txt)
    if txt then
        self.Txt_Title:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Txt_Title:SetText(txt)
    end
end

return UICommonRightPopupWindow
