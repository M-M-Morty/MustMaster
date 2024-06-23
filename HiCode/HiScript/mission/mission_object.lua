
local MissionObject = Class()
local MissionGroupTable = require ("common.data.mission_group_data").data
local MissionActTable = require ("common.data.mission_act_data").data
local MissionTable = require("common.data.mission_data").data
local MissionEventTable = require("common.data.event_description_data").data
local MissionUtil = require("mission.mission_utils")
local G = require("G")


--- Initialize
---@param MissionContainer AvatarMissionComponent
---@param MissionID integer
function MissionObject:ctor(MissionComponent, MissionID, bNew)
    self.Component = MissionComponent
    self.MissionID = MissionID
    self.bArriveMissionArea = false
    self.MissionDistance = 0
    self.MissionVerticalDistance = 0
    self.TrackTargetPosition = nil
    self.bNewMission = bNew
    self.EventUpdateNum = 0  -- 用于辅助判断bNewMission是否为true
end

function MissionObject:GetMissionData()
    return self.Component:FindMissionData(self.MissionID)
end

-- 获取任务所属章的ID
--- return: int
function MissionObject:GetMissionGroupID()
    local MissionData = self:GetMissionData()
    if MissionData == nil then
        return nil
    end
    return MissionData.Identifier.MissionGroupID
end

-- 获取任务所属幕的ID
--- return: int
function MissionObject:GetMissionActID()
    local MissionData = self:GetMissionData()
    if MissionData == nil then
        return nil
    end
    return MissionData.Identifier.MissionActID
end

-- 获取任务ID
--- return: int
function MissionObject:GetMissionID()
    return self.MissionID
end

-- 获取当前任务Event
--- return: /Game/Blueprints/Mission/MissionRecordData/MissionEventData.MissionEventData
function MissionObject:GetMissionEventData()
    local MissionData = self:GetMissionData()
    if MissionData == nil then
        return nil
    end
    if MissionData.ActiveEvents:Length() > 0 then
        return self:GetMissionData().ActiveEvents:Get(1)
    end
    return nil
end


-- 获取当前任务EventID
--- return: int
function MissionObject:GetMissionEventID()
    local MissionEventData = self:GetMissionEventData()
    if MissionEventData == nil then
        return 0
    end
    return MissionEventData.MissionEventID
end

-- 获取任务所属章的名称
--- return: string
function MissionObject:GetMissionGroupName()
    local MissionGroupTableData = MissionGroupTable[self:GetMissionGroupID()]
    if MissionGroupTableData == nil then
        return ""
    end
    return MissionGroupTableData.Name
end

-- 获取任务所属幕的名称
--- return: string
function MissionObject:GetMissionActName()
    local MissionActTableData = MissionActTable[self:GetMissionActID()]
    if MissionActTableData == nil then
        return ""
    end
    return MissionActTableData.Name
end

-- 获取任务所属幕的副标题
--- return: string
function MissionObject:GetMissionActSubname()
    local MissionActTableData = MissionActTable[self:GetMissionActID()]
    if MissionActTableData == nil or MissionActTableData.Subname == nil then
        return ""
    end
    return MissionActTableData.Subname
end

-- 获取任务名称
--- return: string
function MissionObject:GetMissionName()
    local MissionTableData = MissionTable[self:GetMissionID()]
    if MissionTableData == nil then
        return ""
    end
    return MissionTableData.Name
end

-- 获取任务类型
--- return: int
function MissionObject:GetMissionType()
    local MissionTableData = MissionTable[self:GetMissionID()]
    if MissionTableData == nil then
        return 0
    end
    return MissionTableData.Type
end

-- 获取任务追踪图标显示类型
--- return: EMissionTrackIconType
function MissionObject:GetMissionTrackIconType()
    local MissionData = self:GetMissionData()
    if MissionData == nil then
        return nil
    end
    return MissionData.TrackIconType
end

-- 获取任务当前节点描述
--- return: string
function MissionObject:GetMissionEventDesc()
    local MissionEventTableData = MissionEventTable[self:GetMissionEventID()]
    if MissionEventTableData == nil then
        return ""
    end
    if string.find(MissionEventTableData.content, "%s") or string.find(MissionEventTableData.content, "%d") then
        local MissionEventData = self:GetMissionEventData()
        return string.format(MissionEventTableData.content, MissionEventData.Record.Progress)
    else
        return MissionEventTableData.content
    end
end

-- 获取任务当前节点详细描述
--- return: string
function MissionObject:GetMissionEventDetailDesc()
    local MissionEventData = MissionEventTable[self:GetMissionEventID()]
    if MissionEventData == nil then
        return ""
    end
    return MissionEventData.description
end

-- 获取任务所属区域
--- return: string
function MissionObject:GetMissionRegion()
    return ""
end

--- 获取任务奖励列表
--- return: table
function MissionObject:GetMissionAwards()
    local MissionData = MissionTable[self:GetMissionID()]
    if not MissionData or not MissionData.RewardItems then
        return {}
    end
    return MissionData.RewardItems
end

-- 任务是否能被追踪
--- return: bool
function MissionObject:IsTrackable()
    if self:IsBlock() then
        return false
    end
    return true
end

-- 任务是否需要AutoTrack
--- return: bool
function MissionObject:IsAutoTrack()
    return true
end

-- 任务是否在追踪
--- return: bool
function MissionObject:IsTracking()
    return self:GetMissionID() == self.Component.TrackingMissionID
end

-- 是否已经到达任务区域
--- return: bool
function MissionObject:IsArriveMissionArea()
    -- todo
end

-- 是否在任务面板显示(废弃)
function MissionObject:IsShowInTaskPanel()
    return true
end

-- 是否在任务面板显示
function MissionObject:IsHide()
    if not self.Component then
        return true
    end

    local MissionActID = self:GetMissionActID()
    if MissionActID ~= 0 then
        -- 任务幕内包含的任务，要先判断对应的任务幕是否Start
        local MissionActData = self.Component:GetMissionActData(MissionActID)
        if not MissionActData or MissionActData.State ~= Enum.EMissionActState.Start then
            -- 对应的任务幕还没到Start状态，不显示
            return true
        end
    end

    local MissionID = self:GetMissionID()
    local MissionTableData = MissionTable[self:GetMissionID()]
    if MissionTableData == nil or MissionTableData.IsHide then
        return true
    end

    return false
end

-- 任务是否被阻塞
function MissionObject:IsBlock()
    return MissionUtil.GetBlockReason(self:GetMissionID(), self.Component) ~= 0
end

-- 是否是新任务
function MissionObject:IsNewMission()
    return self.bNewMission
end

-- 获取离目标任务的距离
--- return: int
function MissionObject:GetMissionDistance()
    local TrackTargetPosition = self:GetFirstTrackTargetPosition()
    if TrackTargetPosition == nil then
        return nil
    end
    local PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self.Component.actor:GetWorld(), 0)
    local PlayerPosition = PlayerPawn:K2_GetActorLocation()
    local Distance = UE.UKismetMathLibrary.Vector_Distance(PlayerPosition, TrackTargetPosition) / 100.0
    return math.floor(Distance)
end

-- 获取离目标任务的垂直距离
--- return: float
function MissionObject:GetMissionVerticalDistance()
    local TrackTargetPosition = self:GetFirstTrackTargetPosition()
    if TrackTargetPosition == nil then
        return nil
    end
    local PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self.Component.actor:GetWorld(), 0)
    local PlayerPosition = PlayerPawn:K2_GetActorLocation()
    local VerticalDistance = (TrackTargetPosition.Z - PlayerPosition.Z) / 100.0
    return VerticalDistance
end

function MissionObject:GetMissionTrackDesc()
    return ""
end

function MissionObject:OnMissionEventUpdated()
    self.EventUpdateNum = self.EventUpdateNum + 1
    if self.EventUpdateNum >= 2 then
        -- EventUpdateNum为1时，此时任务第一个Event Start，仍然表示为新任务。直到第二个Event进入或者第一个Event结束，才不是新任务。
        self.bNewMission = false
    end
end

function MissionObject:GetFirstTrackTarget()
    local MissionEventData = self:GetMissionEventData()
    if MissionEventData == nil then
        return nil
    end
    if MissionEventData.TrackTargetList:Length() == 0 then
        return nil
    end
    return MissionEventData.TrackTargetList:GetRef(1)
end

function MissionObject:GetFirstTrackTargetPosition()
    local TrackTarget = self:GetFirstTrackTarget()
    if TrackTarget == nil then
        return nil
    end
    return self:GetTrackTargetPosition(TrackTarget)
end

function MissionObject:GetTrackTargetList()
    local MissionEventData = self:GetMissionEventData()
    if MissionEventData == nil then
        return nil
    end
    return MissionEventData.TrackTargetList
end

function MissionObject:GetTrackTargetPositionByIndex(Index)
    local MissionEventData = self:GetMissionEventData()
    if MissionEventData == nil then
        return nil
    end
    if Index > MissionEventData.TrackTargetList:Length() then
        return nil
    end
    local TrackTarget = MissionEventData.TrackTargetList:GetRef(Index)
    return self:GetTrackTargetPosition(TrackTarget)
end

function MissionObject:GetTrackTargetPosition(TrackTarget)
    local Position = nil
    if TrackTarget.TrackTargetType == Enum.ETrackTargetType.Actor then
        local ActorPosition = self.Component:QueryActorPositionByMissionID(TrackTarget.ActorID, self.MissionID)
        if ActorPosition ~= nil then
            Position = ActorPosition
        end
    elseif TrackTarget.TrackTargetType == Enum.ETrackTargetType.Position then
        Position = TrackTarget.RelativePosition
    end
    return Position
end

return MissionObject