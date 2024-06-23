--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
local G = require("G")
--local HiCollisionLibrary = require("common.HiCollisionLibrary")

local Actor = require("common.actor")

---@type BP_ChainLightning_C
local ChainBase = Class(Actor)
local DestroyDelaySeconds = 0.1


function ChainBase:Initialize(...)
    Super(ChainBase).Initialize(self, ...)

    self.FrameCount = 0
    self.bDestroying = false
    self.OverlapActors = {}
    self.bInited = false

    self.__TAG__ = "ChainBase"
    self.ChainTimer = nil
end


function ChainBase:Init()
    if self.bInited then
        return
    end
    self.bInited = true
    --self:InitPreAttackCollisionComponent()
end

function ChainBase:InitPreAttackCollisionComponent()
    local CollisionComp = nil
    if self.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Circle
            or self.Spec.CalcRangeType == Enum.Enum_CalcRangeType.Section then
        CollisionComp = self:InitSphereComponent()
    else
        CollisionComp = self:InitBoxComponent()
    end

    if CollisionComp then
        CollisionComp:SetGenerateOverlapEvents(true)
        CollisionComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
        CollisionComp:SetCollisionObjectType(UE.ECollisionChannel.Projectile)
        CollisionComp:SetCollisionProfileName("Chain")
        -- CollisionComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Destructible, UE.ECollisionResponse.ECR_Overlap)
        CollisionComp.OnComponentBeginOverlap:Add(self, self.OnPreAttackBeginOverlap)
        CollisionComp.OnComponentEndOverlap:Add(self, self.OnPreAttackEndOverlap)
        -- TODO replicated box extent show on client not right ?
        CollisionComp:SetIsReplicated(true)
        CollisionComp:K2_AttachToComponent(self:K2_GetRootComponent(), "", UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative)
    end

    self.PreAttackCollisionComp = CollisionComp
end

function ChainBase:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
    self.__TAG__ = string.format("Chain(%s, server: %s)", G.GetObjectName(self), self:IsServer())
    G.log:debug(self.__TAG__, "ReceiveBeginPlay")

    self:Init()

    self:SendMessage("InitCalcForHits", self.SourceActor, self,
        self.Spec, self.KnockInfo, self.GameplayEffectsHandle, self.HitSceneTargetConfig, nil, self.SelfGameplayEffectsHandle)
    self:SendMessage("RegisterHitCallback", self.HitCallback, self)

    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self)
    if TimeDilationActor and self.SourceActor then
        TimeDilationActor:AddCustomTimeDilationObject(self.SourceActor, self)
    end

    self:SendClientMessage("OnSwitchActivateState", true)

    if self:HasAuthority() then
        self:AddBuffToSourceActor()
    end
end

function ChainBase:OnCastChainEffect(EndPos)
    local StartPos = self:K2_GetActorLocation() 
    G.log:debug(self.__TAG__, "OnCastChainEffect (%f %f %f), (%f %f %f)", StartPos.X, StartPos.Y, StartPos.Z, EndPos.X, EndPos.Y, EndPos.Z)
    if not self:IsServer() then
        local NS = UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.ChainEffect, self:K2_GetActorLocation(), self:K2_GetActorRotation())
        NS:SetVariablePosition("StartPos", StartPos)
        NS:SetVariablePosition("EndPos", EndPos)
    else
        self.ChainTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnChainEnd}, self.ChainDuration, false) 
    end
end

function ChainBase:OnChainEnd()
    if self.bAutoDestroy then
        self.ChainTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.DestroySelf}, self.AutoDestoryDelay, false)
    end
end

function ChainBase:DestroySelf()
    if self.bDestroying then
        return
    end
    self.bDestroying = true
    self.ChainTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.K2_DestroyActor}, DestroyDelaySeconds, false)
end

function ChainBase:ReceiveDestroyed()
    self.Overridden.ReceiveDestroyed(self)

    G.log:debug(self.__TAG__, "Receive destroyed %s, IsServer: %s", G.GetDisplayName(self), self:IsServer())

    self:SendClientMessage("OnSwitchActivateState", false)

    local TimeDilationActor = HiBlueprintFunctionLibrary.GetTimeDilationActor(self)
    if TimeDilationActor and self.SourceActor then
        TimeDilationActor:RemoveCustomTimeDilationObject(self.SourceActor, self)
    end

    -- Show destroy effect
    if self.Spec.DestroyEffect and not self:HasAuthority() and not self:IsServer() then
        UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, self.Spec.DestroyEffect, self:K2_GetActorLocation(), self:K2_GetActorRotation())
    end

    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.ChainTimer)

    if self:HasAuthority() then
        self:RemoveBuffFromSourceActor()
    end
end

function ChainBase:AddBuffToSourceActor()
    if not self.SourceActor or not UE.UKismetSystemLibrary.IsValid(self.SourceActor) then
        return
    end

    if self.BuffTags then
        local Tags = self.BuffTags.GameplayTags
        for Ind = 1, Tags:Length() do
            self.SourceActor:SendMessage("AddBuffByTag", Tags:Get(Ind))
        end
    end
end

function ChainBase:RemoveBuffFromSourceActor()
    if not self.SourceActor or not UE.UKismetSystemLibrary.IsValid(self.SourceActor) then
        return
    end

    if self.BuffTags then
        local Tags = self.BuffTags.GameplayTags
        for Ind = 1, Tags:Length() do
            self.SourceActor:SendMessage("RemoveBuffByTag", Tags:Get(Ind))
        end
    end
end

function ChainBase:HitCallback(ChannelType, Hit)
	-- Hook
end

return ChainBase
