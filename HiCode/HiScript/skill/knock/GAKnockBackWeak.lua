local G = require("G")
local GAKnockBackBase = require("skill.knock.GAKnockBackBase")
local GAKnockBackWeak = Class(GAKnockBackBase)

function GAKnockBackWeak:ActivateAbilityFromEvent()
    Super(GAKnockBackWeak).ActivateAbilityFromEvent(self)
end

function GAKnockBackWeak:OnKnockBack(KnockParams)
    G.log:debug(self.__TAG__, "OnKnockBack")

    local HitMontages = nil
    if self.OwnerActor:IsOnFloor() then
        HitMontages = self.HitMontages
    else
        HitMontages = self.HitMontages_Air
    end

    local hit_montage_index = self:GetHitMontageIndex()
    local KnockMontage = HitMontages:Get(hit_montage_index)
    if KnockMontage == nil then
        KnockMontage = HitMontages:Get(1)
    end

    self:PlayMontageWithCallback(self.OwnerActor.Mesh, KnockMontage, 1.0, self.OnKnockMontageEnded, self.OnKnockMontageEnded)
    self.CurKnockBackMontage = KnockMontage
end

function GAKnockBackWeak:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockBackWeak).K2_OnEndAbility(self, bWasCancelled)
end

return GAKnockBackWeak
