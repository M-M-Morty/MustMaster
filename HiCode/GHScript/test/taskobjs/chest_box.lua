--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')


---@type BP_ChestBox_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    if not self:HasAuthority() then
        self.TriggerCapsule.OnComponentBeginOverlap:Add(self, self.TriggerCapsule_OnComponentBeginOverlap)
        self.TriggerCapsule.OnComponentEndOverlap:Add(self, self.TriggerCapsule_OnComponentEndOverlap)

        ---@type WBP_HeadInfo_C
        self.HeadWidget = self.BP_BillBoardWidget:GetWidget()
        if self.HeadWidget then
            self.HeadWidget:SetVisibility(UE.ESlateVisibility.Hidden)
            self.HeadWidget:SetOnConstructDelegate(function(Widget)
                if Widget.TitleProxy then
                    Widget.TitleProxy:SetText('小宝箱')
                end
                if Widget.TextBubble then
                    Widget.TextBubble:SetText('')
                end
            end)
        end
    end
end

-- function M:ReceiveEndPlay()
-- end

-- function M:ReceiveTick(DeltaSeconds)
-- end

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
function M:TriggerCapsule_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
        if InteractVM then
            local InteractItems = {}
            InteractItems[1] =
            {
                GetSelectionTitle = function()
                    return '拾取'
                end,
                SelectionAction = function()
                    self:PickChest()
                end,
                GetDisplayIconPath = function()
                end,
            }
            InteractVM:OpenInteractSelection(InteractItems)
        end
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function M:TriggerCapsule_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
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
    
    local InteractVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.InteractVM.UniqueName)
    InteractVM:CloseInteractSelection()
end

function M:GetHudWorldLocation()
    return self.BP_BillBoardWidget:K2_GetComponentLocation()
end

return M
