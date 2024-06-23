local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")
local SkillUtils = require("common.skill_utils")

local BattleStateComponent = Component(ComponentBase)

local decorator = BattleStateComponent.decorator

decorator.message_receiver()
function BattleStateComponent:AddBattleTarget(Target)
    if not Target or not Target:IsValid() then
        return
    end

    if self.Targets:Contains(Target) then
        return
    end

    -- G.log:debug("yj", "BattleStateComponent:AddBattleTarget MonsterType.%s, Name.%s", Target.MonsterType, Target:GetDisplayName())

    self.Targets:Add(Target)

    local CurTarget_Old = self.CurTarget
    self.CurTarget = self:GetAppropriateBattleTarget()

    if CurTarget_Old ~= self.CurTarget then
        self:SendMessage("OnEnterBattle", CurTarget_Old, self.CurTarget)
    end

    if not UE.UKismetSystemLibrary.K2_IsValidTimerHandle(self.CheckTimerHandler) then
        self.CheckTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.BattleTargetsCheckTimer}, 3, true)
    end
end

decorator.message_receiver()
function BattleStateComponent:OnReceiveTick(DeltaSeconds)
    if self.DrawDebug and self.CurTarget and self.actor:IsClient() then
        UE.UKismetSystemLibrary.DrawDebugLine(self.actor, self.actor:K2_GetActorLocation(), self.CurTarget:K2_GetActorLocation(), UE.FLinearColor(0, 0, 1), 0.1)
    end
end

decorator.message_receiver()
function BattleStateComponent:SubBattleTarget(Target)
    if not Target or not Target:IsValid() then
        return
    end

    if not self.Targets:Contains(Target) then
        return
    end

    -- G.log:debug("yj", "BattleStateComponent:SubBattleTarget MonsterType.%s, Name.%s", Target.MonsterType, Target:GetDisplayName())

    self.Targets:Remove(Target)
    
    local CurTarget_Old = self.CurTarget
    if self.CurTarget == Target then
        self.CurTarget = self:GetAppropriateBattleTarget()
    end

    if self.CurTarget == nil then
        self:SendMessage("OnLeaveBattle", CurTarget_Old)
    elseif CurTarget_Old ~= self.CurTarget then
        self:SendMessage("OnEnterBattle", CurTarget_Old, self.CurTarget)
    end
end

decorator.message_receiver()
function BattleStateComponent:OnBattleTargetDead(Target)
    if not Target then
        return
    end

    ai_utils.BreakBattleTargetPair(Target)

    if Target.MonsterType == Enum.Enum_MonsterType.Elite then
        self:SendMessage("OnEliteTargetDead", Target)
    end
end

function BattleStateComponent:BattleTargetsCheckTimer()
    -- 保底定时检查
    local CurTarget_Old = self.CurTarget
    self.CurTarget = self:GetAppropriateBattleTarget()
    if self.CurTarget == nil then
        if self.InBattle == true then
            self:SendMessage("OnLeaveBattle", CurTarget_Old)
        end

        UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.CheckTimerHandler)
        self.CheckTimerHandler = nil
    end
end

function BattleStateComponent:GetAppropriateBattleTarget()
    local AppropriateTarget = nil
    local MaxMT = -1
    local InvalidTarget = {}

    local Array = self.Targets:ToArray()
    for i = 1, Array:Length() do
        local Target = Array:Get(i)
        if not Target or not Target:IsValid() then
            table.insert(InvalidTarget, Target)
        elseif Target.MonsterType > MaxMT then
            MaxMT = Target.MonsterType
            AppropriateTarget = Target
        end
    end

    self.Targets:Remove(nil)
    
    for idx=1, #InvalidTarget do
        self.Targets:Remove(InvalidTarget[idx])
    end

    return AppropriateTarget
end

function BattleStateComponent:GetBattles()
    self:GetAppropriateBattleTarget()
    return self.Targets
end

decorator.message_receiver()
function BattleStateComponent:SyncLockTarget(Target)
    if not Target then
        return
    end

    local CurTarget_Old = self.CurTarget
    self.CurTarget = Target
    if CurTarget_Old ~= self.CurTarget then
        self:SendMessage("OnEnterBattle", CurTarget_Old, self.CurTarget)
    end
end

decorator.message_receiver()
function BattleStateComponent:OnEnterBattle(OldTarget, NewTarget)
    if not NewTarget or not NewTarget:IsValid() or NewTarget:IsDead() then
        return
    end

    if OldTarget then
        G.log:debug("yj", "BattleStateComponent:OnEnterBattle OldTarget.%s-%s NewTarget.%s-%s", OldTarget.MonsterType, OldTarget:GetDisplayName(), NewTarget.MonsterType, NewTarget:GetDisplayName())
    else
        G.log:debug("yj", "BattleStateComponent:OnEnterBattle OldTarget.nil NewTarget.%s-%s", NewTarget.MonsterType, NewTarget:GetDisplayName())
    end

    self.InBattle = true
    self.IsLeavingBattle = false

    if OldTarget and OldTarget.MonsterType == Enum.Enum_MonsterType.Boss then
        self:OnRep_SetBossBattleState(OldTarget, false)
        self:OnRep_SetBossBattleState_RPC(OldTarget, false)
    end

    if NewTarget.MonsterType == Enum.Enum_MonsterType.Boss then
        self:OnRep_SetBossBattleState(NewTarget, true)
        self:OnRep_SetBossBattleState_RPC(NewTarget, true)
    end

    self:SendMessage("SetInBattleState", true)

    self:Client_OnEnterBattle(OldTarget, NewTarget)
end

decorator.message_receiver()
function BattleStateComponent:OnLeaveBattle(OldTarget)
    G.log:debug("yj", "BattleStateComponent:OnLeaveBattle OldTarget.%s", G.GetDisplayName(OldTarget))
    self.IsLeavingBattle = true

    utils.DoDelay(self.actor, self.LeaveBattleDelay, function( ... )
        if not self.IsLeavingBattle then
            return
        end

        G.log:debug("yj", "BattleStateComponent:OnLeaveBattle real OldTarget.%s", G.GetDisplayName(OldTarget))
        self.InBattle = false
        self:SendMessage("SetInBattleState", false)

        self:Client_OnLeaveBattle(OldTarget)
    end)

    if OldTarget and OldTarget.MonsterType == Enum.Enum_MonsterType.Boss then
        self:OnRep_SetBossBattleState(OldTarget, false)
        self:OnRep_SetBossBattleState_RPC(OldTarget, false)
    end
end

decorator.engine_callback()
function BattleStateComponent:OnRep_SetBossBattleState_RPC(Target, bIsInBattle)
    if not Target:IsValid() then
        return
    end

    if bIsInBattle then
        self:SendMessage("OnEnterBossBattleState", Target)
    else
        self:SendMessage("OnLeaveBossBattleState", Target)
    end
end

function BattleStateComponent:Client_OnEnterBattle_RPC(OldTarget, NewTarget)
    -- G.log:debug("yj", "BattleStateComponent:Client_OnEnterBattle_RPC OldTarget.%s IsClient.%s", G.GetDisplayName(OldTarget), self.actor:IsClient())
    if SkillUtils.IsAvatar(self.actor) then
        local GameState = UE.UGameplayStatics.GetGameState(self.actor)
        if GameState then            
            GameState:SendClientMessage("SetBattleInfo", NewTarget)
        end
        self.actor:SendMessage("HandleEnterBattleUI")
    end
end

function BattleStateComponent:Client_OnLeaveBattle_RPC(OldTarget)
    -- G.log:debug("yj", "BattleStateComponent:Client_OnLeaveBattle_RPC OldTarget.%s IsClient.%s", G.GetDisplayName(OldTarget), self.actor:IsClient())
    if SkillUtils.IsAvatar(self.actor) then
        local GameState = UE.UGameplayStatics.GetGameState(self.actor)
        if GameState then
            GameState:SendClientMessage("SetBattleInfo", nil)
        end
        self.actor:SendMessage("HandleLeaveBattleUI")
    end
end

function BattleStateComponent:IsInBattle()
    return self.InBattle
end

return BattleStateComponent
