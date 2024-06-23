require "UnLua"

local G = require("G")
local os = require("os")

local BTDecorator_IsCaptureUseSkill = Class()

function BTDecorator_IsCaptureUseSkill:PerformConditionCheckAI(Controller, Pawn)

	if Pawn.InteractionComponent.Capture == nil then
		-- G.log:debug("yj", "BTDecorator_IsCaptureUseSkill 1 Pawn.%s Name.%s", Pawn, Pawn:GetDisplayName())
		return false
	end

	if Pawn.LastCaptureTime == nil or Pawn.InteractionComponent.Capture.LastUseSkillTime == nil then
		-- G.log:debug("yj", "BTDecorator_IsCaptureUseSkill 2 LastCaptureTime.%s LastUseSkillTime.%s", Pawn.LastCaptureTime, Pawn.InteractionComponent.Capture.LastUseSkillTime)
		return false
	end

	if Pawn.LastCaptureTime > Pawn.InteractionComponent.Capture.LastUseSkillTime then
		-- G.log:debug("yj", "BTDecorator_IsCaptureUseSkill 3 LastCaptureTime.%s LastUseSkillTime.%s", Pawn.LastCaptureTime, Pawn.InteractionComponent.Capture.LastUseSkillTime)
		Pawn.LastCaptureTime = G.GetNowTimestampMs()
		return false
	end

	Pawn.LastCaptureTime = G.GetNowTimestampMs()

	return true
end


return BTDecorator_IsCaptureUseSkill
