require "UnLua"

local G = require("G")
local utils = require("common.utils")
local decorator = require("common.decorator")
local Actor = require("common.actor")
local BuildingCameraActor = Class(Actor)


BuildingCameraActor.__all_client_components__ = {
    InputComponent = "actors.client.components.input_component",   
}


function BuildingCameraActor:ReceiveBeginPlay()
    Super(BuildingCameraActor).ReceiveBeginPlay(self)    
    if self:IsPlayer() then
        local Controller = self:GetController()
        if Controller and Controller:IsValid() then
            local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
            CameraManager:ToBuildingSystemMode(0.5)
            self.PlacementBuilderComponent:ActiveBuildingSystem()
            Controller.bShowMouseCursor = true
            Controller.bEnableClickEvents = true
            Controller.bEnableTouchEvents = true
        end
    end
end

function BuildingCameraActor:ReceiveEndPlay(Reason)
    Super(BuildingCameraActor).ReceiveEndPlay(self, Reason)    
    local Controller = self:GetController()
    if Controller and Controller:IsValid() then
        Controller.bShowMouseCursor = false
        Controller.bEnableClickEvents = false
        Controller.bEnableTouchEvents = false
    end
end

function BuildingCameraActor:BP_OnRep_PlayerState()    
    if self.PlayerState then
        self:AddScriptComponent("InputComponent", true)
    end
end

function BuildingCameraActor:MovmentAction(Direction, value)
    local MovementSpeed = self.SpringArmComponent.TargetArmLength * self.SpeedFactorAboutCameraDist;
    MovementSpeed = UE.UKismetMathLibrary.FClamp(MovementSpeed, self.MovementSpeedMin, self.MovementSpeedMax)    
    local MoveDirection = Direction 
    MoveDirection.Z = 0.0
    MoveDirection = MoveDirection * value * MovementSpeed;    
    local TargetLocation = self:K2_GetActorLocation() + MoveDirection   
    local HitResult = UE.FHitResult()
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.actor)
    local OffsetVector = UE.FVector(0.0, 0.0, self.SpringArmComponent.TargetArmLength)
	local ReturnValue = UE.UKismetSystemLibrary.LineTraceSingle(self:GetWorld(), TargetLocation + OffsetVector, TargetLocation - OffsetVector, UE.ETraceTypeQuery.WorldStatic, true, ActorsToIgnore, UE.EDrawDebugTrace.None, HitResult, true)
    if ReturnValue then
        --G.log:info("hybuild", "BuildingCameraActor:HitResult() %f", HitResult.Location.Z)
        TargetLocation.Z = HitResult.Location.Z + 100
    end
    self:K2_SetActorLocation( TargetLocation, false, nil, true)
end

function BuildingCameraActor:ForwardMovementAction(value)
    local ForwardDirection = self:GetActorForwardVector()
    self:MovmentAction(ForwardDirection, value)
end

function BuildingCameraActor:RightMovementAction(value)
    --G.log:info("hybuild", "BuildingCameraActor:RightMovementAction() %f", value) 
    local RightDirection = self:GetActorRightVector()
    self:MovmentAction(RightDirection, value)
end

function BuildingCameraActor:AttackAction(value)    
    self:SendMessage("Attack", value)    
end

function BuildingCameraActor:AimAction(value)
    self:SendMessage("Aim", value)   
    self.AimActionPressed = value
end

function BuildingCameraActor:CameraUpAction(value)
    --G.log:info("hybuild", "BuildingCameraActor:CameraUpAction() %f", value)
    if self.AimActionPressed then
        local ActorRotator = self:K2_GetActorRotation()
        local Pitch = ActorRotator.Pitch - value * self.RotationSensitivity
        ActorRotator.Pitch = UE.UKismetMathLibrary.FClamp(Pitch, self.RotationMinAngle , self.RotationMaxAngle)
        self:K2_SetActorRotation(ActorRotator, true)
    end   
end

function BuildingCameraActor:CameraRightAction(value)
    --G.log:info("hybuild", "BuildingCameraActor:CameraRightAction() %f", value)
    if self.AimActionPressed then
        local ActorRotator = self:K2_GetActorRotation()    
        ActorRotator.Yaw = ActorRotator.Yaw + value * self.RotationSensitivity
        self:K2_SetActorRotation(ActorRotator, true)
    end    
end

function BuildingCameraActor:CameraScaleAction(value)    
    local TargetArmLength = self.SpringArmComponent.TargetArmLength
    TargetArmLength = TargetArmLength - self.ZoomSensitivity * value
    TargetArmLength = UE.UKismetMathLibrary.FClamp(TargetArmLength, self.MinArmDistance, self.MaxArmDistance)
    self.SpringArmComponent.TargetArmLength = TargetArmLength    
    self.PlacementBuilderComponent:OnTargetArmLengthChanged(TargetArmLength)
end

function BuildingCameraActor:SwitchNormalBuilder()
    self.PlacementBuilderComponent:Enable()
    self.PlacementBuilderComponent:ActiveBuildingSystem()
    self.SplineBuilderComponent:DisEnable()
    self.SplineBuilderComponent:EnableSplineBuilder(false)
end

function BuildingCameraActor:SwitchSplineBuilder()
    self.PlacementBuilderComponent:DisEnable()
    --self.PlacementBuilderComponent:InactiveBuildingSystem()
    self.SplineBuilderComponent:Enable()
    self.SplineBuilderComponent:EnableSplineBuilder(true)
end

return RegisterActor(BuildingCameraActor)