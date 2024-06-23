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
local utils = require("common.utils")

local TIMER_INTERVAL = 0.1

---@type WBP_Tips_Tips2_C
local WBP_Tips_Common = Class(UIWindowBase)

--function WBP_Tips_Common:Initialize(Initializer)
--end

--function WBP_Tips_Common:PreConstruct(IsDesignTime)
--end

function WBP_Tips_Common:OnConstruct()
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

-- function WBP_Tips_Common:Tick(MyGeometry, InDeltaTime)
-- end

function WBP_Tips_Common:OnDestruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

function WBP_Tips_Common:TimerLoop()
    if self.CurMsgInfo and self.CurMsgInfo.Duration then
        self.CurMsgInfo.Duration = self.CurMsgInfo.Duration - TIMER_INTERVAL
        if self.CurMsgInfo.Duration < 0 then
            self:CloseMyself(true)
        end
    end
end

---@param Message string
---@param Duration number
function WBP_Tips_Common:AddMessage(Message, Duration)
    G.log:debug("zys", table.concat({"WBP_Tips_Common:AddMessage, msg: ", tostring(Message), "duration: ", tostring(Duration)}))
    self:StopAnimationsAndLatentActions()
    self.CurMsgInfo = {}
    self.CurMsgInfo.Message = Message
    self.CurMsgInfo.Duration = Duration or 2
    self.Text_Content:SetText(Message)
    self:PlayAnimation(self.DX_in, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

-- function WBP_Tips_Common:AnimEnd()
    -- self:CloseMyself()
-- end

return WBP_Tips_Common
