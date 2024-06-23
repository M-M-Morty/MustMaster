

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local DurationBase = require('CP0032305_GH.Script.actors.common.TargetActor_Mecha_Duration')


---@type TargetActor_Mecha_Skill_05_C
local TargetActor_Mecha_Skill_05_C = Class(DurationBase)

function TargetActor_Mecha_Skill_05_C:ReceiveBeginPlay()
    Super(TargetActor_Mecha_Skill_05_C).ReceiveBeginPlay(self)
end
function TargetActor_Mecha_Skill_05_C:ReceiveEndPlay(EndPlayReason)
    Super(TargetActor_Mecha_Skill_05_C).ReceiveEndPlay(self, EndPlayReason)
end
function TargetActor_Mecha_Skill_05_C:ReceiveTick(DeltaSeconds)
    Super(TargetActor_Mecha_Skill_05_C).ReceiveTick(self, DeltaSeconds)

    --FunctionUtil:DrawShapeComponent(self.Collision)
end

return TargetActor_Mecha_Skill_05_C

