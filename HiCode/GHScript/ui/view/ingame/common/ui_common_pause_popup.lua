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
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@class WBP_Common_MiniGames_PausePopup_C
local UICommonPausePopup = Class(UIWindowBase)

--function UICommonPausePopup:Initialize(Initializer)
--end

--function UICommonPausePopup:PreConstruct(IsDesignTime)
--end

-- function UICommonPausePopup:Construct()
-- end

--function UICommonPausePopup:Tick(MyGeometry, InDeltaTime)
--end

function UICommonPausePopup:OnConstruct()
    self:InitWidget()
end

function UICommonPausePopup:OnShow()
end

function UICommonPausePopup:UpdateParams(fnReStart, fnContinue, fnExit, window)
    self.fnReStart = fnReStart
    self.fnContinue = fnContinue
    self.fnExit = fnExit
    self.targetWinodw = window
end

function UICommonPausePopup:InitWidget()
    self.WBP_Btn_PausePopup_Quit.OnClicked:Add(self, self.Quit_OnClick)
    self.WBP_Btn_PausePopup_Resetting.OnClicked:Add(self, self.Resetting_OnClick)
    self.WBP_Btn_PausePopup_Continue.OnClicked:Add(self, self.Continue_OnClick)
end

function UICommonPausePopup:Quit_OnClick()
    ---@type WBP_Common_SecondTextConfirm_C
    self.PopUpInstance = UIManager:OpenUI(UIDef.UIInfo.UI_Common_SecondTextConfirm)
    self:OnOpenConfirmWindow()
end

function UICommonPausePopup:Resetting_OnClick()
    self.fnReStart(self.targetWinodw)
    self:CloseWindow()
end

function UICommonPausePopup:Continue_OnClick()
    self.fnContinue(self.targetWinodw)
    self:CloseWindow()
end

function UICommonPausePopup:AddBindQuitFunc()
    self.fnExit(self.targetWinodw)
    self:CloseWindow()
end

function UICommonPausePopup:OnOpenConfirmWindow()
    self.PopUpInstance.WBP_Common_Popup_Small:BindCommitCallBack(self, self.AddBindQuitFunc)
    self.PopUpInstance:SetTitleAndContent(self.targetWinodw.TitleText, self.targetWinodw.QuitText)
end

function UICommonPausePopup:CloseWindow()
    self:CloseMyself(true)
end

function UICommonPausePopup:OnReturn()
    self:Continue_OnClick()
end

return UICommonPausePopup
