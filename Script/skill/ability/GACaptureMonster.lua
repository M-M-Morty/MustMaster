local G = require("G")
local GACapture = require("skill.ability.GACapture")
local GACaptureMonster = Class(GACapture)


function GACaptureMonster:HandleActivateAbility()
    Super(GACaptureMonster).HandleActivateAbility(self)
    self:HandleAbsorbSuccessEvent()
end

function GACaptureMonster:HandleAbsorbSuccessEvent()
    local WaitATSCalcTask = UE.UAbilityTask_WaitGameplayEvent.WaitGameplayEvent(self, self.AbsorbSuccessPrefixTag, nil, false, false)
    WaitATSCalcTask.EventReceived:Add(self, self.OnAbsorbSuccessEvent)
    WaitATSCalcTask:ReadyForActivation()
    self:AddTaskRefer(WaitATSCalcTask)
end

function GACaptureMonster:OnAbsorbSuccessEvent()
    if not self:CanCalc() then
        return
    end

    local OwnerInteractionComp = self.OwnerActor.InteractionComponent
    local CaptureTarget = OwnerInteractionComp:GetUpTargetBeSelected()
    -- local TargetSocketName = OwnerInteractionComp.CaptureBoneName
    local TargetSocketName = self.AbsorbBoneName
    local TargetLocation = self.OwnerActor:GetSocketLocation(TargetSocketName)
    local MoveTime = self.AbsorbMoveTime
    self.OwnerActor.InteractionComponent:AbsorbTargetWithProcess(CaptureTarget, MoveTime, TargetLocation, TargetSocketName, true)
end

function GACaptureMonster:OnCapture()
    -- local CaptureTarget = self.OwnerActor.InteractionComponent.TargetBeSelected
    local CaptureTarget = self.OwnerActor.InteractionComponent:GetUpTargetBeSelected()
    -- G.log:debug("yj", "GACaptureMonster:OnCaptureEvent_Monster %s", G.GetDisplayName(CaptureTarget))
    if CaptureTarget then
        self.OwnerActor.InteractionComponent:CaptureTarget(CaptureTarget)
    end
end

return GACaptureMonster
