require "UnLua"

local G = require("G")

local BTDecorator_IsActorInTrap = Class()

function BTDecorator_IsActorInTrap:PerformConditionCheck(Controller)

    local Pawn = Controller:GetInstigator()
    local Actors = GameAPI.GetActorsWithTag(Pawn, self.ActorTag)
    if not Actors then
        return false
    end
    
    local TrapActors = GameAPI.GetActorsWithTags(Pawn, self.TrapTags)

    -- G.log:error("yj", "BTDecorator_IsActorInTrap %s %s", self.TrapTags:Length(), #TrapActors)

    for idx, TrapActor in pairs(TrapActors) do
        for j = 1, #Actors do
            -- G.log:error("yj", "BTDecorator_IsActorInTrap:PerformConditionCheck %s %s %s", TrapActor:GetDisplayName(), Actors[j]:GetDisplayName(), TrapActor.StaticMesh:IsOverlappingActor(Actors[j]))
            if TrapActor.StaticMesh:IsOverlappingActor(Actors[j]) then
                return true
            end
        end
    end

    return false
end


return BTDecorator_IsActorInTrap
