--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Common_RedDot : WBP_Common_RedDot_C

---@type WBP_Common_RedDot_C
local WBP_Common_RedDot = UnLua.Class()

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

function WBP_Common_RedDot:ShowRedDot()
    self.Switch_RedDot:SetActiveWidgetIndex(0)
end

function WBP_Common_RedDot:ShowNew()
    self.Switch_RedDot:SetActiveWidgetIndex(1)
end

function WBP_Common_RedDot:ShowGift()
    self.Switch_RedDot:SetActiveWidgetIndex(2)
    self.Switch_Bubble:SetActiveWidgetIndex(0)
end

---@param Number integer
function WBP_Common_RedDot:ShowNumber(Number)
    self.Switch_RedDot:SetActiveWidgetIndex(2)
    self.Switch_Bubble:SetActiveWidgetIndex(1)
    self.Text_RedDotNumber:SetText(Number)
end

function WBP_Common_RedDot:ShowUp()
    self.Switch_RedDot:SetActiveWidgetIndex(2)
    self.Switch_Bubble:SetActiveWidgetIndex(2)
end

function WBP_Common_RedDot:ShowInUse()
    self.Switch_RedDot:SetActiveWidgetIndex(3)
end

return WBP_Common_RedDot
