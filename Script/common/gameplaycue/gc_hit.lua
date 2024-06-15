---
--- Used for KnockBack and KnockFly of skill.
---
local G = require("G")
local GCHit = Class()

--- Target AActor target this gc apply on.
--- Params FGameplayCueParameters
--- Context FGameplayCueNotify_Context
function GCHit:OnExecute(Target, Params, Context)
    local EffectContextHandle = Params.EffectContext
    local Instigator = UE.UAbilitySystemBlueprintLibrary.EffectContextGetInstigatorActor(EffectContextHandle)
    local HitResult = UE.UAbilitySystemBlueprintLibrary.EffectContextGetHitResult(EffectContextHandle)
    G.log:debug("GCHit", "OnExecute instigator: %s, IsServer: %s", G.GetDisplayName(Instigator), UE.UHiUtilsFunctionLibrary.IsServer(Target))

    -- TODO now disable.
    --if Target.HandleKnockInLocal then
    --    G.log:debug("GCHit", "Invoke HandleKnockInLocal on target: %s", G.GetDisplayName(Target))
    --    Target:HandleKnockInLocal(Instigator, UE.UAbilitySystemBlueprintLibrary.EffectContextGetEffectCauser(EffectContextHandle), self.KnockInfo, HitResult)
    --end
end

return GCHit
