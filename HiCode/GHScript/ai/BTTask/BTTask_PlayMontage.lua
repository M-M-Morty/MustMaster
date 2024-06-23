--
-- 【Simple】 to play a montage
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ai_utils = require("common.ai_utils")
local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_PlayMontage_C
local BTTask_PlayMontage_C = Class(BTTask_Base)


function BTTask_PlayMontage_C:Execute(Controller, Pawn)
    if (not self.montage) or (not Pawn.ChararacteStateManager) then
        return ai_utils.BTTask_Failed
    end

    if FunctionUtil:FloatZero(self.duration) then
        self.duration = UE.UHiUtilsFunctionLibrary.GetMontagePlayLength(self.montage)
    end
    Pawn.ChararacteStateManager:NotifyEvent('PlayMontage', self.montage)
    self.expireTime = UE.UGameplayStatics.GetTimeSeconds(Pawn) + self.duration
end

function BTTask_PlayMontage_C:Tick(Controller, Pawn, DeltaSeconds)
    if UE.UGameplayStatics.GetTimeSeconds(Pawn) >= self.expireTime then
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Succeeded
    end
end

function BTTask_PlayMontage_C:FinishTask(Controller, Pawn)
    if Pawn and Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:NotifyEvent('StopMontage')
    end
end

function BTTask_PlayMontage_C:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    self:FinishExecute(false)
end

return BTTask_PlayMontage_C