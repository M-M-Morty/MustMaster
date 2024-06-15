--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

---@class WBP_HUD_Stamina_C
local UIStamina = Class(UIWidgetBase)

function UIStamina:OnConstruct()
    self:InitWidget()
end

function UIStamina:InitWidget()
    self.Duration = 1
    self.RedPercent = 0.3
    self.PlaySpeed = 0.5
    self.GetOldPercent = 1
    self.AnimProgress = 0
    self.EndAtTime = 0
    self:SetVisibility(UE.ESlateVisibility.Hidden)
end

-- function UIStamina:OnShow()
-- end


function UIStamina:SetPercent(lastPercent, percent)
    if self.RedPercent > percent then
        self:OnChangeRed()
    else
        self:OnChangeWhite()
    end
    self:SetStaminaActive()
    if percent >= 1 then
        self:OnPlayEndAnimation()
    end
    if percent > lastPercent then
        self.StartAtTime = lastPercent
        self.EndAtTime = percent
        self:OnPlayAddAnimation()
    else
        self.StartAtTime = 1 - lastPercent
        self.EndAtTime = 1 - percent
        if self.StartAtTime < self.EndAtTime then
            self:OnPlaySubtractAnimation()
        end
    end
end

function UIStamina:OnChangeRed()
    self.PB_StaminaBuffer:SetColorAndOpacity(self.RedStaminaColor)
    self.PB_Stamina_Red_BG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PB_Stamina_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIStamina:OnChangeWhite()
    self.PB_StaminaBuffer:SetColorAndOpacity(self.WhiteStaminaColor)
    self.PB_Stamina_BG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.PB_Stamina_Red_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UIStamina:OnPlaySubtractAnimation()
    self:StopAnimation(self.DX_PBBuffer_Reverse)
    self:StopAnimation(self.DX_PBBuffer)
    self:PlayAnimationTimeRange(self.DX_PBBuffer_Reverse, self.StartAtTime, self.EndAtTime, 1,
        UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIStamina:OnPlayAddAnimation()
    self:StopAnimation(self.DX_PBBuffer_Reverse)
    self:StopAnimation(self.DX_PBBuffer)
    self:PlayAnimationTimeRange(self.DX_PBBuffer, self.StartAtTime, self.EndAtTime, 1, UE.EUMGSequencePlayMode.Forward,
        self.PlaySpeed, false)
end

function UIStamina:OnPlayEndAnimation()
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIStamina:OnPlayEnterAnimation()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, self.PlaySpeed, false)
end

function UIStamina:SetStaminaActive()
    self:StopAnimation(self.DX_Out)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.StaminaCanvas:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:SetRenderOpacity(1)
    self.StaminaCanvas:SetRenderOpacity(1)
end

function UIStamina:SetStaminaHide()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.StaminaCanvas:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:SetRenderOpacity(0)
    self.StaminaCanvas:SetRenderOpacity(0)
end

function UIStamina:OnStaminaClose()
    self:OnPlayEndAnimation()
end

return UIStamina
