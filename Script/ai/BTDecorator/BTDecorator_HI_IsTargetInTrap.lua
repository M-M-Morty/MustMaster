require "UnLua"

local G = require("G")
local GameAPI = require("common.game_api")

local BTDecorator_IsTargetInTrap = Class()

function BTDecorator_IsTargetInTrap:PerformConditionCheck(Controller)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")

    local TargetState = nil;
    -- 因为TrapActor里面保存的是 PlayerState信息
    if Target then
        TargetState = Target.PlayerState;
    end

    if nil == Target then
        return false
    end

    local Pawn = Controller:GetInstigator()
    local TrapActors = GameAPI.GetActorsWithTags(Pawn, self.TrapTags)

    for idx, TrapActor in pairs(TrapActors) do
        if TrapActor.InnerActors:Contains(Target) then
            return true
        elseif TargetState and TrapActor.InnerActors:Contains(TargetState) then
            return true
        else
            if TrapActor.StaticMesh:IsOverlappingActor(Target) then
                G.log:warn("yj", "BTDecorator_IsTargetInTrap unexcept result %s Target.%s", tostring(TrapActor.Tags), Target:GetDisplayName())
                return true
            end
        end
    end

    return false
end


return BTDecorator_IsTargetInTrap
