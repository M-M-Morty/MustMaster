require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_Confront = Class(BTTask_Base)


function BTTask_Confront:Execute(Controller, Pawn)
    self.MovePath = {}
    
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local TargetActor = BB:GetValueAsObject("TargetActor")
    local SelfLocation = Pawn:K2_GetActorLocation()
    local TargetLocation = TargetActor:K2_GetActorLocation()

    local NormalForward = UE.UKismetMathLibrary.Normal(SelfLocation - TargetLocation)
    for idx = 1, self.ConfrontMoveNum do
        if math.random(0, 1) == 1 then
            NormalForward = UE.UKismetMathLibrary.RotateAngleAxis(NormalForward, self.ConfrontAngle, UE.FVector(0, 0, 1))
        else
            NormalForward = UE.UKismetMathLibrary.RotateAngleAxis(NormalForward, -self.ConfrontAngle, UE.FVector(0, 0, 1))
        end
        local MovePoint = TargetLocation + NormalForward * Pawn:GetAIServerComponent().ConfrontDis
        table.insert(self.MovePath, MovePoint)
    end

    if #self.MovePath == 0 then
        G.log:error("yj", "BTTask_Confront MovePath empty")
        return ai_utils.BTTask_Failed
    end

    ai_utils.EvMoveToLocation(Controller, Pawn, self.MovePath[1])
end

function BTTask_Confront:Tick(Controller, Pawn, DeltaSeconds)
    if self.MaxMoveTime == nil then
        self.MaxMoveTime = 3.0
    end

    self.MaxMoveTime = self.MaxMoveTime - DeltaSeconds

    local SelfLocation = Pawn:K2_GetActorLocation()
    if UE.UKismetMathLibrary.Vector_Distance2D(SelfLocation, self.MovePath[1]) < 50 or self.MaxMoveTime < 0 then
        self.MaxMoveTime = 3.0
        self.RemainTimeInter = 0.5
        table.remove(self.MovePath, 1)
        if #self.MovePath == 0 then
            return ai_utils.BTTask_Succeeded
        end
    end

    if self.RemainTimeInter ~= nil and self.RemainTimeInter > 0 then
        self.RemainTimeInter = self.RemainTimeInter - DeltaSeconds
    else
        ai_utils.EvMoveToLocation(Controller, Pawn, self.MovePath[1])
    end


    if self.bDebug then
        for idx = 1, #self.MovePath do
            UE.UKismetSystemLibrary.DrawDebugPoint(Pawn, self.MovePath[idx] + UE.FVector(0, 0, 0), 20, UE.FLinearColor(0, 0, 0), 0.1)
        end
    end
end

function BTTask_Confront:OnBreak(Controller, Pawn)
    Controller:StopMovement()
end

return BTTask_Confront
