--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"


local G = require("G")

local Component = require("common.component")
local ComponentBase = require("common.componentbase")


---@class BP_DoubleObjectCameraComponent
local DoubleObjectCameraComponent = Component(ComponentBase)
local decorator = DoubleObjectCameraComponent.decorator


function DoubleObjectCameraComponent:OnEnter(PlayerCameraManager)
    if not self.bEnableCameraScheme then
        return
    end
    local VisionerInstance = PlayerCameraManager:GetVisionerBP()
    if VisionerInstance then
        -- Change Config
        local CustomView = VisionerInstance:GetVisionerCustomViewByTag("DoubleObject")
        CustomView:SetCameraSchemeConfig(self.CameraSchemeConfig)
        -- Change Collision
        VisionerInstance.CollisionPushChannel = self.ReplacedCameraCollision
    end
    -- Add Post Process Material
    local PostProcessor = PlayerCameraManager:FindCameraPostProcessorByName("CameraOcclusion")
    if PostProcessor and self.PostProcessMaterial then
        PostProcessor.OcclusionPostProcessMaterials:Add(self.PostProcessMaterial)
        -- G.log:info("zlgg", "DoubleObjectCameraComponent OnEnter")
    end
end


function DoubleObjectCameraComponent:OnLeave(PlayerCameraManager)
    local VisionerInstance = PlayerCameraManager:GetVisionerBP()
    if VisionerInstance then
        -- Restore Collision
        VisionerInstance.CollisionPushChannel = UE.ECollisionChannel.ECC_Camera
    end
    -- Remove Post Process Material
    local PostProcessor = PlayerCameraManager:FindCameraPostProcessorByName("CameraOcclusion")
    if PostProcessor and self.PostProcessMaterial then
        PostProcessor.OcclusionPostProcessMaterials:Remove(self.PostProcessMaterial)
        -- G.log:info("zlgg", "DoubleObjectCameraComponent OnLeave")
    end
end


return DoubleObjectCameraComponent
