--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class WBP_Knapsack_Tips_SetEffect : WBP_Knapsack_Tips_SetEffect_C

---@type WBP_Knapsack_Tips_SetEffect_C
local WBP_Knapsack_Tips_SetEffect = UnLua.Class()

--function M:Initialize(Initializer)
--end

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

---Called when this entry is assigned a new item object to represent by the owning list view
---@param ListItemObject BP_Tips_SetEffect_C
---@return void
function WBP_Knapsack_Tips_SetEffect:OnListItemObjectSet(ListItemObject) end

return WBP_Knapsack_Tips_SetEffect
