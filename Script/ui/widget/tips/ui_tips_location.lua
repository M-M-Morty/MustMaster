--
-- @COMPANY GHGame
-- @AUTHOR zhengyanshuai
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')

---@type WBP_Tips_Location_C
local WBP_Tips_Location = Class(UIWindowBase)

--function WBP_Tips_Location:Initialize(Initializer)
--end

--function WBP_Tips_Location:PreConstruct(IsDesignTime)
--end

function WBP_Tips_Location:OnConstruct()
end

function WBP_Tips_Location:UpdateParams(RegionText, LangText)
    self.Text_Name:SetText(RegionText)
    self.Text_Lang:SetText(LangText)
end

function WBP_Tips_Location:OnShow()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    
end
--function WBP_Tips_Location:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Tips_Location:FadeOutEnd()
    self:CloseMyself()
end

return WBP_Tips_Location
