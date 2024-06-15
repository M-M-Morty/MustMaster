require "UnLua"

local G = require("G")

local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local StateController = Component(ComponentBase)
local decorator = StateController.decorator

local StateMachine = require("common.hfsm.state_machine")
local check_table = require("common.data.state_conflict_data")
local utils = require("common.utils")

local BreakTable = {
    [check_table.State_Idle] = "BreakStateIdle",
    [check_table.State_Move] = "BreakStateMove",
    [check_table.State_Jump] = "BreakStateJump",
    [check_table.State_Dodge] = "BreakDodge",
    [check_table.State_DodgeTail] = "BreakDodge",
    [check_table.State_Sprint] = "BreakSprint",
    [check_table.State_SkillTail] = "BreakSkillTail",
    [check_table.State_SkillTail_NotMovable] = "BreakSkillTail",
    [check_table.State_HitTail] = "BreakHitTail",
    [check_table.State_HitTail_NotMovable] = "BreakHitTail",
    [check_table.State_Hit] = "OnBreakHit",
    [check_table.State_AttackZeroGravity] = "EndCurrentZeroGravity",
    [check_table.State_JumpInAir] = "BreakJumpInAirState",
    [check_table.State_Rush] = "BreakStateRush",
    [check_table.State_Climb] = "BreakStateClimb",
    [check_table.State_WithStand] = "BreakWithStand",
    [check_table.State_MoveWithStand] = "BreakWithStand",
    [check_table.State_Skill] = "BreakSkill",
    [check_table.State_SkillNormal] = "BreakSkill",
    [check_table.State_FixedPointJump] = "BreakFixedPointJump",
    [check_table.State_FixedPointJumpLand] = "BreakFixedPointJumpLand",
    [check_table.State_ChargePre] = "BreakSkill",
    [check_table.State_SuperSkill] = "BreakSkill",
    [check_table.State_OnThrowEnd] = "BreakOnThrowEnd",
    [check_table.State_Mantle] = "BreakMantle",
    [check_table.State_Aiming_Mode] = "BreakAimingMode",
    [check_table.State_Glide] = "BreakGlide",
}

local CancelTable = {
    [check_table.Action_Idle] = "CancelActionIdle",
    [check_table.Action_Move] = "CancelActionMove",
    [check_table.Action_Jump] = "CancelActionJump",
    [check_table.Action_Skill] = "CancelActionSkill",
}

function StateController:Initialize(...)
    Super(StateController).Initialize(self, ...)
    self.state_machine = StateMachine.new(self, check_table.data, self.__OnBreakState__, self.__OnCancelAction__)
end

function StateController:Start()
    Super(StateController).Start(self)

    assert(self.actor)

    local check_func = function(component, func, action, cost_cd_check_func, ...)
        -- Ensure cost_cd_check_func must return bool whether pass check.
        if cost_cd_check_func then
            local bPass, NewAction = cost_cd_check_func(component, action)
            if not bPass then
                return
            end

            if NewAction then
                action = NewAction
            end
        end

        local arg = {...}
        --G.log:debug("lizhao", "StateController:ExecuteAction %s %s %s", tostring(action), tostring(func), tostring(arg[1]))
        if self.state_machine:ExecuteAction(action) then
            func(component, ...)
        end
    end

    assert(self.actor:GetHookFunc(decorator.hook_func_type_require_check_action) == nil)

    self.actor:SetHookFunc(decorator.hook_func_type_require_check_action, check_func)
end

function StateController:Stop()
    Super(StateController).Stop(self)

    self.actor:SetHookFunc(decorator.hook_func_type_require_check_action, nil)
end

decorator.message_receiver()
function StateController:EndState(State, EnableCallback)
    G.log:info("StateController", "End state: %s", utils.StateToStr(State))
    self.state_machine:EndState(State, EnableCallback)
end

decorator.message_receiver()
function StateController:EnterState(State)
    G.log:info("StateController", "Enter state: %s", utils.StateToStr(State))
    self.state_machine:EnterState(State)
end

decorator.message_receiver()
function StateController:ExecuteAction(Action)
    return self.state_machine:ExecuteAction(Action)
end

function StateController:CheckAction(Action)
    return self.state_machine:CheckAction(Action)
end

decorator.message_receiver()
function StateController:GM_ClearAllActiveStates()
    self.state_machine:GM_ClearAllActiveStates()
end

decorator.message_receiver()
function StateController:ClearAllStates()
    self.state_machine:ClearAllStates()
end

function StateController:__OnBreakState__(state, reason)
    -- G.log:info("StateController", "StateController:__OnBreakState__ %s, reason: %s", utils.StateToStr(state), utils.StateToStr(reason))
    local callback = BreakTable[state]
    if callback then
        self:SendMessage(callback, reason)
    end
end

function StateController:__OnCancelAction__(action, reason)
    G.log:debug("StateController", "StateController:__OnCancelAction__ %s, reason: %s", utils.ActionToStr(action), utils.StateToStr(reason))
    local callback = CancelTable[action]
    if callback then
        self:SendMessage(callback, reason)
    end
end

function StateController:InSkillState()
    return self.state_machine:CheckState(check_table.State_Skill) or self.state_machine:CheckState(check_table.State_SkillNormal)
end

function StateController:CheckState(State)
    return self.state_machine:CheckState(State)
end

return StateController
