require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SprintToLocation = Class(BTTask_Base)


-- 冲向固定目标点
-- 根据冲刺时长计算出冲刺速度
function BTTask_SprintToLocation:Execute(Controller, Pawn)

    local AIControl = Pawn:GetAIServerComponent()
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    self.TargetLocation = BB:GetValueAsVector("MoveToLocation")
    if not self.TargetLocation then
        return
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    self.TargetLocation.Z = SelfLocation.Z

    local Dis = UE.UKismetMathLibrary.Vector_Distance(SelfLocation, self.TargetLocation)

    if self.SprintMontage then
        Pawn.AppearanceComponent:Server_PlayMontage(self.SprintMontage, self.MontagePlayRate)
    end

    self.SprintSpeed = Dis / self.TotalSprintSeconds

    G.log:debug("yj", "BTTask_SprintToLocation ##########@@@@@@@@@@@@@@@@ CosDelta.%s DegreesDelta.%s self.TotalSprintSeconds.%s self.TurnSpeed.%s", CosDelta, DegreesDelta, self.TotalSprintSeconds, self.TurnSpeed)
end

function BTTask_SprintToLocation:Tick(Controller, Pawn, DeltaSeconds)

    Pawn.AppearanceComponent:SmoothActorLocation(self.TargetLocation, self.SprintSpeed, DeltaSeconds)

    self.TotalSprintSeconds = self.TotalSprintSeconds - DeltaSeconds

    if self.TotalSprintSeconds < 0 then

        if self.SprintMontage then
            Pawn.AppearanceComponent:Server_StopMontage()
        end
        
        return ai_utils.BTTask_Succeeded
    end
end

return BTTask_SprintToLocation
