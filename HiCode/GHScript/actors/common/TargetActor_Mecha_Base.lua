

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

---@type TargetActor_Mecha_Base_C
local TargetActor_Mecha_Base_C = Class()


function TargetActor_Mecha_Base_C:OnStartTargeting(Ability)
    self.Overridden.OnStartTargeting(self, Ability)

    --FunctionUtil:DrawShapeComponent(self.Collision)
end

function TargetActor_Mecha_Base_C:OnCollideActor(tarActor)
    --UnLua.LogWarn('TargetActor_Mecha_Base_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))

    if FunctionUtil:IsPlayer(tarActor) then
        self.vCollideActors:AddUnique(tarActor)
    end
end


function TargetActor_Mecha_Base_C:BeforeConfirm()
    local length = self.vCollideActors:Length()
    if self.closestDamage and length > 1 then
        local Caster = self.OwningAbility:GetAvatarActorFromActorInfo()
        local NearestObj
        local Dist
        for i = 1, length do
            local actor = self.vCollideActors:Get(i)
            local dist = Caster:GetDistanceTo(actor)
            if actor ~= Caster and (not Dist or Dist > dist) then
                Dist = dist
                NearestObj = actor
            end
        end
        if NearestObj then
            self.vCollideActors:Clear()
            self.vCollideActors:Add(NearestObj)
        end
    end
end

return TargetActor_Mecha_Base_C

