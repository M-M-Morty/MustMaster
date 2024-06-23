require "UnLua"

local G = require("G")
local os = require("os")

local BTDecorator_IsTimeToAttack = Class()

function BTDecorator_IsTimeToAttack:PerformConditionCheckAI(Actor)

    local Controller = UE.UAIBlueprintHelperLibrary.GetAIController(Actor)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local NextAttackTime = BB:GetValueAsInt("NextAttackTime")

    local CurTime = os.time()
    -- G.log:debug("yjj", "BTDecorator_IsTimeToAttack NextAttackTime(%s) <= CurTime(%s) - %s", NextAttackTime, CurTime, NextAttackTime <= CurTime)

    if NextAttackTime <= CurTime then
	    local AttackInterval = math.random(self.MinAttackInterval, self.MaxAttackInterval)
	    local NextAttackTime = CurTime + AttackInterval
	    BB:SetValueAsInt("NextAttackTime", NextAttackTime)
	end

	if self.ImmediatelyAttack then
	    return NextAttackTime <= CurTime
	else
	    return NextAttackTime ~= 0 and NextAttackTime <= CurTime
	end
end


return BTDecorator_IsTimeToAttack
