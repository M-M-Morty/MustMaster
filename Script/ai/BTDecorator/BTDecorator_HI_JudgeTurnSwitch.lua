require "UnLua"

local G = require("G")

local BTDecorator_JudgeTurnSwitch = Class()

function BTDecorator_JudgeTurnSwitch:PerformConditionCheck(Actor)
    local ASC = Actor:GetAbilitySystemComponent()
    local ret = ASC:HasGameplayTag(UE.UHiGASLibrary.RequestGameplayTag("Ability.AI.Skill.OpenTurn"))
    -- G.log:debug("yj", "OnCalcEvent, IsServer %s", ret)
    return ret
end


return BTDecorator_JudgeTurnSwitch
