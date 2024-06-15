local AppearanceBase = require("actors.common.components.common_appearance")
local Component = require("common.component")
local G = require("G")

local check_table = require("common.data.state_conflict_data")

---@type BP_MonsterAppearance_C
local MonsterAppearance = Component(AppearanceBase)

local decorator = MonsterAppearance.decorator
local DeathDissolveFre = 0.05

function MonsterAppearance:ReceiveBeginPlay()
    Super(MonsterAppearance).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("MonsterAppearance(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())

    self:OnAnimInitialized()
    self.actor.Mesh.OnAnimInitialized:Add(self, self.OnAnimInitialized)

    self.bHitFresnel = false
    self.HitFresnelTime = 0
end

decorator.message_receiver()
function MonsterAppearance:OnReceiveTick(DeltaSeconds)
    if self.bHitFresnel then
        self.HitFresnelTime = self.HitFresnelTime + DeltaSeconds
        self:UpdateHitFresnel()
    end
end

function MonsterAppearance:OnAnimInitialized()
    self.AnimInstance = self.actor.Mesh:GetAnimInstance()
    if self.AnimInstance == nil then
        assert(false, string.format("%s AnimClass is nil", self.actor:GetDisplayName()))
        return
    end

    assert(self.DefaultDeadAnimation, string.format("%s Missing default dead animation", self.actor:GetDisplayName()))
    if self.actor.LifeTimeComponent.bDead then
        self.AnimInstance.IsDead = true
        local BlendArgs = UE.FAlphaBlendArgs()
        BlendArgs.BlendTime = 0.0
        self.AnimInstance:Montage_PlayWithBlendIn(self.DefaultDeadAnimation, BlendArgs, 1.0, UE.EMontagePlayReturnType.MontageLength, self.DefaultDeadAnimation.SequenceLength)
    end
end

decorator.message_receiver()
function MonsterAppearance:OnDead()
    if not self.AnimInstance.IsDead then
        G.log:debug(self.__TAG__, "OnDead")
        self.AnimInstance.IsDead = true

        local DeadCallback = function()
            G.log:debug(self.__TAG__, "OnDead after finish dead animation, destroy actor.")
            utils.DoDelay(self.actor, 0.01, function ( ... )
                self.actor:K2_DestroyActor()
            end)
        end

        if self.DefaultDeadAnimation then
            local PlayMontageCallbackProxy = UE.UPlayMontageCallbackProxy.CreateProxyObjectForPlayMontage(self.actor.Mesh, self.DefaultDeadAnimation, 1.0)
            PlayMontageCallbackProxy.OnInterrupted:Add(self.actor, DeadCallback)
            PlayMontageCallbackProxy.OnCompleted:Add(self.actor, DeadCallback)
        else
            DeadCallback()
        end
    end
end

decorator.message_receiver()
function MonsterAppearance:OnDeadWithSpecifiedAnimation(SpecifiedDeadAnimation)
    if self.actor.LifeTimeComponent.bDead and SpecifiedDeadAnimation and (not self.AnimInstance.IsDead) then
        self.AnimInstance.IsDead = true
        self.AnimInstance:Montage_Play(SpecifiedDeadAnimation)
    end
end

decorator.message_receiver()
function MonsterAppearance:OnHit(Instigator, Causer, Hit)
    if self.bEnableHitLight then
        self.bHitFresnel = true
        self.HitFresnelTime = 0
        UE.UKismetMaterialLibrary.SetVectorParameterValue(self.actor:GetWorld(), self.HitParamCollection, "Hit_Point", UE.FLinearColor(Hit.ImpactPoint.X, Hit.ImpactPoint.Y, Hit.ImpactPoint.Z))
        self:UpdateHitFresnel()
    end
end

function MonsterAppearance:UpdateHitFresnel()
    local CurValue = self.HitLifeTimeCurve:GetFloatValue(self.HitFresnelTime)
    if CurValue <= 0 then
        self.bHitFresnel = false
    end

    UE.UKismetMaterialLibrary.SetScalarParameterValue(self.actor:GetWorld(), self.HitParamCollection, "Hit_LifeTime", CurValue)
end

--死亡消散效果Begin(客户端) 通过帧事件触发
function MonsterAppearance:OnDeathDissolveBegin()
    if self.DeathDissolveTimer then return end
    self.DeathDissolveTimer = 0
    self.DeathDissolveTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self,self.OnDeathDissolveUpdateFunc},DeathDissolveFre,true)
    self:OnDeathDissolveUpdateFunc()
end

--死亡消散效果Update(客户端)
function MonsterAppearance:OnDeathDissolveUpdateFunc()
    self.DeathDissolveTimer = math.min(self.DeathDissolveTimer + DeathDissolveFre,self.DeathDissolveTime)
    local Value = self.DeathDissolveTimer/self.DeathDissolveTime
    local Mesh = self.actor.Mesh
    for i = 0, self.DeathDissolveMaterial_Arr:Length() - 1 do
        local M = self.DeathDissolveMaterial_Arr:Get(i + 1) --从1开始
        UE.UMeshComponent.SetMaterial(Mesh,i,M) --从0开始
        local MI = UE.UPrimitiveComponent.CreateDynamicMaterialInstance(Mesh,i,M,"None"..tostring(i))    --从0开始
        UE.UMaterialInstanceDynamic.SetScalarParameterValue(MI,"Dissolve",Value)
    end
    if math.abs(self.DeathDissolveTimer - self.DeathDissolveTime) <= 0.0001 then 
        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.DeathDissolveTimerHandle)
    end
end

return MonsterAppearance
