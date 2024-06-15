--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
---@type AN_CastAssistSkill_C
local AN_CastAssistSkill = Class()

function AN_CastAssistSkill:Received_Notify(MeshComp, Animation, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner or Owner:IsServer() or not GameAPI.IsPlayer(Owner) then return false end
    local SkillComponent = Owner.SkillComponent
    if SkillComponent then
        G.log:info("yb", "[assist skill]cast assist skill %s", MeshComp:GetOwner():IsServer())
        SkillComponent:AssistSkill()
    end
    return true
end

return AN_CastAssistSkill
