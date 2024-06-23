
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')

local NavPathClass = Class()

function NavPathClass:ctor(Controller, Pawn)
    self.Controller = Controller
    self.Pawn = Pawn
    self.nOutNavIndex = 0
    self.nPathIndex = 2
    self.tbPathPoints = {}
    self.tbPathPointDirection = {}
end

function NavPathClass:ResetMovingData()
    self.nOutNavIndex = 0
    self.nPathIndex = 2
    self.tbPathPoints = {}
    self.tbPathPointDirection = {}
end

function NavPathClass:IsEmpty()
    return #self.tbPathPoints == 0
end

function NavPathClass:PointNum()
    return #self.tbPathPoints
end

function NavPathClass:ReachGoal()
    return self.nPathIndex > #self.tbPathPoints
end

function NavPathClass:GetCurrentTarget()
    if self.nPathIndex <= #self.tbPathPoints then
        return self.tbPathPoints[self.nPathIndex], self.tbPathPointDirection[self.nPathIndex]
    end
end

function NavPathClass:GetCurrentInNavTarget()
    if self:IsCurrentSegmentInNav() then
        return self:GetCurrentTarget()
    end

    local nCurrentIndex = math.max(self.nPathIndex, self.nOutNavIndex + 1)
    if nCurrentIndex <= #self.tbPathPoints then
        return self.tbPathPoints[nCurrentIndex], self.tbPathPointDirection[nCurrentIndex]
    end
end

function NavPathClass:GetFinalTarget()
    if not self:IsEmpty() then
        local nEndPathIndex = #self.tbPathPoints
        return self.tbPathPoints[nEndPathIndex], self.tbPathPointDirection[nEndPathIndex]
    end
end

function NavPathClass:IsCurrentSegmentInNav()
    return self.nPathIndex ~= self.nOutNavIndex
end

function NavPathClass:InEndSegment()
    return self.nPathIndex == #self.tbPathPoints
end

function NavPathClass:MoveNextSegment()
    self.nPathIndex = self.nPathIndex + 1
end

function NavPathClass:GetRandomReachablePoint(InRange, InLocation)
    local OutLocation = UE.FVector(0,0,0)
    if not InLocation then
        InLocation = self.Pawn:K2_GetActorLocation()
    end
    UE.UNavigationSystemV1.K2_GetRandomReachablePointInRadius(self.Pawn, InLocation, OutLocation, InRange, nil, nil)
    return OutLocation
end

function NavPathClass:ProjectPointToNavigation(Location, QueryExtent)
    local OutLocation = UE.FVector(0,0,0)
    QueryExtent = QueryExtent or UE.FVector(0,0,0)

    local bSuccess = UE.UNavigationSystemV1.K2_ProjectPointToNavigation(self.Pawn, Location, OutLocation, nil, nil, QueryExtent)
    return bSuccess, OutLocation
end

function NavPathClass:CreateNavPath(StartLocation, EndLocation, OutNavLocation)
    local NavigationPath = UE.UNavigationSystemV1.FindPathToLocationSynchronously(self.Pawn, StartLocation, EndLocation, self.Pawn, nil)
    if NavigationPath then
        return self:UpdateNavPath(NavigationPath.PathPoints, OutNavLocation)
    end
end

function NavPathClass:UpdateNavPath(InPathPoints, OutNavLocation)
    self:ResetMovingData()

    local ueLastV3
    local pathLen = InPathPoints:Length()
    if pathLen >= 2 then

        if OutNavLocation then
            table.insert(self.tbPathPoints, OutNavLocation)
            ueLastV3 = OutNavLocation
            self.nOutNavIndex = 2
        end

        for i = 1, pathLen do
            local uev3 = InPathPoints:Get(i)
            table.insert(self.tbPathPoints, uev3)

            if ueLastV3 then
                local dir = uev3 - ueLastV3
                dir.Z = 0
                dir:Normalize()
                table.insert(self.tbPathPointDirection, dir)
            end
            ueLastV3 = uev3
        end
        table.insert(self.tbPathPointDirection, self.tbPathPointDirection[#self.tbPathPointDirection])
        return true
    end
end


function NavPathClass.GetFaceToTarget(Pawn, StartLocation, EndLocation, QueryExtent)
    local NavigationPath = UE.UNavigationSystemV1.FindPathToLocationSynchronously(Pawn, StartLocation, EndLocation, Pawn, nil)
    if NavigationPath and NavigationPath.PathPoints:Length() >= 2 then
        local TargetLocation = NavigationPath.PathPoints:Get(2)
        return TargetLocation
    else
        local OutLocation = UE.FVector(0,0,0)
        QueryExtent = QueryExtent or UE.FVector(0,0,0)

        -- 如果没有找到路径，有可能是本身处于不可达区域
        local bTargetProject = UE.UNavigationSystemV1.K2_ProjectPointToNavigation(Pawn, EndLocation, OutLocation, nil, nil, UE.FVector(0,0,0))
        if bTargetProject then
            -- 如果目标点处于导航网格内，尝试扩大范围查找离自己最近的有效点
            local bFindProject = UE.UNavigationSystemV1.K2_ProjectPointToNavigation(Pawn, StartLocation, OutLocation, nil, nil, QueryExtent)
            if bFindProject then
                return OutLocation
            end
        end
    end
    return EndLocation
end

return NavPathClass

