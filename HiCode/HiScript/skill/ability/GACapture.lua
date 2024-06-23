local G = require("G")
local GASkillBase = require("skill.ability.GASkillBase")
local GACapture = Class(GASkillBase)


function GACapture:HandleActivateAbility()
    Super(GACapture).HandleActivateAbility(self)

    self:HandleCaptureEvent()
end

function GACapture:HandleCaptureEvent()
    local WaitATSCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.CapturePrefixTag, nil, false, false)
    WaitATSCalcTask.EventReceived:Add(self, self.OnCaptureEvent)
    WaitATSCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitATSCalcTask)
end

function GACapture:OnCaptureEvent()
    if not self:CanCalc() then
        return
    end

    self:OnCapture()
end

function GACapture:OnCapture()
end

function GACapture:CanCalc()
    if self:K2_HasAuthority() then
        return true
    end

    return false
end

return GACapture
