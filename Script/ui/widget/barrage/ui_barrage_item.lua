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
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local utils = require("common.utils")
local Brg = require("ui.widget.barrage.ui_barrage")
local BrgVM = require('CP0032305_GH.Script.viewmodel.ingame.hud.barrage_vm')

local TIMER_INTERVAL = 0.05

---@class UI_Barrage_Item: WBP_Barrage_Item_C
local UI_Barrage_Item = Class(UIWidgetBase)

--function UI_Barrage_Item:Initialize(Initializer)
--end

--function UI_Barrage_Item:PreConstruct(IsDesignTime)
--end

function UI_Barrage_Item:OnConstruct()
    self.BrgInfo = {}
    self.VerticalInfo = {}

    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
end

function UI_Barrage_Item:OnDestruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
    if self.BrgInfo.MainUI and UE.UKismetSystemLibrary.IsValid(self.BrgInfo.MainUI) then
        self.BrgInfo.MainUI:QueryCloseUI()
    end
end

-- function UI_Barrage_Item:Tick(MyGeometry, InDeltaTime)
-- end

function UI_Barrage_Item:TimerLoop()
    if self.BrgInfo.Motion and self.BrgInfo.Motion == BrgVM.EBrgMotion.Vertical then
        if self.BrgInfo.CurDuration then
            self.BrgInfo.CurDuration = self.BrgInfo.CurDuration + TIMER_INTERVAL
            if self.BrgInfo.CurDuration >= self.BrgInfo.Duration then
                self.BrgInfo.CurDuration = nil
                self:RemoveFromParent()
                self.BrgInfo.Task.VerticalMgr:RemoveBrg(self.VerticalInfo.ID)
            end
        end
    elseif self.BrgInfo.Motion and self.BrgInfo.Motion == BrgVM.EBrgMotion.Boom then
        if self.BrgInfo.CurDuration then
            self.BrgInfo.CurDuration = self.BrgInfo.CurDuration + TIMER_INTERVAL
            if self.BrgInfo.CurDuration >= self.BrgInfo.Duration then
                self.BrgInfo.CurDuration = nil
                self:RemoveFromParent()
            end
        end
    end
end

---`brief`初始化这个弹幕
---@param BrgIdx number
---@param Text string
---@param Style EBrgStyle
---@param Motion BrgVM.EBrgMotion
---@param Speed number
---@param Pos UE.FVector
---@param Duration number
function UI_Barrage_Item:InitBrg(BrgIdx, Text, Style, Motion, Speed, Pos, Duration, Task, MainUI)
    self.BrgInfo.Task = Task
    self.BrgInfo.BrgIdx = BrgIdx
    self.BrgInfo.Text = Text
    self.BrgInfo.Style = Style
    self.BrgInfo.Motion = Motion
    self.BrgInfo.Speed = Speed
    self.BrgInfo.Pos = Pos
    self.BrgInfo.Duration = Duration
    self.BrgInfo.CurDuration = 0
    self.BrgInfo.MainUI = MainUI
    self['Txt_Barrage0' .. Style]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self['Txt_Barrage0' .. Style]:SetText(Text)
    if Motion == BrgVM.EBrgMotion.Roll then
        self:BeginRoll(Speed)
        if Pos then
            UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsPos):SetPosition(UE.FVector2D(0, Pos.Y))
        end
    elseif Motion == BrgVM.EBrgMotion.Vertical then
        if Pos then
            UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsPos):SetPosition(Pos)
        else
            self['Txt_Barrage0' .. Style]:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    elseif Motion == BrgVM.EBrgMotion.Boom then
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsPos):SetPosition(Pos)
    end
end

---`brief`
---@param Info VerticalBrgItem
function UI_Barrage_Item:InitVertical(Info)
    self.VerticalInfo = Info
end

---`brief`开始滚动
---@param Speed number 初始滚动速度
function UI_Barrage_Item:BeginRoll(Speed)
    self.BrgInfo.Speed = Speed
    self:PlayAnimation(self.Roll, 0, 1, UE.EUMGSequencePlayMode.Forward, Speed, false)
    self:BindToAnimationFinished(self.Roll, {self, self.PlayRollFinish})
end

function UI_Barrage_Item:PlayRollFinish()
    self:RemoveFromParent()
end

---`brief`设置弹幕滚动速度
---@param Speed number 弹幕滚动速度
function UI_Barrage_Item:ChangeRollAnimSpeed(Speed)
    self.BrgInfo.Speed = Speed
    self:SetPlaybackSpeed(self.Roll, Speed)
end

function UI_Barrage_Item:GetBrgSize()
    return self:Measure(UE.UKismetStringLibrary.GetCharacterArrayFromString(self.BrgInfo.Text), self:GetFont(self['Txt_Barrage0' .. self.BrgInfo.Style]))
end

---@param Pos UE.FVector
function UI_Barrage_Item:SetPos(Pos)
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.CvsPos):SetPosition(Pos)
    self['Txt_Barrage0' .. self.BrgInfo.Style]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
end

return UI_Barrage_Item
