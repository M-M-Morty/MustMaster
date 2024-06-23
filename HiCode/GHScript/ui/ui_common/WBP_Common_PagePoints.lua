--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
---@class WBP_Common_PagePoints : WBP_Common_PagePoints_C
---@field Max integer
---@field Current integer

---@type WBP_Common_PagePoints_C
local WBP_Common_PagePoints = UnLua.Class()

local TOTAL = 6

---@param Max integer
function WBP_Common_PagePoints:SetMax(Max)
    self.Max = Max
    self.Current = 1
    for i = 1, TOTAL do
        if i <= Max then
            ---@type WBP_Common_PagePoint
            local WBPCommonPagePoint = self["WBP_Common_PagePoint"..i]
            WBPCommonPagePoint:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if i == self.Current then
                WBPCommonPagePoint:SetSelected(true)
            else
                WBPCommonPagePoint:SetSelected(false)
            end
        else
            self["WBP_Common_PagePoint"..i]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---@param Current integer
function WBP_Common_PagePoints:SetCurrent(Current)
    self.Current = Current
    for i = 1, self.Max do
        ---@type WBP_Common_PagePoint
        local WBPCommonPagePoint = self["WBP_Common_PagePoint"..i]
        if i == self.Current then
            WBPCommonPagePoint:SetSelected(true)
        else
            WBPCommonPagePoint:SetSelected(false)
        end
    end
end

return WBP_Common_PagePoints
