--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/07/20
--

---@BP_WayPoint_C

require "UnLua"
local math = require("math")
local os = require("os")
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_item")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")

local M = Class(ActorBase)

function M:Initialize(...)
    Super(M).Initialize(self, ...)
    self.Tag = "WayPoint"
    self.OwnerIdList = {}
    self.isOverlapping = {}
    self.ParentActorIdList = {}
end

function M:MakeOwnerId(OwnerID)
    self.OwnerIdList[OwnerID] = true
    self:LogInfo("zsf", "[waypoint_lua] MakeOwnerId %s", OwnerID)
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    local Points = self.Spline:GetNumberOfSplinePoints()
    for ind=0,Points-1 do
        self.Spline:SetSplinePointType(ind, self.eType, true)
        local Location = self.Spline:GetLocationAtSplinePoint(ind, UE.ESplineCoordinateSpace.World)
        local CollisionComp = self:AddComponentByClass(UE.USphereComponent, false, UE.FTransform.Identity, false)
        local HitResult = UE.FHitResult()
        CollisionComp:K2_SetWorldLocation(Location, false, HitResult, false)
        --local Location0 = self.Spline:GetLocationAtSplinePoint(ind, UE.ESplineCoordinateSpace.Local)
        --self:LogInfo("zsf", "[waypoint_lua] ReceiveBeginPlay %s %s %s %s", self:GetEditorID(), ind, Location0, self.fSphereRadius)
        CollisionComp:SetCollisionProfileName(self.Tag, true)
        CollisionComp:SetSphereRadius(self.fSphereRadius, true)
        CollisionComp.OnComponentBeginOverlap:Add(self, self.OnBeginOverlap_Sphere)
        CollisionComp.OnComponentEndOverlap:Add(self, self.OnEndOverlap_Sphere)
        CollisionComp.ComponentTags = {tostring(ind), self.Tag}
        local Tags = CollisionComp.ComponentTags
        --self:LogInfo("zsf", "[waypoint] ReceiveBeginPlay %s %s %s %s", Points, Location, CollisionComp, Tags)
    end
end

function M:DoMergeToParentActorIdList(IdList)
    for _,ActorId in ipairs(IdList) do
        if not self.ParentActorIdList[ActorId] then
            self:LogInfo("zsf", "[waypoint_lua] DoMergeToParentActorIdList %s %s", self:GetEditorID(), ActorId)
            self.ParentActorIdList[ActorId] = true
        end
    end
end

function M:RandIndex(len)
    math.randomseed(os.time())
    return math.random(len)
end

function M:GetParentWayPointID()
    local ids = {}
    for ActorId,_ in pairs(self.ParentActorIdList) do
        table.insert(ids, ActorId)
    end
    return ids[self:RandIndex(#ids)]
end

function M:GetParentWayPointNum()
    local cnt = 0
    for ActorId,_ in pairs(self.ParentActorIdList) do
        cnt = cnt + 1
    end
    return cnt
end

function M:GetChildWayPointID()
    local ids = {}
    for ActorId,_ in pairs(self.ActorIdList) do
        table.insert(ids, ActorId)
    end
    self:LogInfo("zsf", "[waypoint_lua] GetChildWayPointID %s %s %s", #ids, self:GetChildWayPointNum(), self:RandIndex(#ids))
    return ids[self:RandIndex(#ids)]
end

function M:GetChildWayPointNum()
    local cnt = 0
    for ActorId,_ in pairs(self.ActorIdList) do
        cnt = cnt + 1
    end
    return cnt
end

function M:MergeToParentActorIdList()
    for ActorId,_ in pairs(self.ActorIdList) do
        local ChildActor = self:GetEditorActor(ActorId)
        if ChildActor and ChildActor.DoMergeToParentActorIdList then
            ChildActor:DoMergeToParentActorIdList({self:GetEditorID()})
        end
    end
end

function M:AllChildReadyServer()
    self:MergeToParentActorIdList()
    Super(M).AllChildReadyServer(self)
end

function M:AllChildReadyClient()
    self:MergeToParentActorIdList()
    Super(M).AllChildReadyClient(self)
end

function M:GetSplineLength()
    return self.Spline:GetSplineLength()
end

function M:GetTransformAtDistanceAlongSpline(Distance)
    return self.Spline:GetTransformAtDistanceAlongSpline(Distance, UE.ESplineCoordinateSpace.World, false)
end

function M:GetPointsNum()
    return self.Spline:GetNumberOfSplinePoints()
end

function M:GetPointLocation(index)
    return self.Spline:GetLocationAtSplinePoint(index, UE.ESplineCoordinateSpace.World)
end

function M:OnEndOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex)
    self.isOverlapping[OtherActor] = false
    self:LogInfo("zsf", "[waypoint_lua] OnEndOverlap_Sphere %s %s", G.GetDisplayName(OtherActor), self.isOverlapping)
end

function M:OnBeginOverlap_Sphere(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
    for OwnerId,_ in pairs(self.OwnerIdList) do
        self:LogInfo("zsf", "[waypoint_lua] OnBeginOverlap_Sphere %s %s %s %s", G.GetDisplayName(OtherActor), self.isOverlapping, self:GetEditorID(), OwnerId)
    end
    --if self.isOverlapping[OtherActor] then
    --    return
    --end
    local Tags = OverlappedComponent.ComponentTags
    local index = tonumber(Tags:Get(1))
    if self.OwnerIdList then
        for OwnerId,_ in pairs(self.OwnerIdList) do
            local OwnerActor = self:GetEditorActor(OwnerId)
            if OwnerActor and OwnerActor.NPCMoveViaPoint then
                local ActionStruct = self.mapAction:FindRef(index)
                OwnerActor.NPCMoveViaPoint:ReachIndex(index, OtherActor, ActionStruct)
                self.isOverlapping[OtherActor] = true
            end
        end
    end
end

function M:ReceiveEndPlay()
    local Collisions = self:GetComponentsByTag(UE.USphereComponent, self.Tag)
    for ind=1,Collisions:Length() do
        local Collision = Collisions:Get(ind)
        Collision.OnComponentBeginOverlap:Remove(self, self.OnBeginOverlap_Sphere)
        Collision.OnComponentEndOverlap:Remove(self, self.OnEndOverlap_Sphere)
        self:LogInfo("zsf", "[waypoint] ReceiveEndPlay %s %s", ind, Collision)
    end
    Super(M).ReceiveEndPlay(self)
end

return M