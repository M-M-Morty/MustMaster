--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local G = require("G")
local FunctionUtil = require('CP0032305_GH.Script.common.utils.function_utl')
local ai_utils = require("common.ai_utils")
local AINavPath = require('CP0032305_GH.Script.ai.ai_nav_path')
local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_FaceToTarget_C
local BTTask_FaceToTarget_C = Class(BTTask_Base)


function BTTask_FaceToTarget_C:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.targetKey.SelectedKeyType, objClass)
    if isActor then
        local faceActor = BB:GetValueAsObject(self.targetKey.SelectedKeyName)
        if not faceActor then
            return ai_utils.BTTask_Failed
        end
        self.faceToActor = faceActor
    else
        self.faceToPoint = BB:GetValueAsVector(self.targetKey.SelectedKeyName)
    end

    local tarLocation, precision
    if self.faceToActor then
        tarLocation = self.faceToActor:K2_GetActorLocation()
        precision = self.precisionToActor
    else
        tarLocation = self.faceToPoint
        precision = self.precisionToLocation
    end

    if self.lookNavPathFirstTarget then
        local AgentLocation = Pawn:GetNavAgentLocation()
        tarLocation = AINavPath.GetFaceToTarget(Pawn, AgentLocation, tarLocation, self.queryNavExtent)
    end

    local lootAtRot = UE.UKismetMathLibrary.FindLookAtRotation(Pawn:K2_GetActorLocation(), tarLocation)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(Pawn:K2_GetActorRotation(), lootAtRot)
    if math.abs(deltaRot.Yaw) < precision then
        return ai_utils.BTTask_Succeeded
    end

    local RotateYaw = 0
    if deltaRot.Yaw > 135 then
        RotateYaw = 180
    elseif deltaRot.Yaw > 0 then
        RotateYaw = 90
    elseif deltaRot.Yaw < -135 then
        RotateYaw = -180
    elseif deltaRot.Yaw < 0 then
        RotateYaw = -90
    end

    local playRate = self.turnAnimPlayRate
    if self.checkQuickFollow and Pawn.GetQuickFollowAction then
        local action = Pawn:GetQuickFollowAction()
        if action then
            playRate = playRate * 2
        end
    end
    
    self.waitingAnimTime = 0
    Pawn.ChararacteStateManager.turnAnimPlayDuration = 3.0      -- 先设置一个初始值，会由AnimBP覆盖
    Pawn.ChararacteStateManager:NotifyEvent('TurnInPlaceStart', RotateYaw, playRate)
end

function BTTask_FaceToTarget_C:Tick(Controller, Pawn, DeltaSeconds)
    self.waitingAnimTime = self.waitingAnimTime + DeltaSeconds
    if self.waitingAnimTime > Pawn.ChararacteStateManager.turnAnimPlayDuration then
        if self.waitSyncDelay > 0 and FunctionUtil:IsGHCharacter(Pawn) then
            local current = UE.UGameplayStatics.GetTimeSeconds(Pawn)
            if (not Pawn.waitSyncStart or UE.UKismetMathLibrary.NearlyEqual_FloatFloat(Pawn.waitSyncStart, 0, 0.1)) then
                Pawn.waitSyncStart = current
            elseif current - Pawn.waitSyncStart > self.waitSyncDelay then --delay end
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Succeeded
            end
        else --direct end
            self:FinishTask(Controller, Pawn)
            return ai_utils.BTTask_Succeeded
        end
    end
end

function BTTask_FaceToTarget_C:FinishTask(Controller, Pawn)
    Pawn.ChararacteStateManager:NotifyEvent('TurnInPlaceEnd')
    if Pawn.waitSyncStart then
        Pawn.waitSyncStart = 0
    end
end

function BTTask_FaceToTarget_C:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    self:FinishExecute(false)
end

return BTTask_FaceToTarget_C