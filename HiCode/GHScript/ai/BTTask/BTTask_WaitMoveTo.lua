--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


require "UnLua"

local G = require("G")
local ai_utils = require("common.ai_utils")
local AINavPath = require('CP0032305_GH.Script.ai.ai_nav_path')

local BTTask_Base = require("ai.BTCommon.BTTask_Base")

---@type BTTask_WaitMoveTo_C
local BTTask_WaitMoveTo_C = Class(BTTask_Base)


---@class BTNavMoveType
local BTNavMoveType = 
{
    InNav = 0,
    OutNavToInNav = 1,
}


function BTTask_WaitMoveTo_C:Execute(Controller, Pawn)
    local TargetLocation = self:GetTargetLocation(Controller, Pawn)
    if not TargetLocation then
        return ai_utils.BTTask_Failed
    end

    self.reachTargetRadius = self.acceptableRadius
    local NavMovement = Pawn:GetMovementComponent()
    if NavMovement then
        self.reachTargetRadius = self.acceptableRadius + NavMovement.NavAgentProps.AgentRadius
    end

    local AgentLocation = Pawn:GetNavAgentLocation()
    local Dis = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, TargetLocation)
    if Dis < self.reachTargetRadius then
        return ai_utils.BTTask_Succeeded
    end
    
    self.NavMoveType = BTNavMoveType.InNav
    self.NavPath = AINavPath.new(Controller, Pawn)
    self.NavPath:CreateNavPath(AgentLocation, TargetLocation)

    if self.NavPath:IsEmpty() then
        -- 如果没有找到路径，有可能是本身处于不可达区域
        local bTargetProject = self.NavPath:ProjectPointToNavigation(TargetLocation)
        if bTargetProject then
            -- 如果目标点处于导航网格内，尝试扩大范围查找离自己最近的有效点
            local bFindProject, OutLocation = self.NavPath:ProjectPointToNavigation(AgentLocation, UE.FVector(500,500,500))
            if bFindProject then
                local FinalStartLocation = self.NavPath:GetRandomReachablePoint(100, OutLocation)

                -- 重新计算路径
                self.NavPath:CreateNavPath(FinalStartLocation, TargetLocation, AgentLocation)
                if not self.NavPath:IsEmpty() then

                    -- 设置当前移动模式为脱困模式
                    self.NavMoveType = BTNavMoveType.OutNavToInNav
                    self.OutNavToInNavLocation = FinalStartLocation
                    self.OutNavToInNavDirection = FinalStartLocation - AgentLocation
                    self.OutNavToInNavDirection.Z = 0
                    self.OutNavToInNavDirection:Normalize()
                end
            end
        end
    end

    if self.NavPath:IsEmpty() then
        G.log:warn("duzy", "BTTask_WaitMoveTo_C:Execute NavPath ERROR")
        return ai_utils.BTTask_Failed
    end

    self.waitingAnimTime = 0
    self.updateTimeStamp = -1
    Pawn.ChararacteStateManager.startMoveAnimPlayDuration = 1.0      -- 先设置一个初始值，会由AnimBP覆盖
    Pawn.ChararacteStateManager:NotifyEvent('WaitMoveTo')
end

function BTTask_WaitMoveTo_C:Tick(Controller, Pawn, DeltaSeconds)

    self.waitingAnimTime = self.waitingAnimTime + DeltaSeconds
    if self.waitingAnimTime < Pawn.ChararacteStateManager.startMoveAnimPlayDuration then
        return
    else
        if self.updateTimeStamp < 0 then
            self.updateTimeStamp = UE.UGameplayStatics.GetTimeSeconds(Pawn)
            if self.NavMoveType == BTNavMoveType.InNav then
                local TargetLocation = self:GetTargetLocation(Controller, Pawn)
                Controller:MoveToLocation(TargetLocation, 0, false)
            end
        end
    end

    local AgentLocation = Pawn:GetNavAgentLocation()

    if self.NavMoveType == BTNavMoveType.OutNavToInNav then
        local MoveDirection = self.OutNavToInNavLocation - AgentLocation
        MoveDirection.Z = 0
        MoveDirection:Normalize()

        local pathDotValue = self.OutNavToInNavDirection:Dot(MoveDirection)
        -- 处理从无效区域走入有效区域，有效区域的点有可能紧贴着导航网格，这里不使用距离判断是否到达，尝试一直走直到越过目标点
        if pathDotValue > -0.1 then
            Pawn:AddMovementInput(MoveDirection)
            return
        else
            -- 越过目标点，开始进入正常依赖当行网格的移动状态
            self.NavMoveType = BTNavMoveType.InNav

            -- 重新计算一次路径
            local TargetLocation = self:GetTargetLocation(Controller, Pawn)
            self.NavPath:CreateNavPath(AgentLocation, TargetLocation)
            if self.NavPath:IsEmpty() then
                G.log:warn("duzy", "BTTask_WaitMoveTo_C:ChangeMoveType NavPath ERROR")
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Failed
            end

            Controller:MoveToLocation(TargetLocation, 0, false)
            self.updateTimeStamp = UE.UGameplayStatics.GetTimeSeconds(Pawn)
            return
        end
    end

    if self.NavMoveType == BTNavMoveType.InNav then

        local TargetLocation = self:GetTargetLocation(Controller, Pawn)
        local NavFinalLocation = self.NavPath:GetFinalTarget()
        local Dis = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, NavFinalLocation)
        if Dis < self.reachTargetRadius then
            G.log:warn("duzy", "BTTask_WaitMoveTo_C reach target %f", Dis)
            self:FinishTask(Controller, Pawn)
            return ai_utils.BTTask_Succeeded
        end

        -- 处理目标点移动的情况
        local current = UE.UGameplayStatics.GetTimeSeconds(Pawn)
        if current - self.updateTimeStamp > self.updateInterval then
            self.updateTimeStamp = current

            local NavFinalLocation = self.NavPath:GetFinalTarget()
            if not UE.UKismetMathLibrary.EqualEqual_VectorVector(TargetLocation, NavFinalLocation) then
                -- 重新计算一次路径
                TargetLocation = self:GetTargetLocation(Controller, Pawn)
                self.NavPath:CreateNavPath(AgentLocation, TargetLocation)
                if self.NavPath:IsEmpty() then
                    G.log:warn("duzy", "BTTask_WaitMoveTo_C:TargetLocationChanged NavPath ERROR")
                    self:FinishTask(Controller, Pawn)
                    return ai_utils.BTTask_Failed
                end

                Controller:MoveToLocation(TargetLocation, 0, false)
                return
            end
        end
    end
end

function BTTask_WaitMoveTo_C:GetTargetLocation(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local tarLocation
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.targetKey.SelectedKeyType, objClass)
    if isActor then
        local faceActor = BB:GetValueAsObject(self.targetKey.SelectedKeyName)
        if faceActor then
            tarLocation = faceActor:GetNavAgentLocation()
        end
    else
        local facePoint = BB:GetValueAsVector(self.targetKey.SelectedKeyName)
        tarLocation = facePoint
    end
    return tarLocation
end

function BTTask_WaitMoveTo_C:FinishTask(Controller, Pawn)
    if Controller then
        Controller:StopMovement()
    end
    if Pawn and Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:RemoveStateTagDirect("StateGH.WaitMoveTo")
    end
    
end

function BTTask_WaitMoveTo_C:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    if ControlledPawn.SetLastAbortAction then
        ControlledPawn:SetLastAbortAction('BTTask_WaitMoveTo_C')
    end
    self:FinishExecute(false)
end


return BTTask_WaitMoveTo_C
