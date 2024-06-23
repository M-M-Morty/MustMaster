--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
local TargetActorSequenceAttack = require("actors.common.TargetActorSequenceAttack")
local TargetFilter = require("actors.common.TargetFilter")

---@type TargetActor_ReboundProjectile_C
local TargetActorReboundProjectileSeq = Class(TargetActorSequenceAttack)
function TargetActorReboundProjectileSeq:ReceiveBeginPlay()
    Super(TargetActorReboundProjectileSeq).ReceiveBeginPlay(self)

    --self.TargetFilter = TargetFilter.new(self.SourceActor, self.Spec.CalcFilterType, self.Spec.CalcFilterIdentity)
end


function TargetActorReboundProjectileSeq:DoCalcForHits(ResHits)
    G.log:info("yb", "PerformOverlap begin hits:%s", ResHits:Num())
    local HitActors = UE.TArray(UE.AActor)
    for _, CurHit in pairs(ResHits:ToTable()) do
        local CurActor = CurHit.HitObjectHandle.Actor
        if  CurActor and self.TargetFilter:FilterActor(CurActor) then
            HitActors:AddUnique(CurActor)
        end
    end
    self:OnReboundTarget(HitActors)
end

function TargetActorReboundProjectileSeq:OnReboundTarget(Projectiles)
    for _, Projectile in pairs(Projectiles:ToTable()) do
        --update Direction
        -- Projectile.SkillTarget,Projectile.SkillTargetController,Projectile.SkillTargetTransform = self:OnUseNewProjectileFollowTarget()
        -- 子弹有限弹给技能当前施法目标，子弹则按照当前角色朝向进行飞行
        -- Projectile:OnBeExtremeWithStand(self.SourceActor)
        Projectile:OnBeRebound(self.SourceActor, self.SkillTarget)
        --G.log:info(self.__TAG__, "Projectile:UpdateForward %s %s", G.GetObjectName(Projectile), tostring(Projectile:K2_GetRootComponent():GetForwardVector()))
    end
end

function TargetActorReboundProjectileSeq:OnConfirmTargetingAndContinue()
    return false
end

function TargetActorReboundProjectileSeq:OnStartTargeting(Ability)
    Super(TargetActorReboundProjectileSeq).OnStartTargeting(self, Ability)
    self.TargetFilter = TargetFilter.new(self.SourceActor, self.Spec.CalcFilterType, self.Spec.CalcFilterIdentity)
end

return RegisterActor(TargetActorReboundProjectileSeq)
