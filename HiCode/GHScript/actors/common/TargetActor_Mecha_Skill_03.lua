

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ProjectileBase = require('CP0032305_GH.Script.actors.common.TargetActor_Mecha_Projectile')


---@type TargetActor_Mecha_Skill_03_C
local TargetActor_Mecha_Skill_03_C = Class(ProjectileBase)


function TargetActor_Mecha_Skill_03_C:OnCollideActor(tarActor, hitResult)
    --UnLua.LogWarn('TargetActor_Mecha_Skill_03_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))

    if not self.OwningAbility then
        return
    end
    
    if FunctionUtil:IsPlayer(tarActor) then
        self.vCollideActors:Clear()
        self.vCollideActors:AddUnique(tarActor)
        self:ConfirmTargeting()
        if self.flyObjectInst then
            if self.flyObjectInst.OnHitTarget then
                self.flyObjectInst:OnHitTarget(tarActor)
            else
                self.flyObjectInst:K2_DestroyActor()
            end
        end
    elseif not FunctionUtil:IsHiCharacter(tarActor) then
        if self.flyObjectInst and self.flyObjectInst.OnHitEnvironment then
            self.flyObjectInst:OnHitEnvironment(tarActor, hitResult)
        else
            self:ConfirmTargeting()
            if self.flyObjectInst then
                self.flyObjectInst:K2_DestroyActor()
            end
        end
    end
end



return TargetActor_Mecha_Skill_03_C

