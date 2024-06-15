require "UnLua"
local G = require("G")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")
local VehicleComponent = Component(ComponentBase)
local decorator = VehicleComponent.decorator
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local CustomMovementModes = require("common.event_const").CustomMovementModes


function VehicleComponent:Start()
    Super(VehicleComponent).Start(self)
    self.SpeedLimit = self.actor.SpeedLimit
    self.Accel = self.actor.Acceleration
    self.Gravity = self.actor.Gravity
    self.MinSpeed = self.actor.MinSpeed
    self.CurrSplineTrack = nil
    self.TickCounts = 0
    self.ReverseSplineForward = false
    self.move_dist = 0
    self.all_dist = 0
    self.Speed = 0
    self.spline_data = nil
    self.move_mode = -1
    self.TargetYaw = nil
    self.StartYaw = 0
    self.last_direction = nil
    self.JumpDuration = 0
    self.InAirDuration = 0
    self.JumpOffset = 0
    self.JumpVel = 0
    self.TransitionAreas = nil
    self.TargetTransitionRange = nil
    self.TargetSplineActors = nil
    self.NextSpecAnimRemainingTime = 0
    self.InJumpInAction = false
    self.DelayOutSprintTime = 0
    self.Appear = false
    self.bEnabled = false
    self.CurrAnimIndex = 0
    self.DisableJump = false
    self.LastMovementMode = nil;
    self.InputForward = 0
    self.InputRight = 0
    self.LastInputForward = 0
    self.LastInputRight = 0
end

decorator.message_receiver()
function VehicleComponent:OnClientReady()
    if self.actor:IsClient() then
        local Player = G.GetPlayerCharacter(self, 0)
        G.log:info_obj(self, "VehicleComponent", "OnClientReady %s", tostring(self.actor))
        Player:SendMessage('OnClientVehicleCreated', self.actor)
    end
end

function VehicleComponent:CanGetOn(passenger)
    local PassengerCount = self.Passengers:Length()

    if self.bGettingOn or self.bGettingOff then
        return PassengerCount < self.MaxPassengers - 1
    else
        return PassengerCount <= self.MaxPassengers - 1
    end
end

function VehicleComponent:OnJumpMontageEnd(name)
    G.log:info_obj(self, "VehicleComponent", "OnJumpMontageEnd %s", name)
end

function VehicleComponent:CanJump()
    return true
    
    --[[local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    local MovementMode = self.actor.CharacterMovement.MovementMode
    
    if MovementMode == UE.EMovementMode.MOVE_Falling then
        return false
    end
    if self.TargetLocation ~= nil then
        return false
    end
    
    if self.TargetSplineActors and self.TargetSplineActors:Length() > 0 then
        --local percent = (self.progress - self.TargetTransitionRange[1])/(self.TargetTransitionRange[2] - self.TargetTransitionRange[1])
        --for i=1 , self.TargetSplineActors:Length() do
        --    local Target = self.TargetSplineActors:Get(i)
        --    local target_progress = Target.Begin + percent *(Target.End - Target.Begin)
        --    G.log:info_obj(self, "VehicleComponent", "CanJump To %s, progress:%f", G.GetObjectName(Target.TargetSpline), target_progress)
        --end
        return true
    end
    
    if self.JumpDuration > 0 then
        return false
    end
    
    return true
    ]]--
end

function VehicleComponent:GetProgress()
    if self.ReverseSplineForward then
        return 1 - self.progress
    end
    return self.progress
end

decorator.message_receiver()
function VehicleComponent:ANS_SkateBoard_TurnAround_Begin()
    self.InTurnAround = true;
end

decorator.message_receiver()
function VehicleComponent:ANS_SkateBoard_TurnAround_End()
    self.InTurnAround = false;
end

decorator.message_receiver()
function VehicleComponent:AppearAction()
    G.log:info_obj(self, "VehicleComponent", "AppearAction %s %s", G.GetObjectName(self.Driver),
    self.Driver.AppearanceComponent.bIsMoving)
    local PlayRate = 1.0
    local Montage = self:GetStartMontage()
    for idx = 1, self.Passengers:Length() do
        local Passenger = self.Passengers:Get(idx)
        --Passenger:SendMessage("OnVehicleAppear", PlayRate)
    end
    
    if Montage then
        self.InJumpInAction = true
        G.log:info_obj(self, "VehicleComponent", "JumpInMontage %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, PlayRate)
        local callback = function(name)
            self.OnEndJumpInMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    self.actor.CharacterMovement.bRunPhysicsWithNoController = true
    self.Appear = true
end

function VehicleComponent:TryJumpToSpline()
    if self.TargetLocation ~= nil then
        return false
    end
    local progress = self:GetProgress()
    local percent = (progress - self.TargetTransitionRange[1])/(self.TargetTransitionRange[2] - self.TargetTransitionRange[1])
    percent = math.min(1.0, math.max(0, percent));
    for i=1 , self.TargetSplineActors:Length() do
        local Target = self.TargetSplineActors:Get(i)
        if Target ~= nil and Target.TargetSplin ~= nil then
            local target_progress = Target.Begin + percent *(Target.End - Target.Begin)
            local InHead = true
            G.log:info_obj(self, "VehicleComponent", "CanJump To %s, progress:%f", G.GetObjectName(Target.TargetSpline), target_progress)
            if Target.Begin > Target.End then
                InHead = false
                target_progress = 1-target_progress
            end
            self:JumpToSpline(Target.TargetSpline.spline, InHead, target_progress, Target.DurationTime)
            return true
        end
    end
    return false
end


decorator.message_receiver()
function VehicleComponent:Notify_SkateBoard_JumpStart()
    --[[
    local Velocity = self.actor.CharacterMovement.Velocity
    G.log:info_obj(self, "VehicleComponent Notify_SkateBoard_JumpStart", "Velocity %f, %f, %f",Velocity.X, Velocity.Y, Velocity.Z)

    if self.InJumpInAction and false then
        local v = self.actor.CharacterMovement.UpdatedComponent:GetForwardVector() * 600
        G.log:info_obj(self, "VehicleComponent", "GetForwardVector %f, %f, %f",v.X, v.Y, v.Z)
        Velocity.X = v.X
        Velocity.Y = v.Y
    end
    Velocity.Z =  Velocity.Z + 666
    G.log:info_obj(self, "VehicleComponent", "set Velocity %f, %f, %f",Velocity.X, Velocity.Y, Velocity.Z)
    self.actor.CharacterMovement.Velocity = Velocity
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    ]]
end


decorator.message_receiver()
function VehicleComponent:JumpAction(InJump)
    if not self:CanJump() then
        return
    end
    if self.CurrSplineTrack ~= nil then
        if InJump then
            if self.TargetSplineActors and self.TargetSplineActors:Length() > 0 then
                -- 可以切换轨道
                if self:TryJumpToSpline() then
                    return
                end
            end

            local Montage = self.JumpMontage

            if Montage and self.actor:GetCurrentMontage() == Montage then
                return
            end
            G.log:info_obj(self, "VehicleComponent", "JumpAction %s", InJump)
            if Montage then
                G.log:info_obj(self, "VehicleComponent", "JumpAction %s", G.GetObjectName(Montage))
                local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
                local callback = function(name)
                    self.OnJumpMontageEnd(self, name)
                end
                self:ResetNextSpecAnimRemainingTime(Montage:GetPlayLength())
                PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
                PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)

            end
            for idx = 1, self.Passengers:Length() do
                local Passenger = self.Passengers:Get(idx)
                Passenger:SendMessage("DoJumpOnVehicle", self.actor, 1.0)
            end
            
        end
        return
    end
    
    if InJump then
        self.actor:Jump()
    else
        self.actor:StopJumping()
    end
end

decorator.message_receiver()
function VehicleComponent:OnSyncVehicle(InputVector,Location,Rotation,Velocity,Angular)
    self.actor:K2_SetActorLocation(Location,false, nil, true)
    self.actor:K2_SetActorRotation(Rotation,false, nil, true)
    self.actor.CharacterMovement:AddInputVector(InputVector, true)
    self.actor.CharacterMovement.Velocity = Velocity
    self.actor.CharacterMovement:SetLocalAngularVelocity(UE.FVector(0,0,Angular))
end

decorator.message_receiver()
function VehicleComponent:SyncSplineProgress(Spline, Progress)
    if Spline ~= nil then
        G.log:info_obj(self, "VehicleComponent", "SyncSplineProgress From :%s, %f, %s %f",
                Spline, Progress, self.CurrSplineTrack, self.progress)
    else
        G.log:info_obj(self, "VehicleComponent", "SyncSplineProgress From :%f, %s %f",
                Progress, self.CurrSplineTrack, self.progress)
    end
    --TODO 不同 Spline轨道时的同步，避免永远差一个轨道导致无法同步，或者在跳转时加上同步
    if Spline == self.CurrSplineTrack and self.progress < Progress and self.bEnabled then
        self.move_dist = Progress * self.all_dist
    end
end

function VehicleComponent:UpdatePoint(auto)
    local overflow_dist = 0
    local finished = false
    if self.progress >= 1.0 then
        if self.move_mode == 1 then
            overflow_dist = self.move_dist - self.all_dist
        end 
        finished = true
        self.progress = 1.0
    end
    local SplineDistance = self.all_dist * self.progress

    local TargetYaw = nil
    if self.TargetYaw ~= nil then
        TargetYaw = self.StartYaw + (self.TargetYaw - self.StartYaw) * self.progress
    end
    local location, scale3d = UE.FVector(1,1,1)
    local rotation = self.actor:K2_GetActorRotation()
    local location_pre = self.actor:K2_GetActorLocation()
    local rotation_pre = rotation
    if self.CurrSplineTrack ~= nil then
        local Spline = self.CurrSplineTrack
        if self.ReverseSplineForward then
            SplineDistance = self.all_dist - SplineDistance
        end
        local transform = Spline:GetTransformAtDistanceAlongSpline(SplineDistance, UE.ESplineCoordinateSpace.World, false)
        location, rotation, scale3d = UE.UKismetMathLibrary.BreakTransform(transform)
        local direction = Spline:GetDirectionAtDistanceAlongSpline(SplineDistance, UE.ESplineCoordinateSpace.World)
        --G.log:info_obj(self,"target location ", "%f ( %f, %f, %f)", SplineDistance, location.X, location.Y, location.Z)
        self.last_direction = direction
        if self.ReverseSplineForward then
            self.last_direction = - self.last_direction
            rotation.Pitch = -rotation.Pitch
            rotation.Yaw = 180 + rotation.yaw
            rotation.Roll = -rotation.Roll

        end
    end
    if self.TargetLocation ~= nil then
        location.X = self.StartLocation.X + (self.TargetLocation.X - self.StartLocation.X) * self.progress
        location.Y = self.StartLocation.Y + (self.TargetLocation.Y - self.StartLocation.Y) * self.progress
        location.Z = self.StartLocation.Z
    end
    --G.log:info_obj(self, "VehicleComponent", "Update location :<%f, %f, %f>", location.X, location.Y, location.Z)
    if self.KeepPitch then
        rotation.Pitch = rotation_pre.Pitch
    end
    if TargetYaw ~= nil then
        rotation.Yaw = TargetYaw
    end

    --有一点点穿插，抬高一点
    local CapsuleHalfHeight = self.actor.CapsuleComponent.CapsuleHalfHeight
    local AddHeightOffset = CapsuleHalfHeight + 2
    if self.JumpOffset then
        AddHeightOffset = self.JumpOffset * 100 + CapsuleHalfHeight + 2
    end
    --local add_location = transform:InverseTransformVector(UE.FVector(0,0,AddHeightOffset))
    local add_location = UE.FVector(0,0,AddHeightOffset)
    location = location + add_location
    self.last_location = location
    --G.log:info_obj(self, "VehicleComponent", "Update add_location :<%f, %f, %f>", add_location.X, add_location.Y, add_location.Z)

    --if overflow_dist > 0 and finished and self.spline_data.next == nil then
    --    location = location + self.last_direction * overflow_dist -- fix speed
    --end
    self.actor:K2_SetActorLocation(location, false, nil, true)
    self.actor:K2_SetActorRotation(rotation, false, nil, true)
    if self.move_mode == 0 then
        local speed = (location - location_pre):Size2D()/self.DeltaSeconds
        -- 忽略速度变化不合理的数值（可能是有溢出修正导致的此帧移动距离很小）
        if self.JumpVel > 0 and speed < self.Speed then
            self.Speed = speed
        elseif self.JumpVel < 0 and speed > self.Speed then
            self.Speed = speed
        end
        --G.log:info_obj(self, "Tick location ", "Update Speed %f", self.Speed)
    end
    --G.log:info("Tick location ", "%s ( %f, %f, %f)",self.is_server, location.X, location.Y, location.Z)
    --self.actor.CharacterMovement.Velocity = Velocity
    if finished then

        if self.spline_data.next ~= nil then
            if auto then
                self.spline_data = self.spline_data.next
                self:init_spline_data()
            end
            return
        end
        local Velocity = self.last_direction * self.Speed
        Velocity.Z = math.max(Velocity.Z, 0) + 670
        for idx = 1, self.Passengers:Length() do
            local Passenger = self.Passengers:Get(idx)
            Passenger:SendMessage("OnLeaveSplineTrack", location, rotation, Velocity)
        end
        G.log:info_obj(self, "solorio END location ", "%s ( %f, %f, %f)",self.is_server, location.X, location.Y, location.Z)
    end
end

function VehicleComponent:ShowTransitionTips()
    G.log:info_obj(self, "VehicleComponent","ShowTransitionTips")
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM then
        local Callback = function()
            self:HideTransitionTips()
        end
        HudMessageCenterVM:ShowControlTips("跳跃切换轨道", InputDef.Keys.SpaceBar, Callback)
    end
end

function VehicleComponent:HideTransitionTips()
    G.log:info_obj(self, "VehicleComponent","HideTransitionTips")
    local HudMessageCenterVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudMessageCenterVM.UniqueName)
    if HudMessageCenterVM and HudMessageCenterVM.controlTips then
        HudMessageCenterVM:HideControlTips()
    end
end

function VehicleComponent:UpdateTransitionAreas()
    local TargetTransitionRange = nil
    local TargetSplineActors = nil
    local progress = self:GetProgress()
    
    if self.TransitionAreas and self.TransitionAreas:Length() > 0 then
        for Index = 1, self.TransitionAreas:Length() do
            local Transition = self.TransitionAreas:Get(Index)
            if Transition.Begin <= progress and progress <= Transition.End then
                TargetTransitionRange = {Transition.Begin, Transition.End}
                TargetSplineActors = Transition.TargetAreas
                break
            elseif  Transition.Begin >= progress and progress >= Transition.End then
                TargetTransitionRange = {Transition.Begin, Transition.End}
                TargetSplineActors = Transition.TargetAreas
                break
                
            end
        end
    end
    
    if TargetSplineActors then
        for Index = 1, TargetSplineActors:Length() do
            local Transition = TargetSplineActors:Get(Index)
            if self.TargetSplineActors == nil then
                self:ShowTransitionTips()
                G.log:info_obj(self, "cp", "!!!!Enter TransitionAreas %s, [%f, %f]",
                        G.GetObjectName(Transition.TargetSpline),
                        Transition.Begin, Transition.End)
            end
        end
    else
        if self.TargetSplineActors ~= nil then
            self:HideTransitionTips()
            G.log:info_obj(self, "solorio", "!!!!Leave TransitionAreas %s", self.TargetLocation)
            if self.TargetLocation == nil then
                for idx = 1, self.Passengers:Length() do
                    local Passenger = self.Passengers:Get(idx)
                    Passenger:SendMessage("JumpAction", true)
                end
            end
        end
    end
    self.TargetTransitionRange = TargetTransitionRange
    self.TargetSplineActors = TargetSplineActors
    
end

decorator.message_receiver()
function VehicleComponent:UpdateCustomMovement(DeltaSeconds)
    --G.log:info_obj(self, 'UpdateCustomMovement', "%f", DeltaSeconds)
    local CustomMode = self.actor.CharacterMovement.CustomMovementMode
    if CustomMode == CustomMovementModes.Spline then
        self:UpdateSplineMove(DeltaSeconds)
    end
end


decorator.message_receiver()
function VehicleComponent:SprintAction(value)
    if value then
        self:StartSprint()
    else
        self:EndSprint()
    end
end
function VehicleComponent:EndSprint()
    if self.InSprintTime < 1.0 then
        if self.DelayOutSprintTime == 0 then
            self.DelayOutSprintTime = 1.0 - self.InSprintTime
        end
        G.log:info_obj(self, 'VehicleComponent Delay EndSprint', "%f", self.DelayOutSprintTime)
        return
    end
    G.log:info_obj(self, 'VehicleComponent:EndSprint', "%f", self.InSprintTime)
    self.actor.CharacterMovement.ExtraSpeedLimit = 0
    self.actor.CharacterMovement.ExtraNormalAccel = 0
    self.InSprintTime = 0
    self.DelayOutSprintTime = 0
    self.InSprintState = false
end

function VehicleComponent:StartSprint()
    G.log:info_obj(self, 'VehicleComponent:StartSprint', "%f", self.InSprintTime)
    self.InSprintState = true
    self.DelayOutSprintTime = 0
    self.actor.CharacterMovement.ExtraSpeedLimit = self.actor.CharacterMovement.SprintExtraSpeedLimit
    self.actor.CharacterMovement.ExtraNormalAccel = self.actor.CharacterMovement.SprintExtraAccel
end

function VehicleComponent:UpdateSprint(DeltaSeconds)
    if self.InSprintState or self.DelayOutSprintTime > 0 then
        self.InSprintTime = self.InSprintTime + DeltaSeconds
        if self.DelayOutSprintTime > 0 then
            self.DelayOutSprintTime = self.DelayOutSprintTime - DeltaSeconds
            if self.DelayOutSprintTime <= 0 then
                self:EndSprint()
            end
        end
    end
end

decorator.message_receiver()
function VehicleComponent:OnLevelSequencePlay(DisableJump, DisableSpecAnim)
    self.DisableJump = DisableJump
    self.actor.DisableSpecAnim = DisableSpecAnim
    self:ResetNextSpecAnimRemainingTime(0)
end

decorator.message_receiver()
function VehicleComponent:OnLevelSequenceFinished()
    self.DisableJump = false
    self.actor.DisableSpecAnim = false
end

decorator.message_receiver()
function VehicleComponent:MoveRight(value)
    self.InputRight = value
end

decorator.message_receiver()
function VehicleComponent:MoveForward(value)
    self.InputForward = value
end

decorator.message_receiver()
function VehicleComponent:OnReceiveTick(DeltaSeconds)
    
   if not self.bEnabled then
        return
    end
    if not self.Driver then
        return
    end
    --local v = self.actor.CharacterMovement.Velocity
    --G.log:info_obj(self, 'OnReceiveTick', "%f ,%f ，%f ",v.X, v.Y, v.Z)

    self.TickCounts = self.TickCounts + 1
    
    local MovementMode = self.actor.CharacterMovement.MovementMode
    if MovementMode ~= self.LastMovementMode then
        --G.log:info_obj(self, 'OnReceiveTick Change MovementMode %s',MovementMode)
        self:ResetNextSpecAnimRemainingTime(0)
    end
    
    self:UpdateSprint(DeltaSeconds)
    self:UpdateSpecAnim(DeltaSeconds)
    
    self.LastMovementMode = MovementMode
    if MovementMode == UE.EMovementMode.MOVE_None or MovementMode == UE.EMovementMode.MOVE_Custom then
        return
    end

    
    
    
    if  self.actor:IsClient() then
        local InputVector = self.Driver.CharacterMovement:GetPendingInputVector()
        
        local LocalInputVector = self.actor:GetTransform():InverseTransformVector(InputVector)
        local LocalInputRotation = LocalInputVector:ToRotator()
        if math.abs(LocalInputRotation.Yaw) > 5 then
            --self:ResetNextSpecAnimRemainingTime(0)
        end
        --[[
        if InputVector:Size() > 0 then
            G.log:info_obj(self, 'OnReceiveTick', "InputVector     <%f,%f,%f>", InputVector.X, InputVector.Y, InputVector.Z)
            G.log:info_obj(self, 'OnReceiveTick', "LocalInputVector<%f,%f,%f> Yaw:%f", LocalInputVector.X, LocalInputVector.Y, LocalInputVector.Z, LocalInputRotation.Yaw)
        end
        ]]
        
        local R = LocalInputRotation.Yaw
       

        --G.log:info_obj(self, "Input ", '[%s] Forward %s => %s, Right %s=> %s',R, self.LastInputForward, self.InputForward, self.LastInputRight, self.InputRight)
        self.actor.CharacterMovement:AddInputVector(InputVector, true)
        if self.LastInputRight ~= self.InputRight or self.LastInputForward ~= self.InputForward then
            -- Input key
            if math.abs(R) > 60 then
                self:TurnAction(R)
            else
                --self.actor.CharacterMovement:AddInputVector(InputVector, true)
            end
        else
            --self.actor.CharacterMovement:AddInputVector(InputVector, true)
            if math.abs(R) > 120 then
                self:TurnAction(R)
            end
        end
        
        if self.TickCounts % 10 == 0 then
            self.Driver:SendMessage('SyncVehicle',InputVector,
                    self.actor:K2_GetActorLocation(),
                    self.actor:K2_GetActorRotation(),
                    self.actor.CharacterMovement.Velocity,
                    self.actor.CharacterMovement.LocalAngularVelocity.Z
            )
        end
    end

    self.LastInputForward = self.InputForward
    self.LastInputRight = self.InputRight

    self.InputRight = 0
    self.InputForward = 0
    
end


function VehicleComponent:TurnAction(Rotation)
    local AnimInstance = self.actor.Mesh:GetAnimInstance()
    if AnimInstance:Montage_IsPlaying() then
        return
    end
    
    if self.InTurnAround then
        return
    end
    local Montage = nil
    local mps = self.actor.CharacterMovement.Velocity:Size2D()
    if mps > 0 then
        --G.log:info_obj(self, "VehicleComponent", "GetTurnMontage InSprintState %s", self.InSprintState)
        if self.InSprintState then
            Montage = self:GetSprintTurnMontage(-Rotation)
        else
            Montage = self:GetTurnMontage(-Rotation)
        end
    else
        Montage = self:GetStartTurnMontage(-Rotation)
    end
    
    if Montage then

        local rotation = self.actor:K2_GetActorRotation()
        local Yaw =  rotation.Yaw + Rotation
        
        G.log:info_obj(self, "VehicleComponent", "Turn, %s %f %f, %f, ret = %f", G.GetObjectName(Montage), 
                mps,  rotation.Yaw, Rotation, Yaw)
        rotation.Yaw = Yaw

        --self.actor.MotionWarping:AddOrUpdateWarpTargetFromTransform("TurnRotation",  rotation)
        self:ResetNextSpecAnimRemainingTime(Montage:GetPlayLength())
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            self.OnTurnActionMontageEnd(self)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
end

function VehicleComponent:OnTurnActionMontageEnd()
end
function VehicleComponent:UpdateSplineMove(DeltaSeconds)
    self.DeltaSeconds = DeltaSeconds
    if self.move_mode == 1 then
        if not self.last_direction then
            self.last_direction = UE.FVector(1,0,0)
        end
        local lastSpeed = self.Speed
        self.Speed = self.Speed + self.Accel * DeltaSeconds
        local Velocity = self.last_direction * self.Speed
        local Speed2D = Velocity:Size2D()
        G.log:info_obj(self, "update", "%s, %s, (%f, %f, %f)", self.SpeedLimit, Speed2D, Velocity.X, Velocity.Y, Velocity.Z)
        if Speed2D > self.SpeedLimit then
            Velocity = Velocity * (self.SpeedLimit/Speed2D)
        end
        
        if Velocity.Z > 0 then
            Velocity.Z = math.max(Velocity.Z + self.Gravity * DeltaSeconds, 0)
        else
            Velocity.Z = Velocity.Z + self.Gravity * DeltaSeconds
        end
        self.Speed = Velocity:Size()
        
        if lastSpeed > self.Speed and self.Speed < self.MinSpeed then
            self.Speed = self.MinSpeed
        end
        local MoveDist = self.Speed * DeltaSeconds
        self.move_dist = self.move_dist + MoveDist
        self.progress = self.move_dist / self.all_dist
        self:UpdateTransitionAreas()
        self:UpdatePoint(true)
        if self.move_dist + MoveDist >= self.all_dist then
            for idx = 1, self.Passengers:Length() do
                local Passenger = self.Passengers:Get(idx)
                Passenger:SendMessage("SyncSplineProgress", self.progress)
            end
        end
    end
   
end

function VehicleComponent:UpdateSpecAnim(DeltaSeconds)
    if self.actor.DisableSpecAnim then
        return
    end
    --G.log:info_obj(self, "VehicleComponent", "UpdateSpecAnim Velocity %f, %f",  self.actor.CharacterMovement.Velocity:Size2D(), self.Speed)

    if self.CurrAnimIndex ~= 0 and self.actor.CharacterMovement.Velocity:Size2D() < 10 and self.Speed < 10 then
        --G.log:info_obj(self, "VehicleComponent", "StopSpecAnimMontage")
        self:StopSpecAnimMontage()
        return
    elseif self.actor.CharacterMovement.Velocity:Size2D() < 400 and self.Speed < 400 then
        self.NextSpecAnimRemainingTime = 0
        --G.log:info_obj(self, "VehicleComponent", "self.NextSpecAnimRemainingTime = 0")
        return
    end
    
    local IntervalTimeForSpecAnim = self.actor.IntervalTimeForSpecAnim
    if self.CurrSplineTrack ~= nil then
        IntervalTimeForSpecAnim = self.actor.IntervalTimeForInTrackSpecAnim
    end
    self.NextSpecAnimRemainingTime = self.NextSpecAnimRemainingTime + DeltaSeconds
    if self.NextSpecAnimRemainingTime >= IntervalTimeForSpecAnim then
        
        local MovementMode = self.actor.CharacterMovement.MovementMode
        local Montage = nil;
        if self.CurrSplineTrack ~= nil then
            self.CurrAnimIndex = math.random(1, self.actor.SpecialAnims:Length())
            Montage = self.actor.SpecialAnims[self.CurrAnimIndex]
            --G.log:info_obj(self, "VehicleComponent", "Do Spec Anim On Track %d, %s, %f",  self.CurrAnimIndex, G.GetObjectName(Montage), Montage:GetPlayLength())
        elseif self.InSprintState then
            self.CurrAnimIndex = math.random(1, self.actor.SpecialAnimsSprint:Length())
            Montage = self.actor.SpecialAnimsSprint[self.CurrAnimIndex]
            --G.log:info_obj(self, "VehicleComponent", "Do Spec Anim In Sprint %d, %s, %f",  self.CurrAnimIndex, G.GetObjectName(Montage), Montage:GetPlayLength())
        elseif UE.EMovementMode.MOVE_Falling == MovementMode then 
            self.CurrAnimIndex = math.random(1, self.actor.SpecialAnimsFall:Length())
            Montage = self.actor.SpecialAnimsFall[self.CurrAnimIndex]
            --G.log:info_obj(self, "VehicleComponent", "Do Spec Anim On Falling %d, %s, %f",  self.CurrAnimIndex, G.GetObjectName(Montage), Montage:GetPlayLength())
        else
            self.CurrAnimIndex = math.random(1, self.actor.SpecialAnimsRun:Length())
            Montage = self.actor.SpecialAnimsRun[self.CurrAnimIndex]
            --G.log:info_obj(self, "VehicleComponent", "Do Spec Anim In Running %d, %s, %f",  self.CurrAnimIndex, G.GetObjectName(Montage), Montage:GetPlayLength())
        end
        
       
        if Montage then
            self:ResetNextSpecAnimRemainingTime(Montage:GetPlayLength())
            local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
            local callback = function(name)
                self.OnSpecAnimMontageEnd(self)
            end
            PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
            PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
            --for idx = 1, self.Passengers:Length() do
            --    local Passenger = self.Passengers:Get(idx)
            --    Passenger:SendMessage("PlaySpecAnimMontage", Montage)
            --end
        else
            self.OnSpecAnimMontageEnd(self)
        end
    end
end

function VehicleComponent:StopSpecAnimMontage()
    --G.log:info_obj(self, "VehicleComponent", "StopSpecAnimMontage %d ", self.CurrAnimIndex)
    if self.CurrAnimIndex == 0 then
        return
    end
    local CurrentMontage = self.actor:GetCurrentMontage()
    --G.log:info_obj(self, "VehicleComponent", "StopSpecAnimMontage %s ", G.GetObjectName(CurrentMontage))
    
    if self.actor.SpecialAnimsRun:Contains(CurrentMontage) or self.actor.SpecialAnimsFall:Contains(CurrentMontage) or self.actor.SpecialAnimsSprint:Contains(CurrentMontage) 
            or self.actor.SpecialAnims:Contains(CurrentMontage)   then
        local AnimInstance = self.actor.Mesh:GetAnimInstance()
        if AnimInstance then
            AnimInstance:Montage_Stop(0.2, CurrentMontage)
        end
    end
    self.CurrAnimIndex = 0
    --for idx = 1, self.Passengers:Length() do
    --    local Passenger = self.Passengers:Get(idx)
    --    Passenger:SendMessage("StopSpecAnimMontage", CurrentMontage)
   -- end
end

function VehicleComponent:OnSpecAnimMontageEnd()
    --G.log:info_obj(self, "VehicleComponent", "OnSpecAnimMontageEnd")
    --self.NextSpecAnimRemainingTime = 0
end

function VehicleComponent:ResetNextSpecAnimRemainingTime(amin_length)
    if self.bEnabled then
        --self:StopSpecAnimMontage()
        self.NextSpecAnimRemainingTime = 0 - amin_length
        --G.log:info_obj(self, "VehicleComponent", "ResetNextSpecAnimRemainingTime %f", amin_length)
    end
end

function VehicleComponent:OnPassengerJumpIn()
    
end

decorator.message_receiver()
function VehicleComponent:BeginRide(passenger)

    assert(self.Passengers:Find(passenger) == 0)

    local Montage = self:GetBeginRideMontage(passenger)
    self.bGettingOn = true
    self.bEnabled = true
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(passenger, true)
    self.actor.CharacterMovement.bServerAcceptClientAuthoritativePosition = true
    self.Speed = 0
    --G.log:error("lizhao", "VehicleComponent:BeginRide %s %s", tostring(self.actor:K2_GetActorLocation()), tostring(passenger))
    if Montage then
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            self.OnBeginRideMontageEnd(self, name, passenger)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    else
        self.OnBeginRideMontageEnd(self, nil, passenger)
    end
    
end

function VehicleComponent:OnBeginRideMontageEnd(name, passenger)
    passenger.Mesh:AddTickPrerequisiteComponent(self.actor.Mesh)
    self.Passengers:Add(passenger)
    self.bGettingOn = false
    if passenger.Vehicle == self.actor then
        self.Driver = passenger
    end
    
end

function VehicleComponent:HasPassenger()
    local InValidPsgs = {}
    for idx = 1, self.Passengers:Length() do
        local Passenger = self.Passengers:Get(idx)
        if not UE.UKismetSystemLibrary.IsValid(Passenger) then
            table.insert(InValidPsgs, Passenger)
        end
    end

    for _, InValidPsg in pairs(InValidPsgs) do
        self.Passengers:RemoveItem(InValidPsg)
    end

    if self.Passengers:Length() == 0 then
        return false
    else
        return true
    end
end

decorator.message_receiver()
function VehicleComponent:AttachToVehicle(passenger)
    local SnapToTarget = UE.EAttachmentRule.SnapToTarget
    local KeepWorld = UE.EAttachmentRule.KeepWorld
    --G.log:error("lizhao", "VehicleComponent:AttachToVehicle %s %s %s %s %s", tostring(self.actor:IsClient()), tostring(self.actor:K2_GetActorLocation()), self.SeatSocket, tostring(self.actor.Mesh:GetSocketLocation(self.SeatSocket)), tostring(self.actor.Mesh:GetSocketRotation(self.SeatSocket)))
    passenger:K2_AttachToComponent(self.actor.Mesh, self.SeatSocket, KeepWorld, KeepWorld, KeepWorld, false)
    if self.actor.Mesh.AddSyncedMeshComponents ~= nil then
        self.actor.Mesh:AddSyncedMeshComponents(passenger.Mesh)
        passenger.Mesh:SetHiddenInGame(true)
    end
    
    --G.log:error("lizhao", "VehicleComponent:AttachToVehicle 111 %s %s %s %s %s", tostring(self.actor:IsClient()), tostring(self.actor:K2_GetActorLocation()), tostring(passenger:K2_GetActorLocation()), tostring(self.actor.Mesh:GetSocketLocation(self.SeatSocket)), tostring(self.actor.Mesh:GetSocketRotation(self.SeatSocket)))
end

decorator.message_receiver()
function VehicleComponent:EndRide(passenger)
    G.log:info_obj(self, "VehicleComponent", "EndRide %s",G.GetObjectName(passenger))
    assert(self.Passengers:Find(passenger) > 0)
    self.bGettingOff = true
    self.bEnabled = false
    self.Speed = 0
    self.Passengers:RemoveItem(passenger)
    passenger.Mesh:RemoveTickPrerequisiteComponent(self.actor.Mesh)
    local Montage = self:GetLeaveVehicleMontage()
    
    if Montage then
        G.log:info_obj(self, "VehicleComponent", "GetLeaveVehicleMontage %s",G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, 1.0)
        local callback = function(name)
            self.OnEndRideMontageEnd(self, name, passenger)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    else
        self.OnEndRideMontageEnd(self, nil, passenger)
    end
end

function VehicleComponent:CanJumpOut()
    local MovementMode = self.actor.CharacterMovement.MovementMode
    return MovementMode == UE.EMovementMode.MOVE_Walking
end

decorator.message_receiver()
function VehicleComponent:ANS_SkateBoardJump_Begin(TotalDuration, TopHeight, DistanceXY)
    G.log:info_obj(self, "VehicleComponent", "ANS_SkateBoardJump_Begin %f, %f, %f, %f",G.GetNowTimestampMs(), TotalDuration , TopHeight, DistanceXY)
    
    local MovementMode = self.actor.CharacterMovement.MovementMode
    if MovementMode == UE.EMovementMode.MOVE_None or MovementMode == UE.EMovementMode.MOVE_Custom then
        --continue
    else
        
        local Velocity = self.actor.CharacterMovement.Velocity
        Velocity.Z = Velocity.Z + 666
        if self.InJumpInAction then
            local v = self.actor.CharacterMovement.UpdatedComponent:GetForwardVector() * 600
            G.log:info_obj(self, "VehicleComponent", "GetForwardVector %f, %f, %f",v.X, v.Y, v.Z)
            Velocity.X = v.X
            Velocity.Y = v.Y
        end
        G.log:info_obj(self, "VehicleComponent", "set Velocity %f, %f, %f",Velocity.X, Velocity.Y, Velocity.Z)
        self.actor.CharacterMovement.Velocity = Velocity
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
        return
    end
    self.JumpDuration = TotalDuration
    self.InAirDuration = -1
    self.JumpOffset = 0
    local t1 = 0
    
    if self.TargetLocation == nil then
        -- 无目标点，跳跃动画
        t1 = TotalDuration * 0.5
        self.JumpGravity = - 2 * TopHeight/(t1 * t1)
    else
        --跳向目标
        local H1 = self.StartLocation.Z
        local H2 = self.TargetLocation.Z
        local TopZ = 0
        TopHeight = TopHeight * 100
        if math.abs(H1-H2) > TopHeight - 100 then
            TopZ = math.max(H1, H2) + 100 -- 至少要跳高1米
        else
            TopZ = math.min(H1, H2) + TopHeight   --动画默认跳高为1.6米
        end
        local h1 = 0.01*(TopZ-H1)
        local h2 = 0.01*(TopZ-H2)
        self.JumpGravity = -(2*h1 + 2*h2 + 4*math.sqrt(h1*h2))/(TotalDuration*TotalDuration)
        t1 = math.sqrt(-2*h1/self.JumpGravity)
        self.MinOffsetInFalling = 0.01*(H2-H1) --防止落到目标点之下
        G.log:info_obj(self, "VehicleComponent", "Start:<%f, %f, %f> H1:%f, H2:%f, MinOffsetZ %f",
                self.StartLocation.X, self.StartLocation.Y, self.StartLocation.Z, H1, H2, self.MinOffsetInFalling )
    end

    self.JumpVel = -self.JumpGravity * t1
    G.log:info_obj(self, "VehicleComponent", "%f, %f, ",self.JumpVel, self.JumpGravity )
end

decorator.message_receiver()
function VehicleComponent:ANS_SkateBoardJump_Tick(FrameDeltaTime)
    --G.log:info_obj(self, 'ANS_SkateBoardJump_Tick', "%f", FrameDeltaTime)
    local MovementMode = self.actor.CharacterMovement.MovementMode
    if MovementMode == UE.EMovementMode.MOVE_None or MovementMode == UE.EMovementMode.MOVE_Custom then
        --continue
    else
        return
    end
    self.DeltaSeconds = FrameDeltaTime
    if self.InAirDuration < 0 then
        self.InAirDuration = 0 --first tick with begin
    else
        self.InAirDuration = self.InAirDuration + FrameDeltaTime
    end
    if self.InAirDuration > 0 then
        self.progress = self.InAirDuration / self.JumpDuration
        local V = self.JumpVel
        local Gravity = self.JumpGravity
        self.JumpVel = V + Gravity * FrameDeltaTime
        self.JumpOffset = self.JumpOffset + V * FrameDeltaTime + 0.5 * Gravity * FrameDeltaTime * FrameDeltaTime
        if self.TargetLocation ~= nil then
            if V < 0 and self.JumpOffset < self.MinOffsetInFalling then
                self.JumpOffset = self.MinOffsetInFalling -- 下落时的最小值,不低于目标点
            end
            self:UpdatePoint(false)
        end
        --G.log:info_obj(self, "VehicleComponent", "ANS_SkateBoardJump_Tick Progress %f%% Target v:%f, offset:%f",self.progress * 100, self.JumpVel, self.JumpOffset )
    end
end

decorator.message_receiver()
function VehicleComponent:ANS_SkateBoardJump_End()
    
    if self.InJumpInAction then
        self.InJumpInAction = false
        G.log:info_obj(self,'VehicleComponent', 'SkateBoard Jump In End')
    end
    local MovementMode = self.actor.CharacterMovement.MovementMode
    if MovementMode == UE.EMovementMode.MOVE_None or MovementMode == UE.EMovementMode.MOVE_Custom then
        --continue
    else
        return
    end
    if self.TargetLocation ~= nil then
        if self.progress and self.progress < 1.0 then
            G.log:info_obj(self, "VehicleComponent", "Received_NotifyEnd fix Update %f" ,self.progress)
            self.progress = 1.0
            self.move_dist = self.all_dist
            self.JumpOffset = self.MinOffsetInFalling
            self:UpdatePoint()
        end
        if self.spline_data.next ~= nil then
            self.spline_data = self.spline_data.next
            self:init_spline_data()
        end
    end
    
    self.JumpDuration = 0
    self.InAirDuration = 0
    self.JumpOffset = 0
    self.JumpVel = 0
end

decorator.message_receiver()
function VehicleComponent:JumpOutSpline(Location, Rotation, Velocity)
    local Montage = self.JumpMontage
    local PlayRate = 1.0
    if Montage then
        self.InJumpInAction = true
        G.log:info_obj(self, "VehicleComponent", "JumpOutSpline %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, PlayRate)
        local callback = function(name)
            self.OnEndJumpInMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
    self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    self.actor.CharacterMovement.bRunPhysicsWithNoController = true
    self.Speed = 0
end

function VehicleComponent:JumpToSpline(Spline, InHead, StartPercent, DurationTime)
    local TargetYaw = 0
    local TargetTransform = nil
    local location , rotation, scale3d= nil
    local SplineLength = Spline:GetSplineLength()
    
    if InHead then
        TargetTransform = Spline:GetTransformAtDistanceAlongSpline(SplineLength * StartPercent , UE.ESplineCoordinateSpace.World)
        location, rotation, scale3d = UE.UKismetMathLibrary.BreakTransform(TargetTransform)
        TargetYaw = rotation.Yaw
    else
        TargetTransform = Spline:GetTransformAtDistanceAlongSpline(SplineLength * (1-StartPercent) , UE.ESplineCoordinateSpace.World)
        location, rotation, scale3d = UE.UKismetMathLibrary.BreakTransform(TargetTransform)
        TargetYaw = rotation.Yaw + 180
    end
    G.log:info_obj(self, "VehicleComponent", "JumpToSpline %s, InHead %s, StartLocation:<%f, %f, %f>", G.GetObjectName(Spline),
            InHead, location.X, location.Y, location.Z
    )
    local PlayRate = 1.0
    local Montage = self.JumpInMontage
    if self.Appear then
        Montage = self.JumpMontage
    end
    if self.actor.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_Walking then
        self.Speed = self.actor.CharacterMovement.Velocity:Size2D()
    end
    if self.CurrSplineTrack then
        -- Spline Jump to Spline use JumpMontage
        Montage = self.JumpMontage
        
        local MontageTime = 0.750000
        if DurationTime ~= nil and DurationTime > 0 then
            PlayRate = MontageTime / DurationTime
        elseif self.Speed ~= 0 then
            PlayRate = math.min(math.max(MontageTime, self.Speed / (self.actor:K2_GetActorLocation() - location):Size2D()), 1.5)
        end
        G.log:info_obj(self, "VehicleComponent", "Do JumpToSpline Speed, %f PlayRate %f",self.Speed, PlayRate )

    end
    
    local track_spline_data = { spline=Spline, reverse=not InHead, start=StartPercent, mode=1}
    self.spline_data = { --spline=Spline:GetParabolaSplineTrack(InHead, pre_location, anim_time),
        target_location = location,
        mode=0, reverse=false, next=track_spline_data}
    self.spline_data.target_yaw = TargetYaw
    self.spline_data.keep_pitch = true
    self:init_spline_data()
    for idx = 1, self.Passengers:Length() do
        local Passenger = self.Passengers:Get(idx)
        Passenger:SendMessage("OnVehicleJumpToSpline", Spline, InHead, PlayRate)
    end

    if Montage then
        self:ResetNextSpecAnimRemainingTime(Montage:GetPlayLength())
        G.log:info_obj(self, "VehicleComponent", "JumpInMontage %s", G.GetObjectName(Montage))
        local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, Montage, PlayRate)
        local callback = function(name)
            self.OnEndJumpInMontageEnd(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, callback)
        PlayMontageCallbackProxy.OnCompleted:Add(self.actor, callback)
    end
    self.Appear = true
end

decorator.message_receiver()
function VehicleComponent:JumpToSplineTrack(Spline, InHead)
    --G.log:info("VehicleComponent", "JumpToSplineTrack %s, InHead%s", Spline, InHead)
    self:JumpToSpline(Spline, InHead, 0, 0)
end

function VehicleComponent:OnEndJumpInMontageEnd(name)
    G.log:info_obj(self, "VehicleComponent", "OnEndJumpInMontageEnd %s", G.GetObjectName(name))
end

function VehicleComponent:fix_rotation(yaw)
    if yaw > 180 then
        yaw = yaw - 360 * math.floor((yaw + 180)/ 360)
    elseif yaw < -180 then
        yaw = yaw + 360 *  math.floor((yaw - 180)/ -360)
    end
    return yaw
end

function VehicleComponent:init_spline_data()
    self.CurrSplineTrack = self.spline_data.spline
    self.TargetLocation = self.spline_data.target_location
    self.StartLocation = self.actor:K2_GetActorLocation()
    self.ReverseSplineForward = self.spline_data.reverse
    local target_mode = self.spline_data.mode
    self.move_mode = target_mode
    
    self.KeepPitch = self.spline_data.keep_pitch
    self.TargetYaw = self.spline_data.target_yaw
    if self.TargetYaw ~= nil then
        self.StartYaw = self:fix_rotation(self.actor:K2_GetActorRotation().Yaw)
        self.TargetYaw = self:fix_rotation(self.TargetYaw)
        if math.abs(self.TargetYaw - self.StartYaw) > 180 then
            if self.TargetYaw > self.StartYaw then
                self.TargetYaw = self.TargetYaw - 360
            else
                self.TargetYaw = self.TargetYaw + 360
            end
        end
    end
    if self.CurrSplineTrack then
        self.all_dist = self.CurrSplineTrack:GetSplineLength()
        G.log:info_obj(self, "VehicleComponent", "To Spline %s, InHead %s, Start %f", G.GetObjectName(self.CurrSplineTrack),
                self.ReverseSplineForward, self.spline_data.start
        )
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom, CustomMovementModes.Spline)
    else
        self.all_dist = (self.TargetLocation - self.StartLocation):Size2D()
        G.log:info_obj(self, "VehicleComponent", "To TargetLocation <%f, %f, %f>",
                self.TargetLocation.X, self.TargetLocation.Y, self.TargetLocation.Z
        )
        self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    end
    self.progress = 0
    
    if self.spline_data.start ~= nil then
        self.progress = self.spline_data.start
    end
   
    self.move_dist = self.progress * self.all_dist
    G.log:info_obj(self, "cp", "Init Spline start %s, %s, %s", self.spline_data.start, self.move_dist, self.progress)
    if self.CurrSplineTrack then
        local SplineActor = self.CurrSplineTrack.actor
        self.TransitionAreas = SplineActor.SplineTransitionAreas
        G.log:info_obj(self, "cp", "Init Spline %s", self.TransitionAreas:Length())
    else
        self.TransitionAreas = nil
    end
    self.TargetTransitionRange = nil
    self.TargetSplineActors = nil
    self:HideTransitionTips()
end

function VehicleComponent:OnEndRideMontageEnd(name, passenger)
    self.bGettingOff = false
    --self.actor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(passenger, false)
    --self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    self.actor.Mgr:DestroyVehicle()
    self.Appear = false
end

decorator.message_receiver()
function VehicleComponent:DetachFromVehicle(passenger)
    --self.actor.CharacterMovement.UpdatedComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    --self.actor.Mesh:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    --self.actor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Custom)
    if self.actor.Mesh.RemoveSyncedMeshComponents ~= nil then
        self.actor.Mesh:RemoveSyncedMeshComponents(passenger.Mesh)
        passenger.Mesh:SetHiddenInGame(false)
    end
    passenger:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
end

function VehicleComponent:TurnInPlace(Angle)
    local Passengers = self.Passengers
    for Ind = 1, Passengers:Length() do
        local Passenger = Passengers:Get(Ind)
        Passenger:SendMessage("TurnInPlace", Angle)
    end
end

decorator.message_receiver()
function VehicleComponent:OnHealthChanged(NewValue, OldValue)
    if self.Passengers:Length() == 0 then
        return
    end
    self.Passengers:Get(1):SendMessage("OnVehicleHealthChanged")
end

return VehicleComponent