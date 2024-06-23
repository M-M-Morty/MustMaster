--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local ConstText = require("CP0032305_GH.Script.common.text_const")

---@class WBP_Knapsack_ViewText : WBP_Knapsack_ViewText_C

---@type WBP_Knapsack_ViewText_C
local WBP_Knapsack_ViewText = Class(UIWindowBase)

local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6

---@param self WBP_Knapsack_ViewText
local function ShowUpShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Knapsack_ViewText
local function ShowDownShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
end

---@param self WBP_Knapsack_ViewText
local function ShowBothShadow(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Knapsack_ViewText
---@param Offset float
local function OnUserScrolled(self, Offset)
    if Offset < 0.1 then
        ShowDownShadow(self)
    elseif math.abs(Offset - self.ScrollBoxContent:GetScrollOffsetOfEnd()) < 1 then
        ShowUpShadow(self)
    else
        ShowBothShadow(self)
    end
end

---@param self WBP_Knapsack_ViewText
local function OnClickCloseButton(self)
    self:PlayAnimation(self.DX_Out, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
end

function WBP_Knapsack_ViewText:Construct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Add(self, OnClickCloseButton)
    self.ScrollBoxContent.OnUserScrolled:Add(self, OnUserScrolled)
end

function WBP_Knapsack_ViewText:Destruct()
    self.WBP_Common_TopContent.CommonButton_Close.OnClicked:Remove(self, OnClickCloseButton)
    self.ScrollBoxContent.OnUserScrolled:Remove(self, OnUserScrolled)
end

function WBP_Knapsack_ViewText:OnShow()
    self:PlayAnimation(self.DX_In, 0, 1, UE.EUMGSequencePlayMode.Forward, 1, false)
    self.ScrollBoxContent:ScrollToStart()
    local Offset = self.ScrollBoxContent:GetScrollOffset()
    OnUserScrolled(self, Offset)
end

function WBP_Knapsack_ViewText:OnAnimationFinished(Animation)
    if Animation == self.DX_Out then
        UIManager:CloseUI(self, true)
    end
end

---@param TextKeys string[]
function WBP_Knapsack_ViewText:SetTexts(TextKeys)
    if #TextKeys == 1 then
        self.CanvasPanelTitle:SetVisibility(UE.ESlateVisibility.Collapsed)
        local Body = ConstText.GetConstText(TextKeys[1])
        self.Text_Content:SetText(Body)
    elseif #TextKeys == 2 then
        self.CanvasPanelTitle:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local Title = ConstText.GetConstText(TextKeys[1])
        self.RichText_Title:SetText(Title)
        local Body = ConstText.GetConstText(TextKeys[2])
        self.Text_Content:SetText(Body)
    else
        G.log:error("WBP_Knapsack_ViewText", "Task item config error! text key length is not 1 or 2!")
    end
end

return WBP_Knapsack_ViewText
