require "UnLua"

local G = require("G")

local BTService_SetSpeed = Class()


function BTService_SetSpeed:ReceiveActivation(Actor)
    -- G.log:debug("yj", "BTService_SetSpeed %s", self.Gait)

    local Pawn = Actor:GetInstigator()
    Pawn.AppearanceComponent:SetDesiredGait(self.Gait)
end


return BTService_SetSpeed
