require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_HealthLessThan = Class()

-- 血量低于百分比
function BTDecorator_HealthLessThan:PerformConditionCheckAI(Controller, Pawn)
	local ASC = Pawn:GetAbilitySystemComponent()
	local HealthAttr = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.Health)
	local MaxHealAttr = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.MaxHealth)

	local Health = HealthAttr.CurrentValue
	local MaxHealth = MaxHealAttr.CurrentValue

	--G.log:debug("yj", "BTDecorator_HealthLessThan %s < %s = %s", Health / MaxHealth, self.LessThan, Health / MaxHealth < self.LessThan)
	return utils.FloatEqual(Health / MaxHealth, self.LessThan) or utils.FloatLittle(Health / MaxHealth, self.LessThan)
end


return BTDecorator_HealthLessThan
