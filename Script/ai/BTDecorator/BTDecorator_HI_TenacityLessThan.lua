require "UnLua"

local G = require("G")
local utils = require("common.utils")

local BTDecorator_TenacityLessThan = Class()

-- 血量低于百分比
function BTDecorator_TenacityLessThan:PerformConditionCheckAI(Controller, Pawn)
	local ASC = Pawn:GetAbilitySystemComponent()
	local TenacityAttr = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.Tenacity)
	local MaxHealAttr = SkillUtils.GetAttribute(ASC, SkillUtils.AttrNames.MaxTenacity)

	local Tenacity = TenacityAttr.CurrentValue
	local MaxTenacity = MaxHealAttr.CurrentValue

	-- G.log:error("yj", "BTDecorator_TenacityLessThan Tenacity.%s, MaxTenacity.%s", Tenacity, MaxTenacity)
	-- G.log:error("yj", "BTDecorator_TenacityLessThan %s < %s = %s", Tenacity / MaxTenacity, self.LessThan, Tenacity / MaxTenacity < self.LessThan)
	return utils.FloatEqual(Tenacity / MaxTenacity, self.LessThan) or utils.FloatLittle(Tenacity / MaxTenacity, self.LessThan)
end


return BTDecorator_TenacityLessThan
