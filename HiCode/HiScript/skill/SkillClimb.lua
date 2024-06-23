local G = require("G")
local SkillObj = require("skill.SkillObj")

local SkillClimb = Class(SkillObj)

function SkillClimb:ctor(Owner, SkillID)
    Super(SkillClimb).ctor(self, Owner, SkillID)

    G.log:debug("santi", "Create SkillClimb skillID: %d", SkillID)
end

function SkillClimb:IsPlaneAttack()
    local AbilityCDO = self:GetAbilityCDO()
    local SkillType = AbilityCDO.SkillType
    return SkillType == Enum.Enum_SkillType.ClimbForward
            or SkillType == Enum.Enum_SkillType.ClimbForwardCharge
            or SkillType == Enum.Enum_SkillType.ClimbLeft
            or SkillType == Enum.Enum_SkillType.ClimbLeftCharge
            or SkillType == Enum.Enum_SkillType.ClimbRight
            or SkillType == Enum.Enum_SkillType.ClimbRightCharge
end

return SkillClimb
