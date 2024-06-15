local M = {}

local ActionEnum = {}
ActionEnum.Action_Move = 1
ActionEnum.Action_Jump = 2

local StateEnum = {}
StateEnum.State_Move = 1
StateEnum.State_Jump = 2

M.ActionEnum = ActionEnum
M.StateEnum = StateEnum

return M