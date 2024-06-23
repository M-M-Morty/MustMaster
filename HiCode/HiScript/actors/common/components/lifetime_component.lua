require "UnLua"

local G = require("G")
local MsgCode = require("common.consts").MsgCode

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local LifetimeComponent = Component(ComponentBase)
local decorator = LifetimeComponent.decorator

function LifetimeComponent:Start()
    Super(LifetimeComponent).Start(self)
end

function LifetimeComponent:ReceiveBeginPlay()
    Super(LifetimeComponent).ReceiveBeginPlay(self)

    self.__TAG__ = string.format("LifetimeComponent(%s, server: %s)", G.GetObjectName(self.actor), self.actor:IsServer())
end

decorator.message_receiver()
function LifetimeComponent:OnHealthChanged(NewValue, OldValue, Attribute, Spec)
    if self.actor:IsServer() then
        if NewValue <= 0 then
            G.log:debug(self.__TAG__, "TryDead")
            local SourceActor, DeadReason = self:GetDeadReasonAndSourceActor(Spec)
            self:TryDead(SourceActor, DeadReason)
        else
            G.log:debug(self.__TAG__, "Relive")
            self:Relive()
        end
    end
end

---根据 GameplayAbilitySpec 判断死亡来源.
function LifetimeComponent:GetDeadReasonAndSourceActor(Spec)
    -- local SourceAbility = UE.UHiGASLibrary.GetAbilityCDO(Spec)
    local _ = UE.UHiGASLibrary.IsDefendFrontDamage(self.actor, self.actor)
    local SourceAbility = UE.UHiGASLibrary.GetAbilityInstanceNotReplicated(Spec)
    if SourceAbility then
        -- 战斗中死亡
        return SourceAbility:GetAvatarActorFromActorInfo(), Enum.BPE_DeadReason.Battle
    end

    return nil, Enum.BPE_DeadReason.Unknown
end

function LifetimeComponent:Relive()
    self:Multicast_OnRelive()
end

function LifetimeComponent:Multicast_OnRelive_RPC()
    self:OnRelive()
end

function LifetimeComponent:OnRelive()
    self.bDead = false
    self:SendMessage(MsgCode.OnRelive)
end

decorator.message_receiver()
function LifetimeComponent:KillSelf()
    SkillUtils.SetAttributeBaseValue(self.actor:GetAbilitySystemComponent(), SkillUtils.AttrNames.Health, 0)
end

function LifetimeComponent:TryDead(SourceActor, DeadReason)
    G.log:debug(self.__TAG__, "TryDead SourceAbility: %s DeadReason: %s", G.GetDisplayName(SourceAbility), tostring(DeadReason))
    -- 标记 actor 为死亡状态
    self.actor:SetDead(true)

    -- 死亡后续流程在一些条件下可能延迟进行。
    if not self:CheckCanDeadNow() then
        return
    end

    self:Multicast_OnDead(SourceActor, DeadReason)
end

function LifetimeComponent:CheckCanDeadNow()
    -- 处决状态下死亡，只有当处决结束时才能继续。
    if self.actor.SkillComponent.bJudgeState then
        G.log:debug(self.__TAG__, "CheckCanDeadNow in judge state")
        return false
    end

    return true
end

function LifetimeComponent:Multicast_OnDead_RPC(SourceActor, DeadReason)
    self:OnDead(SourceActor, DeadReason)
end

function LifetimeComponent:OnDead(SourceActor, DeadReason)
    G.log:debug(self.__TAG__, "OnDead")
    if self.actor:IsPlayer() then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self.actor:GetWorld(), 0)
        PlayerController:OnClientRoleDead(self.actor.CharType)
    end

    self:SendMessage("OnDead", SourceActor, DeadReason)
end

decorator.message_receiver()
function LifetimeComponent:OnEndBeJudge()
    if not self.actor:IsServer() then
        return
    end

    if self.bDead then
        self:Multicast_OnDead()
    end
end

decorator.message_receiver()
function LifetimeComponent:OnEndJudge()
    if self.bDead then
        self:Dead()
    end
end

function LifetimeComponent:DestroySelf()
    G.log:debug(self.__TAG__, "DestroySelf")
    self.actor:K2_DestroyActor()    
end

-- 无敌金身
decorator.message_receiver()
function LifetimeComponent:GoldenBody(open)
    self.IsGoldenBody = open
end

return LifetimeComponent
