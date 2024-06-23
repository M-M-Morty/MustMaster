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

---@type BTTask_WaitPathMove
local BTTask_WaitPathMove = Class(BTTask_Base)

function BTTask_WaitPathMove:InitActionNodeData(Controller, Pawn)
    if Pawn then
        Pawn.path_move_stuck = false
    end
    self.CachedNavTargetLocation = nil
    self.NavPath = AINavPath.new(Controller, Pawn)
end

function BTTask_WaitPathMove:Execute(Controller, Pawn)
    self:InitActionNodeData(Controller, Pawn)
    
    local TargetLocation = self:GetTargetLocation(Controller, Pawn)
    if not TargetLocation then
        return ai_utils.BTTask_Failed
    end

    self.reachTargetRadius = self:GetAcceptableRadius(Controller, Pawn)

    local AgentLocation = Pawn:GetNavAgentLocation()
    local RawDis = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, TargetLocation)
    if RawDis < self.reachTargetRadius then
        return ai_utils.BTTask_Succeeded
    end
    
    self.NavPath:CreateNavPath(AgentLocation, TargetLocation)

    if self.NavPath:IsEmpty() then
        -- 如果没有找到路径，有可能是本身处于不可达区域
        local bTargetProject = self.NavPath:ProjectPointToNavigation(TargetLocation)
        if bTargetProject then
            -- 如果目标点处于导航网格内，尝试扩大范围查找离自己最近的有效点
            local bFindProject, OutLocation = self.NavPath:ProjectPointToNavigation(AgentLocation, self.queryNavExtent)
            if bFindProject then
                -- 重新计算路径
                self.NavPath:CreateNavPath(OutLocation, TargetLocation, AgentLocation)
            end
        end
    end

    if self.NavPath:IsEmpty() then
        Pawn.path_move_stuck = true
        G.log:warn('lizhi', 'BTTask_WaitPathMove:Execute NavPath ERROR')
        return ai_utils.BTTask_Failed
    end

    if self.NavPath:InEndSegment() then
        if self:HasReachedCurrentTarget(Controller, Pawn, 1.0) then
            -- 处理目标点与当前点可能不处于同一个连通网格的到达情况
            local radius = self.reachTargetRadius * 2
            local distance = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, TargetLocation)
            if distance < radius then
                G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick reach target')
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Succeeded
            else
                Pawn.path_move_stuck = true
                G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick reach target ERROR')
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Failed
            end
        end
    end

    local breakDirectionDelta = self:GetBreakDirectionDelta(Controller, Pawn)
    if breakDirectionDelta > self.breakDelta then
        G.log:warn('lizhi', 'BTTask_WaitPathMove:Execute direction break %f', breakDirectionDelta)
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Failed
    end
    
    -- self:SetDebugPathPoints(Controller, Pawn)

    self.FinalTargetLocation = TargetLocation
    self.waitingAnimTime = 0
    self.updateTimeStamp = -1
    self.detectMoveStuckDuration = 0
    Pawn.ChararacteStateManager.startMoveAnimPlayDuration = 1.0      -- 先设置一个初始值，会由AnimBP覆盖
    Pawn.ChararacteStateManager:NotifyEvent('WaitMoveTo')
end

function BTTask_WaitPathMove:Tick(Controller, Pawn, DeltaSeconds)

    self.waitingAnimTime = self.waitingAnimTime + DeltaSeconds
    if self.waitingAnimTime < Pawn.ChararacteStateManager.startMoveAnimPlayDuration then
        -- 启动动画中同时转向
        local CurrentRotation = Pawn:K2_GetActorRotation()
        local AgentLocation = Pawn:GetNavAgentLocation()
        local currentTarget = self.NavPath:GetCurrentInNavTarget()
        local ToTarget = currentTarget - AgentLocation
        ToTarget.Z = 0
        local ToTargetRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(ToTarget)
        local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(CurrentRotation, ToTargetRotation)
        if math.abs(deltaRot.Yaw) < self.breakDelta then
            local LerpRotation = UE.UKismetMathLibrary.RInterpTo(CurrentRotation, ToTargetRotation, DeltaSeconds, 2.0)
            Pawn:K2_SetActorRotation(LerpRotation, false)
        end
        return
    else
        if self.updateTimeStamp < 0 then
            self.updateTimeStamp = UE.UGameplayStatics.GetTimeSeconds(Pawn)
            self.moveStuckLocation = Pawn:GetNavAgentLocation()
        end
    end

    if self.NavPath:IsEmpty() then
        G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick NavPath Empty')
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Failed
    end

    if self.NavPath:ReachGoal() then
        G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick ReachGoal')
        self:FinishTask(Controller, Pawn)
        return ai_utils.BTTask_Succeeded
    end

    local AgentLocation = Pawn:GetNavAgentLocation()
    -- 处理目标点移动的情况
    if self.NavPath:IsCurrentSegmentInNav() then
        local current = UE.UGameplayStatics.GetTimeSeconds(Pawn)
        if current - self.updateTimeStamp > self.updateInterval then
            self.updateTimeStamp = current

            local TargetLocation = self:GetTargetLocation(Controller, Pawn)
            if not UE.UKismetMathLibrary.EqualEqual_VectorVector(TargetLocation, self.FinalTargetLocation) then
                self.FinalTargetLocation = TargetLocation

                -- 重新计算一次路径
                self.NavPath:CreateNavPath(AgentLocation, TargetLocation)
                if self.NavPath:IsEmpty() then
                    Pawn.path_move_stuck = true
                    G.log:warn('lizhi', 'BTTask_WaitPathMove:TargetLocationChanged NavPath ERROR')
                    self:FinishTask(Controller, Pawn)
                    return ai_utils.BTTask_Failed
                end

                local breakDirectionDelta = self:GetBreakDirectionDelta(Controller, Pawn)
                if breakDirectionDelta > self.breakDelta then
                    G.log:warn('lizhi', 'BTTask_WaitPathMove:RecalcPath direction break %f', breakDirectionDelta)
                    self:FinishTask(Controller, Pawn)
                    return ai_utils.BTTask_Failed
                end
            end
        end
    end

    -- 处理卡住的情况
    self.detectMoveStuckDuration = self.detectMoveStuckDuration + DeltaSeconds
    if UE.UKismetMathLibrary.EqualEqual_VectorVector(self.moveStuckLocation, AgentLocation, 10) then
        if self.detectMoveStuckDuration > self.detectMoveStuckTime then
            Pawn.path_move_stuck = true
            G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick move stuck over time')
            self:FinishTask(Controller, Pawn)
            return ai_utils.BTTask_Failed
        end
    else
        self.detectMoveStuckDuration = 0
        self.moveStuckLocation = AgentLocation
    end

    local currentTarget = self.NavPath:GetCurrentTarget()
    local Direction = currentTarget - AgentLocation
    Direction.Z = 0
    Direction:Normalize()
    Pawn:AddMovementInput(Direction)
    
    if self.NavPath:InEndSegment() then
        if self:HasReachedCurrentTarget(Controller, Pawn, 1.0) then
            -- 处理目标点与当前点可能不处于同一个连通网格的到达情况
            local TargetLocation = self:GetTargetLocation(Controller, Pawn)
            local radius = self.reachTargetRadius * 2
            local distance = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, TargetLocation)
            if distance < radius then
                G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick reach target')
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Succeeded
            else
                Pawn.path_move_stuck = true
                G.log:warn('lizhi', 'BTTask_WaitPathMove:Tick reach target ERROR')
                self:FinishTask(Controller, Pawn)
                return ai_utils.BTTask_Failed
            end
        end
    else
        if self:HasReachedCurrentTarget(Controller, Pawn, 0.05) then
            self.NavPath:MoveNextSegment()
            -- local breakDirectionDelta = self:GetBreakDirectionDelta(Controller, Pawn)
            -- if breakDirectionDelta > self.breakDelta then
            --     G.log:warn('lizhi', 'BTTask_WaitPathMove:MoveNextSegment direction break %f', breakDirectionDelta)
            --     self:FinishTask(Controller, Pawn)
            --     return ai_utils.BTTask_Failed
            -- end
        end
    end
end

function BTTask_WaitPathMove:HasReachedCurrentTarget(Controller, Pawn, RadiusMultiplier)
    local AgentLocation = Pawn:GetNavAgentLocation()
    local currentTarget, currentTargetDirection = self.NavPath:GetCurrentTarget()

    local ToTarget = currentTarget - AgentLocation
    local SegmentDot = ToTarget:Dot(currentTargetDirection)
    if SegmentDot < 0 then
        return true
    end

    local radius = self.reachTargetRadius * RadiusMultiplier
    local distance = UE.UKismetMathLibrary.Vector_Distance(AgentLocation, currentTarget)
    if distance < radius then
        return true
    end
end

function BTTask_WaitPathMove:GetBreakDirectionDelta(Controller, Pawn)
    -- 处理Actor朝向与速度方向相差过大的情况
    local AgentLocation = Pawn:GetNavAgentLocation()
    local currentTarget = self.NavPath:GetCurrentTarget()
    local ToTarget = currentTarget - AgentLocation
    local ToTargetRotation = UE.UKismetMathLibrary.Conv_VectorToRotator(ToTarget)
    local deltaRot = UE.UKismetMathLibrary.NormalizedDeltaRotator(ToTargetRotation, Pawn:K2_GetActorRotation())
    return math.abs(deltaRot.Yaw)
end

function BTTask_WaitPathMove:GetTargetLocation(Controller, Pawn)
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local tarLocation
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.targetKey.SelectedKeyType, objClass)
    if isActor then
        local targetActor = BB:GetValueAsObject(self.targetKey.SelectedKeyName)
        if targetActor then
            local ActorLocation = targetActor:GetNavAgentLocation()

            -- 检测目标点是否处于导航网格之内
            local bTargetProject, FixedLocation = self.NavPath:ProjectPointToNavigation(ActorLocation, self.queryNavExtent)
            if bTargetProject then
                tarLocation = FixedLocation
            else
                G.log:warn('lizhi', 'BTTask_WaitPathMove:GetTargetLocation ActorLocation is out of Navigation')
            end
        end
    else
        -- 静态点直接取Cache结果
        if self.CachedNavTargetLocation then
            tarLocation = self.CachedNavTargetLocation
        else
            local staticLocation = BB:GetValueAsVector(self.targetKey.SelectedKeyName)
            -- 检测目标点是否处于导航网格之内
            local bTargetProject, FixedLocation = self.NavPath:ProjectPointToNavigation(staticLocation, self.queryNavExtent)
            if bTargetProject then
                tarLocation = FixedLocation
                self.CachedNavTargetLocation = FixedLocation
            else
                G.log:warn('lizhi', 'BTTask_WaitPathMove:GetTargetLocation StaticLocation is out of Navigation')
            end
        end
    end
    return tarLocation
end

function BTTask_WaitPathMove:GetAcceptableRadius(Controller, Pawn)
    local AcceptableRadius = self.acceptableRadius
    local BB = UE.UAIBlueprintHelperLibrary.GetBlackboard(Controller)
    local objClass = UE.UClass.Load("/Script/AIModule.BlackboardKeyType_Object")
    local isActor = UE.UKismetMathLibrary.ClassIsChildOf(self.targetKey.SelectedKeyType, objClass)
    if isActor then
        local targetActor = BB:GetValueAsObject(self.targetKey.SelectedKeyName)
        local NavMovement = targetActor:GetMovementComponent()
        if NavMovement then
            AcceptableRadius = AcceptableRadius + NavMovement.NavAgentProps.AgentRadius
        end
    end
    return AcceptableRadius
end

function BTTask_WaitPathMove:FinishTask(Controller, Pawn)
    if Controller then
        Controller:StopMovement()
    end
    if Pawn and Pawn.ChararacteStateManager then
        Pawn.ChararacteStateManager:RemoveStateTagDirect("StateGH.WaitMoveTo")
    end
end

function BTTask_WaitPathMove:ReceiveAbortAI(OwnerController, ControlledPawn)
    self:FinishTask(OwnerController, ControlledPawn)
    if ControlledPawn and ControlledPawn.SetLastAbortAction then
        ControlledPawn:SetLastAbortAction('BTTask_WaitPathMove')
    end
    self:FinishExecute(false)
end

function BTTask_WaitPathMove:SetDebugPathPoints(Controller, Pawn)
    if not self.NavPath:IsEmpty() then
        for _, v in ipairs(self.NavPath.tbPathPoints) do
            Pawn.ChararacteStateManager.DebugNavPath:Add(v)
        end
    end
end

return BTTask_WaitPathMove
