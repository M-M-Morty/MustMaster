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
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')

---@type WBP_Tips_Second_TaskCompleted_C
local WBP_Tips_Second_TaskCompleted = Class(UIWindowBase)

--function WBP_Tips_Second_TaskCompleted:Initialize(Initializer)
--end

--function WBP_Tips_Second_TaskCompleted:PreConstruct(IsDesignTime)
--end

-- function WBP_Tips_Second_TaskCompleted:OnConstruct()
-- end

--function WBP_Tips_Second_TaskCompleted:Tick(MyGeometry, InDeltaTime)
--end



function WBP_Tips_Second_TaskCompleted:OnShow()
    self:PlayAnimation(self.DX_in,0,1,UE.EUMGSequencePlayMode.Forward,1.0,false)
    
end

function WBP_Tips_Second_TaskCompleted:UpdateParams(MissionText)
    self.Text_Tips2:SetText(MissionText)
    
end

function WBP_Tips_Second_TaskCompleted:FadeOutEnd()
    self:CloseMyself()
    
end

return WBP_Tips_Second_TaskCompleted
