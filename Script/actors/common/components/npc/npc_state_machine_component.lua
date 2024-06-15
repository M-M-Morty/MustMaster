--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local G = require("G")
local ComponentBase = require("common.componentbase")
local Component = require("common.component")
local StateMachineModule = require("common.utils.base_state_machine")

---@type BP_NpcStateMachineComponent_C
local NpcStateMachineComponent = Component(ComponentBase)

function NpcStateMachineComponent:ReceiveBeginPlay()
    Super(NpcStateMachineComponent).ReceiveBeginPlay(self)
    if self:GetOwner():IsServer() then
        -- 初始化AI状态机
        self.StateMachine = StateMachineModule.BaseStateMachine.New(self, self.HandleStateEnter, self.HandleStateLeave, self.HandleStateUpdate)
        -- FIXME(hangyuewang): 先手写加入状态
        self.StateMachine:AddState(StateMachineModule.BaseState.New(Enum.BPE_NpcAiState.Idle))
        self.StateMachine:AddState(StateMachineModule.BaseState.New(Enum.BPE_NpcAiState.Walk))
        self.StateMachine:AddState(StateMachineModule.BaseState.New(Enum.BPE_NpcAiState.Dialogue))
        self.StateMachine:AddState(StateMachineModule.BaseState.New(Enum.BPE_NpcAiState.Stress))
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Idle, Enum.BPE_NpcAiState.Walk)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Idle, Enum.BPE_NpcAiState.Dialogue)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Idle, Enum.BPE_NpcAiState.Stress)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Walk, Enum.BPE_NpcAiState.Idle)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Walk, Enum.BPE_NpcAiState.Dialogue)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Walk, Enum.BPE_NpcAiState.Stress)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Dialogue, Enum.BPE_NpcAiState.Idle)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Dialogue, Enum.BPE_NpcAiState.Walk)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Stress, Enum.BPE_NpcAiState.Idle)
        self.StateMachine:AddTransition(Enum.BPE_NpcAiState.Stress, Enum.BPE_NpcAiState.Walk)
        self.StateMachine:SetStartState(Enum.BPE_NpcAiState.Idle)
        self.StateMachine:Start()
    end
end

function NpcStateMachineComponent:ReceiveEndPlay()
    Super(NpcStateMachineComponent).ReceiveEndPlay(self)
    if self:GetOwner():IsServer() then
        self.StateMachine:Destroy()
    end
end

function NpcStateMachineComponent:HandleStateEnter(StateName)
    self.EventOnStateEnter:Broadcast(StateName)
end

function NpcStateMachineComponent:HandleStateLeave(StateName)
    self.EventOnStateLeave:Broadcast(StateName)
end

function NpcStateMachineComponent:HandleStateUpdate(StateName)
    self.EventOnStateUpdate:Broadcast(StateName)
end

function NpcStateMachineComponent:ChangeToPrevState()
    if not self.StateMachine.bRunning then
        G.log:warn("NpcStateMachineComponent", "ChangeToPrevState: StateMachine is not running")
        return false
    end

    local PrevState = self.StateMachine:GetPrevState()
    if PrevState then
        return self.StateMachine:ChangeState(PrevState.StateName)
    end
end

function NpcStateMachineComponent:ChangeState(StateName)
    if not self.StateMachine.bRunning then
        G.log:warn("NpcStateMachineComponent", "ChangeState: StateMachine is not running")
        return false
    end

    return self.StateMachine:ChangeState(StateName)
end

function NpcStateMachineComponent:GetCurrState()
    if not self.StateMachine.bRunning then
        G.log:warn("NpcStateMachineComponent", "GetCurrState: StateMachine is not running")
        return nil
    end

    return self.StateMachine:GetCurrState()
end

return NpcStateMachineComponent
