--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/19
--

---@type BP_SightPillar_C
local G = require("G")
local os = require("os")
local table = require("table")
local MutableActorOperations = require("actor_management.mutable_actor_operations")
local utils = require("common.utils")

require "UnLua"
local ActorBase = require("actors.common.interactable.base.base_item")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    if self.bUseCircle then
        if self.NS_AreaLightFire_Keep then
            self.NS_AreaLightFire_Keep:SetActive(true, true)
            local HitResult = UE.FHitResult()
            self.RootSphere1:SetSphereRadius(self.EffectRadius, true)
            self.RootSphere1:K2_SetRelativeLocation(UE.FVector(-1*self.EffectRadius,0,0), false, HitResult, false)
            HitResult = UE.FHitResult()
            self.NS_AreaLightFire_Keep:K2_SetRelativeLocation(UE.FVector(-1*self.EffectRadius,0,0), false, HitResult, false)
            --self.RootSphere1:K2_AddRelativeLocation(UE.FVector(0, 0, self.AreaAbilitySelfUseRadius), false, nil, true)
            --self.NS_AreaLightFire_Keep:K2_AddRelativeLocation(UE.FVector(0, 0, self.AreaAbilitySelfUseRadius), false, nil, true)
        end
        if self.NS_TengManLight_Close then
            self.NS_TengManLight_Close:SetActive(false, false)
        end
        self.RootSphere2:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.RootSphere2:SetHiddenInGame(true)
        if self.NS_TengManLight_Close then
            self.NS_TengManLight_Close:SetActive(true, true)
        end
    else
        if self.NS_AreaLightFire_Keep then
            self.NS_AreaLightFire_Keep:SetActive(false, false)
        end
        if self.NS_TengManLight_Close then
            self.NS_TengManLight_Close:SetActive(true, true)
        end
        self.RootSphere1:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
        self.RootSphere1:SetHiddenInGame(true)
        self.RootSphere2:SetSphereRadius(self.EffectRadius, true)
    end
    
    --self.RotatingMovement:SetActive(false,false)
end

function M:StartRotation()
    local EnableFunc
    EnableFunc = function(bEnable, YawRate)
        if not UE.UKismetSystemLibrary.IsValid(self) then
            return
        end
        --self:SetActorTickEnabled(bEnable)
        self.RotatingMovement:SetActive(bEnable, false)
        self.RotatingMovement.RotationRate = UE.FRotator(0, YawRate, 0)
        local DelayTime = bEnable and 2.0 or 2.0
        utils.DoDelay(self, DelayTime, function()
            if not bEnable then
                YawRate = YawRate * -1
            end
            EnableFunc(not bEnable, YawRate)
        end)
    end
    local speed = self.fSpeed > 400 and 400 or self.fSpeed
    EnableFunc(true, speed)
end

function M:OnEndOverlap_Sphere1(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
     if OtherActor.UseAreaAbility then
        -- 开始失效
        self:LogInfo("zsf", "OnEndOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
        OtherActor:UseAreaAbility(self.iAreaAbility, false)
    end
end

function M:OnEndOverlap_Sphere2(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    if OtherActor.UseAreaAbility then
        -- 开始失效
        self:LogInfo("zsf", "OnEndOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
        OtherActor:UseAreaAbility(self.iAreaAbility, false)
    end
end

function M:OnBeginOverlap_Sphere1(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.UseAreaAbility then
        -- 开始生效
        self:LogInfo("zsf", "OnBeginOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
        OtherActor:UseAreaAbility(self.iAreaAbility, true)
    end
end

function M:OnBeginOverlap_Sphere2(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    if OtherActor.UseAreaAbility then
        -- 开始生效
        self:LogInfo("zsf", "OnBeginOverlap_AreaAbilityCollisionComp %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
        OtherActor:UseAreaAbility(self.iAreaAbility, true)
    end
end

function M:ReceiveEndPlay()
    local OverlappedActors = UE.TArray(UE.AActor)
    local names = {"RootSphere1", "RootSphere2"}
    for _,name in ipairs(names) do
        self[name]:GetOverlappingActors(OverlappedActors)
        for Index = 1, OverlappedActors:Length() do
            local OtherActor = OverlappedActors:Get(Index)
            if OtherActor.UseAreaAbility then
                self:LogInfo("zsf", "UseAreaAbility %s %s", G.GetDisplayName(OtherActor), self.iAreaAbility)
                OtherActor:UseAreaAbility(self.iAreaAbility, false)
            end
        end
    end
    self.RootSphere1.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere1)
    self.RootSphere1.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_Sphere1)
    self.RootSphere2.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere2)
    self.RootSphere2.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_Sphere2)
    Super(M).ReceiveEndPlay(self)
end

function M:ReceiveTick(DeltaSeconds)
    Super(M).ReceiveTick(self, DeltaSeconds)
    if not self.bUseCircle then
        return
    end
end

function M:Multicast_Fly2Pos_RPC(EndLocation)
    self:LogInfo("ys","Multicast_Fly2Pos_RPC")
    if self.ProjectileMovement then
        local function DoFly2Play(EndLocation, factor)
            self.RootSphere:SetMobility(UE.EComponentMobility.Movable)

            self.ProjectileMovement:SetActive(true)
            self.ProjectileMovement:SetUpdatedComponent(self.RootSphere)
            self.ProjectileMovement:SetComponentTickEnabled(true)
            self.ProjectileMovement.ProjectileGravityScale = 0.0

            local ItemLocation = self:K2_GetActorLocation()
            local Distance = EndLocation - ItemLocation
            local Velocity = EndLocation - ItemLocation
            self:LogWarn("ys","Velocity = %s %s %s",Velocity.X,Velocity.Y,Velocity.Z)
            Velocity:Normalize()

            self.ProjectileMovement.Velocity = Velocity * self.fAbsorbVelocity * factor
            
            local DelayTime = Distance.Z / self.ProjectileMovement.Velocity.Z
            self:LogWarn("ys","DelayTime = %s",DelayTime)
            
            local ReachDest = function()
                self:LogWarn("ys","ReachDestination")
                self.ProjectileMovement:SetComponentTickEnabled(false)
                self.ProjectileMovement.ProjectileGravityScale = 0.0
                self.ProjectileMovement.Velocity = UE.FVector(0,0,0)
                self:StartRotation()
            end
            
            utils.DoDelay(self,DelayTime,ReachDest)
        end

        DoFly2Play(EndLocation, 700)
    else
        self:LogWarn("ys","ProjectileMovement not found")
    end
end

return M