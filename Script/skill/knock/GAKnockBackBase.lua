local G = require("G")
local GAKnockBase = require("skill.knock.GAKnockBase")
local GAKnockBackBase = Class(GAKnockBase)

function GAKnockBackBase:ActivateAbilityFromEvent()
    Super(GAKnockBackBase).ActivateAbilityFromEvent(self)

    self:OnKnockBack(self.KnockParams)
end

function GAKnockBackBase:OnKnockBack(KnockParams)
end

function GAKnockBackBase:K2_OnEndAbility(bWasCancelled)
    Super(GAKnockBackBase).K2_OnEndAbility(self, bWasCancelled)

    if self.CurKnockBackMontage then
        self.OwnerActor:StopAnimMontage(self.CurKnockBackMontage)
    end
end

return GAKnockBackBase
