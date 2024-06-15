require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")

local Stage_BeforeHit = 0
local Stage_InHit = 1
local Stage_Fantan = 2

local NotifyState_NiagaraEffectWithDamage = Class()

function NotifyState_NiagaraEffectWithDamage:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    Owner:SendMessage("OnFuYouPaoBegin")

    if not Owner:IsClient() then
	    return true
	end

	self.NiagaraComponent = Owner.NiagaraSlotComponent:GetNextValidNiagaraComponent()

    self.NiagaraComponent:SetAsset(self.NiagaraAsset)
    self.NiagaraComponent:SetAutoAttachmentParameters(Owner.Mesh, self.ParentSocket, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    self.NiagaraComponent:SetVariableObject("Data", Owner)
    self.NiagaraComponent:ReinitializeSystem()
    self.NiagaraComponent:K2_SetRelativeLocationAndRotation(self.LocationOffset, self.RotationOffset, false, UE.FHitResult(), true)

    self.Stage = Stage_BeforeHit

    local TargetLocation = ai_utils.GetBattleTarget(Owner):K2_GetActorLocation() + UE.FVector(0, 0, 5000)
    self.NiagaraComponent:SetNiagaraVariableVec3("ZiDan_Position", TargetLocation)

    UE.UKismetSystemLibrary.K2_SetTimerDelegate({Owner, 
        function(...) 
            self:BeginUpdatePosition(MeshComp)
        end
    }, self.TrackDelay, false)

    self.ContinueTime = self.TrackContinue

    return true
end

function NotifyState_NiagaraEffectWithDamage:BeginUpdatePosition(MeshComp)
    self.bStartTrack = true
end

function NotifyState_NiagaraEffectWithDamage:UpdatePosition(MeshComp, DeltaTime)
    if not self.bStartTrack or self.ContinueTime < 0 then
        self.bStartTrack = false
        return
    end

    self.ContinueTime = self.ContinueTime - DeltaTime

    local Owner = MeshComp:GetOwner()
    local TargetLocation = utils.GetActorLocation_Down(ai_utils.GetBattleTarget(Owner))
    self.NiagaraComponent:SetNiagaraVariableVec3("ZiDan_Position", TargetLocation)
end

function NotifyState_NiagaraEffectWithDamage:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    if not Owner:IsClient() then
        return true
	end

    self:UpdatePosition(MeshComp, DeltaTime)

    -- self:UpdateStage(MeshComp)

    -- self:UpdateZiDanPosition(MeshComp)
    -- self:UpdateNoiseCurveScale(MeshComp)
    -- self:UpdateCollisionBetweenDelay(MeshComp)
    -- self:UpdateCollisionResponse(MeshComp)

	return true
end

-- function NotifyState_NiagaraEffectWithDamage:Received_NotifyEnd(MeshComp, Animation, EventReference)
--     -- self.NiagaraComponent:SetAsset(nil)
--     local Owner = MeshComp:GetOwner()
--     Owner.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_WorldDynamic, UE.ECollisionResponse.ECR_Ignore)
--     local Owner = MeshComp:GetOwner()
--     return true
-- end

-- function NotifyState_NiagaraEffectWithDamage:UpdateStage(MeshComp)
--     local Owner = MeshComp:GetOwner()
--     if not Owner.BurstPointComponent:IsBurstOnTarget() and not Owner.AIComp.bBeWithStand then
--         self.Stage = Stage_BeforeHit
--     elseif Owner.BurstPointComponent:IsBurstOnTarget() and not Owner.AIComp.bBeWithStand then
--         self.Stage = Stage_InHit
--     elseif Owner.AIComp.bBeWithStand then
--         self.Stage = Stage_Fantan
--     end
--     -- G.log:debug("yj", "NotifyState_NiagaraEffectWithDamage:UpdateStage %s IsBurstOnTarget.%s bBeWithStand.%s", self.Stage, Owner.BurstPointComponent:IsBurstOnTarget(), Owner.AIComp.bBeWithStand)
-- end

-- function NotifyState_NiagaraEffectWithDamage:UpdateZiDanPosition(MeshComp)
--     local Owner = MeshComp:GetOwner()
--     local TargetLocation = self:MakeTargetLocation(MeshComp)
--     self.NiagaraComponent:SetNiagaraVariableVec3("ZiDan_Position", TargetLocation)
-- end

-- function NotifyState_NiagaraEffectWithDamage:MakeTargetLocation(MeshComp)
--     local TargetLocation = UE.FVector(0, 0, 0)
--     local Owner = MeshComp:GetOwner()
--     if self.Stage == Stage_BeforeHit or self.Stage == Stage_InHit then
--         TargetLocation = self:GetRandomBoneLocation(Owner.TargetActor, self.TargetBoneNames)
--     elseif self.Stage == Stage_Fantan then
--         TargetLocation = Owner:GetBoneLocation(self.SelfBoneName)
--     end
--     -- G.log:debug("yj", "NotifyState_NiagaraEffectWithDamage:MakeTargetLocation Stage.%s TargetLocation.%s %s", self.Stage, TargetLocation, Owner.TargetActor:GetLocalRole())

--     return TargetLocation
-- end

-- function NotifyState_NiagaraEffectWithDamage:UpdateNoiseCurveScale(MeshComp)
--     -- G.log:debug("yj", "UpdateNoiseCurveScale %s", self.Stage)
--     if self.Stage == Stage_BeforeHit or self.Stage == Stage_Fantan then
--         self.NiagaraComponent:SetNiagaraVariableFloat("NoiseCurveScale", 1.0)
--     else
--         self.NiagaraComponent:SetNiagaraVariableFloat("NoiseCurveScale", 0.0)
--     end
-- end

-- function NotifyState_NiagaraEffectWithDamage:UpdateCollisionBetweenDelay(MeshComp)
--     local Owner = MeshComp:GetOwner()

--     if self.Stage == Stage_BeforeHit then
--         self.NiagaraComponent:SetNiagaraVariableFloat("CollisionBetweenDelay", 0.1)
--     elseif self.Stage == Stage_InHit then
--         self.NiagaraComponent:SetNiagaraVariableFloat("CollisionBetweenDelay", 1.0)
--     elseif self.Stage == Stage_Fantan then
--         self.NiagaraComponent:SetNiagaraVariableFloat("CollisionBetweenDelay", 0.3)
--     end
-- end

-- function NotifyState_NiagaraEffectWithDamage:UpdateCollisionResponse(MeshComp)
--     local Owner = MeshComp:GetOwner()
--     -- G.log:debug("yj", "NotifyState_NiagaraEffectWithDamage:UpdateCollisionResponse %s", self.Stage)
--     if self.Stage == Stage_BeforeHit then
--         Owner.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_WorldDynamic, UE.ECollisionResponse.ECR_Ignore)
--     elseif self.Stage == Stage_Fantan then
--         Owner.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_WorldDynamic, UE.ECollisionResponse.ECR_Block)
--     end
-- end

-- function NotifyState_NiagaraEffectWithDamage:GetRandomBoneLocation(Actor, BoneNames)
--     local BoneName = BoneNames:Get(math.random(1, BoneNames:Length()))
--     local Location = Actor:GetBoneLocation(BoneName)

--     -- G.log:debug("yj", "NotifyState_NiagaraEffectWithDamage:GetRandomBoneLocation Name.%s Bone.%s Location.%s", Actor:GetDisplayName(), BoneName, Location)
--     return Location
-- end

return NotifyState_NiagaraEffectWithDamage
