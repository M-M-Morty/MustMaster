require "UnLua"

local G = require("G")

local BTDecorator_IsSelfInTrap = Class()

function BTDecorator_IsSelfInTrap:PerformConditionCheck(Controller)

    local Pawn = Controller:GetInstigator()
    local TrapActors = GameAPI.GetActorsWithTags(Pawn, self.TrapTags)

    -- G.log:error("yj", "BTDecorator_IsSelfInTrap %s %s", self.TrapTags:Length(), #TrapActors)

    for idx, TrapActor in pairs(TrapActors) do
        if TrapActor.StaticMesh:IsOverlappingActor(Pawn) then
            return true
        end
    end

    return false
end


return BTDecorator_IsSelfInTrap
