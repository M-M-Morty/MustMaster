local G = require("G")
local GAKnockBase = require("skill.knock.GAKnockBase")
local GAKnockSubpartBase = Class(GAKnockBase)

function GAKnockSubpartBase:ActivateAbilityFromEvent()
    Super(GAKnockSubpartBase).ActivateAbilityFromEvent(self)

    if self.SubpartBlockMontageArray:Length() <= 0 then
        G.log:warn("zale", "Missing subpart block montages in %s", G.GetDisplayName(self))
        return
    end

    -- Find select bone
    local CloestBoneName = nil
    local SelectMontage = self.RootBlockMontage
    local MeshComponent = self.OwnerActor.Mesh
    for index = 1, self.SubpartBlockMontageArray:Length() do
        local BoneMontagePair = self.SubpartBlockMontageArray:Get(index)
        local BoneName = BoneMontagePair.BoneName
        if MeshComponent:BoneIsChildOf(self.KnockParams.HitResult.BoneName, BoneName) then
            if CloestBoneName == nil or MeshComponent:BoneIsChildOf(BoneName, CloestBoneName) then
                CloestBoneName = BoneName
                SelectMontage = BoneMontagePair.Montage
            end
        end
    end

    -- G.log:error("zale", "Find bone (%s) with %s  %s   [Authority %s]", CloestBoneName, self.KnockParams.HitResult.BoneName, G.GetDisplayName(SelectMontage), self.OwnerActor:HasAuthority())

    -- Play montage
    self.CurKnockBackMontage = SelectMontage
    if SelectMontage then
        self:PlayMontageWithCallback(self.OwnerActor.Mesh, self.CurKnockBackMontage, 1.0, self.K2_OnEndAbility, self.K2_OnEndAbility)
        -- self.OwnerActor:PlayAnimMontage(self.CurKnockBackMontage)
    else
        G.log:error("zale", "Invalid bone (%s) in SubpartBlockMontageArray %s", CloestBoneName, G.GetDisplayName(self))
    end
end

function GAKnockSubpartBase:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockSubpartBase).K2_OnEndAbility(self, bWasCancelled)

    if bWasCancelled and self.CurKnockBackMontage then
        self.OwnerActor:StopAnimMontage(self.CurKnockBackMontage)
    end
end

return GAKnockSubpartBase
