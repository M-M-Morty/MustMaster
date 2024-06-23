--UnLua
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local BPA_GH_MonsterBase = require("CP0032305_GH.Script.actors.common.BPA_GH_MonsterBase")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local utils = require("common.utils")

---@type BPA_Snail_C
local BPA_Snail_C = Class(BPA_GH_MonsterBase)


function BPA_Snail_C:ReceiveBeginPlay()
    --self.Overridden.ReceiveBeginPlay(self)
    Super(BPA_Snail_C).ReceiveBeginPlay(self)
end

function BPA_Snail_C:ReceiveTick(DeltaSeconds)
    --self.Overridden.ReceiveTick(self, DeltaSeconds)
    Super(BPA_Snail_C).ReceiveTick(self, DeltaSeconds)

    if self:HasAuthority() then
        local moveComp = self:GetMovementComponent()
        if moveComp and FunctionUtil:FloatZero(moveComp.MaxWalkSpeed) then
            moveComp.MaxWalkSpeed = self.MaxWalkSpeed
        end

        -- skill05
        if self:HasGameplayTag('StateGH.AbilityState.Crazying') then
            self:TryLeakOil()
        end
    end

    self:TurretYawUpdate(DeltaSeconds)
end

function BPA_Snail_C:ReceiveEndPlay(EndPlayReason)
    --self.Overridden.ReceiveEndPlay(self, EndPlayReason)
    Super(BPA_Snail_C).ReceiveEndPlay(self, EndPlayReason)
end

function BPA_Snail_C:SetTurretYawTar(tar, speed)
    local v = tonumber(tar)
    if v then
        self:SetTurretYawTarValue(v, false)
    elseif tar and tar.IsA then
        if tar:IsA(UE.AActor) then
            self:SetTurretYawTarActor(tar)
        end
    end
    
    speed = speed or self.TurretYawSpeedDefault
    if not FunctionUtil:FloatEqual(self:GetTurretYawSpeed(), speed) then
        self:SetTurretYawSpeed(speed)
    end
end

function BPA_Snail_C:SetTurretReachCB(fn, cb_time)
    self.turret_yaw_reach_cb = fn
    if fn then
        self.turret_yaw_reach_cb_time = cb_time or 1
    else
        self.turret_yaw_reach_cb_time = nil
    end
end

function BPA_Snail_C:GetTurretYaw(WorldCoord)
    return self.Overridden.GetTurretYaw(self, WorldCoord)
end

function BPA_Snail_C:TurretYawUpdate(DeltaSeconds)
    local tar = self:GetTurretYawTar()
    local cur = self:GetTurretYaw()
    local modifyYaw = self:GetTurretYawSpeed() * DeltaSeconds
    local yaw = UE.UKismetMathLibrary.ClampAngle(tar, cur - modifyYaw, cur + modifyYaw)
    self.TurretYaw = yaw

    if FunctionUtil:FloatEqual(self:GetTurretYaw(), tar) then
        if self.turret_yaw_reach_cb and self.turret_yaw_reach_cb_time > 0 then
            self.turret_yaw_reach_cb()
            self.turret_yaw_reach_cb_time = self.turret_yaw_reach_cb_time - 1
        end
    end
end

function BPA_Snail_C:TryLeakOil()
    local current = UE.UGameplayStatics.GetTimeSeconds(self)
    local TIME_INTERVAL = 0.3
    local OIL_DISTANCE = 200
    if current - (self.leak_oil_time or 0) < TIME_INTERVAL then
        return
    end
    local tbObjectTypes = { UE.EObjectTypeQuery.Weapon }
    local OilObjClass = FunctionUtil:IndexRes('Snail_Skill_05_Oil_C')
    local overlapActors = UE.TArray(UE.AActor)
    UE.UKismetSystemLibrary.SphereOverlapActors(self, self:K2_GetActorLocation(), OIL_DISTANCE, tbObjectTypes, OilObjClass, {}, overlapActors)
    if overlapActors:Length() > 0 then
        return
    end
    self.leak_oil_time = current
    local Location = utils.GetActorLocation_Down(self)
    local transform = UE.FTransform(self:K2_GetActorRotation():ToQuat(), Location)
    self:GetWorld():SpawnActor(OilObjClass, transform, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, self)
end


return BPA_Snail_C

