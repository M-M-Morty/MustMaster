require "UnLua"

local G = require("G")

local BTDecorator_IsRotationIn = Class()

function BTDecorator_IsRotationIn:PerformConditionCheck(Controller)
    local Pawn = Controller:GetInstigator()
    local SelfRotation = Pawn:K2_GetActorRotation()
    local bIsPitchIn, bIsYawIn, bIsRollIn = true, true, true

    if self.bPitch then
    	bIsPitchIn = self.MinRotation.Pitch < SelfRotation.Pitch and SelfRotation.Pitch < self.MaxRotation.Pitch
    end

    if self.bYaw then
    	bIsYawIn = self.MinRotation.Yaw < SelfRotation.Yaw and SelfRotation.Yaw < self.MaxRotation.Yaw
    end

    if self.bRoll then
    	bIsRollIn = self.MinRotation.Roll < SelfRotation.Roll and SelfRotation.Roll < self.MaxRotation.Roll
    end

    -- G.log:debug("yj", "BTDecorator_IsRotationIn:PerformConditionCheck bIsPitchIn.%s, MinPitch.%s, SelfPitch.%s MaxPitch.%s", bIsPitchIn, self.MinRotation.Pitch, SelfRotation.Pitch, self.MaxRotation.Pitch)
    -- G.log:debug("yj", "BTDecorator_IsRotationIn:PerformConditionCheck bIsYawIn.%s, MinYaw.%s, SelfYaw.%s MaxYaw.%s", bIsYawIn, self.MinRotation.Yaw, SelfRotation.Yaw, self.MaxRotation.Yaw)
    -- G.log:debug("yj", "BTDecorator_IsRotationIn:PerformConditionCheck bIsRollIn.%s, MinRoll.%s, SelfRoll.%s MaxRoll.%s", bIsRollIn, self.MinRotation.Roll, SelfRotation.Roll, self.MaxRotation.Roll)
    return bIsPitchIn and bIsYawIn and bIsRollIn
end


return BTDecorator_IsRotationIn
