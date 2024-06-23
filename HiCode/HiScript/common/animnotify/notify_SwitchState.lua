--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require("G")
check_table = require("common.data.state_conflict_data")

---@type AN_SwitchState_C
local AN_SwitchState = Class()

function AN_SwitchState:Received_Notify(MeshComp, Animation, EventReference)
    -- G.log:info("yb", "switch state %s %s", check_table[self.SourceState], check_table[self.TargetState])
    if(check_table[self.SourceState] == nil or check_table[self.TargetState] == nil) then return false end
    local Owner = MeshComp:GetOwner()
    if Owner then G.log:info("yb", "switch state %s %s", Owner:IsServer(), GameAPI.IsPlayer(Owner)) end
    if not Owner or Owner:IsServer() or not GameAPI.IsPlayer(Owner) then return false end
    local StateController = Owner:_GetComponent("StateController", false)
    if not StateController then return false end
    if StateController:CheckState(check_table[self.SourceState]) then
        StateController:EndState(check_table[self.SourceState], self.bBreakState)
        StateController:EnterState(check_table[self.TargetState])
    end
    return true
end

return AN_SwitchState
