--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--



local G = require("G")
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ai_utils = require("common.ai_utils")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')

local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_SelectAction_C
local BTTask_SelectAction_C = Class(BTTask_Base)

function BTTask_SelectAction_C:Execute(Controller, Pawn)
    if self.actions:Length() < 1 then
        --G.log:debug("duzy", "BTTask_SelectAction_C:Execute actions:Length() ERROR")
        return ai_utils.BTTask_Failed
    end

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local tarActor = BB:GetValueAsObject(self.tarActor.SelectedKeyName)
    if not tarActor then
        --G.log:debug("duzy", "BTTask_SelectAction_C:Execute tarActor ERROR")
        return ai_utils.BTTask_Failed
    end

    local extend = Pawn:GetBlackBoardExtend()
    extend:TryInitActions(self.actions)

    local action
    if Pawn.GetQuickFollowAction then
        action = Pawn:GetQuickFollowAction()
    end
    if not action then
        action = FunctionUtil:SelectActionRaw(Pawn, tarActor)
    end

    if action then
        BB:SetValueAsString(self.saveKey.SelectedKeyName, action.ActionKey)
        BB:SetValueAsObject(self.saveObj1.SelectedKeyName, action.ActionAbilityCls)
        --G.log:debug("duzy", "BTTask_SelectAction_C:Execute action SUCCESS")
        return ai_utils.BTTask_Succeeded
    else
        --G.log:debug("duzy", "BTTask_SelectAction_C:Execute action ERROR")
        return ai_utils.BTTask_Failed
    end
end

return BTTask_SelectAction_C

