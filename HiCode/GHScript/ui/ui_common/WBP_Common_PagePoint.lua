--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_PagePoint : WBP_Common_PagePoint_C

---@type WBP_Common_PagePoint_C
local WBP_Common_PagePoint = UnLua.Class()

---@param bSelected boolean
function WBP_Common_PagePoint:SetSelected(bSelected)
    if bSelected then
        self.Image_Circle_Selected:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.Image_Circle_Selected:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

return WBP_Common_PagePoint
