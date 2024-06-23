require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_SetRotationToTarget = Class(BTTask_Base)


function BTTask_SetRotationToTarget:Execute(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if Target == nil then
        return ai_utils.BTTask_Failed
    end

    local SelfLocation = Pawn:K2_GetActorLocation()
    local TargetLocation = Target:K2_GetActorLocation()
    local Forward = TargetLocation - SelfLocation
    local Rotation = UE.UKismetMathLibrary.Conv_VectorToRotator(Forward)

    if self.IgnoreZ then
        Rotation.Pitch = 0
    end

    -- 方案1
    -- 太暴力，不安全，有多个地方同时在改Rotation
    -- 在standalone模式下表现正常，但as client模式下会有抖动
    Pawn:K2_SetActorRotation(Rotation, false)

    -- G.log:debug("yj", "BTTask_SetRotationToTarget %s", Rotation)

    return ai_utils.BTTask_Succeeded
end


return BTTask_SetRotationToTarget
