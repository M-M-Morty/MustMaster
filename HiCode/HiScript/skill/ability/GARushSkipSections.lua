--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
local GARush= require("skill.ability.GARush")
---@type GA_RushSkipSections_C
local GARushSkipSections = Class(GARush)


function GARushSkipSections:PlayBeginMontage()
    G.log:info(self.__TAG__, "GARushSkipSections:PlayBeginMontage %s", self:IsNearToTarget())
    if self.bSkipStartSection and self:IsNearToTarget() then
        self:PlayLoopMontage()
        return
    end
    Super(GARushSkipSections).PlayBeginMontage(self)
end

function GARushSkipSections:PlayLoopMontage()
    G.log:info(self.__TAG__, "GARushSkipSections:PlayLoopMontage %s", self:IsNearToTarget())
    if self.bSkipLoopSection and self:IsNearToTarget() then
        self:PlayEndMontage()
        return
    end
    Super(GARushSkipSections).PlayLoopMontage(self)
end

function GARushSkipSections:IsNearToTarget()
    -- if source near to target, will skip loop section
    local UserData = self:GetCurrentUserData()
    local TargetActor = UserData.SkillTarget
    local TargetComponent = UserData.SkillTargetComponent
    local _, CurTargetLocation = utils.GetTargetNearestDistance(self.OwnerActor:K2_GetActorLocation(), TargetActor, TargetComponent)
    if not CurTargetLocation then
        return false
    end
    local Distance = math.max(self.RushInfo.RushDisToTarget, self.RushInfo.RushTargetOffset:Size())
    if UE.UKismetMathLibrary.Vector_Distance(CurTargetLocation, self.OwnerActor:K2_GetActorLocation()) < Distance then
        return true
    end
    return false
end

return GARushSkipSections
