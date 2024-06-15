local G = require("G")

local BTService_SetDesiredRotationMode = Class()


function BTService_SetDesiredRotationMode:ReceiveActivation(Actor)
    -- G.log:debug("yj", "BTService_SetDesiredRotationMode %s", self.DesiredRotationMode)

    local Pawn = Actor:GetInstigator()
    Pawn.AppearanceComponent:Multicast_SetDesiredRotationMode(self.DesiredRotationMode)
end


return BTService_SetDesiredRotationMode
