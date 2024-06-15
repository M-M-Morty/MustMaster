require "UnLua"

local G = require("G")
local os = require("os")
local utils = require("common.utils")
local ai_utils = require("common.ai_utils")

local BTTask_Base = require("ai.BTCommon.BTTask_Base")
local BTTask_ObserveConfig = Class(BTTask_Base)


local Sin = UE.UKismetMathLibrary.DegSin  -- Sin(30) = 0.5
local Cos = UE.UKismetMathLibrary.DegCos


function BTTask_ObserveConfig:Execute(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    if nil == Target then
        G.log:error("yj", "BTTask_ObserveConfig Target nil")
        return ai_utils.BTTask_Failed
    end
    
    -- 生成内中外圈
    self:GenerateAllCircle(Pawn)

    -- 随机连续移动的次数
    local MoveCnt = math.random(self.MinMoveCnt, self.MaxMoveCnt)

    -- 生成观察路径
    local AIControl = Pawn:GetAIServerComponent()
    AIControl.ObservePath = {}
    self:GenerateObservePath(Controller, Pawn, MoveCnt)

    local S = ""
    for i = 1, #AIControl.ObservePath do
        S = S .. " - (" .. utils.ToString(AIControl.ObservePath[i]) .. ")"
    end
    G.log:debug("yjj", "BTTask_ObserveConfig ObservePath %s", S)

    -- 观察路径索引重置为1
    BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    BB:SetValueAsInt("ObserveIndex", 1)

    return ai_utils.BTTask_Succeeded
end

function BTTask_ObserveConfig:GenerateAllCircle(Pawn)
    if Pawn.AllCircle ~= nil then
        return
    end

    Pawn.AllCircle = {}

    local DivideAngle = self.DivideAngle
    local InnerRadius = self.InnerRadius
    local MiddleRadius = self.MiddleRadius
    local OutRadius = self.OutRadius

    -- 内中外三圈
    for i = 1, 3 do
        local R = i == 1 and InnerRadius or i == 2 and MiddleRadius or i == 3 and OutRadius or 0
        if 0 == R then
            goto continue
        end

        local DivideCnt = 360 // DivideAngle
        local Circle = {}
        local Scale = i
        for j = 0, DivideCnt - 1 do
            local x = math.floor(R * Cos(DivideAngle * j))
            local y = math.floor(R * Sin(DivideAngle * j))
            local Point = {x, y, 0}
            table.insert(Circle, Point)
        end
        table.insert(Pawn.AllCircle, Circle)

        ::continue::
    end

    for i = 1, #Pawn.AllCircle do
        local S = ""
        for j = 1, #Pawn.AllCircle[i] do
            S = S .. " - (" .. utils.ToString(Pawn.AllCircle[i][j]) .. ")"
        end
        G.log:debug("yjj", "BTTask_ObserveConfig Pawn.AllCircle - %s", S)
    end
end

-- 生成观察路径
function BTTask_ObserveConfig:GenerateObservePath(Controller, Pawn, MoveCnt)

    local AIControl = Pawn:GetAIServerComponent()

    local Loop = 1000
    while Loop > 0 do
        local Index = self:GenerateObservePointIndex(Controller, Pawn)
        local Point = Pawn.AllCircle[Index[1]][Index[2]]
        if not self:HasObserveIndex(Pawn, Point) then
            table.insert(AIControl.ObservePath, Point)
            self.PreIndex = Index
        end

        if #AIControl.ObservePath >= MoveCnt then
            break
        end

        Loop = Loop - 1
    end
end

-- 根据前一个观察路径点索引生成下一个索引
function BTTask_ObserveConfig:GenerateObservePointIndex(Controller, Pawn)
    --[[
        移动策略：
        1.优先(概率为QieDirRatio)切向移动，其次径向移动
        2.切向上优先(概率为SameDirRatio)朝同一个方向移动

        X代表径向移动，Y代表切向移动，DY代表切向方向
    ]]

    local AIControl = Pawn:GetAIServerComponent()

    if #AIControl.ObservePath == 0 then
        self.PreIndex = self:GetCurLocationIndex(Controller, Pawn)
        self.DY = math.random(100) <= 50 and 1 or -1
    end

    local X, Y = self.PreIndex[1], self.PreIndex[2]

    local QieDirRatio = self.QieDirRatio
    local SameDirRatio = self.SameDirRatio

    local r = math.random(100)
    local OldX, OldY = X, Y
    if r <= QieDirRatio then
        -- 切向移动
        Y = self:_RandY(Pawn, Y, self.DY)
        self.DY = math.random(100) <= SameDirRatio and self.DY or -self.DY
    else
        -- 径向移动
        X = self:_RandX2(Pawn, X)
    end

    -- G.log:debug("yjj", "BTTask_ObserveConfig (%s, %s) - %s - %s", X, Y, self.DY, r <= QieDirRatio)

    return {X, Y}
end

-- 获取离当前位置最近的观察点索引
function BTTask_ObserveConfig:GetCurLocationIndex(Controller, Pawn)

    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local Target = BB:GetValueAsObject("TargetActor")
    
    local Location = Pawn:K2_GetActorLocation()

    local MinDis = -1
    local RetIndex = {1, 1}

    for i = 1, #Pawn.AllCircle do
        for j = 1, #Pawn.AllCircle[i] do

            local OffsetLoc = UE.FVector()
            OffsetLoc:Set(Pawn.AllCircle[i][j][1], Pawn.AllCircle[i][j][2], Pawn.AllCircle[i][j][3])

            -- local TargetPawn = Target:GetInstigator()
            -- local TargetTransform = TargetPawn:GetTransform()
            -- local Loc = UE.UKismetMathLibrary.TransformLocation(TargetTransform, OffsetLoc)

            local TargetLocation = Target:K2_GetActorLocation()
            local Loc = UE.UKismetMathLibrary.Add_VectorVector(TargetLocation, OffsetLoc)

            local Dis = UE.UKismetMathLibrary.Vector_Distance(Loc, Location)
            MinDis = MinDis == -1 and Dis or MinDis

            -- G.log:debug("yjj", "BTTask_ObserveConfig %s, %s-%s, %s(%s)", utils.ToString(self.PreIndex), i, j, Dis, MinDis)

            if Dis < MinDis then
                MinDis = Dis
                RetIndex = {i, j}
            end
        end
    end

    G.log:debug("yjj", "BTTask_ObserveConfig:GetCurLocationIndex %s", utils.ToString(RetIndex))

    return RetIndex
end

function BTTask_ObserveConfig:HasObserveIndex(Pawn, Point)
    local AIControl = Pawn:GetAIServerComponent()
    
    for i = 1, #AIControl.ObservePath do
        if Point[1] == AIControl.ObservePath[i][1] and Point[2] == AIControl.ObservePath[i][2] then
            return true
        end
    end

    return false
end 

function BTTask_ObserveConfig:_RandX2(Pawn, X)
    local r = math.random(100)
    if r < 50 then
        X = X - 1
    else
        X = X + 1
    end

    -- 边界判断
    X = math.min(X, #Pawn.AllCircle)
    X = math.max(X, 1)
    return X
end

function BTTask_ObserveConfig:_RandY(Pawn, Y, DY)
    Y = Y + DY

    -- 环状 - 首尾相连
    Y = Y > #Pawn.AllCircle[1] and 1 or Y
    Y = Y < 1 and #Pawn.AllCircle[1] or Y
    return Y
end

return BTTask_ObserveConfig
