--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local HudTrackVMModule = require('CP0032305_GH.Script.viewmodel.ingame.hud.hud_track_vm')

---@type BP_TaskVolume_C
local M = Class()

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

function M:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    if not self:HasAuthority() then
        self.AreaBox.OnComponentBeginOverlap:Add(self, self.AreaBox_OnComponentBeginOverlap)
        self.AreaBox.OnComponentEndOverlap:Add(self, self.AreaBox_OnComponentEndOverlap)

        ---@type WBP_HeadInfo_C
        self.HeadWidget = self.BP_BillBoardWidget:GetWidget()
        if self.HeadWidget then
            self.HeadWidget:SetVisibility(UE.ESlateVisibility.Hidden)
            self.HeadWidget:SetBubble('')
            self.HeadWidget:HideIcon()
        end
        self.tbAttachedActors = self:GetAttachedActors()
        self.TrackTargetWrapper = HudTrackVMModule.ActorTrackTargetWrapper.new(self)
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
function M:AreaBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep,
                                           SweepResult)
    if not self:HasAuthority() then
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM
        .UniqueName)
        HudMessageCenterVM:ShowLocationTip('树测试地点', 'tree location')

        self.HeadWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.HeadWidget:SetBubble('树测试地点树测试地点树测试地点')
    end
end

---@param OverlappedComponent UPrimitiveComponent
---@param OtherActor AActor
---@param OtherComp UPrimitiveComponent
---@param OtherBodyIndex integer
function M:AreaBox_OnComponentEndOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if not self:HasAuthority() then
        self.HeadWidget:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function M:HudTrackSelf()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        HudTrackVM:AddTrackActor(self.TrackTargetWrapper)
    end
end

function M:HudUnTrackSelf()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        HudTrackVM:RemoveTrackActor(self.TrackTargetWrapper)
    end
end

function M:HudTrackRandomItem_Task()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            if i <= Num / 3 then
                if not self.tbItemArr then
                    self.tbItemArr = {}
                end
                for _, v in pairs(self.tbItemArr) do
                    if v == i then
                        return
                    end
                end
                table.insert(self.tbItemArr, i)
                local TrackTargetWrapper = HudTrackVMModule.ActorTrackTargetWrapper.new(self.tbAttachedActors:Get(i))
                HudTrackVM:AddTrackActor(TrackTargetWrapper)
            end
        end
    end
end

function M:HudTrackRandomItem_Hurt()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            local ChildActor = self.tbAttachedActors:Get(i)
            HudTrackVM:AddHurtTrackActor(ChildActor)
        end
    end
end

function M:HudTrackRandomItem_HurtRemove()
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)

    local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            local ChildActor = self.tbAttachedActors:Get(i)
            HudTrackVM:RemoveHurtTrackActor(ChildActor)
        end
end

function M:HudTrackRandomItem_TreasureBox()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            if math.random(1, 100) > 70 and i > Num / 3 and i <= Num * 2 / 3 then
                local TrackTargetWrapper = HudTrackVMModule.TreasureBoxTrackTargetWrapper.new(self.tbAttachedActors:Get(
                i))
                HudTrackVM:AddTrackActor(TrackTargetWrapper)
            end
        end
    end
end

function M:HudTrackRandomItem_Babieta()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            if math.random(1, 100) > 70 and i > Num * 2 / 3 then
                local TrackTargetWrapper = HudTrackVMModule.BadietaTrackTargetWrapper.new(self.tbAttachedActors:Get(i))
                HudTrackVM:AddTrackActor(TrackTargetWrapper)
            end
        end
    end
end

function M:GetHudWorldLocation()
    return self.BP_BillBoardWidget:K2_GetComponentLocation()
end

return M
