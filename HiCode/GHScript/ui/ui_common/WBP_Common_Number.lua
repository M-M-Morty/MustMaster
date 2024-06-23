--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local MathUtil = require("CP0032305_GH.Script.common.utils.math_util")

---@class WBP_Common_Number : WBP_Common_Number_C
---@field Min integer
---@field Max integer
---@field Step integer

---@type WBP_Common_Number_C
local WBP_Common_Number = UnLua.Class()

---@param self WBP_Common_Number
local function EnableButtons(self)
    local Value = self:GetValue()
    self.WBP_ComBtn_Subtract:SetIsEnabled(MathUtil.rounding(Value)  > self.Step)
    self.WBP_ComBtn_Add:SetIsEnabled(MathUtil.rounding(Value) < self.Max)
end

---@param Min integer
---@param Max integer
---@param Step integer
function WBP_Common_Number:InitData(Min, Max, Step)
    if Min then
        self.Min = Min
    end
    if Max then
        self.Max = Max
    end
    if Step then
        self.Step = Step
    end
    self.Slider_Number:SetMinValue(self.Min)
    self.Slider_Number:SetMaxValue(self.Max)
    self.Slider_Number:SetStepSize(self.Step)
    self.Slider_Number:SetValue(self.Step)
    EnableButtons(self)
end

function WBP_Common_Number:GetValue()
    return MathUtil.rounding(self.Slider_Number:GetValue())
end

---@param self WBP_Common_Number
---@param Value number
local function OnValueChanged(self, Value)
    self.OnValueChanged:Broadcast(MathUtil.rounding(Value))
    EnableButtons(self)
end

---@param self WBP_Common_Number
local function OnClickAdd(self)
    local Value = self:GetValue()
    Value = math.min(self.Max, Value + self.Step)
    self.Slider_Number:SetValue(Value)
    OnValueChanged(self, Value)
end

---@param self WBP_Common_Number
local function OnClickSubtract(self)
    local Value = self:GetValue()
    Value = math.max(self.Min, Value - self.Step)
    self.Slider_Number:SetValue(Value)
    OnValueChanged(self, Value)
end

---@param self WBP_Common_Number
local function OnMouseCaptureEnd(self)
    local Value = self:GetValue()
    Value = math.max(self.Step, Value)
    self.Slider_Number:SetValue(Value)
    OnValueChanged(self, Value)
    EnableButtons(self)
end

function WBP_Common_Number:Construct()
    self.Min = 0
    self.Max = 100
    self.Step = 1
    self.Slider_Number.OnValueChanged:Add(self, OnValueChanged)
    self.WBP_ComBtn_Add.OnClicked:Add(self, OnClickAdd)
    self.WBP_ComBtn_Subtract.OnClicked:Add(self, OnClickSubtract)
    self.Slider_Number.OnMouseCaptureEnd:Add(self, OnMouseCaptureEnd)
end

function WBP_Common_Number:Destruct()
    self.Slider_Number.OnValueChanged:Remove(self, OnValueChanged)
    self.WBP_ComBtn_Add.OnClicked:Remove(self, OnClickAdd)
    self.WBP_ComBtn_Subtract.OnClicked:Remove(self, OnClickSubtract)
    self.Slider_Number.OnMouseCaptureEnd:Remove(self, OnMouseCaptureEnd)
end

return WBP_Common_Number
