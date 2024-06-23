local G = require("G")
local GAPlayerBase = require("skill.ability.GAPlayerBase")

local GAHugThrow = Class(GAPlayerBase)

GAHugThrow.__replicates = {
    bTargetAttached = 0,
    Target = 0,
}

function GAHugThrow:K2_PostTransfer()
    Super(GAHugThrow).K2_PostTransfer(self)
end

function GAHugThrow:K2_CommitAbility()
    if not Super(GAHugThrow).K2_CommitAbility(self) then
        return false
    end

    self.Target = self:GetSkillTarget()
    self.bTargetAttached = false

    -- Filter target if can't be hug throw, but still activate ability.
    if not self.Target or not self.Target.HitComponent or not self.Target.HitComponent.bCanBeHugThrow then
        self.Target = nil
    end

    return true
end

function GAHugThrow:HandleActivateAbility()
    if self.Target then
        self:OnTargetAttach()
    end

    Super(GAHugThrow).HandleActivateAbility(self)
end

function GAHugThrow:OnTargetAttach()
    local SocketTransform = self.OwnerActor.Mesh:GetSocketTransform(self.AttachSocketName)
    local TargetTransform = UE.UKismetMathLibrary.ComposeTransforms(UE.FTransform(self.AttachRotationOffset:ToQuat(), self.AttachLocationOffset), SocketTransform)

    -- Set some settings.
    self.Target:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)
    self.TargetGravityScale = self.Target.CharacterMovement.GravityScale
    self.Target.CharacterMovement.GravityScale = 0
    self.Target:SetReplicateMovement(false)
    self.Target.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
    self.Target:K2_SetActorLocationAndRotation(TargetTransform.Translation, UE.UKismetMathLibrary.Quat_Rotator(TargetTransform.Rotation), false, nil, true)

    -- Attach target to owner.
    self.bTargetAttached = true
    self.Target.CapsuleComponent:K2_AttachToComponent(self.OwnerActor.Mesh, self.AttachSocketName, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld)

    self.Target:SendMessage("OnBeginBeHugThrow")
end

function GAHugThrow:OnCalcEvent(Payload)
    if not self.Target then
        return
    end

    G.log:debug(self.__TAG__, "OnCalcEvent.")
    local EventTag = Payload.EventTag
    if UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(EventTag, self.ThrowTag) then
        self:OnTargetDetach()

        if self:IsServer()  then
            -- Apply knock to target.
            local KnockInfo = Payload.OptionalObject
            self:SendHitToActor(self.Target, nil, KnockInfo)
        end
        return
    end

    Super(GAHugThrow).OnCalcEvent(self, Payload)
end
UE.DistributedDSLua.RegisterFunction("OnCalcEvent", GAHugThrow.OnCalcEvent)

function GAHugThrow:OnTargetDetach()
    local CorrectRot = UE.FRotator(0, self.Target:K2_GetActorRotation().Yaw, 0)
    self.Target:K2_SetActorRotation(CorrectRot, true)
    -- Detach target from owner.
    self.bTargetAttached = false
    self.Target.CapsuleComponent:K2_DetachFromComponent(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)

    -- Recover some settings.
    self.Target:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
    self.Target:SetReplicateMovement(true)
    self.Target.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Falling)
    self.Target.CharacterMovement.GravityScale = self.TargetGravityScale

    self.Target:SendMessage("OnEndBeHugThrow")
end

function GAHugThrow:HandleEndAbility(bWasCancelled)
    if self.bTargetAttached then
        self:OnTargetDetach()
    end

    Super(GAHugThrow).HandleEndAbility(self, bWasCancelled)
end

UE.DistributedDSLua.RegisterCustomClass("GAHugThrow", GAHugThrow, GAPlayerBase)

return GAHugThrow
