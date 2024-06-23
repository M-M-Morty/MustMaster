require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local VehicleComponent = Component(ComponentBase)
local InputModes = require("common.event_const").InputModes

local decorator = VehicleComponent.decorator

function VehicleComponent:Initialize(...)
    Super(VehicleComponent).Initialize(self, ...)
    self.enable_tick = false
    self.tick_time = 0
    self.DisableJump = false
    self.DisableSpecAnim = false
    self.InVehicleWhenEnterSpline = false
end

function VehicleComponent:Start()
    Super(VehicleComponent).Start(self)
end

function VehicleComponent:Stop()
    Super(VehicleComponent).Stop(self)
end

function VehicleComponent:OnJumpMontageEnd(name)
    G.log:info_obj(self, "VehicleComponent", "OnJumpMontageEnd, %s", name)
end

decorator.message_receiver()
function VehicleComponent:OnClientReady()
    if self.actor:IsClient() or self.actor:IsStandalone() then
        self:SendMessage("RegisterInputHandler", InputModes.Ride, self)
    end
end

decorator.message_receiver()
function VehicleComponent:MoveRight(value) 
    self:Server_MoveRight(value)
    self:OnMoveRight(value)
end

function VehicleComponent:OnMoveRight(value)
    local vehicle = self.actor.Vehicle
    if not vehicle then
        return
    end
    vehicle:SendMessage("MoveRight", value)
end

decorator.message_receiver()
function VehicleComponent:MoveForward(value)
    self:Server_MoveForward(value)
    self:OnMoveForward(value)
end

function VehicleComponent:OnMoveForward(value)
    local vehicle = self.actor.Vehicle
    if not vehicle then
        return
    end
    vehicle:SendMessage("MoveForward", value)
end

function VehicleComponent:SprintAction(value)
    G.log:info_obj(self, "VehicleComponent", "SprintAction %s", value )
    self:Server_SprintAction(value)
end

function VehicleComponent:OnSprintAction(value)
    G.log:info_obj(self, "VehicleComponent", "OnSprintAction %s", value )
    local vehicle = self.actor.Vehicle
    if not vehicle then
        return
    end
    vehicle:SendMessage("SprintAction", value)
end

decorator.message_receiver()
function VehicleComponent:JumpAction(InJump)
    G.log:info_obj(self, "VehicleComponent", "JumpAction, %s", InJump)
    if self.DisableJump then
        return
    end
    
    local vehicle = self.actor.Vehicle
    if not vehicle then
        return
    end
    if not vehicle.VehicleComponent:CanJump() then
        return
    end
    if InJump then
        vehicle:SendMessage("JumpAction", InJump)
    end
end

decorator.message_receiver()
function VehicleComponent:StopSpecAnimMontage(VehicleMontage)
    local Montage = self.SpecialAnimsMaps:Find(VehicleMontage)
    if self.actor:GetCurrentMontage() == Montage then
        local AnimInstance = self.actor.Mesh:GetAnimInstance()
        if AnimInstance then
            AnimInstance:Montage_Stop(0.2, Montage)
        end
    end
end

decorator.message_receiver()
function VehicleComponent:PlaySpecAnimMontage(VehicleMontage)
    local Montage=self.SpecialAnimsMaps:Find(VehicleMontage)
    if Montage then
        G.log:info_obj(self, "VehicleComponent", "PlaySpecAnimMontage: %s, Montage: %s", G.GetObjectName(VehicleMontage),
                G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            self.OnSpecAnimMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
end

function VehicleComponent:OnSpecAnimMontageEnd(_)
    G.log:info_obj(self, "VehicleComponent", "OnSpecAnimMontageEnd: %s, %s",G.GetObjectName(self),
            G.GetObjectName(_))
end

decorator.message_receiver()
function VehicleComponent:DoJumpOnVehicle(Vehicle, PlayRate)
    local Montage = self:GetJumpActionMontage(Vehicle.VehicleComponent)
    if Montage then
        G.log:info_obj(self, "VehicleComponent", "Vehicle %s, Montage %s", G.GetObjectName(Vehicle),
                G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, PlayRate)
        local callback = function(name)
            self.OnJumpMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
end

decorator.message_receiver()
function VehicleComponent:OnLevelSequencePlay(DisableJump, DisableSpecAnim)
    self.DisableJump = DisableJump
    self.DisableSpecAnim = DisableSpecAnim
    if self.actor.Vehicle then
        self.actor.Vehicle:SendMessage('OnLevelSequencePlay', DisableJump, DisableSpecAnim)
    end
end

decorator.message_receiver()
function VehicleComponent:OnLevelSequenceFinished()
    if self.actor.Vehicle then
        self.actor.Vehicle:SendMessage('OnLevelSequenceFinished')
    end
    self.DisableJump = false
    self.DisableSpecAnim = false
end


decorator.message_receiver()
function VehicleComponent:OnReceiveTick(DeltaSeconds)
    if not self.enable_tick then
        return
    end
    self.tick_time = self.tick_time - DeltaSeconds
    if self.tick_time <= 0 then
        self.enable_tick = false
    end
    local Location = self.actor:K2_GetActorLocation()
    local Rotation = self.actor:K2_GetActorRotation()
    G.log:info_obj(self, "VehicleComponent", "Tick Location (%f, %f, %f)", Location.X, Location.Y, Location.Z)
    G.log:info_obj(self, "VehicleComponent", "Tick Rotation (%f, %f, %f)", Rotation.Pitch, Rotation.Yaw, Rotation.Roll)
end

decorator.message_receiver()
function VehicleComponent:EnterSplineTrack(Spline, InHead)
    G.log:info_obj(self, "VehicleComponent", "EnterSplineTrack %s InHead", Spline, InHead)
    self:Multicast_OnEnterSplineTrack(Spline, InHead)
    --self:Multicast_JumpToVehicle()
    --self:OnEnterSplineTrack(Spline, InHead)
end

function VehicleComponent:Multicast_OnEnterSplineTrack_RPC(Spline, InHead)
    self:OnEnterSplineTrack(Spline, InHead)
end

decorator.message_receiver()
function VehicleComponent:SyncSplineProgress(progress)
    self:Server_SyncSplineProgress(self.SplineTrack, progress)
end

decorator.message_receiver()
function VehicleComponent:SyncVehicle(InputVector,Location,Rotation,Velocity,Angular)
    self:Server_SyncVehicle(InputVector,Location,Rotation,Velocity,Angular)
end

function VehicleComponent:OnSyncVehicle(InputVector,Location,Rotation,Velocity,Angular)
    if self.actor.Vehicle ~= nil then
        self.actor.Vehicle:SendMessage("OnSyncVehicle", InputVector,Location,Rotation,Velocity,Angular)
    end
end

decorator.message_receiver()
function VehicleComponent:GetInVehicleAction(InJump)
    if InJump then
        local PlayerController = self.actor.PlayerState:GetPlayerController()
        if not self.actor.EnableVehicle then
            PlayerController:SendMessage("VehicleStateChange", 5)
            return
        end
        
        local Vehicle = self.actor.Vehicle
        if Vehicle == nil then
            local Location = self.actor:K2_GetActorLocation()
            local Rotation = self.actor:K2_GetActorRotation()
            local Velocity = self.actor.CharacterMovement.Velocity
            self:JumpToVehicle(Location, Rotation, Velocity)
            self:Server_JumpToVehicle(Location, Rotation, Velocity)
            PlayerController:SendMessage("VehicleStateChange", 2)
        else
            local Location = Vehicle:K2_GetActorLocation()
            local CapsuleHalfHeight = Vehicle.CapsuleComponent.CapsuleHalfHeight
            Location.Z = Location.Z - CapsuleHalfHeight
            local Rotation = Vehicle:K2_GetActorRotation()
            local Velocity = Vehicle.CharacterMovement.Velocity
            if Vehicle.VehicleComponent:CanJumpOut() then
                self:Server_SyncVehicle(UE.FVector(0,0,0),Location,Rotation,Velocity, 0)
            --self:JumpOutVehicle(Location, Rotation, Velocity)
                self:Server_JumpOutVehicle(Location, Rotation, Velocity)
            end
            PlayerController:SendMessage("VehicleStateChange", 1)
        end
    end
end

function VehicleComponent:Server_SyncSplineProgress_RPC(Spline, Progress)
    G.log:info_obj(self, "VehicleComponent", "SyncSplineProgress_RPC %s,%f", self.actor:IsClient(), Progress)
    if self.actor.Vehicle ~= nil then
        self.actor.Vehicle:SendMessage("SyncSplineProgress", Spline, Progress)
    end
end

decorator.message_receiver()
function VehicleComponent:OnClientVehicleCreated(Vehicle)
    G.log:info_obj(self, "VehicleComponent", "OnClientVehicleCreated %s", tostring(Vehicle))
    if Vehicle:GetLocalRole() == UE.ENetRole.ROLE_SimulatedProxy then
        self:Server_OnClientVehicleCreated(Vehicle)
    end
end

function VehicleComponent:OnVehicleCreated(Vehicle)
    G.log:info_obj(self, "VehicleComponent", "OnVehicleCreated %s", tostring(Vehicle))
    if self.actor.Vehicle then
        self.actor.Vehicle:SetRemoteVehicle(Vehicle)
    end
end

function VehicleComponent:CreateVehicle()
    local vehicle_mgr = self.actor:GetVehicleMgr()
    vehicle_mgr:CreateVehicle(1)
end


function VehicleComponent:Server_OnClientVehicleCreated_RPC(Vehicle)
    if Vehicle == self.actor.Vehicle then
        self:Client_OnVehicleCreated(self.actor.Vehicle)
    end
end


function VehicleComponent:BeginRide()
    if self.actor.CharacterStateManager:IsInVehicle() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self.actor:GetWorld(), 0)
    local vehicle = self.actor.Vehicle
    --CameraManager:OnPossess(vehicle)
    self.actor.bEnableAttachmentReplication = false
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    self.actor.AppearanceComponent:SetMovementState(UE.EHiMovementState.Ride)
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.Ride)
    self.actor.CharacterMovement.bServerAcceptClientAuthoritativePosition = true
    
    self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(vehicle, true)
    vehicle.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.actor, true)
    if vehicle.RemoteVehicle ~= nil then
        self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(vehicle.RemoteVehicle, true)
        vehicle.RemoteVehicle.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.actor, true)
    end
    
    local Location = self.actor:K2_GetActorLocation()

    G.log:info("VehicleComponent", "%s, BeginRide %s SetVehicle Location ( %f, %f, %f)",vehicle:GetLocalRole() , G.GetObjectName(self.actor), Location.X, Location.Y, Location.Z)
    local VehicleCapsuleHalfHeight = vehicle.CapsuleComponent.CapsuleHalfHeight
    local CapsuleHalfHeight = self.actor.CapsuleComponent.CapsuleHalfHeight
    Location.Z = Location.Z - CapsuleHalfHeight + VehicleCapsuleHalfHeight
    vehicle:SendMessage("BeginRide", self.actor)
    vehicle:SendMessage("AttachToVehicle", self.actor)
    vehicle:K2_SetActorLocation(Location, false, nil, true)
    vehicle:K2_SetActorRotation(self.actor:K2_GetActorRotation(), false, nil, true)
    self.actor.CharacterStateManager:SetInVehicle(true)

    local location, rotation, scale3d = UE.UKismetMathLibrary.BreakTransform(vehicle.Mesh:GetRelativeTransform())
    Location.Z = Location.Z + CapsuleHalfHeight + location.Z * scale3d.Z
    G.log:info("VehicleComponent", "%s SetActor Location ( %f, %f, %f)", G.GetObjectName(self.actor), Location.X, Location.Y, Location.Z)
    self.actor:K2_SetActorLocation(Location, false, nil, true)
    
end

function VehicleComponent:JumpToVehicle(Location, Rotation, Velocity)
    G.log:info_obj(self, "VehicleComponent", "JumpToVehicle %s", G.GetObjectName(self.actor.Vehicle))
    if self.actor.Vehicle ~= nil then
        return
    end
    self:CreateVehicle()
    if self.actor.Vehicle then
        local Vehicle = self.actor.Vehicle
        self:BeginRide()
        self.actor.Vehicle:SendMessage("AppearAction")
    end
end

function VehicleComponent:OnEnterSplineTrack(Spline, InHead)
    local PlayerController = self.actor.PlayerState:GetPlayerController()
    if not self.actor.EnableVehicle then
        PlayerController:SendMessage("VehicleStateChange", 6)
        return
    end
    
    G.log:info_obj(self, "VehicleComponent:OnEnterSplineTrack", "%s %s", Spline, InHead)
    if self.SplineTrack ~= nil then
        G.log:info_obj(self, "VehicleComponent:OnEnterSplineTrack", "already in %s", Spline)
        return
    end
    self.actor:SendMessage("GM_ClearAllActiveStates")
    G.log:info_obj(self, "VehicleComponent", "ActorEnterTrack %s, %s", tostring(self.actor), tostring(Spline))
    Spline:ActorEnterTrack(self.actor)
    self.SplineTrack = Spline
    self.Reverse_Spline = not InHead
    if self.actor.CharacterStateManager:IsInVehicle() then
        self.InVehicleWhenEnterSpline = true
        self.actor.Vehicle:SendMessage("JumpToSplineTrack", Spline, InHead)
        return
    end
    self.InVehicleWhenEnterSpline = false
    self:CreateVehicle()
    local Vehicle = self.actor.Vehicle
    if Vehicle then
        self:BeginRide()
        self.actor.Vehicle:SendMessage("JumpToSplineTrack", Spline, InHead)
    end
end
 
decorator.message_receiver()
function VehicleComponent:OnVehicleJumpToSpline(Spline, InHead, PlayRate)
    local Vehicle = self.actor.Vehicle
    
    local Montage = self:GetJumpInMontage(Vehicle.VehicleComponent)

    if self.InVehicleWhenEnterSpline then
        Montage = self:GetJumpActionMontage(Vehicle.VehicleComponent)
    end
    if self.SplineTrack ~= nil and self.SplineTrack ~= Spline then
        self.SplineTrack:ActorLeaveTrack( self.actor)
        Montage = self:GetJumpActionMontage(Vehicle.VehicleComponent)
    end
    self.SplineTrack = Spline
    self.Reverse_Spline = not InHead
    Spline:ActorEnterTrack(self.actor)
    
    --[[if Montage then
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, PlayRate)
        local callback = function(name)
            self.OnEndJumpToSplineMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end]]
    
end

function VehicleComponent:OnEndJumpToSplineMontageEnd(name)
    
end

function VehicleComponent:JumpOutVehicle(Location, Rotation, Velocity)
    local Vehicle = self.actor.Vehicle
    if Vehicle == nil then
        return
    end
    Vehicle.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving( self.actor, true)
    self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving( Vehicle, true)
    if Vehicle.RemoteVehicle ~= nil then
        G.log:info_obj(self, "VehicleComponent", "!!!!!!!!!!!!!!!!!!!!!!!RemoteVehicle")
        Vehicle.RemoteVehicle.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving( self.actor, true)
        self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving( Vehicle.RemoteVehicle, true)
    end
    self:EndRide(Vehicle)
    --Vehicle:K2_SetActorLocation(Location, false, nil, true)
    --Vehicle:K2_SetActorRotation(Rotation, false, nil, true)
    local CapsuleHalfHeight = self.actor.CapsuleComponent.CapsuleHalfHeight
    G.log:info_obj(self, "VehicleComponent", "JumpOutVehicle.... Location (%f, %f, %f)", Location.X, Location.Y, Location.Z)
    Location.Z = Location.Z + CapsuleHalfHeight + 30
    self.actor:K2_SetActorLocation(Location, false, nil, true)
    self.actor:K2_SetActorRotation(Rotation, false, nil, true)
    self.actor.AppearanceComponent:SetActorLocationAndTargetRotation(Location, Rotation)
    self.actor.CharacterMovement.UpdatedComponent:K2_SetWorldLocationAndRotation(Location, Rotation, false, nil, true)
    
    
    G.log:info_obj(self, "VehicleComponent", "JumpOutVehicle.... (%f, %f, %f)", Velocity.X, Velocity.Y, Velocity.Z)
    
    --SetCharacterRotation
    --
    local Montage = self:GetJumpOutMontage(self.actor.Vehicle.VehicleComponent, false, Velocity:Size())
    Velocity.Z =Velocity.Z + 100
    self.actor.CharacterMovement.Velocity = Velocity
    if Montage then
        G.log:info_obj(self, "VehicleComponent", "JumpOutVehicle Montage.... %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            G.log:info_obj(self, "On JumpOutVehicle MontageEnd callback","%s", name)
            self.OnJumpOutVehicleMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    else
        self.OnJumpOutVehicleMontageEnd(self, "")
    end
    self.actor.Vehicle = nil
end

function VehicleComponent:OnJumpOutVehicleMontageEnd(Name)
    self.actor.bEnableAttachmentReplication = true
    self.actor.CharacterMovement.bServerAcceptClientAuthoritativePosition = false
    self.actor.CharacterMovement.UpdatedComponent:ClearMoveIgnoreActors()
    
end

function VehicleComponent:JumpOutSpline(Location, Rotation, Velocity)
    local Vehicle = self.actor.Vehicle
    
    local Montage = self:GetJumpActionMontage(Vehicle.VehicleComponent)
    if Montage then
        G.log:info_obj(self, "VehicleComponent", "JumpOutSpline %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            self.OnEndJumpOutMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
    self.InVehicleWhenEnterSpline = false
    Vehicle:SendMessage('JumpOutSpline', Location, Rotation, Velocity)
end

function VehicleComponent:OnEndJumpOutMontageEnd(name)
    
end

decorator.message_receiver()
function VehicleComponent:OnLeaveSplineTrack(Location, Rotation, Velocity)
    G.log:info_obj(self, "VehicleComponent", " %s OnLeaveSplineTrack ( %f, %f, %f), ( %f, %f, %f)", self.is_server, Velocity.X, Velocity.Y, Velocity.Z, Location.X, Location.Y, Location.Z)
    local CurrSplineTrack = self.SplineTrack.actor
    self.SplineTrack:ActorLeaveTrack( self.actor)
    self.SplineTrack = nil
    
    if self.InVehicleWhenEnterSpline then
        self:JumpOutSpline(Location, Rotation, Velocity)
        return
    end
    
    local CapsuleHalfHeight = self.actor.CapsuleComponent.CapsuleHalfHeight
    Location.Z = Location.Z + CapsuleHalfHeight
    self.actor.CharacterMovement.Velocity = Velocity
    local rate = 1.0
    
    self:EndRide(self.actor.Vehicle)
    local TargetLocation = CurrSplineTrack.TailJumpOutTarget
    if self.Reverse_Spline then --头进尾出
        TargetLocation = CurrSplineTrack.HeadJumpOutTarget
    end
    TargetLocation = UE.UKismetMathLibrary.TransformLocation(CurrSplineTrack:GetTransform(), TargetLocation)
    TargetLocation.Z = TargetLocation.Z - CapsuleHalfHeight
    G.log:info_obj(self, "VehicleComponent", "Jump Out Target Location (%f, %f, %f)", TargetLocation.X, TargetLocation.Y, TargetLocation.Z)
    
    
    self.actor:K2_SetActorLocation(Location, false, nil, true)
    self.actor:K2_SetActorRotation(Rotation, false, nil, true)
    --SetCharacterRotation
    self.actor.AppearanceComponent:SetActorLocationAndTargetRotation(Location, Rotation)
    self.actor.CharacterMovement.UpdatedComponent:K2_SetWorldLocationAndRotation(Location, Rotation, false, nil, true)
    G.log:info_obj(self, "VehicleComponent", "OnLeaveSplineTrack Location (%f, %f, %f)", Location.X, Location.Y, Location.Z)
    G.log:info_obj(self, "VehicleComponent", "OnLeaveSplineTrack Rotation (%f, %f, %f)", Rotation.Pitch, Rotation.Yaw, Rotation.Roll)
    
    local Montage = self:GetJumpOutMontage(self.actor.Vehicle.VehicleComponent, true)
    
    if Montage then
        local OwnerTransform = self.actor:GetTransform()
        local WarpTransform = OwnerTransform
        -- Attention HiSimpleWarp use capsule bottom position to compare.
        WarpTransform = UE.FTransform(OwnerTransform.Rotation, TargetLocation, OwnerTransform.Scale3D)
        
        self.actor.MotionWarpingModifyComponent:WarpTransform("JumpOut", WarpTransform)
        --self.actor.MotionWarpingModifyComponent:Server_SetWarpTarget("JumpOut", WarpTransform)
        
        G.log:info_obj(self, "VehicleComponent", "Montage.... %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, rate)
        local callback = function(name)
            G.log:info_obj(self, "OnJumpOutMontageEnd callback","%s", name)
            self.OnJumpOutMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    else
        self.OnJumpOutMontageEnd(self)
    end
end



function VehicleComponent:OnJumpOutMontageEnd(name)
    G.log:info_obj(self, "VehicleComponent", "OnJumpOutMontageEnd.... %s", name)
   
    local Location = self.actor:K2_GetActorLocation()
    local Rotation = self.actor:K2_GetActorRotation()
    G.log:info_obj(self, "VehicleComponent", "OnJumpOutMontageEnd Location (%f, %f, %f)", Location.X, Location.Y, Location.Z)
    G.log:info_obj(self, "VehicleComponent", "OnJumpOutMontageEnd Rotation (%f, %f, %f)", Rotation.Pitch, Rotation.Yaw, Rotation.Roll)
    --self.tick_time = 0.1
    --self.enable_tick = true
    Location = self.actor.CharacterMovement.UpdatedComponent:K2_GetComponentRotation()
    G.log:info_obj(self, "VehicleComponent", "OnJumpOutMontageEnd Rotation (%f, %f, %f)", Rotation.Pitch, Rotation.Yaw, Rotation.Roll)
end

function VehicleComponent:EndRide(vehicle)
    self.actor.CharacterStateManager:SetInVehicle(false)
    vehicle:SendMessage("DetachFromVehicle", self.actor)
    vehicle:SendMessage("EndRide", self.actor)
   
    self.VehicleType = Enum.Enum_VehicleType.None
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    self.actor.AppearanceComponent:SetMovementState(UE.EHiMovementState.InAir)
    self.actor.AppearanceComponent:SetMovementAction(UE.EHiMovementAction.None)
    
end

function VehicleComponent:OnEndRideMontageEnd()

end

function VehicleComponent:StartMoveOnSpline()
    
end

return VehicleComponent