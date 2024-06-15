--已废弃，脚本以及绑定的WBP无引用  by shiniingliu
-- -- DESCRIPTION
-- --
-- -- @COMPANY **
-- -- @AUTHOR **
-- -- @DATE ${date} ${time}
-- --

-- local G = require('G')

-- ---@type InteractiveItemWidget_C
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

-- function M:Tick(MyGeometry, InDeltaTime)
--     self.fUpdateUITime = self.fUpdateUITime + InDeltaTime
--     if self.fUpdateUITime <= 0.2 then
--         return
--     end
--     self.fUpdateUITime = 0
--     self:UpdateMagicCircleActor()
-- end

-- function M:ResetItemData()
--     self.ListItemObject = nil
--     self.MagicCircleActor = nil
--     self.fUpdateUITime = 0

--     self.ActorName:SetText('Invalid ListItemObject')
--     self:SetIsEnabled(false)
-- end

-- function M:UpdateMagicCircleActor()
--     if self.MagicCircleActor then
--         self:SetIsEnabled(false)

--         ---@type BP_ThirdPersonCharacter_C
--         local localPlayerActor = G.GetPlayerCharacter(self, 0)
--         if localPlayerActor then
--             if localPlayerActor.PickupInventoryComponent:hasPickedSceneObject() then
--                 self.ActorName:SetText('放置碎片')
--                 self:SetIsEnabled(true)
--             else
--                 self.ActorName:SetText('无法放置(没碎片)')
--             end
--         end
--     end
-- end

-- function M:SetItemText(ListItemObject)
--     self:ResetItemData()
--     ---@type AActor
--     local actorInstance = ListItemObject:Cast(UE.AActor)
--     self:LogInfo("zsf", "[interactive_item_widget] OnListItemObjectSet %s %s %s", actorInstance, ListItemObject, actorInstance.sUIPick)
--     if actorInstance then
--         self.ListItemObject = actorInstance
--         self:SetIsEnabled(true)
--         if actorInstance.IsMagicCircle and actorInstance:IsMagicCircle() then
--             self.MagicCircleActor = actorInstance
--             self:UpdateMagicCircleActor()
--         else
--             self.ActorName:SetText(actorInstance.sUIPick)
--         end
--     end
-- end

-- function M:OnListItemObjectSet(ListItemObject)
--     self:SetItemText(ListItemObject)
-- end

-- -- call by On_InteractiveActionBorder_MouseButtonDown
-- function M:OnInteractiveItem()
--     self:LogInfo('zsf', '[interactive_item_widget] OnInteractiveItem %s %s', self.ListItemObject, self.ListItemObject.DoClientInteractAction)
--     if self.ListItemObject and self.ListItemObject.DoClientInteractAction then
--         local localPlayerActor = G.GetPlayerCharacter(self, 0)
--         if localPlayerActor then
--             self.ListItemObject:DoClientInteractAction(localPlayerActor)
--         end
--     end
-- end

-- return M
