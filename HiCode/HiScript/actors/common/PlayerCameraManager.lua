require "UnLua"

local G = require("G")

local Actor = require("common.actor")
local check_table = require("common.data.state_conflict_data")

local PlayerCameraManager = Class(Actor)


function PlayerCameraManager:OnPossess(NewCharacter)
    self.Overridden.OnPossess(self, NewCharacter)
    -- G.log:debug("zaleggzhao", "Camera:OnPossess %s  IsClient: %s", G.GetDisplayName(NewCharacter), UE.UHiUtilsFunctionLibrary.IsClientWorld())
    local VisionerInstance = self:GetVisionerInstance()
    if VisionerInstance then
        VisionerInstance.ControlledActor = NewCharacter
    end
end

function PlayerCameraManager:OnUnPossess()
    self.Overridden.OnUnPossess(self)
    -- G.log:debug("zaleggzhao", "Camera:OnUnPossess %s  IsClient: %s", G.GetDisplayName(self.ControlledCharacter), UE.UHiUtilsFunctionLibrary.IsClientWorld())
    local VisionerInstance = self:GetVisionerInstance()
    if VisionerInstance then
        VisionerInstance.ControlledActor = nil
    end
end

function PlayerCameraManager:SetBossBattleState(bIsInBossBattleState, Target)
    local ConfigComponent = Target:GetComponentByClass(UE.UHiDoubleObjectCameraComponent)
    local bEnableDoubleObject = bIsInBossBattleState and Target and self.ControlledCharacter
    bEnableDoubleObject = bEnableDoubleObject and ConfigComponent

    local VisionerInstance = self:GetVisionerInstance()
    if VisionerInstance then
        if bEnableDoubleObject then
            VisionerInstance.TargetActor = Target
            VisionerInstance.CurrentCameraMode = Enum.E_CameraMode.DoubleObject
            ConfigComponent:OnEnter(self)
        else
            VisionerInstance.TargetActor = nil
            VisionerInstance.CurrentCameraMode = Enum.E_CameraMode.Classic
            ConfigComponent:OnLeave(self)
        end
        return
    end

    if bEnableDoubleObject then
        self:ToDoubleObjectViewMode(0.1, Target)
    else
        self:ChangeCameraViewMode(UE.EHiCameraViewMode.Classic, 0.1)
    end
end

-- 相机触发动画的简易封装，方便外部调用 --

function PlayerCameraManager:PlayAnimation_WatchTarget(Target)
    local VisionerInstance = self:GetVisionerInstance()
    if VisionerInstance then
        VisionerInstance.TargetActor = Target
        VisionerInstance:PlayCustomAnimationByTag("WatchTarget")
    end
end

function PlayerCameraManager:PlayAnimation_Rotate(Orientation, RotateHalfLife)
	local VisionerInstance = self:GetVisionerInstance()
	if VisionerInstance then
		VisionerInstance.RotateHalflife = RotateHalfLife
		VisionerInstance.RotateOrientation = Orientation
		VisionerInstance:PlayCustomAnimationByTag("Rotate")
	end
end

function PlayerCameraManager:PlayAnimation_Delay()
	local VisionerInstance = self:GetVisionerInstance()
	if VisionerInstance then
		VisionerInstance:PlayCustomAnimationByTag("Delay")
	end
end

function PlayerCameraManager:StopAnimation_Delay()
	local VisionerInstance = self:GetVisionerInstance()
	if VisionerInstance then
		VisionerInstance:StopCustomAnimationByTag("Delay")
	end
end


return PlayerCameraManager