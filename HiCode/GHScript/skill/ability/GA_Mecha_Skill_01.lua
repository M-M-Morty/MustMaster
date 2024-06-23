--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local GA_GH_CommonBase = require('CP0032305_GH.Script.skill.ability.GA_GH_CommonBase')

---@type GA_Mecha_Skill_01_C
local GA_Mecha_Skill_01 = Class(GA_GH_CommonBase)


function GA_Mecha_Skill_01:K2_ActivateAbility()
    self:K2_CommitAbility()

    local PlayTask = UE.UAbilityTask_PlayMontageAndWait.CreatePlayMontageAndWaitProxy(self, nil, self.MontageToPlay, 1.0, nil, true, 1.0, 0)
    self:RefTask(PlayTask)
    PlayTask.OnCompleted:Add(self, self.OnCompleted_Default)
    --PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
    PlayTask.OnInterrupted:Add(self, self.OnInterrupted_Default)
    PlayTask.OnCancelled:Add(self, self.OnCancelled_Default)
    PlayTask:ReadyForActivation()

    self:WaitHandleDamage()
    self:WaitHandleTurn()
end

function GA_Mecha_Skill_01:OnCompleted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_01:OnInterrupted_Default()
    self:K2_EndAbility(false)
end
function GA_Mecha_Skill_01:OnCancelled_Default()
    self:K2_EndAbility(false)
end

return GA_Mecha_Skill_01

