--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local ai_utils = require("common.ai_utils")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_TryActiveGA
local BTTask_TryActiveGA = Class(BTTask_Base)

function BTTask_TryActiveGA:Execute(Controller, Pawn)

    local abilityCls, key = self:GetAbilityClass(Controller, Pawn)
    if not abilityCls then
        return ai_utils.BTTask_Failed
    end

    if key and Pawn.UpdateAbilityResult then
        Pawn:UpdateAbilityResult(key)
    end

    Controller:StopMovement()
    FunctionUtil:TryActiveGA(Pawn, abilityCls)
end

function BTTask_TryActiveGA:Tick(Controller, Pawn, DeltaSeconds)
    local abilityCls = self:GetAbilityClass(Controller, Pawn)
    if not FunctionUtil:IsGAInActive(Pawn, abilityCls) then
        self:FinishTask(Controller, Pawn)
        --set quick follower
        if self.fromBlackboard and Pawn and Controller and Pawn and Pawn.GetBlackBoardExtend and Pawn.SetQuickFollowAction then
            local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
            local key = BB:GetValueAsString('actionKey')
            local extend = Pawn:GetBlackBoardExtend()
            local QuickFollow = ''
            for i, action in pairs(extend.actions) do
                if action.ActionKey == key then
                    QuickFollow = action.QuickFollow
                    break
                end
            end
            Pawn:SetQuickFollowAction(QuickFollow, 5)
        end
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_TryActiveGA:GetAbilityClass(Controller, Pawn)
    if self.fromBlackboard then
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        return BB:GetValueAsObject(self.abilityClsKey.SelectedKeyName), BB:GetValueAsString('actionKey')
    else
        return self.abilityClass
    end
end

function BTTask_TryActiveGA:FinishTask(Controller, Pawn)
    local extend = Pawn and Pawn:GetBlackBoardExtend()
    if self.fromBlackboard and extend then
        local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
        local key = BB:GetValueAsString('actionKey')
        if key then
            extend:SetSkillCastTime(key)
        end
    end
end

function BTTask_TryActiveGA:ReceiveAbortAI(OwnerController, ControlledPawn)
    local abilityCls = self:GetAbilityClass(OwnerController, ControlledPawn)
    FunctionUtil:CancelGA(ControlledPawn, abilityCls)
    
    self:FinishTask(OwnerController, ControlledPawn)
    self:FinishExecute(false)
end

return BTTask_TryActiveGA
