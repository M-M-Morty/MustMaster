local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GAAirTread = Class(GASkillBase)


function GAAirTread:K2_ActivateAbility()
    Super(GAAirTread).K2_ActivateAbility(self)

    local Owner = self:GetOwner()
    Owner:SendMessage("OnGAAirTreadActivate")
end

function GAAirTread:GetOwner()
    local OwnerActor = self:GetOwningActorFromActorInfo()
    return OwnerActor
end

return GAAirTread
