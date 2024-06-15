require "UnLua"

local G = require("G")

local Actor = require("common.actor")

local TargetActorBase = Class(Actor)

function TargetActorBase:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    self:SetActorTickEnabled(true)
    self.__TAG__ = string.format("TargetActorBase(actor: %s, server: %s)", G.GetObjectName(self), self:IsServer())
end

function TargetActorBase:OnStartTargeting(Ability)
    self.Overridden.OnStartTargeting(self, Ability)

    self.OwningAbility = Ability
    self.SourceActor = Ability:GetAvatarActorFromActorInfo()

    if self:IsServer() then
        self:Multicast_OnStartTargeting(Ability)
    end
end

function TargetActorBase:Multicast_OnStartTargeting_RPC(Ability)
    G.log:debug(self.__TAG__, "OnStartTargeting ability: %s", G.GetObjectName(Ability))

    if self.ReticleClass and self:IsClient() then
        self:CreateReticleActor()
        self:UpdateReticlePosition()
    end
end

function TargetActorBase:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    if self.ReticleActor then
        -- TODO 相机未做视角平滑，目前准星会抖动.
        self:UpdateReticlePosition(DeltaSeconds)
    end
end

function TargetActorBase:UpdateReticlePosition(DeltaSeconds)
    local TargetTransform = self:GetReticleTargetTransform()
    --self.ReticleActor:K2_SetActorLocation(TargetTransform.Translation, false, nil, true)
    utils.SmoothActorLocation(self.ReticleActor, TargetTransform.Translation, 30000, DeltaSeconds)
end

function TargetActorBase:GetReticleTargetTransform()
    local StartLocation = self.SourceActor:K2_GetActorLocation()
    local StartRotation = self.SourceActor:K2_GetActorRotation()
    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if CameraManager then
        StartRotation = CameraManager:GetCameraRotation()
    end
    local TargetLocation = StartLocation + UE.UKismetMathLibrary.Conv_RotatorToVector(StartRotation) * self.ReticleMaxRange

    local TargetTransform = UE.UKismetMathLibrary.MakeTransform(TargetLocation, StartRotation, UE.FVector(1.0, 1.0, 1.0))
    return TargetTransform
end

function TargetActorBase:OnConfirmTargetingAndContinue()
    self.Overridden.OnConfirmTargetingAndContinue(self)
end

function TargetActorBase:OnTargetDataReceived(TargetDataHandle)
    return self.Overridden.OnTargetDataReceived(self, TargetDataHandle)
end

function TargetActorBase:GetWeapon()
    if self.SourceActor and self.SourceActor.Weapons:Length() > 0 then
        return self.SourceActor.Weapons:Get(1)
    end
    return nil
end

function TargetActorBase:ReceiveDestroyed()
    self.Overridden.ReceiveDestroyed(self)
    G.log:debug(self.__TAG__, "ReceiveDestroyed")

    if self.ReticleActor then
        self.ReticleActor:K2_DestroyActor()
        self.ReticleActor = nil
    end
end

return TargetActorBase
