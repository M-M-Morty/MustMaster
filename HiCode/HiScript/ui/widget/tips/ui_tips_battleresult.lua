--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')


---@type WBP_Tips_BattleResult_C
local WBP_Tips_BattleResult = Class(UIWindowBase)

--function WBP_Tips_BattleResult:Initialize(Initializer)
--end

--function WBP_Tips_BattleResult:PreConstruct(IsDesignTime)
--end

function WBP_Tips_BattleResult:OnConstruct()
end

--function WBP_Tips_BattleResult:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Tips_BattleResult:UpdateParams(bWin)
    self.WidgetSwitcher_Win:SetActiveWidgetIndex(bWin and 1 or 0)

    self:StopAnimationsAndLatentActions()
    if bWin then
        self:PlayAnimation(self.DX_BattleSuccess, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    else
        self:PlayAnimation(self.DX_BattleFail, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    end
end


function WBP_Tips_BattleResult:DXEventBattleSuccessEnd()
    self:CloseMyself()
end

function WBP_Tips_BattleResult:DXEventBattleFailEnd()
    self:CloseMyself()
end

return WBP_Tips_BattleResult
