require "UnLua"

local G = require("G")

local BTDecorator_IsDogInTrap = Class()

function BTDecorator_IsDogInTrap:PerformConditionCheck(Controller)
    local Pawn = Controller:GetInstigator()
    return Pawn.UtilsComponent.DogInTrap
end


return BTDecorator_IsDogInTrap
