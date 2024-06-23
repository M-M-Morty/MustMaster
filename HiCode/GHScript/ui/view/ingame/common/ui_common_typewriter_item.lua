--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWidgetListItemBase = require('CP0032305_GH.Script.framework.ui.ui_widget_listitem_base')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')

local TIMER_INTERVAL = 0.04

---@type WBP_TypeWriter_Item_C
local M = Class(UIWidgetListItemBase)

local function CalcItemPosYForLineSpace(self)
    if self.ItemValue then
        if self.ItemValue.ItemIndex == 1 then
            return 0
        else
            return self.ItemValue.LineSpace
        end
    else
        return 0
    end
end

local function SetScalarParameterValue(self, value)
    self.Mask:GetEffectMaterial():SetScalarParameterValue('progress', value)
end

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

function M:OnConstruct()
    self.ItemValue = {}

    self.RichTextContentField = self:CreateUserWidgetField(self.SetTextContent)
    self.bPlayTypingField = self:CreateUserWidgetField(self.SetPlayTyping)
end

function M:TimerLoop()
    if self.ItemValue.CanMask and not self.MaskFinished then
        self:UpdateMask(TIMER_INTERVAL)
    end
    if self.EnableMerryGoRound then
        self:UpdateMerryGoRound(TIMER_INTERVAL)
    end
end

function M:Tick(MyGeometry, InDeltaTime)
end

function M:OnListItemObjectSet(ItemValue)
    if not UE.UKismetSystemLibrary.K2_IsValidTimerHandle(self.TimerHandle) then
        ---@type FTimerHandle
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerLoop}, TIMER_INTERVAL, true)
    end
    
    self.WBP_TypewriterRichText:SetText('')
    
    self.ItemValue = ItemValue.ItemValue:GetFieldValue()

    ViewModelBinder:BindViewModel(self.RichTextContentField, self.ItemValue.ContentField, ViewModelBinder.BindWayToWidget)
    ViewModelBinder:BindViewModel(self.bPlayTypingField, self.ItemValue.TypeWriterVM.bPlayTypingField, ViewModelBinder.BindWayToWidget)

    -- 换行功能后手动计算速度
    self.ItemValue.PlayDuration = self.ItemValue.PlayDuration / self.ItemValue.RichTextSize.X * self.ItemValue.ContentSize
    if not self.MaskFinished then
        SetScalarParameterValue(self, 0)
    end

    self.nowTime = 0
    self:SetProperty(
        self.ItemValue.InTextStyleSet,
        self.ItemValue.InDefaultTextStyle,
        self.ItemValue.InMinDesiredWidth,
        self.ItemValue.InJustification,
        self.ItemValue.InSizeToContent
    )
    self.MaskFinished = false
    self.EnableMerryGoRound = false


    if self.ItemValue.SizeX then
        local pos = (self.ItemValue.RichTextSize.X - self.ItemValue.SizeX) / 2
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Mask):SetPosition(UE.FVector2D(pos, CalcItemPosYForLineSpace(self)))
    else
        UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Mask):SetPosition(UE.FVector2D(0, CalcItemPosYForLineSpace(self)))
    end

end

function M:UpdateMerryGoRound(InDeltaTime)
    local Pos = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Mask):GetPosition()
    if Pos.X < -(self.ItemValue.MerryGoRoundLength - self.ItemValue.RichTextSize.X) then
        self.EnableMerryGoRound = false
        self.ItemValue.TypeWriterVM:TriggerFinishedEvent()
    end
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.Mask):SetPosition(UE.FVector2D(Pos.X - InDeltaTime * self.ItemValue.MerryGoRoundSpeed, CalcItemPosYForLineSpace(self)))
end

function M:SetTextContent(Content)
    self.WBP_TypewriterRichText:SetText(Content)
end

function M:UpdateMask(InDeltaTime)
    self.nowTime = self.nowTime + InDeltaTime
    local possess = self.nowTime / self.ItemValue.PlayDuration
    if not self.Mask or not self.Mask.GetEffectMaterial or not self.Mask:GetEffectMaterial() or not self.Mask:GetEffectMaterial().SetScalarParameterValue then
        return
    end
    SetScalarParameterValue(self, possess)
    local factor = self.ItemValue.bIsMerryGoRound and (self.ItemValue.RichTextSize.X / self.ItemValue.MerryGoRoundLength) or 1 
    if self.nowTime >= self.ItemValue.PlayDuration * factor then
        self:MaskFinish()
    end
end

function M:MaskFinish()
    SetScalarParameterValue(self, 1)
    self.MaskFinished = true
    if self.ItemValue.bIsMerryGoRound then
        self.EnableMerryGoRound = true
    else
        if UE.UKismetSystemLibrary.K2_IsValidTimerHandle(self.TimerHandle) then
            UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
        end
        self.ItemValue.TypeWriterVM:MaskNext()
    end
end

function M:SetPlayTyping(Data)
    self.MaskFinished = (Data == false) and true or false
    SetScalarParameterValue(self, Data == false and 1 or 0)
    if self.MaskFinished then
        self:MaskFinish()
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
    end
end

return M