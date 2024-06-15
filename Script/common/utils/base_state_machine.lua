local G = require("G")

local BaseStateMachineModule = {}

-- 状态基类
local BaseState = {}
BaseState.__index = BaseState

function BaseState.New(StateName)
    ---@type BaseState
    local State = setmetatable({}, BaseState)

    State.StateName = StateName
    State.EnterCondition = nil

    return State
end

function BaseState:SetEnterCondition(Condition)
    self.EnterCondition = Condition
end

function BaseState:CheckEnterCondition()
    if (self.EnterCondition ~= nil) then
        return self.EnterCondition()
    end

    return true
end


-- 状态机基类
local BaseStateMachine = {}
BaseStateMachine.__index = BaseStateMachine

function BaseStateMachine.New(Owner, OnStateEnter, OnStateLeave, OnStateUpdate)
    ---@type BaseStateMachine
    local StateMachine = setmetatable({}, BaseStateMachine)

    StateMachine.States = {}
    StateMachine.Transitions = {}
    StateMachine.PrevState = nil
    StateMachine.CurState = nil
    StateMachine.bRunning = false
    StateMachine.Owner = Owner
    StateMachine.OnStateEnter = OnStateEnter
    StateMachine.OnStateLeave = OnStateLeave
    StateMachine.OnStateUpdate = OnStateUpdate

    return StateMachine
end

function BaseStateMachine:Destroy()
    self:Pause()
    for Key, _ in pairs(self.States) do
        self.States[Key] = nil
    end
    self.States = nil
    self.PrevState = nil
    self.CurState = nil
    self.Owner = nil
end

function BaseStateMachine:SetStartState(StateName)
    local StartState = self.States[StateName]
    if StartState == nil then
        return false
    end

    self.PrevState = nil
    self.CurState = StartState

    return true
end

function BaseStateMachine:AddState(NewState)
    if NewState == nil then
        return false
    end

    if self.States[NewState.StateName] ~= nil then
        return false
    end

    self.States[NewState.StateName] = NewState
    return true
end

function BaseStateMachine:AddTransition(FromStateName, ToStateName)
    if not self.States[FromStateName] or not self.States[ToStateName] then
        return false
    end

    if not self.Transitions[FromStateName] then
        self.Transitions[FromStateName] = {}
    end
    self.Transitions[FromStateName][ToStateName] = true

    return true
end

function BaseStateMachine:GetPrevState()
    return self.PrevState
end

function BaseStateMachine:GetCurrState()
    return self.CurState
end

function BaseStateMachine:GetStateByName(StateName)
    return self.States[StateName]
end

function BaseStateMachine:ChangeState(StateName)
    if not self.bRunning then
        return false
    end

    local TargetState = self.States[StateName]
    if TargetState == nil then
        return false
    end

    if self.CurState == TargetState then
        return false
    end

    if not TargetState:CheckEnterCondition() then
        return false
    end

    if not self.Transitions[self.CurState.StateName] or not self.Transitions[self.CurState.StateName][StateName] then
        return false
    end

    self.OnStateLeave(self.Owner, self.CurState.StateName)

    self.PrevState = self.CurState
    self.CurState = TargetState

    self.OnStateEnter(self.Owner, self.CurState.StateName)

    return true
end

function BaseStateMachine:Update()
    if not self.bRunning then
        return
    end

    if self.CurState ~= nil then
        self.OnStateUpdate(self.Owner, self.CurState.StateName)
    end
end

function BaseStateMachine:Start()
    if self.bRunning then
        return
    end
    self.bRunning = true
    if self.CurState then
        self.OnStateEnter(self.Owner, self.CurState.StateName)
    end
end

function BaseStateMachine:Pause()
    if not self.bRunning then
        return
    end
    self.bRunning = false
    if self.CurState then
        self.OnStateLeave(self.Owner, self.CurState.StateName)
    end
end

BaseStateMachineModule.BaseState = BaseState
BaseStateMachineModule.BaseStateMachine = BaseStateMachine

return BaseStateMachineModule