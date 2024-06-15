require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local OutBalanceComponent = Component(ComponentBase)

local decorator = OutBalanceComponent.decorator

 function OutBalanceComponent:ReceiveBeginPlay()
     Super(OutBalanceComponent).ReceiveBeginPlay(self)

     self.OutBalanceStepIndex = -1
     self.__TAG__ = string.format("OutBalanceComponent(actor: %s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
 end

-- TODO client OnAttributeChanged, OldValue same with NewValue, not correct!
decorator.message_receiver()
function OutBalanceComponent:OnTenacityChanged(NewValue, OldValue, Attribute, Spec)
    if self.actor:IsServer() then
        G.log:debug(self.__TAG__, "OutBalanceComponent OnTenacityChanged new: %f, old: %f", NewValue, OldValue)

        self.LastEnterOBTenacity = OldValue
        self:CheckEnterOutOB(Spec)
    end
end

function OutBalanceComponent:CheckEnterOutOB(Spec)
    local CurValue = self.actor:GetTenacityCurrentValue()
    if CurValue == 0 and self.bEnableHeavyOutBalance then
        if self:EnterHeavyOB() then
            self.LastEnterOBTenacity = CurValue
            self.OutBalanceType = Enum.Enum_OutBalanceType.Heavy
            self:TryNotifySource(self.OutBalanceType, Spec)
        end
        return
    end
    for Ind = self.OutBalanceLevels:Length(), 1, -1 do
        local OBLevelItem = self.OutBalanceLevels:Get(Ind)
        local OBLevel = OBLevelItem.Level
        if self.LastEnterOBTenacity > OBLevel and CurValue <= OBLevel then
            if self:EnterLightOB(Ind) then
                self.LastEnterOBTenacity = CurValue
                self.OutBalanceType = Enum.Enum_OutBalanceType.Light
                self.OutBalanceStepIndex = Ind
                self:TryNotifySource(self.OutBalanceType, Spec)
            end
            return
        end
    end
end

function OutBalanceComponent:TryNotifySource(OutBalanceType, Spec)
    local SourceAbility = UE.UHiGASLibrary.GetAbilityInstanceNotReplicated(Spec)
    if not SourceAbility then
        return
    end

    G.log:debug(self.__TAG__, "TryNotifySource source ability: %s", tostring(G.GetObjectName(SourceAbility)))
    SourceAbility:OnTargetEnterOutBalance()
end

function OutBalanceComponent:EnterLightOB(StepIndex)
    if self.bEnteringOutBalance or self.bOutBalanceState then
        return false
    end

    G.log:debug(self.__TAG__, "EnterLightOB step: %d", StepIndex)
    -- 只改标记状态，不真正进入可处决，可处决需要等失衡动画的 notify
    self.bEnteringOutBalance = true
    self.OutBalanceType = Enum.Enum_OutBalanceType.Light
    self.OutBalanceStepIndex = StepIndex
    self:SendMessage("OnBeginningOutBalance", self.OutBalanceType)

    local LevelMontage = self.OutBalanceLevels:Get(StepIndex).Montage
    if LevelMontage then
        self:PlayMontageWithCallback(self.actor.Mesh, LevelMontage, 1.0, self.OnLightOBMontageEnded, self.OnLightOBMontageEnded)
    end

    return true
end

function OutBalanceComponent:EnterHeavyOB()
    if self.bEnteringOutBalance or self.bOutBalanceState then
        return false
    end

    G.log:debug(self.__TAG__, "OutBalanceComponent actor: %s, enter heavy Out balance.", self.actor:GetDisplayName())
    self.bEnteringOutBalance = true
    self.OutBalanceType = Enum.Enum_OutBalanceType.Heavy
    self.OutBalanceStepIndex = -1
    self:SendMessage("OnBeginningOutBalance", self.OutBalanceType)

    if self.HeavyOutBalanceMontage then
        self:PlayMontageWithCallback(self.actor.Mesh, self.HeavyOutBalanceMontage, 1.0, self.OnHeavyOBMontageEnded, self.OnHeavyOBMontageEnded)
    end

    return true
end

decorator.message_receiver()
function OutBalanceComponent:NotifyOutBalance()
    if not self.actor:IsServer() then
        return
    end

    -- 真正进入可处决状态
    self:EnterOutBalanceState(self.OutBalanceType, self.OutBalanceStepIndex)
end

function OutBalanceComponent:OnLightOBMontageEnded(Montage)
    self:EndOutBalanceState(Enum.Enum_OutBalanceType.Light)

    -- Handle during OutBalance, another balance level reached. So when finish handle current, try trigger again.
    self:CheckEnterOutOB()
end

function OutBalanceComponent:OnHeavyOBMontageEnded(Montage)
    self:EndOutBalanceState(Enum.Enum_OutBalanceType.Heavy)
    self:SendMessage("ResetTenacity")
end

function OutBalanceComponent:EnterOutBalanceState(OutBalanceType, StepIndex)
    G.log:debug(self.__TAG__, "EnterOutBalanceState")
    self:SetOutBalanceState(true)
    self:HandleOutBalanceState(true, OutBalanceType, StepIndex)
end

function OutBalanceComponent:EndOutBalanceState(OutBalanceType)
    G.log:debug(self.__TAG__, "EndOutBalanceState")
    self.bEnteringOutBalance = false
    self:SetOutBalanceState(false)
    self:HandleOutBalanceState(false, OutBalanceType)
end

function OutBalanceComponent:HandleOutBalanceState(bEnabled, OutBalanceType, StepIndex)
    self:Multicast_HandleOutBalanceState(bEnabled, OutBalanceType, StepIndex)
end

function OutBalanceComponent:Multicast_HandleOutBalanceState_RPC(bEnabled, OutBalanceType, StepIndex)
    if bEnabled then
        self.OutBalanceStepIndex = StepIndex
        G.log:debug(self.__TAG__, "OnBeginOutBalance OutBalanceType: %d, StepIndex: %d", OutBalanceType, StepIndex)
        self:SendMessage("OnBeginOutBalance", OutBalanceType)
    else
        G.log:debug(self.__TAG__, "OnEndOutBalance OutBalanceType: %d, StepIndex: %d", OutBalanceType, StepIndex)
        self:SendMessage("OnEndOutBalance", OutBalanceType)
    end
end

decorator.message_receiver()
function OutBalanceComponent:OnBeginOutBalance(OutBalanceType)
    if not self.actor:IsServer() then
        return
    end

    local ASC = self.actor:GetAbilitySystemComponent()
    if OutBalanceType == Enum.Enum_OutBalanceType.Heavy then
        if self.HeavyOutBalanceGE then
            ASC:BP_ApplyGameplayEffectToSelf(self.HeavyOutBalanceGE, 0.0, nil)
        end
    else
        if self.LightOutBalanceGE then
            ASC:BP_ApplyGameplayEffectToSelf(self.LightOutBalanceGE, 0.0, nil)
        end
    end
end

function OutBalanceComponent:SetOutBalanceState(Value)
    self.bOutBalanceState = Value
end

function OutBalanceComponent:IsInOutBalance()
    return self.bOutBalanceState
end

function OutBalanceComponent:GetOutBalanceStepIndex()
    return self.OutBalanceStepIndex
end

function OutBalanceComponent:PlayMontageWithCallback(Mesh, Montage, PlayRate, InterruptedCallback, CompletedCallback, BlendOutCallback)
    local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(Mesh, Montage, PlayRate)

    if InterruptedCallback then
        local InterruptedFunc = function(name)
            InterruptedCallback(self, name)
        end
        PlayMontageCallbackProxy.OnInterrupted:Add(self, InterruptedFunc)
    end

    if CompletedCallback then
        local CompletedFunc = function(name)
            CompletedCallback(self, name)
        end
        PlayMontageCallbackProxy.OnCompleted:Add(self, CompletedFunc)
    end

    if BlendOutCallback then
        local BlendOutFunc = function(name)
            BlendOutCallback(self, name)
        end
        PlayMontageCallbackProxy.OnBlendOut:Add(self, BlendOutFunc)
    end

    self.ObjectReferList:Add(PlayMontageCallbackProxy)

    -- Notify client to play.
    if self.actor:IsServer() then
        self:Multicast_PlayMontage(Montage)
    end
end

function OutBalanceComponent:Multicast_PlayMontage_RPC(Montage)
    if self.actor:IsServer() then
        return
    end

    self.actor:PlayAnimMontage(Montage)
end

return OutBalanceComponent
