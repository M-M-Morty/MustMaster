
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ProjectileBase = require('CP0032305_GH.Script.actors.common.Projectile_GH_Base')

---@type Snail_Skill_04_Projectile_Obj_C
local Snail_Skill_04_Projectile_Obj_C = Class(ProjectileBase)


function Snail_Skill_04_Projectile_Obj_C:GetStartPos(srcActor, dstActor)
    local transform = srcActor:GetTransform()
    local location = UE.FVector(-200, 0, 0)
    return UE.UKismetMathLibrary.TransformLocation(transform, location)
end
function Snail_Skill_04_Projectile_Obj_C:GetEndPos(srcActor, dstActor)
    local srcLocation = srcActor:K2_GetActorLocation()
    local dstLocation = dstActor:K2_GetActorLocation()
    local lookAt = UE.UKismetMathLibrary.FindLookAtRotation(dstLocation, srcLocation)
    local selfRotation = srcActor:K2_GetActorRotation()
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(selfRotation, lookAt)
    if math.abs(deltaRot.Yaw) < self.DELTA_ROT then
        local dist = srcActor:GetDistanceTo(dstActor)
        dist = UE.UKismetMathLibrary.FClamp(dist, self.DIST_MIN, self.DIST_MAX)
        local rot = UE.UKismetMathLibrary.FindLookAtRotation(srcLocation, dstLocation)
        return srcLocation + UE.UKismetMathLibrary.Quat_RotateVector(rot:ToQuat(), UE.FVector(dist, 0, 0))
    else
        local selfYaw = selfRotation.Yaw
        local tarYaw = lookAt.Yaw
        selfRotation.Yaw = UE.UKismetMathLibrary.ClampAngle(tarYaw, selfYaw - self.DELTA_ROT, selfYaw + self.DELTA_ROT)
        selfRotation.Yaw = UE.UKismetMathLibrary.NormalizeAxis(selfRotation.Yaw + 180)
        local p1 = srcLocation + UE.UKismetMathLibrary.Quat_RotateVector(selfRotation:ToQuat(), UE.FVector(self.DIST_MIN, 0, 0))
        local p2 = srcLocation + UE.UKismetMathLibrary.Quat_RotateVector(selfRotation:ToQuat(), UE.FVector(self.DIST_MAX, 0, 0))
        return UE.UKismetMathLibrary.FindClosestPointOnSegment(dstLocation, p1, p2)
    end
end

function Snail_Skill_04_Projectile_Obj_C:PostBeginPlay()
    local selfMoveComp = self.ProjectileMovement
    selfMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self.TireObj, true)
    local casterMoveComp = self.TireObj:GetMovementComponent()
    casterMoveComp.UpdatedComponent:IgnoreActorWhenMoving(self, true)
end

function Snail_Skill_04_Projectile_Obj_C:ReceiveTick(DeltaSeconds)
    Super(Snail_Skill_04_Projectile_Obj_C).ReceiveTick(self, DeltaSeconds)

    --FunctionUtil:DrawShapeComponent(self.SphereComponent)
end

function Snail_Skill_04_Projectile_Obj_C:OnProjectileBounce(Hit, Velocity)
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

function Snail_Skill_04_Projectile_Obj_C:OnProjectileStop(Hit)
    if self:HasAuthority() then
        local tireObj = self.TireObj
        tireObj:DropProjectileObj()
        self:K2_DestroyActor()
        tireObj:CustomMoveToStart()
    end
end

function Snail_Skill_04_Projectile_Obj_C:InstantBomb()
    self.TireObj:InstantBomb()
end

return Snail_Skill_04_Projectile_Obj_C
