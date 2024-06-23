local G = require("G")
local GAKnockBase = require("skill.knock.GAKnockBase")
local GAKnockFall = Class(GAKnockBase)

function GAKnockFall:ActivateAbilityFromEvent()
    Super(GAKnockFall).ActivateAbilityFromEvent(self)
end

function GAKnockFall:OnKnock(KnockParams)
    Super(GAKnockFall).OnKnock(self, KnockParams)

    self.InKnockHandle = self.OwnerActor.BuffComponent:AddInKnockHitBuff()
    local NegZAxis = UE.FVector(0, 0, -1)
    self.MoveParams.MoveDir = NegZAxis

    if KnockParams.Instigator then
        self.OwnerActor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(KnockParams.Instigator, true)

        local KnockZAxisAngle = self.KnockParams.KnockInfo.KnockZAxisAngle
        if KnockZAxisAngle ~= 0 then
            self.MoveParams.MoveDir = UE.UKismetMathLibrary.RotateAngleAxis(NegZAxis, KnockZAxisAngle, UE.UKismetMathLibrary.NegateVector(KnockParams.Instigator:K2_GetActorRotation():GetRightVector()))
        end
    end

    self.OwnerActor.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    local PlayTask = UE.UHiAbilityTask_MoveTillBlocked.CreateMoveTillBlockedTask(self, "", nil, self.MoveParams)
    PlayTask.OnCompleted:Add(self, self.OnCompleted)
    PlayTask:ReadyForActivation()
    self:AddTaskRefer(PlayTask)
end

function GAKnockFall:OnCompleted()
    G.log:debug(self.__TAG__, "OnCompleted.")
    if self.MontageToPlay then
        self.OwnerActor:StopAnimMontage(self.MontageToPlay)
    end

    if self.EndMontage then
        self:PlayMontageWithCallback(self.OwnerActor.Mesh, self.EndMontage, 1.0, self.OnEndMontageInterrupted, self.OnEndMontageCompleted)
    else
        self:K2_EndAbilityLocally()
    end
end

function GAKnockFall:OnKnockMontageEnded(MontageName)
    -- Override.
end

function GAKnockFall:OnEndMontageInterrupted(MontageName)
    self:K2_EndAbilityLocally()
end

function GAKnockFall:OnEndMontageCompleted(MontageName)
    self:K2_EndAbilityLocally()
end

function GAKnockFall:K2_OnEndAbility(bWasCancelled)
    self.OwnerActor.BuffComponent:RemoveInKnockHitBuff(self.InKnockHandle)
    if self.KnockParams.Instigator then
        self.OwnerActor.CharacterMovement.UpdatedComponent:IgnoreActorWhenMoving(self.KnockParams.Instigator, false)
    end

    Super(GAKnockFall).K2_OnEndAbility(self, bWasCancelled)
end

return GAKnockFall
