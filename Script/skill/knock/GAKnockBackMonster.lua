local G = require("G")
local GAKnockBackBase = require("skill.knock.GAKnockBackBase")
local GAKnockBackMonster = Class(GAKnockBackBase)

function GAKnockBackMonster:OnKnockBack(KnockParams)
    G.log:debug(self.__TAG__, "OnKnockBack")
    -- 受击开始硬直
    self.InKnockHandle = self.OwnerActor.BuffComponent:AddInKnockHitBuff()
    self.OwnerActor.CharacterStateManager:SetHitState(true)
    local KnockInfo = KnockParams.KnockInfo

    local IsInAir = not self.OwnerActor:IsOnFloor()
    local HitMontages = nil
    if IsInAir then
        HitMontages = self.HitMontages_Air
    else
        HitMontages = self.HitMontages
    end

    if not HitMontages then
        self:K2_EndAbilityLocally()
        return
    end

    self:FaceToInstigator(KnockParams)
    self.OwnerActor.MotionWarping:AddOrUpdateWarpTargetFromTransform("HitTarget", UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), UE.FVector(0, 0, 0), KnockInfo.KnockDisScale))

    -- Play different direction knock back according hit dir.
    local DirKey = nil
    if KnockInfo.KnockDir == Enum.Enum_KnockDir.Left then
        DirKey = "Left"
    elseif KnockInfo.KnockDir == Enum.Enum_KnockDir.Right then
        DirKey = "Right"
    else
        DirKey = "Middle"
    end
    local KnockBackMontage = HitMontages[DirKey]

    if not self.MontageActiveCount then
        self.MontageActiveCount = 0
    end
    self.MontageActiveCount = self.MontageActiveCount + 1
    G.log:debug(self.__TAG__, "Play knock back montage: %s, active: %d", G.GetObjectName(KnockBackMontage), self.MontageActiveCount)

    self.CurKnockBackMontage = KnockBackMontage
    self:PlayMontageWithCallback(self.OwnerActor.Mesh, KnockBackMontage, 1.0, self.OnKnockMontageEnded, self.OnKnockMontageEnded, self.OnKnockMontageEnded)
end

function GAKnockBackMonster:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockBackMonster).K2_OnEndAbility(self, bWasCancelled)
    self.MontageActiveCount = self.MontageActiveCount - 1

    G.log:debug(self.__TAG__, "End knock back montage active: %d", self.MontageActiveCount)
    if self.MontageActiveCount > 0 then
        return
    end

    -- 结束硬直
    self.OwnerActor.BuffComponent:RemoveInKnockHitBuff(self.InKnockHandle)
    self.OwnerActor.CharacterStateManager:SetHitState(false)
end

function GAKnockBackMonster:OnKnockMontageEnded(Montage)
    if not self.bEnd then
        self:K2_EndAbilityLocally()
    end
end

return GAKnockBackMonster
