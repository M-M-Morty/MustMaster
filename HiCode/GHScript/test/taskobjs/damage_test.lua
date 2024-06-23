--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')

---@type BP_Damage_Test_C
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
function M:AreaBox_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if not self:HasAuthority() then
        local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
        HudMessageCenterVM:ShowLocationTip('树测试地点', 'tree location')
        
        self.HeadWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.HeadWidget:SetBubble('敌人攻击伤害跳字测试')
        local instance = UIManager:OpenUI(UIDef.UIInfo.UI_DamageText)

        local content = {damage = 100, eleType = Enum.Enum_DamageNumber.Normal}
        local type = "Normal"
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Normal",Enum.Enum_DamageNumber.Normal,"")
        HudMessageCenterVM:AddActorHurtDamage(self,100,"Buff",Enum.Enum_DamageNumber.Thunder,"悬浮")
        HudMessageCenterVM:AddActorHurtDamage(self,300,"Critical",Enum.Enum_DamageNumber.Thunder,"")
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
        HudTrackVM:AddTrackActor(self)
    end
end

function M:HudUnTrackSelf()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        HudTrackVM:RemoveTrackActor(self)
    end
end

function M:HudTrackRandomItem()
    ---@type HudTrackVM
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    if HudTrackVM then
        local Num = self.tbAttachedActors:Length()
        for i = 1, Num do
            if math.random(1, 100) > 70 then
                HudTrackVM:AddTrackActor(self.tbAttachedActors:Get(i))
            end
        end
    end
end

function M:GetHudWorldLocation()
    return self.BP_BillBoardWidget:K2_GetComponentLocation()
end

return M
