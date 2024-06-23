--
-- 给不通用的私货需求使用的
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type BTDecorator_ActorCondition_C
local BTDecorator_ActorCondition_C = Class()


function BTDecorator_ActorCondition_C:PerformConditionCheckAI(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local actor = BB:GetValueAsObject(self.actorKey.SelectedKeyName)
    if not actor then
        actor = Pawn
    end

    if self.Execution == '' then
        return false
    end
    local obj = actor[self.Execution]
    if not obj then
        return false
    end
    if type(obj) == 'function' then
        return obj(actor)
    else
        return obj and true or false
    end
end

return BTDecorator_ActorCondition_C