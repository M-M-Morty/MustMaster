local G = require("G")
local GABeJudgedEndedBase = Class()

function GABeJudgedEndedBase:K2_ActivateAbilityFromEvent()
    self.__TAG__ = string.format("(%s, server: %s)", G.GetObjectName(self), self:K2_HasAuthority())
     G.log:debug(self.__TAG__, "K2_ActivateAbilityFromEvent")

    self.OwnerActor = self:GetAvatarActorFromActorInfo()
    self.CurBeJudgedEndedMontage = nil

    -- Play montage
    if self.DeadMontage and self.OwnerActor:IsDead() then
        self.OwnerActor:SendMessage("OnDeadWithSpecifiedAnimation", self.DeadMontage)
        self.OwnerActor:SendMessage("OnHeavyBeJudgeEnded")
        self:K2_EndAbility()
    elseif self.UndeadRecoveryMontageList:Length() > 0 then
        local Ind = self.OwnerActor.OutBalanceComponent:GetOutBalanceStepIndex()
        if Ind <= 0 or Ind > self.UndeadRecoveryMontageList:Length() then
            Ind = 1
        end

        self.CurBeJudgedEndedMontage = self.UndeadRecoveryMontageList:Get(Ind)
        self:PlayMontageWithCallback(self.OwnerActor.Mesh, self.CurBeJudgedEndedMontage, 1.0, self.OnUndeadRecoveryMontageInterrupted, self.OnUndeadRecoveryMontageCompleted)
    else
        self:K2_EndAbility()
    end
end

function GABeJudgedEndedBase:OnUndeadRecoveryMontageInterrupted(Name)
    self:K2_EndAbility(true)
end

function GABeJudgedEndedBase:OnUndeadRecoveryMontageCompleted(Name)
    self:K2_EndAbility()
end

function GABeJudgedEndedBase:K2_OnEndAbility(bWasCancelled)
    G.log:debug(self.__TAG__, "K2_OnEndAbility, bWasCancelled: %s", bWasCancelled)

    if bWasCancelled and self.CurBeJudgedEndedMontage then
        self.OwnerActor:StopAnimMontage(self.CurBeJudgedEndedMontage)
        self.CurBeJudgedEndedMontage = nil
    end

    self.OwnerActor:SendMessage("OnEndBeJudge")
end

function GABeJudgedEndedBase:PlayMontageWithCallback(Mesh, Montage, PlayRate, InterruptedCallback, CompletedCallback, BlendOutCallback)
    self.PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(Mesh, Montage, PlayRate)

    local InterruptedFunc = function(name)
        InterruptedCallback(self, name)
    end
    self.PlayMontageCallbackProxy.OnInterrupted:Add(self, InterruptedFunc)

    local CompletedFunc = function(name)
        CompletedCallback(self, name)
    end
    self.PlayMontageCallbackProxy.OnCompleted:Add(self, CompletedFunc)

    if BlendOutCallback then
        local BlendOutFunc = function(name)
            BlendOutCallback(self, name)
        end
        self.PlayMontageCallbackProxy.OnBlendOut:Add(self, BlendOutFunc)
    end
end

return GABeJudgedEndedBase
