require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")

local DunFanPaoComponent = Component(ComponentBase)

local decorator = DunFanPaoComponent.decorator


function DunFanPaoComponent:ReceiveBeginPlay()
    Super(DunFanPaoComponent).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        return
    end

    -- 炮弹特效1 - 随炮弹立即销毁
    local SourceActor = self.actor.SourceActor
    self.NiagaraComponent = SourceActor.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    self.NiagaraComponent:SetAsset(self.NiagaraAsset)
    self.NiagaraComponent:SetAutoAttachmentParameters(self.actor.Sphere, "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    self.NiagaraComponent:ReinitializeSystem()

    -- 炮弹特效2 - 不会随炮弹立即销毁
    local NiagaraComponent2 = SourceActor.NiagaraSlotComponent:GetNextValidNiagaraComponent()
    NiagaraComponent2:SetAsset(self.NiagaraAsset_DelayDestroy)
    NiagaraComponent2:SetAutoAttachmentParameters(self.actor.Sphere, "", UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.SnapToTarget, UE.EAttachmentRule.KeepWorld)
    NiagaraComponent2:ReinitializeSystem()
end

function DunFanPaoComponent:ReceiveEndPlay()
    Super(DunFanPaoComponent).ReceiveBeginPlay(self)
    if self.actor:IsServer() then
        return
    end

    self.NiagaraComponent:SetAsset(nil)
end

decorator.message_receiver()
function DunFanPaoComponent:ReboundByExtremeWithStand(SkillTarget)
    self.actor.Spec.MoveType = Enum.Enum_MoveType.ReboundByTarget

    -- 更换受击销毁特效
    if self.ReboundDestroyEffect then
        self.actor.Spec.DestroyEffect = self.ReboundDestroyEffect
    end

    local NewRotation = self.actor:K2_GetActorRotation() - self.actor.Spec.StartRotOffset + self.actor.ReboundRotOffset
    -- G.log:debug("yj", "OldRotation.%s NewRotation.%s", self.actor:K2_GetActorRotation(), NewRotation)
    self.actor:K2_SetActorRotation(NewRotation, true)
    self:SendMessage("CreateSplineAndTimeline", self.actor:GetTransform(), true)
    self:SendMessage("UpdateSplineTargetLocation", self:GetRandomBoneLocation(SkillTarget))

    self:Multicast_ReboundByExtremeWithStand()
end

function DunFanPaoComponent:Multicast_ReboundByExtremeWithStand_RPC()
    -- 播放弹反特效
    if self.ReboundEffect and self.actor:IsClient() then
        -- G.log:debug("yj", "DunFanPaoComponent:ReboundByExtremeWithStand %s IsServer.%s", self.ReboundEffect, self.actor:IsServer())
        UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self.actor, self.ReboundEffect, self.actor:K2_GetActorLocation(), self.actor:K2_GetActorRotation())
    end
end

function DunFanPaoComponent:GetRandomBoneLocation(SkillTarget)
    local BoneName = self.ReboundBoneNames:Get(math.random(1, self.ReboundBoneNames:Length()))
    local Location = SkillTarget:GetBoneLocation(BoneName)
    -- G.log:debug("yj", "DunFanPaoComponent:GetRandomBoneLocation Name.%s Bone.%s Location.%s", SkillTarget:GetDisplayName(), BoneName, Location)
    return Location
end

return DunFanPaoComponent
