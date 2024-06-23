
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@type Mecha_Skill_03_Projectile_Bullet_C
local Mecha_Skill_03_Projectile_Bullet_C = Class()



function Mecha_Skill_03_Projectile_Bullet_C:GetAbility()
    local owner = self:GetOwner()
    return owner and owner.OwningAbility
end

function Mecha_Skill_03_Projectile_Bullet_C:GetAbilityTarget()
    local ability = self:GetAbility()
    return ability and ability:GetSkillTarget()
end


function Mecha_Skill_03_Projectile_Bullet_C:initProjectileMove()
    local GRAVITY_SCALE_LERP = self.GRAVITY_SCALE_LERP:ToTable()
    local USE_CUSTOM = true
    
    self.ProjectileMovement.ProjectileGravityScale = self.INIT_GRAVITY_SCALE
    local tarActor = self:GetAbilityTarget()
    local success
    if tarActor then
        local owner = self:GetOwner()
        local Caster = owner.OwningAbility:GetAvatarActorFromActorInfo()
        local CasterLocation = Caster:K2_GetActorLocation()
        local TargetLocation = tarActor:K2_GetActorLocation()
        -- local startPos = Caster:GetBoneLocation('FireBullet')
        -- startPos = startPos + (UE.UKismetMathLibrary.TransformLocation(Caster:GetTransform(), UE.FVector(157, 0, 35)) - CasterLocation)
        local startPos = Caster.FireLocation:K2_GetComponentLocation()
        self:K2_SetActorLocation(startPos, false, nil, true)
        local endPos = TargetLocation

        --make offset
        local raw_distance = UE.UKismetMathLibrary.Vector_Distance(startPos, endPos)
        local offset = math.ceil(raw_distance * self.TARGET_DISTANCE_OFFSET)
        if FunctionUtil:FloatNotZero(self.TARGET_DISTANCE_OFFSET) then
            endPos = FunctionUtil:GetPosRelativePoint(TargetLocation, UE.UKismetMathLibrary.FindLookAtRotation(TargetLocation, startPos), offset)
            local rand_offset = math.max(1, math.ceil(offset * self.RAND_FACTOR))
            endPos.X = endPos.X + math.random(2 * rand_offset) - rand_offset;
            endPos.Y = endPos.Y + math.random(2 * rand_offset) - rand_offset;
        end

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
            startPos, endPos, self.ProjectileMovement:GetGravityZ(), 0.7)
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

function Mecha_Skill_03_Projectile_Bullet_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    self.bornTime = UE.UGameplayStatics.GetTimeSeconds(self)
    self.ProjectileMovement.OnProjectileBounce:Add(self, self.OnProjectileBounce)
    self.ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileStop)

    if self:HasAuthority() then
        local ability = self:GetAbility()
        if ability then
            local caster = ability:GetAvatarActorFromActorInfo()
            local selfMoveComp = self.ProjectileMovement
            selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(caster, true)
            local casterMoveComp = caster:GetMovementComponent()
            casterMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, true)
        end
    end
end
function Mecha_Skill_03_Projectile_Bullet_C:OnProjectileBounce(Hit, Velocity)
    if self:HasAuthority() then
        local tarActor = Hit.HitObjectHandle.Actor
        if FunctionUtil:IsPlayer(tarActor) then
            local owner = self:GetOwner()
            if owner then
                owner:OnCollideActor(tarActor, Hit)
            end
        else
            local BOUNCE_COUNT = 3            
            self.BounceCount = (self.BounceCount or 0) + 1
            if self.BounceCount >= BOUNCE_COUNT then
                self.fireTime = self.fireTime or UE.UGameplayStatics.GetTimeSeconds(self)
            end
        end
    end
end
function Mecha_Skill_03_Projectile_Bullet_C:OnProjectileStop(Hit)
    if self:HasAuthority() then
        self:BombAtLocation()
    end
end

function Mecha_Skill_03_Projectile_Bullet_C:ReceiveTick(DeltaSeconds)
    --self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        local BOMB_LIFE_TIME = 5
        local FIRE_ELAPSE_TIME = 0.5
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        if (current - self.bornTime >= BOMB_LIFE_TIME) or (self.fireTime and current - self.fireTime > FIRE_ELAPSE_TIME) then
            self:BombAtLocation()
        end
    end
end

function Mecha_Skill_03_Projectile_Bullet_C:OnHitTarget(tarActor)
    --self.ProjectileMovement:StopMovementImmediately()
    --self:SetLifeSpan(3)

    self:BombAtLocation()
end
function Mecha_Skill_03_Projectile_Bullet_C:OnHitEnvironment(tarActor, hitResult)

end

function Mecha_Skill_03_Projectile_Bullet_C:BombAtLocation()
    local owner = self:GetOwner()
    if owner then
        owner:ConfirmTargeting()
    end

    local bomb = self:GetWorld():SpawnActor(self.bombNA, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self:GetWorld())
    bomb:SetLifeSpan(5)

    local Ability = self:GetAbility()
    if Ability then
        Ability.BombLocation = self:K2_GetActorLocation()
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


return Mecha_Skill_03_Projectile_Bullet_C


