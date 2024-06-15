require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local RideComponent = Component(ComponentBase)
local decorator = RideComponent.decorator

function RideComponent:Start()
    Super(RideComponent).Start(self)


end



function RideComponent:BeginRide(vehicle, Location, Rotator)

    assert(not self.CurrentVehicle)

    local Montage = self:GetBeginRideMontage(vehicle)

    self.actor.bEnableAttachmentReplication = false

    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Flying)

    self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(vehicle, true)

    -- G.log:debug("lizhao", "RideComponent:BeginRide %s %s", tostring(self.actor:K2_GetActorLocation()), tostring(Location))

    local CapsuleHalfHeight = self.actor.CapsuleComponent.CapsuleHalfHeight

    Location.Z = Location.Z + CapsuleHalfHeight 

    self.actor:K2_SetActorLocation(Location, false, nil, true)

    local Rotation = self.actor:K2_GetActorRotation()
    local Vehicle_Rotation = vehicle:K2_GetActorRotation()
    Rotation.Yaw = Vehicle_Rotation.Yaw + Rotator.Yaw
    self.actor:K2_SetActorRotation(Rotation, false)

    self.CurrentVehicle = vehicle
    self.VehicleType = vehicle.VehicleComponent.VehicleType

    self.bGettingOn = true

    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
    local callback = function(name) 
                        self.OnBeginRideMontageEnd(self, name, vehicle)
                    end
    PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
    PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)

    vehicle:SendMessage("BeginRide", self.actor)
end

function RideComponent:OnBeginRideMontageEnd(name, vehicle)

    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    self.actor.AppearanceComponent:SetMovementState(UE.EHiMovementState.Ride)
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
    self.bGettingOn = false
    vehicle:SendMessage("AttachToVehicle", self.actor)

    self:SendMessage("OnBeginRide", vehicle)
end


function RideComponent:EndRide(vehicle)
    assert(self.CurrentVehicle)

    local Montage = self:GetEndRideMontage(vehicle)

    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)

    self.CurrentVehicle = nil
    self.VehicleType = Enum.Enum_VehicleType.None

    self.actor.bEnableAttachmentReplication = true

    -- G.log:debug("lizhao", "RideComponent:EndRide %s", tostring(vehicle))

    vehicle:SendMessage("DetachFromVehicle", self.actor)

    self.bGettingOff = true

    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
    local callback = function(name) 
                        self.OnEndRideMontageEnd(self, name, vehicle)
                    end
    PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
    PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)

    vehicle:SendMessage("EndRide", self.actor)
end

-- decorator.message_receiver()
-- function RideComponent:OnReceiveTick(DeltaSeconds)
--     G.log:error("lizhao", "RideComponent:OnReceiveTick %s %s", tostring(self.actor:IsClient()), tostring(self.actor:K2_GetActorLocation()))
-- end

function RideComponent:OnEndRideMontageEnd(name, vehicle)
    self.bGettingOff = false
    self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(vehicle, false)
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)

    self:SendMessage("OnEndRide", vehicle)
end

decorator.message_receiver()
function RideComponent:TurnInPlace(Angle)

    local Asset = self:GetTurnInPlaceAsset(Angle)
    
    self.actor.AppearanceComponent:PlayTurnInPlaceAnimation(TurnAngle, Asset)
end

return RideComponent