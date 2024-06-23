

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')


---@type TargetActor_Mecha_Projectile_C
local TargetActor_Mecha_Projectile_C = Class()


function TargetActor_Mecha_Projectile_C:ReceiveTick(DeltaSeconds)
    --self.Overridden.ReceiveTick(self, DeltaSeconds)
    
    --FunctionUtil:DrawShapeComponent(self.Collision)
end


function TargetActor_Mecha_Projectile_C:OnStartTargeting(Ability)
    if self.flyObjectCls then
        self.flyObjectInst = self:GetWorld():SpawnActor(self.flyObjectCls, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
        self:K2_AttachToActor(self.flyObjectInst, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
        self.start_time = UE.UGameplayStatics.GetTimeSeconds(self)
    end
end

function TargetActor_Mecha_Projectile_C:InDelayPeriod()
    local current = UE.UGameplayStatics.GetTimeSeconds(self)
    if current - (self.start_time or current) < (self.DAMAGE_DELAY_TIME or 0) then
        return true
    end
end

function TargetActor_Mecha_Projectile_C:OnCollideActor(tarActor, hitResult)
    --UnLua.LogWarn('TargetActor_Mecha_Projectile_C:OnCollideActor', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(tarActor))

    if not self.OwningAbility or self:InDelayPeriod() then
        return
    end

    if FunctionUtil:IsPlayer(tarActor) then
        self.vCollideActors:AddUnique(tarActor)
        self:ConfirmTargeting()
        if self.flyObjectInst then
            if self.flyObjectInst.OnHitTarget then
                self.flyObjectInst:OnHitTarget(tarActor)
            else
                self.flyObjectInst:K2_DestroyActor()
            end
        end
        return true
    elseif not FunctionUtil:IsHiCharacter(tarActor) then --floor?
        self:ConfirmTargeting()
        if self.flyObjectInst then
            if self.flyObjectInst.OnHitEnvironment then
                self.flyObjectInst:OnHitEnvironment(tarActor, hitResult)
            else
                self.flyObjectInst:K2_DestroyActor()
            end
        end
        return true
    end
end



return TargetActor_Mecha_Projectile_C

