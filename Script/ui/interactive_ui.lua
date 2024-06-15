-- --已废弃，脚本以及绑定的WBP无引用  by shiniingliu
-- -- DESCRIPTION
-- --
-- -- @COMPANY **
-- -- @AUTHOR **
-- -- @DATE ${date} ${time}
-- --

-- local G = require('G')
-- local Input = require('Input')

-- ---@type InteractiveUI_C
-- local M = UnLua.Class()

-- function M:LogInfo(...)
--     G.log:info_obj(self, ...)
-- end

-- function M:LogDebug(...)
--     G.log:debug_obj(self, ...)
-- end

-- function M:LogWarn(...)
--     G.log:warn_obj(self, ...)
-- end

-- function M:LogError(...)
--     G.log:error_obj(self, ...)
-- end

-- function M:Construct()
-- 	self.Overridden.Construct(self)
-- 	self:BindDelegate()
-- end

-- function M:BindDelegate()
--     self.key_names = {
--         F=1,
--         -- 数字
--         One=1, Two=2, Three=3, Four=4, Five=5, Six=6, Seven=7, Eight=8, Nine=9,
--         -- 小键盘
--         NumPadOne=1, NumPadTwo=2, NumPadThree=3, NumPadFour=4, NumPadFive=5, NumPadSix=6, NumPadSeven=7, NumPadEight=8, NumPadNine=9,
--     }
-- end

-- function M:UpdateInteractiveActorList(nearbyActors)
--     local tbItem = {}
--     for i = 1, nearbyActors:Num() do
--         ---@type AActor
--         local actorInstance = nearbyActors:Get(i)
--         if actorInstance and actorInstance.GetUIShowActors then
--             local Actors = actorInstance:GetUIShowActors()
--             for _,Actor in ipairs(Actors) do
--                 table.insert(tbItem, Actor)
--             end
--         end
--     end
--     local cnt = 1
--     for _,Actor in ipairs(tbItem) do
--         local splite_str, sUI = ". ", tostring(Actor.sUIPick)
--         local index = sUI:find(splite_str)
--         if index and index > 0 then
--             sUI = sUI:sub(index+2)
--         end
--         Actor.sUIPick = tostring(cnt)..splite_str..sUI
--         cnt = cnt + 1
--     end
--     self.InteractiveActorList:BP_SetListItems(tbItem)
--     self.InteractiveActorList:RegenerateAllEntries()
--     --local ItemNum = self.InteractiveActorList:GetNumItems()
--     --local EntryWidgets = self.InteractiveActorList:GetDisplayedEntryWidgets()
--     --for ind=0,ItemNum-1 do
--     --    local ItemObject = self.InteractiveActorList:GetItemAt(ind)
--     --    if EntryWidgets:Length() > ind then
--     --        self:LogInfo("zsf", "[interactive_ui] UpdateInteractiveActorList %s %s %s %s %s", #tbItem, nearbyActors:Num(), ItemNum, ItemObject, G.GetDisplayName(ItemObject))
--     --        EntryWidgets:Get(ind+1):SetItemText(ItemObject)
--     --    end
--     --end
-- end

-- function M:OnPickupAction(InputAction, PressedKeys)
--     local ObjectName = tostring(G.GetObjectName(InputAction))
--     local Len = ObjectName:len()
--     local Index = nil
--     for ind=1,PressedKeys:Length() do
--         local sKey = PressedKeys:Get(ind)
--         for kname, kindex in pairs(self.key_names) do
--             if sKey == UE.EKeys[kname] then
--                 Index = kindex
--                 break
--             end
--         end
--         if Index then
--             break
--         end
--     end
--     local EntryWidgets = self.InteractiveActorList:GetDisplayedEntryWidgets()
--     if EntryWidgets:Length() > 0 then
--         if Index and EntryWidgets:Length() >= Index then
--             EntryWidgets:Get(Index):OnInteractiveItem()
--         end
--     end
-- end

-- return M
