local G = require("G")
local ai_utils = require("common.ai_utils")

local StateToString = {}
StateToString[Enum.Enum_MonsterBattleState.Init]            = "Init"
StateToString[Enum.Enum_MonsterBattleState.Alert]           = "Alert"
StateToString[Enum.Enum_MonsterBattleState.BattlePursue]    = "BattlePursue"
StateToString[Enum.Enum_MonsterBattleState.BattlePerform]   = "BattlePerform"
StateToString[Enum.Enum_MonsterBattleState.BattleAttack]    = "BattleAttack"
StateToString[Enum.Enum_MonsterBattleState.Finding]         = "Finding"
StateToString[Enum.Enum_MonsterBattleState.Returning]       = "Returning"

local StateToGameplayTag = {}
StateToGameplayTag[Enum.Enum_MonsterBattleState.Init]           = "Ability.AI.BSM.Init"
StateToGameplayTag[Enum.Enum_MonsterBattleState.Alert]          = "Ability.AI.BSM.Alert"
StateToGameplayTag[Enum.Enum_MonsterBattleState.BattlePursue]   = "Ability.AI.BSM.BattlePursue"
StateToGameplayTag[Enum.Enum_MonsterBattleState.BattlePerform]  = "Ability.AI.BSM.BattlePerform"
StateToGameplayTag[Enum.Enum_MonsterBattleState.BattleAttack]   = "Ability.AI.BSM.BattleAttack"
StateToGameplayTag[Enum.Enum_MonsterBattleState.Finding]        = "Ability.AI.BSM.Finding"
StateToGameplayTag[Enum.Enum_MonsterBattleState.Returning]      = "Ability.AI.BSM.Returning"


local StateBase             = Class()
local StateInit             = Class(StateBase)
local StateAlert            = Class(StateBase)
local StateBattlePursue     = Class(StateBase)
local StateBattlePerform    = Class(StateBase)
local StateBattleAttack     = Class(StateBase)
local StateFinding          = Class(StateBase)
local StateReturning        = Class(StateBase)

StateInit.state             = Enum.Enum_MonsterBattleState.Init
StateAlert.state            = Enum.Enum_MonsterBattleState.Alert
StateBattlePursue.state     = Enum.Enum_MonsterBattleState.BattlePursue
StateBattlePerform.state    = Enum.Enum_MonsterBattleState.BattlePerform
StateBattleAttack.state     = Enum.Enum_MonsterBattleState.BattleAttack
StateFinding.state          = Enum.Enum_MonsterBattleState.Finding
StateReturning.state        = Enum.Enum_MonsterBattleState.Returning


-- StateBase
function StateBase:ctor(owner)
    self.owner = owner
    self.pre_state = nil
    self.enter_time = 0
    self.target_cache = nil
end

function StateBase:enter( ... )
    G.log:error("yj", "StateBase %s enter %s", self.owner:GetDisplayName(), StateToString[self.state])
    self.enter_time = G.GetNowTimestampMs()
end

function StateBase:turn_to(new_state)
    local next_state = new_state.new(self.owner)
    if next_state.state == self.owner.State.state then
        return
    end

    self.owner.State = next_state
    self.owner.State.pre_state = self.state

    local target = ai_utils.GetBattleTarget(self.owner)
    self.owner.State:enter(target or self.target_cache)
end

function StateBase:tick( ... )
    return not self.owner:GetAIServerComponent().bForbiddenBTSwitch
end

function StateBase:enter_pursue_by_partner_call(target)
    self.target_cache = target
    self:turn_to(StateBattlePursue)
end

function StateBase:on_damaged(target)
    -- TODO - 要判断当前是否处于战斗状态（暂时不处理了）
    -- self.target_cache = target
    -- self:turn_to(StateBattlePursue)
end

function StateBase:get_alert_dis()
    return self.owner.AIPerceptionComponent:GetAlertDis()
end

function StateBase:get_pursue_dis()
    return self.owner.AIPerceptionComponent:GetPursueDis()
end

function StateBase:get_in_attack_dis()
    return self.owner.AIPerceptionComponent:GetInAttackDis()
end

function StateBase:get_out_attack_dis()
    return self.owner.AIPerceptionComponent:GetOutAttackDis()
end

function StateBase:choice_target(Dis)
    return self.owner.AIPerceptionComponent:ChoiceTarget(Dis)
end

function StateBase:update_target(target)
    if target ~= ai_utils.GetBattleTarget(self.owner) then
        ai_utils.BreakBattleTargetPair(self.owner)
        if target then
            ai_utils.MakeBattleTargetPair(self.owner, target)
        end
    end
end

function StateBase:update_target_by_dis(dis)
    local target = self:choice_target(dis)
    self:update_target(target)
end

function StateBase:check_enter_base(State)
    local TagStr = StateToGameplayTag[State.state]
    return self.owner:GetAIServerComponent():HasBTSwitchTag(TagStr)
end

function StateBase:perception_for_alert()
    -- 感知警戒： Init -> Alert
    local target = self.owner.AIPerceptionComponent:PerceptionForAlert()
    self:update_target(target)
    return target
end

function StateBase:perception_for_pursue()
    -- 追击警戒： Finding -> Pursue
    local target = self.owner.AIPerceptionComponent:PerceptionForPursue()
    self:update_target(target)
    return target 
end

function StateBase:check_enter_finding()
    if not self:check_enter_base(StateFinding) then
        return false
    end

    return ai_utils.GetBattleTarget(self.owner) == nil
end

function StateBase:check_enter_returning()
    if not self:check_enter_base(StateReturning) then
        return false
    end

    if ai_utils.GetBattleTarget(self.owner) == nil then
        return true
    end

    local BornLocation = ai_utils.GetBornLocation(self.owner)
    local Dis2Born = UE.UKismetMathLibrary.Vector_Distance(self.owner:K2_GetActorLocation(), BornLocation)
    return Dis2Born > self.owner.AIPerceptionComponent.ReturnDis
end

function StateBase:check_enter_init(target)
    -- init不用check base
    local SelfLocation = self.owner:K2_GetActorLocation()
    local BornLocation = ai_utils.GetBornLocation(self.owner)
    return UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, BornLocation) < 500
end

function StateBase:turn_to_state_battlepursue(Target)
    self:update_target(Target)
    self:turn_to(StateBattlePursue)
end



------------------------------------------------
------------------ StateInit -------------------
------------------------------------------------
function StateInit:ctor(owner)
    Super(StateInit).ctor(self, owner)
end

function StateInit:enter(...)
    Super(StateInit).enter(self, ...)
    self.owner:SendMessage("BSM_EnterInit")
end

function StateInit:tick( ... )
    if not Super(StateInit).tick(self) then
        return
    end

    if self:check_enter_alert() then
        self:turn_to(StateAlert)
        return
    end
end

function StateInit:check_enter_alert()
    if not self:check_enter_base(StateAlert) then
        return false
    end

    return self:perception_for_alert() ~= nil
end


------------------------------------------------
------------------ StateAlert ------------------
------------------------------------------------
function StateAlert:ctor(owner)
    Super(StateAlert).ctor(self, owner)
end

function StateAlert:enter(target)
    Super(StateAlert).enter(self, target)
    ai_utils.MakeBattleTargetPair(self.owner, target)
    self.owner:SendMessage("BSM_EnterAlert", target)
end

function StateAlert:tick()
    if not Super(StateAlert).tick(self) then
        return
    end

    self:update_target_by_dis(self:get_alert_dis())

    if self:check_enter_base(StateReturning) and self:check_out_alert()  then
        self:turn_to(StateReturning)
        return
    end

    if self:check_enter_battle_pursue() then
        self:turn_to(StateBattlePursue)
        return
    end
end

function StateAlert:check_out_alert()
    if ai_utils.GetBattleTarget(self.owner) == nil then
        return true
    end

    local MaxAlertTime = self.owner.BattleStateComponent.MaxAlertTime
    local now = G.GetNowTimestampMs()
    return now - self.enter_time > MaxAlertTime * 1000
end

function StateAlert:check_enter_battle_pursue()
    if not self:check_enter_base(StateBattlePursue) then
        return false
    end

    local target = ai_utils.GetBattleTarget(self.owner)
    local Dis = self.owner:GetDistanceTo(target)
    return Dis < self:get_pursue_dis()
end


------------------------------------------------
--------------- StateBattlePursue --------------
------------------------------------------------
function StateBattlePursue:ctor(owner)
    Super(StateBattlePursue).ctor(self, owner)
end

function StateBattlePursue:enter(target)
    Super(StateBattlePursue).enter(self, target)
    ai_utils.MakeBattleTargetPair(self.owner, target)
    self.owner:SendMessage("BSM_EnterBattlePursue", target)
end

function StateBattlePursue:tick()
    if not Super(StateBattlePursue).tick(self) then
        return
    end

    self:update_target_by_dis(self:get_pursue_dis())

    if self:check_enter_finding() then
        self:turn_to(StateFinding)
        return
    end

    if self:check_enter_returning() then
        self:turn_to(StateReturning)
        return
    end

    if self:check_enter_battle_perform() then
        self:turn_to(StateBattlePerform)
        return
    end
end

function StateBattlePursue:check_enter_battle_perform()
    if not self:check_enter_base(StateBattlePerform) then
        return false
    end

    local target = ai_utils.GetBattleTarget(self.owner)
    local Dis = self.owner:GetDistanceTo(target)
    return Dis < self:get_in_attack_dis()
end


------------------------------------------------
-------------- StateBattlePerform --------------
------------------------------------------------
function StateBattlePerform:ctor(owner)
    Super(StateBattlePerform).ctor(self, owner)
end

function StateBattlePerform:enter(target)
    Super(StateBattlePerform).enter(self, target)
    ai_utils.MakeBattleTargetPair(self.owner, target)
    self.owner:SendMessage("BSM_EnterBattlePerform", target)
end

function StateBattlePerform:tick()
    if not Super(StateBattlePerform).tick(self) then
        return
    end

    self:update_target_by_dis(self:get_pursue_dis())

    if self:check_enter_finding() then
        self:turn_to(StateFinding)
        return
    end

    if self:check_enter_returning() then
        self:turn_to(StateReturning)
        return
    end

    if self:check_enter_battle_pursue() then
        self:turn_to(StateBattlePursue)
        return
    end

    if self:check_enter_battle_attack() then
        self:turn_to(StateBattleAttack)
        return
    end
end

function StateBattlePerform:check_enter_battle_pursue()
    if not self:check_enter_base(StateBattlePursue) then
        return false
    end

    local target = ai_utils.GetBattleTarget(self.owner)
    local Dis = self.owner:GetDistanceTo(target)
    return Dis > self:get_out_attack_dis()
end

function StateBattlePerform:check_enter_battle_attack()
    if not self:check_enter_base(StateBattleAttack) then
        return false
    end

    -- 获得攻击信号
    return self.owner:GetAIServerComponent().BattleSignalSource ~= nil
end


------------------------------------------------
--------------- StateBattleAttack --------------
------------------------------------------------
function StateBattleAttack:ctor(owner)
    Super(StateBattleAttack).ctor(self, owner)
end

function StateBattleAttack:enter(target)
    Super(StateBattleAttack).enter(self, target)
    self.owner:SendMessage("BSM_EnterBattleAttack", target)
end

function StateBattleAttack:tick()
    if not Super(StateBattleAttack).tick(self) then
        return
    end

    self:update_target_by_dis(self:get_pursue_dis())

    if self:check_enter_finding() then
        self.owner:SendMessage("ReturnBattleSignal")
        self:turn_to(StateFinding)
        return
    end

    if self:check_enter_returning() then
        self.owner:SendMessage("ReturnBattleSignal")
        self:turn_to(StateReturning)
        return
    end

    if self:check_enter_base(StateBattlePerform) and self:check_out_battle_attack() then
        self:turn_to(StateBattlePerform)
        return
    end
end

function StateBattleAttack:check_out_battle_attack()
    local target = ai_utils.GetBattleTarget(self.owner)
    local Dis = self.owner:GetDistanceTo(target)
    if Dis > self:get_out_attack_dis() then
        return true
    end

    -- 失去攻击信号
    return self.owner:GetAIServerComponent().BattleSignalSource == nil
end


------------------------------------------------
------------------ StateFinding ----------------
------------------------------------------------
function StateFinding:ctor(owner)
    Super(StateFinding).ctor(self, owner)
end

function StateFinding:enter( ... )
    Super(StateFinding).enter(self, ...)
    ai_utils.BreakBattleTargetPair(self.owner)
    self.owner:SendMessage("BSM_EnterFinding")
end

function StateFinding:tick()
    if not Super(StateFinding).tick(self) then
        return
    end

    if self:check_enter_battle_pursue() then
        self:turn_to(StateBattlePursue)
        return
    end

    if self:check_out_finding() then
        self:turn_to(StateReturning)
        return
    end
end

function StateFinding:check_enter_battle_pursue()
    if not self:check_enter_base(StateBattlePursue) then
        return false
    end

    return self:perception_for_pursue() ~= nil
end

function StateFinding:check_out_finding()
    local MaxFindingTime = self.owner.BattleStateComponent.MaxFindingTime
    local now = G.GetNowTimestampMs()
    return now - self.enter_time > MaxFindingTime * 1000
end


------------------------------------------------
----------------- StateReturning ---------------
------------------------------------------------
function StateReturning:ctor(owner)
    -- StateReturning期间无法再次入战
    Super(StateReturning).ctor(self, owner)
end

function StateReturning:enter( ... )
    Super(StateReturning).enter(self, ...)
    ai_utils.BreakBattleTargetPair(self.owner)
    self.owner:SendMessage("BSM_EnterReturning")
end

function StateReturning:tick()
    if not Super(StateReturning).tick(self) then
        return
    end

    if self:check_enter_init() then
        self:turn_to(StateInit)
    end
end

function StateReturning:on_damaged(target)
    -- ignore
end

function StateReturning:enter_pursue_by_partner_call(target)
    -- ignore
end


local M = {}
function M.InitState(owner)
    local state = StateInit.new(owner)
    state:enter()
    return state
end

M.StateToString = StateToString
M.StateToGameplayTag = StateToGameplayTag
M.StateBase = StateBase
M.StateInit = StateInit
M.StateAlert = StateAlert
M.StateBattlePursue = StateBattlePursue
M.StateBattlePerform = StateBattlePerform
M.StateBattleAttack = StateBattleAttack
M.StateFinding = StateFinding
M.StateReturning = StateReturning

return M
