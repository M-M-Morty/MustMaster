--
-- @COMPANY GHGame
-- @AUTHOR xuminjie 
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')

local HIGN_LIGHT_TIME = 3

---@type WBP_HUD_TimerDisplay_C
local WBP_HUD_TimerDisplay = Class(UIWindowBase)

--function WBP_HUD_TimerDisplay:Initialize(Initializer)
--end

--function WBP_HUD_TimerDisplay:PreConstruct(IsDesignTime)
--end

function WBP_HUD_TimerDisplay:OnConstruct()
    self.Effect_Timer:SetVisibility(UE.ESlateVisibility.Hidden)
    self.Button_Close.OnClicked:Add(self, self.Button_Close_OnClicked)
end

function WBP_HUD_TimerDisplay:OnShow()
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function WBP_HUD_TimerDisplay:UpdateParams(DurationTime, Callback)
    self.ExpireTime = DurationTime
    self.DurationTime = DurationTime
    self.Callback = Callback
    self.bStartRedShine = false
    self.Effect_Timer:SetVisibility(UE.ESlateVisibility.Hidden)
end

function WBP_HUD_TimerDisplay:Button_Close_OnClicked()
    self:InvokeCallback()
end

function WBP_HUD_TimerDisplay:InvokeCallback()
    if self.Callback then
        self.Callback(self.ExpireTime <= 0)
        self:PlayAnimation(self.DX_out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false) 
    end
end

function WBP_HUD_TimerDisplay:DXOutFinishEnd()
    self:CloseMyself()
end

function Num2TimeDisplay(num)
    local str = ''
    local minute = math.floor(num / 60)
    local second = num % 60
    str = string.rep('0', 2 - string.len(tostring(minute))) .. minute .. ':' .. string.rep('0', 2 - string.len(tostring(second))) .. second
    return str

end

function WBP_HUD_TimerDisplay:Tick(MyGeometry, InDeltaTime)
    if self.ExpireTime > 0 then
        self.ExpireTime = self.ExpireTime - InDeltaTime

        local CeilNum = math.ceil(self.ExpireTime)
        if CeilNum <= 0 then
            self:InvokeCallback()
        elseif CeilNum <= HIGN_LIGHT_TIME and not self.bStartRedShine then
            self.bStartRedShine = true
            self.Effect_Timer:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:PlayAnimation(self.DX_RedShine, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
        end
        self.Text_Timer:SetText(Num2TimeDisplay(CeilNum))
    end
end

return WBP_HUD_TimerDisplay
