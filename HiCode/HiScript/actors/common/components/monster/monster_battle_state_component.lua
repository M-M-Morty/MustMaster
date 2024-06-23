local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local G = require("G")
local BattleStateMachine = require("common.utils.battle_state_machine")

local MonsterBattleStateComponent = Component(ComponentBase)

local decorator = MonsterBattleStateComponent.decorator

decorator.message_receiver()
function MonsterBattleStateComponent:OnServerReady()
    if not self.actor.AISwitch then
        self.actor:RemoveBlueprintComponent(self)
        return
    end

    self.actor.State = BattleStateMachine.InitState(self.actor)

    if not SkillUtils.IsBoss(self.actor) then
        -- 小怪卡位检测
        self:ResetStuckCheck()
    end
end

function MonsterBattleStateComponent:ReceiveEndPlay(EndPlayReason)
    Super(MonsterBattleStateComponent).ReceiveEndPlay(self, EndPlayReason)
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.StuckCheckTimerHandler)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnReceiveTick(DeltaSeconds)
    if not self.actor:IsServer() then
        return
    end

    if self.actor.State then
        self.actor.State:tick()
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnDamaged(Damage, HitInfo, Instigator, DamageCauser, DamageAbility, DamageGESpec)
    if self.actor:IsServer() then
        self.actor.State:on_damaged(DamageCauser or Instigator)
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:CallPartnerEnterBattle()
    local OutHits = UE.TArray(UE.FHitResult)
    local ActorsToIgnore = UE.TArray(UE.AActor)
    ActorsToIgnore:Add(self.actor)
    local Location = self.actor:K2_GetActorLocation()
    local ObjectTypes = UE.TArray(UE.EObjectTypeQuery)
    ObjectTypes:Add(UE.EObjectTypeQuery.Pawn)
    UE.UKismetSystemLibrary.SphereTraceMultiForObjects(
        self.actor:GetWorld(), Location, Location, self.CallPartneRadius, ObjectTypes, false, ActorsToIgnore, UE.EDrawDebugTrace.None, OutHits, true)

    local Target = ai_utils.GetBattleTarget(self.actor)
    for idx = 1, OutHits:Length() do
        local CurActor = OutHits:Get(idx).Component:GetOwner()
        if CurActor.IsMonster and CurActor:IsMonster() and CurActor.BattleStateComponent then
            CurActor.State:enter_pursue_by_partner_call(Target)
        end
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:TurnTo_StateBattlePursue(Target)
    -- TODO
    self.actor.State:turn_to_state_battlepursue(Target)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnUpdateTarget(Target)
    self.actor.State:on_update_target(Target)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnLoseTarget(Target)
    self.actor.State:on_lose_target(Target)
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterInit()
    self:ApplyInitGE()
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterAlert(Target)
    self:ApplyAlertGE()
    self.actor:Multicast_Message("OnEnterAlert")
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterBattlePursue(Target)
    self.InBattle = true
    self:ApplyBattlePursueGE()
    self.actor:Multicast_Message("OnEnterBattle")
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterBattlePerform(Target)
    self:ApplyBattlePerformGE()
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterBattleAttack(Target)
    self:ApplyBattleAttackGE()
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterFinding()
    self:ApplyFindingGE()
    self.actor:Multicast_Message("OnEnterFinding")
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterReturning()
    self:ApplyReturningGE()
    self.actor:Multicast_Message("OnEnterReturning")
end

decorator.message_receiver()
function MonsterBattleStateComponent:BSM_EnterStiffness()
    self:ApplyStiffnessGE()
end

function MonsterBattleStateComponent:IsInBattle()
    return self.InBattle
end

decorator.message_receiver()
function MonsterBattleStateComponent:FinishCalling()
    self.actor.State:on_finish_calling()
end

function MonsterBattleStateComponent:ApplyInitGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local InitGESpecHandle = ASC:MakeOutgoingSpec(self.InitGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(InitGESpecHandle)
end

function MonsterBattleStateComponent:ApplyAlertGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local InAlertGESpecHandle = ASC:MakeOutgoingSpec(self.AlertGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(InAlertGESpecHandle)
end

function MonsterBattleStateComponent:ApplyBattlePursueGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local PursueGESpecHandle = ASC:MakeOutgoingSpec(self.BattlePursueGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(PursueGESpecHandle)
end

function MonsterBattleStateComponent:ApplyBattlePerformGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local PerformGESpecHandle = ASC:MakeOutgoingSpec(self.BattlePerformGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(PerformGESpecHandle)
end

function MonsterBattleStateComponent:ApplyBattleAttackGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local AttackGESpecHandle = ASC:MakeOutgoingSpec(self.BattleAttackGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(AttackGESpecHandle)
end

function MonsterBattleStateComponent:ApplyFindingGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local FindingGESpecHandle = ASC:MakeOutgoingSpec(self.FindingGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(FindingGESpecHandle)
end

function MonsterBattleStateComponent:ApplyReturningGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local ReturningGESpecHandle = ASC:MakeOutgoingSpec(self.ReturningGE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(ReturningGESpecHandle)
end

function MonsterBattleStateComponent:ApplyStiffnessGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    local StiffnessGESpecHandle = ASC:MakeOutgoingSpec(self.StiffnessGE, 1, UE.FGameplayEffectContextHandle())
    self.StiffnessGEHandle = ASC:BP_ApplyGameplayEffectSpecToSelf(StiffnessGESpecHandle)
end

decorator.message_receiver()
function MonsterBattleStateComponent:RemoveStiffnessGE()
    local ASC = self.actor:GetAbilitySystemComponent()
    ASC:RemoveActiveGameplayEffect(self.StiffnessGEHandle)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnEnterBattle()
    if not self.actor:IsClient() then
        return
    end
    if not SkillUtils.IsBoss(self.actor) then
        self.actor.BP_MonsterHPWidget:GetWidget():SetBattleMode(true)
    end
    self:SendMessage("ShowWeapon")

    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    HudTrackVM:AddHurtTrackActor(self.actor)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnEnterAlert()
    if not self.actor:IsClient() then
        return
    end
    if not SkillUtils.IsBoss(self.actor) then
        self.actor.BP_MonsterHPWidget:GetWidget():SetAlertMode(true)
    end
    self:SendMessage("ShowWeapon")

    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    HudTrackVM:AddHurtTrackActor(self.actor)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnEnterFinding()
    self.InBattle = false

    if not self.actor:IsClient() then
        return
    end

    if not SkillUtils.IsBoss(self.actor) then
        self.actor.BP_MonsterHPWidget:GetWidget():SetBattleMode(false)
        --self.actor.BP_MonsterHPWidget:GetWidget():SetAlertMode(false)
    end

    self:SendMessage("HideWeapon")

    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    HudTrackVM:RemoveHurtTrackActor(self.actor)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnEnterReturning()
    if not self.actor:IsClient() then
        return
    end

    if not SkillUtils.IsBoss(self.actor) then
        self.actor.BP_MonsterHPWidget:GetWidget():SetReturningMode(true);
    end

    self:SendMessage("HideWeapon")
    
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
    local HudTrackVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.HudTrackVM.UniqueName)
    HudTrackVM:RemoveHurtTrackActor(self.actor)
end

decorator.message_receiver()
function MonsterBattleStateComponent:OnDead()
    if self.actor:IsClient() then
        self:SendMessage("HideHpBar")
        self:SendMessage("HideWeapon")
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:HideWeapon()
    if not self.actor:IsClient() then
        return
    end

    if self.actor.Weapon then
        self.actor.Weapon:SetVisibility(false)
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:ShowWeapon()
    if not self.actor:IsClient() then
        return
    end

    if self.actor.Weapon then
        self.actor.Weapon:SetVisibility(true)
    end
end

decorator.message_receiver()
function MonsterBattleStateComponent:EnterStressState(SubState)
    self.StressSubState = SubState
    if SubState == Enum.Enum_ClusterStressSubState.EliteDead then
        self:ApplyInStressGE(self.InStressGE_EliteDead)
    end
end

function MonsterBattleStateComponent:ApplyInStressGE(GE)
    local ASC = self.actor:GetAbilitySystemComponent()
    local InStressGESpecHandle = ASC:MakeOutgoingSpec(GE, 1, UE.FGameplayEffectContextHandle())
    ASC:BP_ApplyGameplayEffectSpecToSelf(InStressGESpecHandle)
end

function MonsterBattleStateComponent:ResetStuckCheck()
    self.LastCheckLocation = self.actor:K2_GetActorLocation()
    self.StuckCheckCount = 12
    self.StuckCheckTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.StuckCheckTimer}, 9, false)
end

function MonsterBattleStateComponent:StuckCheckTimer()
    local CurLocation = self.actor:K2_GetActorLocation()
    -- G.log:error("yj", "MonsterBattleStateComponent:StuckCheckTimer Dis.%s StuckCheckCount.%s", UE.UKismetMathLibrary.Vector_Distance(CurLocation, self.LastCheckLocation), self.StuckCheckCount)
    if UE.UKismetMathLibrary.Vector_Distance(CurLocation, self.LastCheckLocation) < 10 then
        self.StuckCheckCount = self.StuckCheckCount - 1
        if self.StuckCheckCount < 0 then
            if self.actor.State.state ~= Enum.Enum_MonsterBattleState.Init then
                self:SendMessage("TeleportToBornLocation")
            end
            self:ResetStuckCheck()
        else
            self.LastCheckLocation = CurLocation
            self.StuckCheckTimerHandler = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.StuckCheckTimer}, 2, false)
        end
    else
        self:ResetStuckCheck()
    end
end

return MonsterBattleStateComponent
