--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local HudTrackVMModule = require('CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm')
---@type BP_ChestBigBox_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
    if not self:HasAuthority() then
        self.TriggerBox.OnComponentBeginOverlap:Add(self, self.TriggerBox_OnComponentBeginOverlap)
        self.TriggerBox.OnComponentEndOverlap:Add(self, self.TriggerBox_OnComponentEndOverlap)
    end
end

function M:TestFuncOnSvr()
    if self:HasAuthority() then
        local ItemManager = UE.UGameplayStatics.GetPlayerController(self, 0).PlayerState.ItemManager
        if ItemManager then
            ItemManager:AddItemByExcelID(180101,1)
        end
    end
end


-- function M:ReceiveEndPlay()
-- end

function M:ReceiveTick(DeltaSeconds)
    self.idx = self.idx or 0
    self.idx = self.idx + 1
    if self.idx < 10 then
        return
    end
    if self.start then
        return
    end
    self.start = true
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if not HudTrackVM then
        return
    end
    local TrackTargetWrapper = HudTrackVMModule.ActorTrackTargetWrapper.new(self)
    HudTrackVM:AddTrackActor(TrackTargetWrapper)
end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
---@param bFromSweep boolean
---@param SweepResult FHitResult
function M:TriggerBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            if self.ItemCount == 5 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 5 end,
                    GetSelectionTitle = function() return '拾取_1' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[2] = {
                    GetActor = function() return self end,
                    GetType = function() return 2 end,
                    GetSelectionTitle = function() return '拾取_2' end,
                    SelectionAction = function()
                        local a = 1
                        local b = 'qqq'
                        if a > b then
                            print("666")
                        end
                        self:PickChest()
                    end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[3] = {
                    GetActor = function() return self end,
                    GetType = function() return 5 end,
                    GetSelectionTitle = function() return '拾取_3' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[4] = {
                    GetActor = function() return self end,
                    GetType = function() return 3 end,
                    GetSelectionTitle = function() return '拾取_4' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[5] = {
                    GetActor = function() return self end,
                    GetType = function() return 5 end,
                    GetSelectionTitle = function() return '拾取_5' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, false, 1)
            elseif self.ItemCount == 4 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 5 end,
                    GetSelectionTitle = function() return '拾取_3' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[2] = {
                    GetActor = function() return self end,
                    GetType = function() return 2 end,
                    GetSelectionTitle = function() return '拾取_4' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[3] = {
                    GetActor = function() return self end,
                    GetType = function() return 5 end,
                    GetSelectionTitle = function() return '拾取_5' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[4] = {
                    GetActor = function() return self end,
                    GetType = function() return 2 end,
                    GetSelectionTitle = function() return '拾取_6' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[5] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_7' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, false, 1)
            elseif self.ItemCount == 3 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_1' end,
                    SelectionAction = function() self:PickChest() end,
                    -- GetUsable = function() return false end, -- 
                    GetDisplayIconPath = function() end,
                }
                InteractItems[2] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_2' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[3] = {
                    GetActor = function() return self end,
                    GetType = function() return 3 end,
                    GetSelectionTitle = function() return '拾取_3' end,
                    SelectionAction = function() self:PickChest() end,
                    -- GetUsable = function() return false end, -- 
                    GetDisplayIconPath = function() end,
                }
                InteractItems[4] = {
                    GetActor = function() return self end,
                    GetType = function() return 2 end,
                    GetSelectionTitle = function() return '拾取_4' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[5] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_5' end,
                    SelectionAction = function() self:PickChest() end,
                    GetUsable = function() return false end, -- 不可用
                    GetDisplayIconPath = function() end,
                }
                InteractItems[6] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_6' end,
                    SelectionAction = function() self:PickChest() end,
                    -- GetUsable = function() return false end, -- 
                    GetDisplayIconPath = function() end,
                }
                InteractItems[7] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '拾取_7' end,
                    SelectionAction = function() self:PickChest() end,
                    -- GetUsable = function() return false end, -- 
                    GetDisplayIconPath = function() end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, true, 4)
            elseif self.ItemCount == 2 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '第4层' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[2] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetSelectionTitle = function() return '第3层' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[3] = {
                    GetActor = function() return self end,
                    GetType = function() return 3 end,
                    GetSelectionTitle = function() return '第2层' end,
                    SelectionAction = function() self:PickChest() end,
                    GetUsable = function() return false end,
                    GetDisplayIconPath = function() end,
                }
                InteractItems[4] = {
                    GetActor = function() return self end,
                    GetType = function() return 2 end,
                    GetSelectionTitle = function() return '第1层' end,
                    SelectionAction = function() self:PickChest() end,
                    GetDisplayIconPath = function() end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, true, 3)
            elseif self.ItemCount == 7 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetItemID = function() return 110003 end,
                    SelectionAction = function() self:PickChest() end,
                }
                InteractItems[2] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetItemID = function() return 130022 end,
                    SelectionAction = function() self:PickChest() end,
                }
                InteractItems[3] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    SelectionAction = function() self:PickChest() end,
                    GetItemID = function() return 130025 end,
                }
                InteractItems[4] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    SelectionAction = function() self:PickChest() end,
                    GetItemID = function() return 180003 end,
                }
                InteractItems[5] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    SelectionAction = function() self:PickChest() end,
                    GetItemID = function() return 190004 end,
                }
                InteractItems[6] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    SelectionAction = function() self:PickChest() end,
                    GetItemID = function() return 150001 end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, false, 4)
            elseif self.ItemCount == 1 then
                local InteractItems = {}
                InteractItems[1] = {
                    GetActor = function() return self end,
                    GetType = function() return 1 end,
                    GetItemID = function() return 110003 end,
                    SelectionAction = function()
                        local InteractItems = {}
                        InteractItems[1] = {
                            GetActor = function() return self end,
                            GetType = function() return 1 end,
                            GetSelectionTitle = function() return '就这一条' end,
                            SelectionAction = function()
                                self:PickChest()
                            end,
                        }
                        InteractVM:OpenInteractSelectionForPickup(InteractItems, false, 1)
                    end,
                }
                InteractVM:OpenInteractSelectionForPickup(InteractItems, false, 1)
            end
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function M:TriggerBox_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            InteractVM:CloseInteractSelection()
        end
    end
end

function M:PickChest()
    local MissionSystem = require("CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample")
    local Items = MissionSystem:CreateItemList(math.random(1,5))

    ---@type HudMessageCenter
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    HudMessageCenterVM:PushItemList(Items)

    -- local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    -- InteractVM:CloseInteractSelection()
end

function M:GetHudWorldLocation()
    return self.BP_BillBoardWidget:K2_GetComponentLocation()
end

return M
