require "UnLua"
local utils = require("common.utils")

local G = require("G")

local check_table = require("common.data.state_conflict_data")


local NotifyState_FuYouPao_FanTan = Class()


function NotifyState_FuYouPao_FanTan:Received_NotifyBegin(MeshComp, Animation, TotalDuration, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner.BurstPointComponent then
        Owner.BurstPointComponent:ClearBurstPoint()
        Owner.BurstPointComponent:ClearBurstPointsNum_FanTan()
    end

    return true
end

function NotifyState_FuYouPao_FanTan:Received_NotifyTick(MeshComp, Animation, DeltaTime, EventReference)
    local Owner = MeshComp:GetOwner()
    if Owner:IsClient() then
        if Owner.BurstPointComponent:GetBurstPointsNum_FanTan() > 0 then
            local Target = Owner.BurstPointComponent:GetBurstPoint_FanTan()
            self:ReboundParticle(MeshComp, Target)
            Owner.BurstPointComponent:SubBurstPoints_FanTan()
    	end
    end

	return true
end

function NotifyState_FuYouPao_FanTan:Received_NotifyEnd(MeshComp, Animation, EventReference)
    return true
end

function NotifyState_FuYouPao_FanTan:ReboundParticle(MeshComp, Target)
    local Owner = MeshComp:GetOwner()
    local NiagaraComponent = Owner.NiagaraSlotComponent:GetNextValidNiagaraComponent()

    NiagaraComponent:SetAsset(self.NiagaraAsset)
    NiagaraComponent:SetAutoAttachmentParameters(Owner.Mesh, self.ParentSocket, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    NiagaraComponent:SetVariableObject("Data", Owner)
    NiagaraComponent:ReinitializeSystem()
    NiagaraComponent:K2_SetRelativeLocationAndRotation(self.LocationOffset, self.RotationOffset, false, UE.FHitResult(), true)

    local TargetLocation = self:GetRandomBoneLocation(Target, self.TargetBoneNames)
    NiagaraComponent:SetNiagaraVariableVec3("ZiDan_Position", TargetLocation)

    -- G.log:debug("yj", "NotifyState_FuYouPao_FanTan:ReboundParticle Owner.%s IsClient.%s Target.%s %s.%s", Owner:GetDisplayName(), Owner:IsClient(), Target:GetDisplayName(), NiagaraComponent, TargetLocation)

    Target.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_WorldDynamic, UE.ECollisionResponse.ECR_Block)
    self.Target = Target
end

function NotifyState_FuYouPao_FanTan:GetRandomBoneLocation(Actor, BoneNames)
    local BoneName = BoneNames:Get(math.random(1, BoneNames:Length()))
    local Location = Actor:GetBoneLocation(BoneName)

    -- G.log:debug("yj", "NotifyState_NiagaraEffectWithDamage:GetRandomBoneLocation Name.%s Bone.%s Location.%s", Actor:GetDisplayName(), BoneName, Location)
    return Location
end

return NotifyState_FuYouPao_FanTan
