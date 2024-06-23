--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local BillBoardState = {
    None = 0,
    Dead = 1,
    LowDis = 2,
}
local curState = 0

---@type BP_BillBoardWidget_C
local M = Class()

--function M:PreConstruct(IsDesignTime)
--end

-- function M:Initialize(Initializer)
-- end

-- function M:UserConstructionScript()
-- end

-- function M:ReceiveBeginPlay()
-- end

-- function M:ReceiveEndPlay()
-- end

function M:SetMonsterHpPosition()
    -- local Owner = self:GetOwner()
    -- if Owner.MonsterType == nil then
    --     return
    -- end

    -- local BillBoardLocation = self:K2_GetComponentLocation()
    -- local Origin, BoxExtent = UE.UKismetSystemLibrary.GetComponentBounds(Owner.Mesh)
    -- local OwnerLocation = Origin + BoxExtent
    -- local MonsterOffset = OwnerLocation.Z + self.MonsterHpOffset
    -- local NewVector = UE.FVector(BillBoardLocation.X, BillBoardLocation.Y , MonsterOffset)
    -- local HitResult = UE.FHitResult()
    -- self:K2_SetWorldLocation(NewVector, false, HitResult, true)
end

function M:OpenGetWidgetUI()
    if self.isUIOpened then
        return
    end
    self:OpenMonsterHp()
    self:OpenNPC()
end

function M:OpenMonsterHp()
    if self.isOpenHudHp then
        return
    end
    if self:GetWidget().OpenHudHP == nil then
        return
    end
    local Owner = self:GetOwner()
    self.MonsterType = Owner.MonsterType
    if self.MonsterType == Enum.Enum_MonsterType.Boss then
        return
    end
    self:GetWidget():OpenHudHP(self.MonsterType, self.LevelShowDis, self.LevelAndBarDis, self.MonsterAlertDis,
        self.DiscoverPlayerDis)
    self.isOpenHudHp = true
    self.isUIOpened = true
end

function M:OpenNPC()
    if self.isOpenHudNPC then
        return
    end
    if self:GetWidget().OpenHudNPC == nil then
        return
    end
    -- MissionPointDis, AllUIDis, AllDis, name, bubble, position, TaskIconType, bShowIcon
    self:GetWidget():OpenHudNPC(40, 30, 20, '', '', '', 1, true)
    self:GetWidget():ShowTaskIcon(1, 0)
    self.isOpenHudNPC = true
    self.isUIOpened = true
end

function M:UpdateDistance(DeltaSeconds)
    if not self.isUIOpened then 
        return
    end
    if not self:GetWidget().UpdateDistance then
        return
    end
    local Owner = self:GetOwner()
    local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)
    local CameraLocation = PlayerCameraManager:GetCameraLocation()
    if CameraLocation == nil or Owner == nil then
        return
    end
    local OwnerLocation = Owner:K2_GetActorLocation()
    local Distance = UE.UKismetMathLibrary.Vector_Distance(CameraLocation, OwnerLocation)
    
    self:GetWidget():UpdateDistance(Distance * 0.01, DeltaSeconds)
    self:OnAdjustScale(Owner, Distance * 0.01)
    if self.isOpenHudHp then
        self:UpdateHUDHPDis(Distance)
    end
    if self.isOpenHudNPC then
        self:UpdateHUDNPCDis(Distance)
    end


end
function M:UpdateHUDNPCDis(Distance)

end

function M:UpdateHUDHPDis(Distance)
    if Distance * 0.01 > 45 then
        self:SetCurState(BillBoardState.LowDis)
    else
        self:CancelState(BillBoardState.LowDis)
    end
end

function M:OnAdjustScale(Owner, Distance)
    local Scale
    local newScale
    local dis = math.abs(Distance)
    Scale = dis / 120
    newScale = UE.FVector(Scale, Scale, Scale)

    Owner.BP_BillBoardWidget:SetWorldScale3D(newScale)
end

function M:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    self:OpenGetWidgetUI()
    if not self:GetOwner().GetAbilitySystemComponent then
        return
    end
    local ASC = self:GetOwner():GetAbilitySystemComponent()
    if ASC:HasGameplayTag(UE.UHiGASLibrary.RequestGameplayTag("StateGH.InDeath")) then
        self.SetCurState(BillBoardState.Dead)
    else
        self:CancelState(BillBoardState.Dead)
    end
    self:StateChanged()
end

function M:SetCurState(state)
    if curState == 0 then
        curState = bit.lshift(1, state)
        return
    end
    curState = bit.bor(curState, bit.lshift(1, state))
    self:StateChanged()
end

function M:CancelState(state)
    if curState == 0 then
        return
    end
    curState = bit.band(curState, bit.bnot(bit.lshift(1, state)))
    self:StateChanged()
end

function M:StateChanged()
    if curState > 0 then
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Visible)
    end
end

-- function M:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
-- end

-- function M:ReceiveActorBeginOverlap(OtherActor)
-- end

-- function M:ReceiveActorEndOverlap(OtherActor)
-- end

return M
