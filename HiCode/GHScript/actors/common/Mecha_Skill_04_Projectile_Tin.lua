
local utils = require("common.utils")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@type Mecha_Skill_04_Projectile_Tin_C
local Mecha_Skill_04_Projectile_Tin_C = Class()



function Mecha_Skill_04_Projectile_Tin_C:GetAbility()
    local owner = self:GetOwner()
    return owner and owner.OwningAbility
end

function Mecha_Skill_04_Projectile_Tin_C:GetAbilityTarget()
    local ability = self:GetAbility()
    return ability and ability:GetSkillTarget()
end


function Mecha_Skill_04_Projectile_Tin_C:initProjectileMove()
    local GRAVITY_SCALE_LERP = self.GRAVITY_SCALE_LERP:ToTable()
    local USE_CUSTOM = true
    
    self.ProjectileMovement.ProjectileGravityScale = self.INIT_GRAVITY_SCALE
    local tarActor = self:GetAbilityTarget()
    local success
    if tarActor then
        local owner = self:GetOwner()
        local Caster = owner.OwningAbility:GetAvatarActorFromActorInfo()
        --[[local startPos = owner.OwningAbility.tinActor:K2_GetActorLocation()
        startPos = startPos + (UE.UKismetMathLibrary.TransformLocation(Caster:GetTransform(), UE.FVector(0, 0, 0)) - Caster:K2_GetActorLocation())]]
        local startPos = UE.UKismetMathLibrary.TransformLocation(Caster:GetTransform(), UE.FVector(93, -174, 273))
        self:K2_SetActorLocation(startPos, false, nil, true)
        local endPos = tarActor:K2_GetActorLocation()

        -- 根据start与end线性重力参数
        local distance = UE.UKismetMathLibrary.Vector_Distance(startPos, endPos)
        local low, up, min, max = TableUtil:GetBoundElementOfMap(GRAVITY_SCALE_LERP, distance)
        low = low or min
        up = up or max
        if low and up then
            local GravityScale = GRAVITY_SCALE_LERP[low]
            if low ~= up then
                local alpha = (distance - low) / (up - low)
                GravityScale = UE.UKismetMathLibrary.Lerp(GRAVITY_SCALE_LERP[low], GRAVITY_SCALE_LERP[up], alpha, distance)
            end
            self.ProjectileMovement.ProjectileGravityScale = GravityScale
        end

        local tossVelocity = UE.FVector()

        if USE_CUSTOM then
            success = UE.UGameplayStatics.SuggestProjectileVelocity_CustomArc(owner, tossVelocity,
            startPos, endPos, self.ProjectileMovement:GetGravityZ(), 0.4)
            if success then
                self.ProjectileMovement.InitialSpeed = tossVelocity:Size()
                local rotVelocity = UE.UKismetMathLibrary.Quat_UnrotateVector(self:K2_GetActorRotation():ToQuat(), tossVelocity)
                self.ProjectileMovement.Velocity = rotVelocity    
            end
        else
            success = UE.UGameplayStatics.BlueprintSuggestProjectileVelocity(owner, tossVelocity,
            startPos, endPos, self.INIT_SPEED, self.ProjectileMovement:GetGravityZ(),
            0, 0, true, true)
            if success then
                self.ProjectileMovement.InitialSpeed = self.INIT_SPEED
                local rotVelocity = UE.UKismetMathLibrary.Quat_UnrotateVector(self:K2_GetActorRotation():ToQuat(), tossVelocity)
                self.ProjectileMovement.Velocity = rotVelocity
            end
        end
    end
    if not success then
        self.ProjectileMovement.InitialSpeed = self.INIT_SPEED
        self.ProjectileMovement.Velocity = UE.FVector(1, 0, 2)
    end
end

function Mecha_Skill_04_Projectile_Tin_C:OnHitTarget(tarActor)
    self:BombAtLocation(tarActor, utils.GetActorLocation_Down(tarActor))
end
function Mecha_Skill_04_Projectile_Tin_C:OnHitEnvironment(tarActor, hitResult)
    self:BombAtLocation(tarActor, hitResult.ImpactPoint)
end
function Mecha_Skill_04_Projectile_Tin_C:BombAtLocation(tarActor, Location)
    local transform = UE.FTransform(self:K2_GetActorRotation():ToQuat(), Location)
    local bomb = self:GetWorld():SpawnActor(self.bombNA, transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, tarActor)
    bomb:SetLifeSpan(5)
    --UE.UKismetSystemLibrary.DrawDebugSphere(self, Location, 100, 12, UE.FLinearColor(1, 0, 0), 10, 0)

    local Ability = self:GetAbility()
    if Ability then
        Ability.BombLocation = Location
        local Caster = Ability:GetAvatarActorFromActorInfo()
        local tag = self.BOMB_EVENT_TAG
        local knock = FunctionUtil:MakeUDKnockInfo(Ability, self.UD_FKNOCK_INFO)
        local bombPayload = UE.FGameplayEventData()
        bombPayload.EventTag = tag
        bombPayload.Instigator = Caster
        bombPayload.OptionalObject = knock
        UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Caster, tag, bombPayload)
    end

    self:K2_DestroyActor()
end

function Mecha_Skill_04_Projectile_Tin_C:ReceiveBeginPlay()
    if self:HasAuthority() then
        local ability = self:GetAbility()
        if ability then
            ability:dropTinObject(self)
            self.tinActor:K2_AttachToActor(self, '', UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepRelative)
            self.tinActor:K2_SetActorRelativeLocation(UE.FVector(0, 0, 0), false, nil, true)
            self.tinActor:K2_SetActorRelativeRotation(UE.FRotator(0, 0, 0), false, nil, true)
            self.tinActor:StartFly()

            local caster = ability:GetAvatarActorFromActorInfo()
            local selfMoveComp = self.ProjectileMovement
            selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(caster, true)
            local casterMoveComp = caster:GetMovementComponent()
            casterMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, true)

            local owner = self:GetOwner()
            if owner and owner.InDelayPeriod and owner:InDelayPeriod() then
                self.SphereComponent:SetCollisionProfileName('OverlapAll', true)
            end
        end

        self.bornTime = UE.UGameplayStatics.GetTimeSeconds(self)
        self.ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileStop)
    end
end
function Mecha_Skill_04_Projectile_Tin_C:OnProjectileStop(Hit)
    if self:HasAuthority() then
        local tarActor = Hit.HitObjectHandle.Actor
        local owner = self:GetOwner()
        local result
        if owner then
            result = owner:OnCollideActor(tarActor, Hit)
        end
        if not result then
            self:BombAtLocation(tarActor, utils.GetActorLocation_Down(tarActor))
        end
    end
end
function Mecha_Skill_04_Projectile_Tin_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        local BOMB_LIFE_TIME = 10
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        if current - self.bornTime >= BOMB_LIFE_TIME then
            self:K2_DestroyActor()
        end

        local owner = self:GetOwner()
        if owner and owner.InDelayPeriod and (not owner:InDelayPeriod()) then
            local collision = self.SphereComponent:GetCollisionProfileName()
            if collision ~= 'BlockAll' then
                self.SphereComponent:SetCollisionProfileName('BlockAll', true)
            end
        end
    end
end
function Mecha_Skill_04_Projectile_Tin_C:ReceiveEndPlay()
    if self:HasAuthority() then
        if self.tinActor and self.tinActor:IsValid() then
            self.tinActor:K2_DestroyActor()
        end
    end
end


return Mecha_Skill_04_Projectile_Tin_C


