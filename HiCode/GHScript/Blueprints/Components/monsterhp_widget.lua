--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require('G')
local UI3DComponent = require('CP0032305_GH.Script.framework.ui.ui_component_base')
local BillBoardState = {
    None = 0,
    Dead = 1,
    LowDis = 2,
}

---@type BP_MonsterHPWidget_C
local M = Class(UI3DComponent)

function M:OpenMonsterHp()
    self.curState = 0
    if self.isUIOpened then
        return
    end
    local Owner = self:GetOwner()
    self.MonsterType = Owner.MonsterType
    if self.MonsterType == Enum.Enum_MonsterType.Boss then
        self.isBoss = true
        return
    else
        self.isBoss = false
    end
    if self.isBoss then
        if self:GetWidget().HideAllBar then  
            self:GetWidget():HideAllBar()
        end
        return
    end
    if not self:GetWidget().OpenHudHP then
        return
    end
    self:GetWidget():OpenHudHP(self.MonsterType, self.LevelShowDis, self.LevelAndBarDis, self.MonsterAlertDis,
        self.DiscoverPlayerDis)
    self.isUIOpened = true
    self:GetOwner().MonsterUIComponent:SetDaedEvent(function() self:SetCurState(BillBoardState.Dead) end)
end


function M:UpdateDistance(DeltaSeconds)
    if self.isBoss then
        if self:GetWidget().HideAllBar then  
            self:GetWidget():HideAllBar()
        end
        return
    end
    if not self.isUIOpened then 
        return
    end
    if not self:GetWidget().UpdateDistance then
        return
    end
    self.index = self.index or 0
    self.index = self.index + 1
    if self.index % 5 ~= 0 then
        return
    end
    local Owner = self:GetOwner()
    local PlayerCameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self, 0)

    if PlayerCameraManager == nil or Owner == nil then
        return
    end
    local PlayerCameraLocation = PlayerCameraManager:K2_GetActorLocation()
    local OwnerLocation = Owner:K2_GetActorLocation()
    local Distance = UE.UKismetMathLibrary.Vector_Distance(PlayerCameraLocation, OwnerLocation)
    self:GetWidget():UpdateDistance(Distance * 0.01, DeltaSeconds)
    self:OnAdjustScale(Owner, Distance * 0.01)
    if Distance * 0.01 < self.HideAllDis then
        self:SetCurState(BillBoardState.LowDis)
    else
        self:CancelState(BillBoardState.LowDis)
    end
end
function M:OnAdjustScale(Owner, Distance)
    local Scale
    local newScale
    local dis = math.abs(Distance)
    Scale = math.sqrt(dis)  / 20
    newScale = UE.FVector(Scale, Scale, Scale)

    self:SetWorldScale3D(newScale)
end

function M:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    self:OpenMonsterHp()
    if self.isBoss then
        if self:GetWidget().HideAllBar then  
            self:GetWidget():HideAllBar()
        end
        return
    end
    if not self:GetOwner().GetAbilitySystemComponent then
        return
    end
    self:UpdateDistance(DeltaSeconds)
end

function M:SetCurState(state)
    if not state then
        return
    end
    if not self.curState then
        self.curState = 0
    end
    if self.curState == 0 then
        self.curState = bit.lshift(1, state)
        return
    end
    self.curState = bit.bor(self.curState, bit.lshift(1, state)) 
    self:StateChanged()
end

function M:CancelState(state)
    if not state then
        return
    end
    if not self.curState then
        self.curState = 0
    end
    self.curState = bit.band(self.curState, bit.bnot(bit.lshift(1, state)))
    self:StateChanged()
end

function M:StateChanged()
    if not self.curState then
        self.curState = 0
    end
    if self.curState > 0 then
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Hidden)
    else
        self:GetWidget():SetVisibility(UE.ESlateVisibility.Visible)
    end
end


return M
