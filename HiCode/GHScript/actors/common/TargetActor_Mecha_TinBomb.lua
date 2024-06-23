

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local InstantBase = require('CP0032305_GH.Script.actors.common.TargetActor_Mecha_Base')

---@type TargetActor_Mecha_TinBomb_C
local TargetActor_Mecha_TinBomb_C = Class(InstantBase)


function TargetActor_Mecha_TinBomb_C:OnStartTargeting(Ability)
    Super(TargetActor_Mecha_TinBomb_C).OnStartTargeting(self, Ability)

    local Caster = Ability:GetAvatarActorFromActorInfo()
    self:K2_SetActorLocation(Caster.TinObj:K2_GetComponentLocation(), false, nil, true)

    self.vCollideActors:AddUnique(Caster)

    local bomb = self:GetWorld():SpawnActor(Ability.bombNA, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self:GetWorld())
    bomb:SetLifeSpan(5)
end

function TargetActor_Mecha_TinBomb_C:OnCollideActor(tarActor)
    --UnLua.LogWarn('TargetActor_Mecha_TinBomb_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))
end

return TargetActor_Mecha_TinBomb_C

