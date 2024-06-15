-- Normal attack base.

local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")

local GANormal = Class(GASkillBase)

function GANormal:HandlePlayMontage()
    if self:GetMontageToPlay() then
        local OffsetTime = self:GetStartOffsetTime()
        local BlendArgs = UE.FAlphaBlendArgs()
        BlendArgs.BlendTime = 0.0
        local PlayTask = UE.UHiAbilityTask_PlayMontage.CreatePlayMontageAndWaitProxy(self, "", self:GetMontageToPlay(), BlendArgs, 1.0, nil, true, 1.0, OffsetTime)
        PlayTask.OnCompleted:Add(self, self.OnCompleted)
        PlayTask.OnBlendOut:Add(self, self.OnBlendOut)
        PlayTask.OnInterrupted:Add(self, self.OnInterrupted)
        PlayTask.OnCancelled:Add(self, self.OnCancelled)
        PlayTask:ReadyForActivation()
        self:AddTaskRefer(PlayTask)
    end
end

function GANormal:GetMontageToPlay()
    if self.OwnerActor:IsOnFloor() then
        return self.MontageToPlay
    else
        if self.MontageInAirToPlay then
            return self.MontageInAirToPlay
        else 
            return self.MontageToPlay
        end
    end
end

return GANormal
