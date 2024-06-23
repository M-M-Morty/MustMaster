local G = require("G")
local InteractionComponent = require("actors.common.components.interaction_component")
local Component = require("common.component")

local InteractionComponentCharacter = Component(InteractionComponent)
local decorator = InteractionComponentCharacter.decorator

function InteractionComponentCharacter:Initialize(...)
    Super(InteractionComponentCharacter).Initialize(self, ...)
end

function InteractionComponentCharacter:ReceiveBeginPlay()
    Super(InteractionComponentCharacter).ReceiveBeginPlay(self)
end

function InteractionComponentCharacter:OnAbsorb(Instigator, Duration, TargetLocation, TargetSocketName, bDynamicFollow)
    Super(InteractionComponentCharacter).OnAbsorb(self, Instigator, Duration, TargetLocation, TargetSocketName, bDynamicFollow)

    self.bHitFlyLand = false
    self:SetCaptureThrowState(true)

    if self.actor:IsServer() then
        self.ZGHandle = self.actor.ZeroGravityComponent:EnterZeroGravity(-1, false)
    end
    self.actor:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)

    local Forward = Instigator:K2_GetActorLocation() - self.actor:K2_GetActorLocation()
    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)
    Rotation.Pitch, Rotation.Roll = 0, 0
    self.actor:K2_SetActorRotation(Rotation, true)

    self:PlayMontageWithCallback(self.actor.Mesh, self.OnAbsorbMontage, 1.0)
end

function InteractionComponentCharacter:OnAbsorbCancel()
    Super(InteractionComponentCharacter).OnAbsorbCancel(self)

    self.actor:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
end

function InteractionComponentCharacter:SetCaptureThrowState(bCaptureThrow)
    if self.bStateSet == bCaptureThrow then
        return
    end

    self.bStateSet = bCaptureThrow
    if self.bStateSet then
        if self.actor.BuffComponent then
            self.InKnockHandle = self.actor.BuffComponent:AddInKnockHitFlyBuff()    
        end
        self:SendMessage("BeginHitFly")
        self:SendMessage("CancelAllAbilities")
        self.actor:StopAnimMontage()
    else   
        if self.InKnockHandle and self.actor.BuffComponent then
            self.actor.BuffComponent:RemoveInKnockHitFlyBuff(self.InKnockHandle)
        end
    end
end

decorator.message_receiver()
function InteractionComponentCharacter:OnHitFlyLand()
    if not self.bStateSet then
        return
    end

    if self.bHitFlyLand then
        return
    end
    self.bHitFlyLand = true

    if self.OnThrowEndMontage then
        self:SendMessage("EndHitFly")
        self:PlayMontageWithCallback(self.actor.Mesh, self.OnThrowEndMontage, 1.0, self.OnThrowEndMontageInterrupted, self.OnThrowEndMontageCompleted, nil)
    else
        self:SetCaptureThrowState(false)
    end
end

function InteractionComponentCharacter:OnCapture(Instigator)
    Super(InteractionComponentCharacter).OnCapture(self, Instigator)
end

function InteractionComponentCharacter:OnThrow(Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)
    -- TODO Fix throw not on ground, should move to bt?
    Super(InteractionComponentCharacter).OnThrow(self, Instigator, TargetLocation, StartLocation, ThrowMoveSpeed, EThrowType, ImpulseMag, ThrowRotateInfo)

    if not self.UseSplineRotation then
        local Forward = self.actor:K2_GetActorLocation() - TargetLocation
        local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)
        Rotation.Pitch, Rotation.Roll = 0, 0
        self.actor:K2_SetActorRotation(Rotation, true)
    end

    self.actor:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)

    self:PlayMontageWithCallback(self.actor.Mesh, self.OnThrowMontage, 1.0, self.OnThrowMontageInterrupted)
end

function InteractionComponentCharacter:OnThrowMontageInterrupted(name)
    self:EndThrow()
end

function InteractionComponentCharacter:EndThrow()
    if not self.actor:IsServer() then 
        return 
    end
    local bIsOnFloor = self.actor:IsOnFloor()   --服务器先计算一次结果
    self:Multicast_OnThrowEnd(bIsOnFloor)
end

function InteractionComponentCharacter:Multicast_OnHitTarget_RPC(Hit, bDestroy)
    Super(InteractionComponentCharacter).Multicast_OnHitTarget_RPC(self, Hit, bDestroy)
    if bDestroy then
        self:EndThrow()
    end
end

function InteractionComponentCharacter:OnThrowEnd(bIsOnFloor)
    if self.bThrowEnded then
        return
    end

    Super(InteractionComponentCharacter).OnThrowEnd(self)

    if self.actor:IsServer() then
        self.actor.ZeroGravityComponent:EndZeroGravity(self.ZGHandle)
    end

    -- If hit throw end and on land, play OnThrowEndMontage. Otherwise same as hit fly land process, handled in animation blueprint statemachine.
    if bIsOnFloor then  --self.actor:IsOnFloor()
        self.bHitFlyLand = true
        self:SendMessage("EndHitFly")
        self:PlayMontageWithCallback(self.actor.Mesh, self.OnThrowEndMontage, 1.0, self.OnThrowEndMontageInterrupted, self.OnThrowEndMontageCompleted, nil)
    else
        self.actor:StopAnimMontage(self.OnThrowMontage)
    end
end

function InteractionComponentCharacter:OnThrowEndMontageInterrupted()
    self:SetCaptureThrowState(false)
end

function InteractionComponentCharacter:OnThrowEndMontageCompleted()
    self:SetCaptureThrowState(false)
end

function InteractionComponentCharacter:PlayMontageWithCallback(Mesh, Montage, PlayRate, InterruptedCallback, CompletedCallback, BlendOutCallback)
    if not Montage then
        return
    end

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
end

return InteractionComponentCharacter
