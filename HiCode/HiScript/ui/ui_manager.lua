--已废弃，现在使用CP0032305_GH.Script.ui.ui_manager by shiniingliu
-- local G = require("G")

-- local NpcInteractItemModule = require("mission.npc_interact_item")
-- local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
-- local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

-- local UIManager = {}

-- UIManager.tbInstance = {}

-- function UIManager:GetInstance(worldContext)
--     if worldContext then
--         local world = worldContext:GetWorld()
--         self.tbInstance[world] = self.tbInstance[world] or { tbCreatedUI = {} }
--         return self.tbInstance[world], world
--     end
-- end

-- function UIManager:CreateUI(WidgetClass, worldContext)
--     local world = worldContext:GetWorld()
--     if not world then
--         return
--     end

--     if UE.UKismetSystemLibrary.IsServer(world) then
--         return
--     end

--     if WidgetClass then
--         return UE.UWidgetBlueprintLibrary.Create(world, WidgetClass)
--     end
-- end

-- function UIManager:OpenMainUI(worldContext)

--     local instance, world = self:GetInstance(worldContext)
--     if not instance then
--         return
--     end

--     local mainUI = instance.tbCreatedUI.mainUI
--     if not mainUI then
--         local mainUIClass = UE.UClass.Load('/Game/UI/main_ui.main_ui_C')
--         mainUI = self:CreateUI(mainUIClass, world)
--     end
--     if mainUI then
--         mainUI:AddToViewport(0)
--         instance.tbCreatedUI.mainUI = mainUI
--     end
-- end

-- function UIManager:UpdateInteractiveUI(nearbyActors, edComponent)
--     local tbItem = {}
--     local cnt = 1
--     for i = 1, nearbyActors:Num() do
--         ---@type AActor
--         local actorInstance = nearbyActors:Get(i)
--         if actorInstance and actorInstance.GetUIShowActors then
--             local Actors = actorInstance:GetUIShowActors()
--             for _,Actor in ipairs(Actors) do
--                 local splite_str, sUI = ". ", tostring(Actor.sUIPick)
--                 local index = sUI:find(splite_str)
--                 if index and index > 0 then
--                     sUI = sUI:sub(index+2)
--                 end
--                 Actor.sUIPick = tostring(cnt)..splite_str..sUI
--                 cnt = cnt + 1
--                 local function ItemSelectecCallback()
--                     local localPlayerActor = edComponent:GetOwner()
--                     if localPlayerActor then
--                         Actor:DoClientInteractAction(localPlayerActor)
--                     end
--                 end
--                 local Item = NpcInteractItemModule.DefaultInteractEntranceItem.new(Actor.sUIPick, ItemSelectecCallback)
--                 table.insert(tbItem, Item )
--             end
--         end
--     end

--     local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
--     if InteractVM then
--         InteractVM:OpenInteractSelection(tbItem)
--     end
-- end

--function UIManager:OnPickupAction(InputAction, PressedKeys, worldContext)
--    local instance, world = self:GetInstance(worldContext)
--    if not instance then
--        return
--    end
--    local interactiveUI = instance.tbCreatedUI.interactiveUI
--    if interactiveUI then
--        interactiveUI:OnPickupAction(InputAction, PressedKeys)
--    end
--end

-- return UIManager
