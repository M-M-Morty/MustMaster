--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR panzibin
-- @DATE ${date} ${time}
--

require "UnLua"

---@type BTDecorator_CheckAngleToFindTarget_C
local BTDecorator_CheckAngleToFindTarget = Class()

local DebugAngleHeight = 0.01
local DebugNumSides = 12
local N = UE.FVector(0,0,1)
local DebugTickness = 5

function BTDecorator_CheckAngleToFindTarget:PerformConditionCheckAI(Controller,Pawn)
    local AngleRangeList = self.AngleRangeList
    if AngleRangeList:Length() == 0 then return false end
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
	local Target = BB and BB:GetValueAsObject("TargetActor")
	if not Target then return false end
	local StartPos,TargetPos = Pawn:K2_GetActorLocation(),Target:K2_GetActorLocation()
    TargetPos.Z = StartPos.Z
	local ForVec = Pawn:GetActorForwardVector()
    local TowardVec = UE.UKismetMathLibrary.Normal(UE.UKismetMathLibrary.Subtract_VectorVector(TargetPos, StartPos))
    local DotValue = UE.UKismetMathLibrary.Dot_VectorVector(ForVec,TowardVec)
    local CrossValue = UE.UKismetMathLibrary.Cross_VectorVector(ForVec, TowardVec)
    local Var = math.abs(CrossValue.Z) / CrossValue.Z
    local Angle = math.deg(math.acos(DotValue)) * Var
    local Res = nil
    local UseOr,ShowDebug = self.UseOr,self.ShowDebug
    for i = 1, AngleRangeList:Length() do
        local Info = AngleRangeList:Get(i)
        local MinAngle,MaxAngle = Info.MinAngle,Info.MaxAngle
        local Compare = (MinAngle <= Angle) and (Angle <= MaxAngle)
        if Res == nil then
            Res = Compare
        else
            if UseOr == true then
                Res = Res or Compare
            else
                Res = Res and Compare
            end
        end
        if ShowDebug then
            local Dir = UE.UKismetMathLibrary.RotateAngleAxis(ForVec, (MaxAngle + MinAngle) / 2, N)
            local Pos = StartPos
            Pos.Z = Target:K2_GetActorLocation().Z
            UE.UKismetSystemLibrary.DrawDebugConeInDegrees(Pawn, Pos, Dir, self.DebugLength, math.abs(MaxAngle - MinAngle)/2, DebugAngleHeight, 
            DebugNumSides, self.Color, self.DebugTime, DebugTickness)
        end
    end
    return Res
end

return BTDecorator_CheckAngleToFindTarget