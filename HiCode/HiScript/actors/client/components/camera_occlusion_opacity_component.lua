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


---@class BP_CameraOcclusionOpacityComponent
local CameraOcclusionOpacityComponent = Component(ComponentBase)
local decorator = CameraOcclusionOpacityComponent.decorator


-- function CameraOcclusionOpacityComponent:StartEffect(DistanceOfHitToCamera, DistanceOfCharacterToCamera)
--     self.Overridden.StartEffect(self, DistanceOfHitToCamera, DistanceOfCharacterToCamera)
--     G.log:info("zlgg", "hello %f %f", DistanceOfHitToCamera, DistanceOfCharacterToCamera)
-- end

decorator.message_receiver()
function CameraOcclusionOpacityComponent:SetEffectAllowed(InValue)
    self.bIsEffectAllowed = InValue
end


return CameraOcclusionOpacityComponent
