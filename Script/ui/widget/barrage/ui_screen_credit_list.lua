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
local BrgVM = require('CP0032305_GH.Script.viewmodel.ingame.hud.barrage_vm')

local TIMER_INTERVAL = 0.2
local CLOSE_COOL_DOWN = 1

---@class UI_ScreenCreditList WBP_ScreenCreditList_C
local UI_ScreenCreditList = Class(UIWindowBase)

---@param self UI_ScreenCreditList
local function BuildWidgetProxy(self)
    ---@type UTileViewProxy
    self.ListScreenCreditProxy = WidgetProxys:CreateWidgetProxy(self.ListScreenCredit)
end

--function UI_ScreenCreditList:Initialize(Initializer)
--end

--function UI_ScreenCreditList:PreConstruct(IsDesignTime)
--end

function UI_ScreenCreditList:OnConstruct()
    BuildWidgetProxy(self)
end

--function UI_ScreenCreditList:Tick(MyGeometry, InDeltaTime)
--end

function UI_ScreenCreditList:OnShow()
    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)

    self.ShowInfo = {}
    self.ShowInfo.CloseCD = nil
    self.ShowInfo.Speed = 20
    self.ShowInfo.Roll = true
    self:PlayAnimation(self.DX_BlackIn, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UI_ScreenCreditList:OnHide()
    self.ShowInfo = {}
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

function UI_ScreenCreditList:TimerLoop()
    if self.ShowInfo.CloseCD then
        self.ShowInfo.CloseCD = self.ShowInfo.CloseCD - TIMER_INTERVAL
        if self.ShowInfo.CloseCD < 0 then
            self:BeginClose()
            self.ShowInfo.CloseCD = nil
        end
    end
end

function UI_ScreenCreditList:BeginClose()
    local PlayAnimProxy = UE.UWidgetAnimationPlayCallbackProxy.CreatePlayAnimationProxyObject(UE.NewObject(UE.UUMGSequencePlayer), self, self.FadeOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1)
    PlayAnimProxy.Finished:Add(self, function()
        local BrgVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.BarrageVM.UniqueName)
        BrgVM:CloseScreenCreditList()
    end)

    -- self:PlayAnimation(self.DX_BlackOut, 0, 1, UE.EUMGSequencePlayMode.Forward, 1.0, false)
    -- self:BindToAnimationFinished(self.DX_BlackOut, {self, self.PlayFinish})
end

function UI_ScreenCreditList:PlayFinish()
    local BrgVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.BarrageVM.UniqueName)
    BrgVM:CloseScreenCreditList()
end

---@param Content table
function UI_ScreenCreditList:ShowScreenCreditList(Content)
    Content[#Content].isEnd = true
    self.ListScreenCreditProxy:SetListItems(Content)
    -- UnLua.LogWarn("zys list view size", self.ListScreenCredit:GetDesiredSize())
    self:PlayAnimation(self.Roll, 0, 1, UE.EUMGSequencePlayMode.Forward, 0.5, false)
end

function UI_ScreenCreditList:FeedDog()
    self.ShowInfo.CloseCD = CLOSE_COOL_DOWN
end

return UI_ScreenCreditList
