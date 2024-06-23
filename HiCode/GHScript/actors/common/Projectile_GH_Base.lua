
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

---@type Projectile_GH_Base_C
local Projectile_GH_Base_C = Class()


function Projectile_GH_Base_C:InitParameters()
    -- body
end
function Projectile_GH_Base_C:LifeExpire()
    self:InstantBomb() -- default do bombing when expired
end
function Projectile_GH_Base_C:UserConstructionScript()
    --self.Overridden.UserConstructionScript(self)

    if self:HasAuthority() then
        --数据相关，可定制或配置的
        --self.TOTAL_LIFE_SECOND = 5
        --self.NA_BOMB_CLASS = ''
        --self.BOUNCE_LIMIT_COUNT = 3
        --self.BOMB_TIME_DELAY = 0
        --self.GRAVITY_SCALE_LERP
        --self.PROJECTILE_ARC
        --self.BOMB_EVENT_TAG
        --self.UD_FKNOCK_INFO
        --self:BP_GetStartPos()
        --self:BP_GetEndPos()
        --self:BP_GetGravity()
        --self:BP_OnBombEvent()

        self:InitParameters()

        --check to open options
        if self.BOUNCE_LIMIT_COUNT and self.BOUNCE_LIMIT_COUNT > 0 then
            self.ProjectileMovement.bShouldBounce = true
        end
        self:CalcProjectileMovementParameters()
    end
end
function Projectile_GH_Base_C:ReceiveBeginPlay()
    --self.Overridden.ReceiveBeginPlay(self)

    self.ProjectileMovement.OnProjectileBounce:Add(self, self.OnProjectileBounce)
    self.ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileStop)

    self.projectile_start_time = UE.UGameplayStatics.GetTimeSeconds(self)
    
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
function Projectile_GH_Base_C:ReceiveTick(DeltaSeconds)
    --self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        local current = UE.UGameplayStatics.GetTimeSeconds(self)
        if (self.apply_fire_time and current - self.apply_fire_time >= (self.BOMB_TIME_DELAY or 0)) then
            self:InstantBomb()
            return
        end
        if (current - self.projectile_start_time >= (self.TOTAL_LIFE_SECOND or 5)) then
            self:LifeExpire()
            return
        end
    end
end
function Projectile_GH_Base_C:ReceiveEndPlay(EndPlayReason)
    --self.Overridden.ReceiveEndPlay(self, EndPlayReason)

    self.ProjectileMovement.OnProjectileBounce:Remove(self, self.OnProjectileBounce)
    self.ProjectileMovement.OnProjectileStop:Remove(self, self.OnProjectileStop)
end

function Projectile_GH_Base_C:GetAbility()
    local owner = self:GetOwner()
    return owner and owner.OwningAbility
end
function Projectile_GH_Base_C:GetAbilityTarget()
    local ability = self:GetAbility()
    return ability and ability:GetSkillTarget()
end

function Projectile_GH_Base_C:GetStartPos(srcActor, dstActor)
    if self.BP_GetStartPos then
        return self:BP_GetStartPos(srcActor, dstActor)
    end
    return srcActor:K2_GetActorLocation()
end
function Projectile_GH_Base_C:GetEndPos(srcActor, dstActor)
    if self.BP_GetEndPos then
        return self:BP_GetEndPos(srcActor, dstActor)
    end
    return dstActor:K2_GetActorLocation()
end
function Projectile_GH_Base_C:GetGravity(startPos, endPos)
    local tbGravity = nil
    if self.BP_GetGravity then
        return self:BP_GetGravity(startPos, endPos)
    elseif self.GRAVITY_SCALE_LERP then
        if self.GRAVITY_SCALE_LERP:Length() > 0 then
            tbGravity = self.GRAVITY_SCALE_LERP:ToTable()
        end
    end
    -- 根据start与end线性重力参数
    if not tbGravity then
        tbGravity = {[0] = 30}  --as default
    end
    local distance = UE.UKismetMathLibrary.Vector_Distance(startPos, endPos)
    local low, up, min, max = TableUtil:GetBoundElementOfMap(tbGravity, distance)
    low = low or min
    up = up or max
    if low and up then
        local GravityScale = tbGravity[low]
        if low ~= up then
            local alpha = (distance - low) / (up - low)
            GravityScale = UE.UKismetMathLibrary.Lerp(tbGravity[low], tbGravity[up], alpha, distance)
        end
        return GravityScale
    end
end
function Projectile_GH_Base_C:CalcProjectileMovementParameters()
    local INIT_SPEED = 5000
    local INIT_GRAVITY_SCALE = 7
    local USE_CUSTOM = true
    
    self.ProjectileMovement.ProjectileGravityScale = INIT_GRAVITY_SCALE
    local tarActor = self:GetAbilityTarget()
    local success
    if tarActor then
        local owner = self:GetOwner()
        local Caster = owner.OwningAbility:GetAvatarActorFromActorInfo()
        local startPos = self:GetStartPos(Caster, tarActor)
        self:K2_SetActorLocation(startPos, false, nil, true)
        local endPos = self:GetEndPos(Caster, tarActor)

        local GravityScale = self:GetGravity(startPos, endPos)
        if GravityScale and FunctionUtil:FloatNotZero(GravityScale) then
            self.ProjectileMovement.ProjectileGravityScale = GravityScale
        end

        local tossVelocity = UE.FVector()
        if USE_CUSTOM then
            local arc = self.PROJECTILE_ARC or 0.7
            success = UE.UGameplayStatics.SuggestProjectileVelocity_CustomArc(owner, tossVelocity,
            startPos, endPos, self.ProjectileMovement:GetGravityZ(), arc)
            if success then
                self.ProjectileMovement.InitialSpeed = tossVelocity:Size()
                local rotVelocity = UE.UKismetMathLibrary.Quat_UnrotateVector(self:K2_GetActorRotation():ToQuat(), tossVelocity)
                self.ProjectileMovement.Velocity = rotVelocity    
            end
        else
            success = UE.UGameplayStatics.BlueprintSuggestProjectileVelocity(owner, tossVelocity,
            startPos, endPos, INIT_SPEED, self.ProjectileMovement:GetGravityZ(),
            0, 0, true, true)
            if success then
                self.ProjectileMovement.InitialSpeed = INIT_SPEED
                local rotVelocity = UE.UKismetMathLibrary.Quat_UnrotateVector(self:K2_GetActorRotation():ToQuat(), tossVelocity)
                self.ProjectileMovement.Velocity = rotVelocity
            end
        end
    end
    if not success then
        self.ProjectileMovement.InitialSpeed = INIT_SPEED
        self.ProjectileMovement.Velocity = UE.FVector(1, 0, 2)
    end
end

function Projectile_GH_Base_C:OnProjectileBounce(Hit, Velocity)
    if self:HasAuthority() then
        local tarActor = Hit.HitObjectHandle.Actor
        local owner = self:GetOwner()
        if FunctionUtil:IsPlayer(tarActor) then
            if owner and owner:OnCollideActor(tarActor, Hit) then
                self:InstantBomb()
            end
        else
            self.current_bounce_count = (self.current_bounce_count or 0) + 1
            if self.current_bounce_count >= (self.BOUNCE_LIMIT_COUNT or 0) then
                self.apply_fire_time = self.apply_fire_time or UE.UGameplayStatics.GetTimeSeconds(self)
            end
        end
    end
end
function Projectile_GH_Base_C:OnProjectileStop(Hit)
    if self:HasAuthority() then
        self:InstantBomb()
    end
end

function Projectile_GH_Base_C:OnBombEvent()
    if self.BP_OnBombEvent then
        self:BP_OnBombEvent()
    else
        --爆炸伤害
        local Ability = self:GetAbility()
        if Ability then
            Ability.projectile_bomb_location = self:K2_GetActorLocation()
            local Caster = Ability:GetAvatarActorFromActorInfo()
            local tag
            if self.BOMB_EVENT_TAG then
                tag = self.BOMB_EVENT_TAG
            else
                tag = UE.UHiGASLibrary.RequestGameplayTag("StateGH.NotifyDamage.Point2")
            end
            local bombPayload = UE.FGameplayEventData()
            bombPayload.Instigator = Caster
            if self.UD_FKNOCK_INFO then
                bombPayload.OptionalObject = FunctionUtil:MakeUDKnockInfo(Ability, self.UD_FKNOCK_INFO)
            else
                local knock = UE.NewObject(FunctionUtil:IndexRes('UD_KnockInfo_C'), Ability)
                knock.HitTags.GameplayTags:Add(UE.UHiGASLibrary.RequestGameplayTag('Event.Hit.KnockBack.Light'))
                bombPayload.OptionalObject = knock
            end
            bombPayload.EventTag = tag
            UE.UAbilitySystemBlueprintLibrary.SendGameplayEventToActor(Caster, tag, bombPayload)
        end
    end
end
function Projectile_GH_Base_C:InstantBomb()
    local owner = self:GetOwner()
    if owner then
        owner:ConfirmTargeting()
    end

    local bomb_inst = self:GetWorld():SpawnActor(self.NA_BOMB_CLASS, self:GetTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self:GetWorld())
    bomb_inst:SetLifeSpan(5)

    self:OnBombEvent()
    self:K2_DestroyActor()
end


return Projectile_GH_Base_C


