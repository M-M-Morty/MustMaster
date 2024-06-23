

local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local InstantBase = require('CP0032305_GH.Script.actors.common.TargetActor_GH_Instant')

---@type TargetActor_Snail_Skill_05_C
local TargetActor_Snail_Skill_05_C = Class(InstantBase)

function TargetActor_Snail_Skill_05_C:OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    --UnLua.LogWarn('TargetActor_Snail_Skill_05_C:OnComponentBeginOverlap', UE.UKismetSystemLibrary.GetDisplayName(self:GetClass()), FunctionUtil:GetActorDesc(OtherActor))

    Super(TargetActor_Snail_Skill_05_C).OnComponentBeginOverlap(self, OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    
    local OilObjClass = FunctionUtil:IndexRes('Snail_Skill_05_Oil_C')
    if OtherActor:IsA(OilObjClass) and OtherActor.InstantBomb then
        OtherActor:InstantBomb()
    end
end

return TargetActor_Snail_Skill_05_C

