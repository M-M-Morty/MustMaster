--
-- DESCRIPTION
--
-- @COMPANY tencent
-- @AUTHOR dougzhang
-- @DATE 2023/04/11
--

---@type BP_NPCMoveViaPoint

require "UnLua"
local math = require("math")
local G = require("G")
local ActorBase = require("actors.common.interactable.base.base_character")
local EdUtils = require("common.utils.ed_utils")
local SubsystemUtils = require("common.utils.subsystem_utils")
local BPConst = require("common.const.blueprint_const")
local Component = require("common.component")
local ComponentBase = require("common.componentbase")

local M = Component(ComponentBase)

function M:LogInfo(...)
    G.log:info_obj(self, ...)
end

function M:LogDebug(...)
    G.log:debug_obj(self, ...)
end

function M:LogWarn(...)
    G.log:warn_obj(self, ...)
end

function M:LogError(...)
    G.log:error_obj(self, ...)
end

function M:Initialize(Initializer)
    Super(M).Initialize(self, Initializer)
    self.RootWayPointID = nil
    --self.WayPointID = nil
    --self.GotoIndex = -1
    --self.iIndexModeAdd = 1-- 处理原路返回情况
    self.fCurSplineLength = 0.0
    self.bMoving = false
    self.startLocation = nil
    self.targetLocation = nil
    self.bGotoTarget = false
    self.AfterInitWayPoint_CB = nil
    self.bTriggerByUser = false
end

function M:GotoNext(index)
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    local WayPointActor = Owner:GetEditorActor(self.WayPointID)
    if not WayPointActor then
        return
    end
    WayPointActor:MakeOwnerId(Owner:GetEditorID())
    self.GotoIndex = index + self.iIndexModeAdd
    local CurPointsNum = WayPointActor:GetPointsNum()
    self:LogInfo("zsf", "[npc_move_via_point_lua] GotoNext %s %s %s %s %s", self.WayPointID, index, self.GotoIndex, CurPointsNum, self:IsMoveViaSplie())
    if  self.GotoIndex >= 0 and self.GotoIndex < CurPointsNum then
        local translation = WayPointActor:GetPointLocation(self.GotoIndex)
        if Owner.GetController then
            local Controller = Owner:GetController()
            if Controller then
                --self:LogInfo("zsf", "[npc_move_via_point_lua] GotoNext %s %s %s %s", index, translation, Controller, Controller:GetControlRotation())
                Owner.bTriggered = true
                if not self:IsMoveViaSplie() then
                    UE.UAIBlueprintHelperLibrary.SimpleMoveToLocation(Controller, translation)
                end
            end
        end
        self.bMoving = true
        if Owner.StartMove then
            Owner:StartMove()
        end
    end
end

function M:IsMoveViaSplie()
    local Owner = self:GetOwner()
    if not Owner then
        return false
    end
    local WayPointActor = Owner:GetEditorActor(self.WayPointID)
    if not WayPointActor then
        return false
    end
    --self:LogInfo("zsf", "[npc_move_via_point_lua] IsMoveViaSpline %s", WayPointActor.bMoveViaSpline)
    return WayPointActor.bMoveViaSpline
end

function M:IsWayPointEditorID(ActorId)
    local EditorId = tostring(ActorId):sub(1,5)
    return EditorId == "10101"
end

function M:SetWayPointID(WayPointID)
    if not WayPointID or WayPointID == "" then
        self.WayPointID = self.RootWayPointID
    else
        self.WayPointID = WayPointID
    end
    local Owner = self:GetOwner()
    if Owner then
        if Owner.SetMobility then
            Owner:SetMobility(self:IsMoveViaSplie())
        end
    end
end

function M:ChildReadyNotify(ActorId)
    if not self:IsWayPointEditorID(ActorId) then
        return
    end
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    local WayPointID = Owner:GetActorIdSingle("WayPoint")
    self:SetWayPointID(WayPointID)
    self.RootWayPointID = self.WayPointID
    local WayPointActor = Owner:GetEditorActor(self.WayPointID)
    if WayPointActor then
        WayPointActor:MakeOwnerId(Owner:GetEditorID())
        if Owner.SetWayPointActor then
            Owner:SetWayPointActor(WayPointActor)
        end
    end
    if Owner:IsServer() then
        if Owner.CharacterMovement then
            self.fSpeed = Owner.CharacterMovement:GetMaxSpeed()
        end
    end
    if Owner.fMoveSpeed then
        self.fSpeed = Owner.fMoveSpeed
        if Owner.CharacterMovement then
            Owner.CharacterMovement.MaxWalkSpeed = self.fSpeed
        end
    end
    local moveType = self:GetMoveType()
    if moveType ~= Enum.E_NPCMoveType.BeTrigger and
        moveType ~= Enum.E_NPCMoveType.TriggerOnce and
        moveType ~= Enum.E_NPCMoveType.TriggerByMission then
        self:TriggerAtWayPointIndex(Owner, -1)
    end
    if self.AfterInitWayPoint_CB then
        self.AfterInitWayPoint_CB(self.WayPointID)
    end
    --self:LogInfo("zsf", "[npc_move_via_point_lua] 11 %s %s %s %s %s %s", G.GetDisplayName(self), G.GetDisplayName(self:GetOwner()), self.WayPointID, Owner:GetEditorID(), ActorId, Owner:GetEditorActor(self.WayPointID))
end

function M:TriggerAtWayPointIndex(Owner, index)
    self:ReachIndex(index, Owner)
end

function M:SetMoveType(moveType)
    local Owner = self:GetOwner()
    if Owner then
        local WayPointActor = Owner:GetEditorActor(self.WayPointID)
        if WayPointActor then
            WayPointActor.eNPCMoveType = moveType
        end
    end
end

function M:GetMoveType()
    local Owner = self:GetOwner()
    if Owner then
        local WayPointActor = Owner:GetEditorActor(self.WayPointID)
        if WayPointActor then
            return WayPointActor.eNPCMoveType
        end
    end
    return Enum.E_NPCMoveType.BeTrigger
end

function M:IsPlayer(OtherActor)
    local Owner = OtherActor:GetOwner()
    local PlayerControl = UE.UGameplayStatics.GetPlayerController(self:GetWorld(), 0)
    return Owner == PlayerControl
end

function M:DoReachIndexAction(index, OtherActor, ActionStruct)
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    local FinalDelayTime = 0.0
    local TalkStr = nil
    if ActionStruct then
        local Action = ActionStruct["Action"]
        if OtherActor and OtherActor.GetEditorID then
            if Action == Enum.E_ReachIndexAction.None then
                local Param = ActionStruct["Param"]
            elseif Action == Enum.E_ReachIndexAction.Delay then
                local DelayTime = ActionStruct["DelayTime"]
                FinalDelayTime = FinalDelayTime + DelayTime
            elseif Action == Enum.E_ReachIndexAction.Talk then
                local Param = ActionStruct["Param"]
                TalkStr = Param
            end
        end
    end
    if index == self.GotoIndex then
        if TalkStr then
            local IsServer = Owner:IsServer()
            local Str = tostring(IsServer) .. TalkStr
            utils.PrintString(Str, UE.FLinearColor(0, 1, 0, 1), 2)
        end

        local World = Owner:GetWorld()
        utils.DoDelay(World, FinalDelayTime,
                function()
                    local moveType = self:GetMoveType()
                    if self:IsLastPoint(index) then -- 到达当前路点的最后一个点
                        local WayPointActor = Owner:GetEditorActor(self.WayPointID)
                        if WayPointActor then
                            if (self.iIndexModeAdd == 1) then -- 最后一个点只处理继续往下走的情况
                                local ChildWayPointNum = WayPointActor:GetChildWayPointNum()
                                if (ChildWayPointNum > 0) then -- 正向走，走到终点寻找儿子路点继续走
                                    self:SetWayPointID(WayPointActor:GetChildWayPointID())
                                    self.GotoIndex = -1
                                    self.fCurSplineLength = 0.0
                                    self:TriggerAtWayPointIndex(OtherActor, -1)
                                    return
                                else
                                    if moveType == Enum.E_NPCMoveType.AutoMove_ReverseAtEnd then -- 走到没有儿子的路点并且往回走
                                        self.iIndexModeAdd = -1
                                    elseif moveType == Enum.E_NPCMoveType.AutoMove_BackStartAtEnd or
                                        moveType == Enum.E_NPCMoveType.TriggerOnce then
                                        self:SetWayPointID(self.RootWayPointID)
                                        self.GotoIndex = -1
                                        self.fCurSplineLength = 0.0
                                        self:TriggerAtWayPointIndex(OtherActor, -1)
                                        return
                                    end
                                end
                            end
                        end
                    elseif self:IsStartPoint(index) then -- 到达当前路点的开始点
                        local WayPointActor = Owner:GetEditorActor(self.WayPointID)
                        if WayPointActor then
                            if (self.iIndexModeAdd == -1) then -- 开始点只处理往回走的情况
                                local ParentWayPointNum = WayPointActor:GetParentWayPointNum()
                                if (ParentWayPointNum > 0) then -- 如果有 Parent 继续往上走，如果没有判断是否反转下
                                    self:SetWayPointID(WayPointActor:GetParentWayPointID())
                                    local WayPointsNum = self:GetWayPointsNum(self.WayPointID)
                                    index = WayPointsNum
                                else
                                    self.iIndexModeAdd = 1
                                end
                            end
                        end
                    end
                    if moveType == Enum.E_NPCMoveType.BeTrigger then -- 需要主动触发
                        --self:LogInfo("zsf", "[npc_move_via_point_lua] BeTrigger %s %s %s %s", self.WayPointID, index, self.GotoIndex, self:IsPlayer(OtherActor))
                    end
                    self:GotoNext(index)
                end)
    end
end

function M:IsStartPoint(index)
    return index == 0
end

function M:GetWayPointsNum(WayPointId)
    local Owner = self:GetOwner()
    if Owner then
        if self.WayPointID then
            local WayPointActor = Owner:GetEditorActor(WayPointId)
            if WayPointActor then
                return WayPointActor:GetPointsNum()
            end
        end
    end
    return 0
end

function M:IsLastPoint(index)
    return index+1 == self:GetWayPointsNum(self.WayPointID)
end

function M:CanReachIndex(index, OtherActor, ActionStruct)
    local Owner = self:GetOwner()
    if not Owner then
        return false
    end
    local moveType = self:GetMoveType()
    if moveType == Enum.E_NPCMoveType.BeTrigger then -- 需要主动触发
        return self:IsPlayer(OtherActor) and (index == self.GotoIndex)
    elseif moveType == Enum.E_NPCMoveType.TriggerByMission then -- 任务主动触发
        return self.bTriggerByUser
    else
        return OtherActor == Owner  -- 自己达到目标点
    end
end

function M:ReachIndex(index, OtherActor, ActionStruct)
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    --self:LogInfo("zsf", "[npc_move_via_point_lua] ReachIndex %s %s %s %s %s %s %s %s", self.WayPointID, self.bTriggerByUser, index, index==self.GotoIndex, OtherActor==Owner, OtherActor, Owner, self:IsLastPoint(index))
    if self:CanReachIndex(index, OtherActor, ActionStruct) then
        self.iCurIndex = index
        self:DoReachIndexAction(index, OtherActor, ActionStruct)
        self.bTriggerByUser = false
    end
    if OtherActor == Owner then
        self.bMoving = false
        if index == self.GotoIndex then
            if Owner.StopMove then
                Owner:StopMove(self:IsLastPoint(index))
            end
        end
    end
    if Owner.ReachIndex then
        local WayPointActor = Owner:GetEditorActor(self.WayPointID)
        if WayPointActor then
            local ChildWayPointNum = WayPointActor:GetChildWayPointNum()
            local bLast = (ChildWayPointNum <= 0) and self:IsLastPoint(index)
            Owner:ReachIndex(index, OtherActor, bLast)
        end
    end
end

function M:ReceiveBeginPlay()
    Super(M).ReceiveBeginPlay(self)
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    self.oldLocation = Owner:K2_GetActorLocation()
    self.startLocation = self.oldLocation
end

function M:UpdateOwnerLocationAndRotation(Location, Rotator)
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    if Owner.UpdateOwnerLocationAndRotation then
        Owner:UpdateOwnerLocationAndRotation(Location, Rotator)
    else
        Owner:K2_SetActorLocationAndRotation(Location, Rotator, false, nil, false)
    end
end

function M:Move_Server(Owner)
    local TargetLocation = self.targetLocation
    local NewLocation = TargetLocation
    local moveType = self:GetMoveType()
    if (self:IsStartPoint(self.GotoIndex) and self.iIndexModeAdd == 1) or
            (self:IsLastPoint(self.GotoIndex) and self.iIndexModeAdd == -1) or
            self.bGotoTarget or
            moveType == Enum.E_NPCMoveType.TriggerByMission then
        NewLocation = UE.UKismetMathLibrary.VInterpTo_Constant(self.oldLocation, TargetLocation, 0.01, self.fSpeed*3.0)
        --self:LogInfo("zsf", "[npc_move_via_point_lua] Move_Server %s %s %s %s %s %s", self.WayPointID, NewLocation, TargetLocation, self.iIndexModeAdd, self.GotoIndex, self.fSpeed)
    end
    local Tangent = NewLocation - self.oldLocation
    Tangent.z = 0 -- 角色不躺平
    --TODO(设置动画播放速率)
    if not UE.UKismetMathLibrary.Vector_IsNearlyZero(Tangent) then
        local Tangent = UE.UKismetMathLibrary.Normal(Tangent)
        local Rotator = UE.UKismetMathLibrary.Conv_VectorToRotator(Tangent)
        --self:LogInfo("zsf", "[npc_move_via_point_lua] Move_Server %s %s %s %s %s", self.WayPointID, NewLocation, self.iIndexModeAdd, self.GotoIndex, self.bGotoTarget)
        self:UpdateOwnerLocationAndRotation(NewLocation, Rotator)
    end
    self.oldLocation = NewLocation
    --Owner:K2_SetActorLocationAndRotation(TargetLocation, Rotator, false, nil, false)
    --self.Location = Owner:K2_GetActorLocation()
end

function M:Move_Client(Owner)
    self:Move_Server(Owner)
    --if not self.oldLocation then
    --    self.oldLocation = self.Location
    --end
    --local NewLocation = UE.UKismetMathLibrary.VInterpTo(self.oldLocation, self.Location, 0.1, 1.0)
    --local Tangent = NewLocation - self.oldLocation
    --local Tangent = UE.UKismetMathLibrary.Normal(Tangent)
    --local Rotator = UE.UKismetMathLibrary.Conv_VectorToRotator(Tangent)
    --Owner:K2_SetActorLocationAndRotation(NewLocation, Rotator, false, nil, false)
    --self.oldLocation = NewLocation
end

function M:Move(Owner)
    self:Move_Server(Owner)
end

function M:GetLocationAtSpline()
    if self.bGotoTarget then
        return self.targetLocation
    else
        local Location = self.oldLocation
        local Owner = self:GetOwner()
        if self.WayPointID and Owner then
            local WayPointActor = Owner:GetEditorActor(self.WayPointID)
            if WayPointActor then
                local PoinsNum = WayPointActor:GetPointsNum()
                if self.GotoIndex >= 0 and self.GotoIndex < PoinsNum  then
                    local TargetIndex = self.GotoIndex
                    local SplineDistance = WayPointActor.Spline:GetDistanceAlongSplineAtSplinePoint(TargetIndex)
                    local offset = self.fSpeed / 30.0
                    local fCurSplineLength = math.abs(self.fCurSplineLength)
                    fCurSplineLength = fCurSplineLength + offset * self.iIndexModeAdd
                    if (self.iIndexModeAdd == 1 and fCurSplineLength > SplineDistance) or
                            (self.iIndexModeAdd == -1 and fCurSplineLength < SplineDistance) then
                        fCurSplineLength = SplineDistance
                    end
                    --local moveType = self:GetMoveType()
                    --if moveType == Enum.E_NPCMoveType.TriggerByMission then
                    --    self.oldLocation = Owner:K2_GetActorLocation()
                    --    fCurSplineLength = SplineDistance
                    --end
                    Location = WayPointActor.Spline:GetLocationAtDistanceAlongSpline(fCurSplineLength, UE.ESplineCoordinateSpace.World)
                    local Tangent = WayPointActor.Spline:GetTangentAtDistanceAlongSpline(fCurSplineLength, UE.ESplineCoordinateSpace.World)
                    if self.iIndexModeAdd == -1 then
                        Tangent = Tangent * -1
                        self.fCurSplineLength = fCurSplineLength * -1
                    else
                        self.fCurSplineLength = fCurSplineLength
                    end
                    local Rotator = UE.UKismetMathLibrary.Conv_VectorToRotator(Tangent)
                end
            end
        end
        return Location
    end
end

function M:SetGotToTarget(TargetLocation)
    self.bGotoTarget = true
    self.targetLocation = TargetLocation
end

function M:ReceiveTick(DeltaSeconds)
    if not self:IsMoveViaSplie() then
        return
    end
    local Owner = self:GetOwner()
    if not Owner then
        return
    end
    self.targetLocation = self:GetLocationAtSpline()
    self:Move(Owner)
end

return M

