local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local CameraControl = Component(ComponentBase)
local decorator = CameraControl.decorator

decorator.message_receiver()
function CameraControl:OnClimbPause()
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    local CameraRotationModifier = CameraManager.CameraRotationModifier

    if CameraRotationModifier then
        CameraRotationModifier:DisableModifier(true)
    end
end

decorator.message_receiver()
function CameraControl:OnClimbStop()

end

decorator.message_receiver()
function CameraControl:OnClimbMove(TargetYaw, TargetPitch)
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    if CameraManager:GetCurrentViewMode() == UE.EHiCameraViewMode.DoubleObject then
        return
    end

    local CameraRotationModifier = CameraManager.CameraRotationModifier

    if CameraRotationModifier then
        CameraRotationModifier:DelayEnableModifier()
        CameraRotationModifier:SetTargetYaw(TargetYaw)
        CameraRotationModifier:SetTargetPitch(TargetPitch)
    end

end

decorator.message_receiver()
function CameraControl:OnCameraUpAction(value)
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    local CameraRotationModifier = CameraManager.CameraRotationModifier

    if CameraRotationModifier then
        CameraRotationModifier:DisableModifier(true)
    end
end

decorator.message_receiver()
function CameraControl:OnCameraRightAction(value)
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    local CameraRotationModifier = CameraManager.CameraRotationModifier

    if CameraRotationModifier then
        CameraRotationModifier:DisableModifier(true)
    end
end

decorator.message_receiver()
function CameraControl:OnCameraScaleAction(value)
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    local DistanceScaleModifier = CameraManager.DistanceScaleModifier

    if DistanceScaleModifier then
        DistanceScaleModifier:DisableModifier(true)
    end
end

function CameraControl:OnPlayerMove()
    if not self.actor:IsPlayer() then
        return
    end

    local CameraManager = UE.UGameplayStatics.GetPlayerCameraManager(self:GetWorld(), 0)
    local DistanceScaleModifier = CameraManager.DistanceScaleModifier

    if DistanceScaleModifier then
        DistanceScaleModifier:DelayEnableModifier()
    end
end

decorator.message_receiver()
function CameraControl:MoveForward(value)
    self:OnPlayerMove()
end

decorator.message_receiver()
function CameraControl:MoveRight(value)
    self:OnPlayerMove()
end

return CameraControl