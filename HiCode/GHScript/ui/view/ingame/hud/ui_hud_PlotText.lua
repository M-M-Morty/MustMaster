--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR CuiZhiyuan
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

---@type WBP_HUD_PlotText_C
local WBP_HUD_PlotText = Class(UIWindowBase)

--function WBP_HUD_PlotText:Initialize(Initializer)
--end

--function WBP_HUD_PlotText:PreConstruct(IsDesignTime)
--end


function WBP_HUD_PlotText:OnConstruct()
    self:InitWidget()
end


--function WBP_HUD_PlotText:Tick()
--end

function WBP_HUD_PlotText:InitWidget()
end

function WBP_HUD_PlotText:UpdateParams(InText)
    self.Text_PlotText:SetText(InText)
end

function WBP_HUD_PlotText:OnShow()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_PlotText:SePlotText(ChangeText)
    self.Text_PlotText:SetText(ChangeText)
    
end

function WBP_HUD_PlotText:PlotTextClose()
    self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_PlotText:OnDXOut()
    self:CloseMyself(true)
end


return WBP_HUD_PlotText
