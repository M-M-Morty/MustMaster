
require "UnLua"

local _M  = {}

local G = require("G")

local EventID = require("common.event_const").ComboEventEnum


---Transitions
local Transition = Class()

function Transition:ctor(InFrom, InTo, Priority)    
    self.Priority = Priority
    self.From = InFrom
    self.From:AddTransition(self)
    self.To = InTo
    self.Condition = nil
    self.Action = nil
    
end

function Transition:AddCondition(InCondition)
    self.Condition = InCondition
end

function Transition:AddAction(InAction)
    self.Action = InAction
end

function Transition:Jump(Storyboard)
    if self.Condition and self.Condition(Storyboard) then
        if self.Action then
            self.Action(Storyboard)
        end
        return self.To
    end
end

---export functions
function NormalComboCondition(Storyboard)
    return Storyboard.ComboDownInPeriod
end


local ExportFunc = {}
ExportFunc.NormalComboCondition = NormalComboCondition
ExportFunc.NormalComboAction = NormalComboAction

_M.Transition = Transition
_M.ExportFunc = ExportFunc

return _M