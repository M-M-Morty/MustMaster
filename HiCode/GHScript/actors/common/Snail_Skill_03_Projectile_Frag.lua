
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ProjectileBase = require('CP0032305_GH.Script.actors.common.Projectile_GH_Base')

---@type Snail_Skill_03_Projectile_Frag_C
local Snail_Skill_03_Projectile_Frag_C = Class(ProjectileBase)


function Snail_Skill_03_Projectile_Frag_C:InitParameters()
    self.collision_base_radius = self.Collision:GetUnscaledSphereRadius()
    self.Collision:SetSphereRadius(1, true)
end

function Snail_Skill_03_Projectile_Frag_C:ReceiveBeginPlay()
    Super(Snail_Skill_03_Projectile_Frag_C).ReceiveBeginPlay(self)

    self.Collision.OnComponentBeginOverlap:Add(self, self.OnComponentBeginOverlap)

    if self:HasAuthority() then
        self.AbilityAvatar = self:GetAbility():GetAvatarActorFromActorInfo()
    end
end
function Snail_Skill_03_Projectile_Frag_C:ReceiveTick(DeltaSeconds)
    Super(Snail_Skill_03_Projectile_Frag_C).ReceiveTick(self, DeltaSeconds)

    --FunctionUtil:DrawShapeComponent(self.Collision)
end
function Snail_Skill_03_Projectile_Frag_C:ReceiveEndPlay(EndPlayReason)
    Super(Snail_Skill_03_Projectile_Frag_C).ReceiveEndPlay(self, EndPlayReason)

    self.Collision.OnComponentBeginOverlap:Remove(self, self.OnComponentBeginOverlap)
end

function Snail_Skill_03_Projectile_Frag_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if self:HasAuthority() then
        if FunctionUtil:IsPlayer(OtherActor) then
            self.apply_fire_time = self.apply_fire_time or UE.UGameplayStatics.GetTimeSeconds(self)
        end
    end
end

function Snail_Skill_03_Projectile_Frag_C:GetStartPos(srcActor, dstActor)
    local transform = srcActor:GetTransform()
    local location = UE.FVector(-200, 0, 0)
    return UE.UKismetMathLibrary.TransformLocation(transform, location)
end

function Snail_Skill_03_Projectile_Frag_C:OnProjectileBounce(Hit, Velocity)
    if self:HasAuthority() then
        local tarActor = Hit.HitObjectHandle.Actor
        local owner = self:GetOwner()
        if FunctionUtil:IsPlayer(tarActor) then
            if owner and owner:OnCollideActor(tarActor, Hit) then
                self:InstantBomb()
            end
        end
    end
end
function Snail_Skill_03_Projectile_Frag_C:OnProjectileStop(Hit)
    if self:HasAuthority() then
        self.Collision:SetSphereRadius(self.collision_base_radius, true)
        self.Body:K2_AddRelativeLocation(UE.FVector(0, 0, -15), false, nil, true) --drop into earth
    end
end

function Snail_Skill_03_Projectile_Frag_C:LifeExpire()
    local owner = self:GetOwner()
    if owner then
        owner:ConfirmTargeting()
    end
    self:K2_DestroyActor()
end

function Snail_Skill_03_Projectile_Frag_C:OnBombEvent()
    if not self.AbilityAvatar then
        return
    end

    local Caster = self.AbilityAvatar
    local tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.AbilityIdentify.Snail.FragBomb")
    local bombPayload = UE.FGameplayEventData()
    bombPayload.EventTag = tag
    bombPayload.Instigator = Caster
    bombPayload.Target = self
    bombPayload.OptionalObject = FunctionUtil:MakeUDKnockInfo(Caster, self.UD_FKNOCK_INFO)
    UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Caster, tag, bombPayload)
end

return Snail_Skill_03_Projectile_Frag_C
