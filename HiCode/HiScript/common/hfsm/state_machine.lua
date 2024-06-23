local utils = require("common.utils")
local G = require("G")
local check_table = require("common.data.state_conflict_data")
local state_machine = {}

function state_machine:Initialize(owner, check_table, break_callback, cancel_callback)
    self.active_states = {}
    self.states = {}
    self.check_table = check_table

    self.owner = owner

    self.break_callback = break_callback
    self.cancel_callback = cancel_callback

end

function state_machine:GM_ClearAllActiveStates()
    for index = #self.active_states, 1, -1 do
        local state = self.active_states[index]
        self:EndState(state, true)
    end
    self:EnterState(check_table.State_Idle)
end

function state_machine:ClearAllStates()
    for index = #self.active_states, 1, -1 do
        local state = self.active_states[index]
        self:EndState(state, false)
    end
    self:EnterState(check_table.State_Idle)
end

function state_machine:CheckState(state)
    if self.states[state] then
        return true
    end

    return false
end

function state_machine:CheckAction(action)
    local check_list = self.check_table[action]
    if check_list == nil then
        assert(false)
    end

    local cancel_list = check_list["cancel"]
    if cancel_list == nil then
        return true
    end
    
    local check_states = utils.intersection(self.active_states, cancel_list)

    if #check_states > 0 then
        if self.cancel_callback then
            self.cancel_callback(self.owner, action, check_states)
        end
        return false
    end
    return true
end

function state_machine:ExecuteAction(action)
    if not self:CheckAction(action) then
        return false
    end

    self:BreakStateOfAction(action)

    self:EnterStateOfAction(action)

    return true
end

function state_machine:BreakStateOfAction(action)
    local check_list = self.check_table[action]
    if check_list == nil then
        assert(false)
    end

    local break_list = check_list["break"]
    if break_list == nil then
        return true
    end

    local check_states = utils.intersection(self.active_states, break_list)

    for _, state in ipairs(check_states) do
        self:__OnBreakState__(state, action, true)
    end
end

function state_machine:EnterStateOfAction(action)
    local check_list = self.check_table[action]
    if check_list == nil then
        assert(false)
    end

    local enter_list = check_list["enter"]
    if enter_list == nil then
        return true
    end

    for k, v in ipairs(enter_list) do
        if not self.states[v] then
            self.states[v] = true
            table.insert(self.active_states, v)
        end
    end
end

-- EndState end specified state
function state_machine:EndState(State, EnableCallback)
    self:__OnBreakState__(State, nil, EnableCallback)
end

-- EnterState enter specified state
function state_machine:EnterState(State)
    if not self.states[State] then
        self.states[State] = true
        table.insert(self.active_states, State)
    end
end

function state_machine:__OnBreakState__(state, reason, EnableCallback)
    self.states[state] = false
    local index = utils.find(self.active_states, state)
    if index > 0 then
        table.remove(self.active_states, index)
    end

    if self.break_callback and EnableCallback then
        self.break_callback(self.owner, state, reason)
    end
end

function state_machine:__OnCancelAction__(action, reason)
    if self.cancel_callback then
        self.cancel_callback(self.owner, action, reason)
    end
end

state_machine.new = function(...)
    local obj = {}
    obj.__class__ = state_machine
    setmetatable(obj, {__index = state_machine})
    if state_machine.Initialize then
        obj:Initialize(...)
    end
    return obj
end

return state_machine
