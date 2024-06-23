local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GAAirEmbrace = Class(GASkillBase)


function GAAirEmbrace:K2_ActivateAbility()
    Super(GAAirEmbrace).K2_ActivateAbility(self)

    local Owner = self:GetOwner()
    Owner:SendMessage("OnGAAirEmbraceActivate")
end

function GAAirEmbrace:GetOwner()
    local OwnerActor = self:GetOwningActorFromActorInfo()
    return OwnerActor
end

return GAAirEmbrace
