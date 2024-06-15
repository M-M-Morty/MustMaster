local G = require("G")
local GAKnockBackBase = require("skill.knock.GAKnockBackBase")
local GAKnockBackAvatar = Class(GAKnockBackBase)

function GAKnockBackAvatar:ActivateAbilityFromEvent()
    Super(GAKnockBackAvatar).ActivateAbilityFromEvent(self)

    self:HandleComboTail()
end

function GAKnockBackAvatar:OnKnockBack(KnockParams)
    G.log:debug(self.__TAG__, "OnKnockBack")
    local KnockInfo = KnockParams.KnockInfo

    local HitMontages = nil
    if self.OwnerActor:IsOnFloor() then
        HitMontages = self.HitMontages
    else
        HitMontages = self.HitMontages_Air
    end

    local forward_vector = self.OwnerActor:GetActorForwardVector()
    local direction_vector = self.OwnerActor:K2_GetActorLocation() - KnockParams.Causer:K2_GetActorLocation()
    direction_vector.Z = 0
    
    if direction_vector:Size2D() < 0.0001 then
        direction_vector = -forward_vector
    end
    if KnockInfo.bUseInstigatorDir and KnockParams.Instigator then
        direction_vector = UE.UKismetMathLibrary.RotateAngleAxis(KnockParams.Instigator:GetActorForwardVector(), KnockInfo.InstigatorAngleOffset, UE.FVector(0, 0, 1))
    end
    direction_vector:Normalize()

    self.OwnerActor.MotionWarping:AddOrUpdateWarpTargetFromTransform("HitTarget", UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), UE.FVector(0, 0, 0), KnockInfo.KnockDisScale))

    local DirKey = nil
    if KnockInfo.KnockDir == Enum.Enum_KnockDir.Left then
        DirKey = "Left"
    elseif KnockInfo.KnockDir == Enum.Enum_KnockDir.Right then
        DirKey = "Right"
    else
        DirKey = "Middle"
    end

    local hit_montage_index = self:GetHitMontageIndex()
    local MontageConfig = HitMontages:Get(hit_montage_index)
    if MontageConfig == nil then
        MontageConfig = HitMontages:Get(1)
    end

    local KnockBackMontage = MontageConfig[DirKey]
    G.log:debug(self.__TAG__, "Play knock back montage: %s", G.GetObjectName(KnockBackMontage))
    self:PlayMontageWithCallback(self.OwnerActor.Mesh, KnockBackMontage, 1.0, self.OnKnockMontageEnded, self.OnKnockMontageEnded)

    self.CurKnockBackMontage = KnockBackMontage
end

function GAKnockBackAvatar:OnKnockMontageEnded(Montage)
    self.OwnerActor.CharacterStateManager:SetHitState(false)
    self:K2_EndAbilityLocally()
end

function GAKnockBackAvatar:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockBackAvatar).K2_OnEndAbility(self, bWasCancelled)
end

return GAKnockBackAvatar
