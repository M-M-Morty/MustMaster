local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local MotionWarpingModifyComponent = Component(ComponentBase)
local decorator = MotionWarpingModifyComponent.decorator

local WarpNameRotationTarget = "RotationTarget"

function MotionWarpingModifyComponent:Initialize(...)
    Super(MotionWarpingModifyComponent).Initialize(self, ...)
    self.input_directions = {0, 0}
    self.bAllowWarp = false
    self.last_rotation = UE.FQuat()
end

function MotionWarpingModifyComponent:Start()
    Super(MotionWarpingModifyComponent).Start(self)
end

function MotionWarpingModifyComponent:Stop()
    Super(MotionWarpingModifyComponent).Stop(self)
end

decorator.message_receiver()
function MotionWarpingModifyComponent:MoveForward(value)
    self.input_directions[1] = value

    self:UpdateDirection()
end

decorator.message_receiver()
function MotionWarpingModifyComponent:MoveForward_Released(value)
    self.input_directions[1] = 0

    self:UpdateDirection()
end

decorator.message_receiver()
function MotionWarpingModifyComponent:MoveRight(value)
    self.input_directions[2] = value

    self:UpdateDirection()
end

decorator.message_receiver()
function MotionWarpingModifyComponent:MoveRight_Released(value)
    self.input_directions[2] = 0

    self:UpdateDirection()
end

function MotionWarpingModifyComponent:GetDirectionVector()
    local control_rotation = self.actor:GetControlRotation()
    local AimRotator = UE.FRotator(0, control_rotation.Yaw, 0)
    local DirectionVector = UE.FVector(0, 0, 0)

    local forward_value = self.input_directions[1]

    if forward_value ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetForwardVector() * forward_value
    end

    local right_value = self.input_directions[2]

    if right_value ~= 0 then
        DirectionVector = DirectionVector + AimRotator:GetRightVector() * right_value
    end

    return DirectionVector
end

function MotionWarpingModifyComponent:UpdateDirection()
    if self.bAllowWarp then
        local DirectionVector = self:GetDirectionVector()

        if DirectionVector:SizeSquared() > 0.5 then
            local TargetRotation = UE.UKismetMathLibrary.Conv_VectorToQuaternion(DirectionVector)
            self:WarpTransform(WarpNameRotationTarget, UE.FTransform(TargetRotation))
            if not UE.UKismetMathLibrary.EqualEqual_QuatQuat(self.last_rotation, TargetRotation, 1e-3) then
                self.last_rotation = TargetRotation
                self:Server_SetWarpTarget(WarpNameRotationTarget, UE.FTransform(TargetRotation))
            end
        else
            self:ClearWarpTarget(WarpNameRotationTarget)
            self:Server_ClearWarpTarget(WarpNameRotationTarget)
        end
    end
end

function MotionWarpingModifyComponent:Notify_AllowWarpBegin()
    self.bAllowWarp = true

    -- TODO Need set this before MotionWarping NotifyState triggered, otherwise warp not work.
    local CurTransform = self.actor:GetTransform()
    self:WarpTransform(WarpNameRotationTarget, CurTransform)
    self:Server_SetWarpTarget(WarpNameRotationTarget, CurTransform)
end

function MotionWarpingModifyComponent:Notify_AllowWarpEnd()
    self.bAllowWarp = false
    self:ClearWarpTarget(WarpNameRotationTarget)
    self:Server_ClearWarpTarget(WarpNameRotationTarget)
end

function MotionWarpingModifyComponent:Server_ClearWarpTarget_RPC(WarpTargetName)
    self:MulticastOther_ClearWarpTarget(WarpTargetName)
end

function MotionWarpingModifyComponent:MulticastOther_ClearWarpTarget_RPC(WarpTargetName)
    self:ClearWarpTarget(WarpTargetName)
end

function MotionWarpingModifyComponent:ClearWarpTarget(WarpTargetName)
    if self.actor then
        self.actor.MotionWarping:RemoveWarpTarget(WarpTargetName)
    end
end

function MotionWarpingModifyComponent:Server_SetWarpTarget_RPC(WarpTargetName, TargetTransform)
    self:MulticastOther_SetWarpTarget(WarpTargetName, TargetTransform)
end

function MotionWarpingModifyComponent:MulticastOther_SetWarpTarget_RPC(WarpTargetName, TargetTransform)
    --G.log:debug("MotionWarpingModifyComponent", "Receive set warp target: %s, %s", WarpTargetName, tostring(TargetTransform))
    self:WarpTransform(WarpTargetName, TargetTransform)
end

function MotionWarpingModifyComponent:WarpTransform(WarpTargetName, TargetTransform)
    --G.log:debug("MotionWarpingModifyComponent", "WarpTransform %s, %s", WarpTargetName, tostring(TargetTransform))
    if self.actor then
        self.actor.MotionWarping:AddOrUpdateWarpTargetFromTransform(WarpTargetName, TargetTransform)
    end
end

return MotionWarpingModifyComponent
