--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')

---@type WBP_Common_CircularProgressBar_C
local WBP_Common_CircularProgressBar = Class(UIWindowBase)

function WBP_Common_CircularProgressBar:OnConstruct()
    self:GetProgressRange()
    self:InitParams()
    self:SetPercent(self.Percent)
end

function WBP_Common_CircularProgressBar:Init()
end


---根据遮罩的始末角度，获取进度条的角度范围(%)
function WBP_Common_CircularProgressBar:GetProgressRange()
    local angleSub = math.abs(self.StartAngle - self.EndAngle)
    self.angleRange = 0
    if angleSub > 0.5 then
        self.angleRange = 1 - angleSub
    else
        self.angleRange = angleSub
    end
end

---设置进度条为顺时针还是逆时针进行遮罩
function WBP_Common_CircularProgressBar:InitParams()
    local parameter
    self.ProgressBarFill:GetDynamicMaterial():SetTextureParameterValue("Texture", self.ProgressBarFillTexture)

    self.ProgressBarFill:GetDynamicMaterial():SetScalarParameterValue("StartAngle", self.StartAngle)
    if self.Clockwise then
        parameter = 1
    else
        parameter = 0
    end
    self.ProgressBarFill:GetDynamicMaterial():SetScalarParameterValue("Clockwise", parameter)
end

function WBP_Common_CircularProgressBar:SetPercent(percent)
    local percentParam
    if self.Clockwise then
        percentParam = percent * self.angleRange
    else
        percentParam = 1 - percent * self.angleRange
    end
    self.ProgressBarFill:GetDynamicMaterial():SetScalarParameterValue("percent", percentParam)
end

return WBP_Common_CircularProgressBar
