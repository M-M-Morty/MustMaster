--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require('G')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local MissionConst = require('Script.mission.mission_const')
local FirmUtil = require("CP0032305_GH.Script.ui.view.ingame.Firm.FirmUtil")
local MissionUtil = require('Script.mission.mission_utils')
local MissionActTable = require("common.data.mission_act_data").data
local MissionTable = require("common.data.mission_data").data
local ConstTextTable = require("common.data.const_text_data").data

---@class MissionTypeNodeClass
---@field OwnerVM TaskMainVM
---@field ListType number
---@field MissionListField ViewmodelFieldArray
---@field ChapterListField ViewmodelFieldArray
local MissionTypeNodeClass = {}

---@class ChapterTreeNode
---@field TaskChapterID number
---@field TaskChapterName string
---@field TaskChapterActIndex string
---@field ListType number
---@field TaskListField ViewmodelFieldArray
local ChapterTreeNodeClass = {}

---@class UIMissionNode
---@field OwnerVM TaskMainVM
---@field Parent number
---@field MissionObject MissionObject
---@field MissionNotifyField ViewmodelField
local UIMissionNodeClass = {}

---@class HudTrackingState
local HudTrackingState =
{
    Hidden = 1,               -- 隐藏(没有任务追踪)
    Visible = 2,              -- 可见(有任务追踪)
    Interact = 3,             -- 新任务
    Finished = 4,             -- 任务完成
    Tracked = 5,              -- 可追踪
    Submit = 6,               -- 可提交
    PreMissionUnfinished = 7, -- 需要完成前置任务
}

---@class MissionNotifyState
local MissionNotifyState =
{
    Progress = 'Progress',
    Distance = 'Distance',
    ReTracking = 'ReTracking',
    All = 'all'
}

---@class MissionListType
local MissionListType =
{
    Mission = 1,
    Act = 2,
}

---@class MissionParent
local MissionParent =
{
    Act = 1,
    Type = 2,
}

---@class MissionBlockReason
local MissionBlockReason =
{
    "PREMISSION_TEXT_1001",
    "PREMISSION_TEXT_1002",
}

---@class HudTrackingMission
local HudTrackingMission = Class()

function HudTrackingMission:ctor(InOwnerVM)
    ---@type TaskMainVM
    self.OwnerVM = InOwnerVM
    self.HudTrackStateField = self.OwnerVM:CreateVMField(HudTrackingState.Hidden)
    self.HudTrackingMissionField = self.OwnerVM:CreateVMField(self.OwnerVM.INVALID_TASK_ID)
    self.HudTrackingMissionNotifyField = self.OwnerVM:CreateVMField(self.OwnerVM.INVALID_TASK_Notify) -- 用于数据变更后的消息通知

    self.TrackingMissionID = self.OwnerVM.INVALID_TASK_ID
    self.bWaitingForInteract = false
end

---@param MissionObject MissionObject
function HudTrackingMission:HudTracking(MissionObject)
    if MissionObject then
        self.TrackingMissionID = MissionObject:GetMissionID()
        self.HudTrackStateField:SetFieldValue(HudTrackingState.Tracked)

        self.HudTrackingMissionField:SetFieldValue(MissionObject:GetMissionID())
        self.HudTrackingMissionField:BroadcastValueChanged() -- 强行Broadcast，防止上个状态也是同一个missionid导致信息不更新
        FirmUtil.NotifyMissionChanged(MissionObject)
    end
end

function HudTrackingMission:HudUnTracking()
    local mission_id = self.TrackingMissionID
    self.TrackingMissionID = 0
    FirmUtil.NotifyMissionChanged(mission_id)
    --不打断任务完成动画，任务mission的服务端remove和客户端finish动画不同步
    if mission_id == self.HudTrackingMissionField:GetFieldValue() and not self.OwnerVM.bShowingTrackAnim then
        self.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
        self.HudTrackingMissionField:SetFieldValue(self.OwnerVM.INVALID_TASK_ID)
    end
end

function HudTrackingMission:OnMissionTracked()
    local MissionObject = self:GetTrackingMissionObject()
    if MissionObject then
        self.HudTrackStateField:SetFieldValue(HudTrackingState.Tracked)
        self.OwnerVM:SetTaskTracking(MissionObject, true)
    end
end

function HudTrackingMission:OnMissionProgressUpdate()
    -- local MissionObject = self:GetTrackingMissionObject()
    -- if MissionObject then
    self.HudTrackingMissionNotifyField:SetFieldValue(MissionNotifyState.Progress)
    self.HudTrackingMissionNotifyField:BroadcastValueChanged()
    -- end
end

function HudTrackingMission:OnMissionDistanceUpdate()
    local MissionObject = self:GetTrackingMissionObject()
    if MissionObject then
        self.HudTrackingMissionNotifyField:SetFieldValue(MissionNotifyState.Distance)
        self.HudTrackingMissionNotifyField:BroadcastValueChanged()
    end
end

function HudTrackingMission:OnMissionUnTracked()
    local TrackingMissionID = self.OwnerVM.CurrentTrackingTaskField:GetFieldValue()
    if TrackingMissionID ~= self.OwnerVM.INVALID_TASK_ID then
        self.HudTrackStateField:SetFieldValue(HudTrackingState.Visible)
    else
        self.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
    end
    self.HudTrackingMissionField:SetFieldValue(TrackingMissionID)
end

function HudTrackingMission:OnMissionSubmit()
    self.HudTrackStateField:SetFieldValue(HudTrackingState.Submit)
end

-- 追踪面板 当前任务开启追踪 动画播放完成，执行后续
function HudTrackingMission:OnStartTrackingAnimPlayEnd()
    self.OwnerVM:TaskTrackAnimFinished()
end

-- 追踪面板的新任务提示 显示时长结束后
function HudTrackingMission:OnInteractWaitEnd()
    self.bWaitingForInteract = false
    self.OwnerVM:TaskTrackAnimFinished()
end

-- 追踪面板的新任务提示动画播放完毕，执行后续
function HudTrackingMission:OnNewTaskAnimPlayEnd()
    self.bWaitingForInteract = true
    if self.OwnerVM:NextStateIsTracked() then
        self.OwnerVM:TaskTrackAnimFinished()
    end
end

-- 追踪面板的任务完成动画播放完毕，执行后续
function HudTrackingMission:OnFinishAnimPlayEnd()
    if self.TrackingMissionID == self.OwnerVM.currentTrackId then
        self.TrackingMissionID = 0
    end

    self.OwnerVM:TaskTrackAnimFinished()
end

function HudTrackingMission:GetTrackingMissionObject()
    local UIMissionNode = self.OwnerVM:GetUIMissionNode(self.TrackingMissionID)
    if UIMissionNode then
        return UIMissionNode.MissionObject
    end
end

function HudTrackingMission:OnReTrackingMission()
    local MissionObject = self:GetTrackingMissionObject()
    if MissionObject then
        self.HudTrackingMissionNotifyField:SetFieldValue(MissionNotifyState.ReTracking)
        self.HudTrackingMissionNotifyField:BroadcastValueChanged()
    end
end

---@param MissionObject MissionObject
---@param Arrow UImage
function HudTrackingMission:GetTrackingMissionDistanceText(MissionObject, Arrow)
    local MissionDistance = MissionObject:GetMissionDistance()
    local MissionHeights = MissionObject:GetMissionVerticalDistance()
    local DistanceText
    local heightText

    local DistanceLimit = MissionConst.MissionTrackHorizontalDistanceLimit or 80
    local HeightLimit = MissionConst.MissionTrackVerticalDistanceLimit or 3
    if not MissionDistance and not MissionHeights then
        local GetMissionTrackDesc = MissionObject:GetMissionTrackDesc()
        Arrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        if GetMissionTrackDesc == "" then
            return
        end
        return GetMissionTrackDesc
    end

    local MissionItem = MissionObject:GetFirstTrackTarget()
    if math.abs(MissionDistance) <= DistanceLimit and math.abs(MissionHeights) > HeightLimit and MissionDistance ~= 0 then
        Arrow:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if MissionHeights < 0 then
            heightText = ConstTextTable["QUEST_POSITION_TEXT_02"].Content
            Arrow:SetRenderScale(UE.FVector2D(1, -1))
        else
            heightText = ConstTextTable["QUEST_POSITION_TEXT_01"].Content
            Arrow:SetRenderScale(UE.FVector2D(1, 1))
        end
        MissionHeights = math.abs(MissionDistance)
        DistanceText = heightText .. math.floor(MissionHeights) .. 'm'
    else
        Arrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        if MissionDistance < 0 then
            MissionDistance = math.abs(MissionDistance)
        end
        
        if MissionDistance*100 <= MissionItem.Radius then
            
            DistanceText = "已到达任务区域"
        else
            DistanceText = math.floor(MissionDistance) .. 'm'
        end
    end
    return DistanceText
end

---@class TaskMainVM : ViewModelBase
local TaskMainVM = Class(ViewModelBaseClass)
TaskMainVM.INVALID_TASK_ID = 0
TaskMainVM.INVALID_TASK_Notify = ''

function TaskMainVM:ctor()
    Super(TaskMainVM).ctor(self)

    self.tbUIMissionNode = {}
    self.tbUIChapterHideList = {}
    self.tbUIMissionHideList = {}
    self.tbMissionTreeNode = {}
    self.tbUIMissionIdList = {}

    self.tbMissionTrackAnimState = {}
    self.tbMissionTrackId = {}

    self.CurrentSelectTaskField = self:CreateVMField(self.INVALID_TASK_ID)
    self.CurrentTrackingTaskField = self:CreateVMField(self.INVALID_TASK_ID)
    self.MissionTypeListField = self:CreateVMArrayField({})
    ---@type HudTrackingMission
    self.HudTrackingMission = HudTrackingMission.new(self)

    -- 这里注册MissionSystemModule，目前暂时使用Require的方式
    local MissionSystemModule = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_module')
    MissionSystemModule:InitModule(self)

    self:InitMissionSystem(MissionSystemModule)
end

function TaskMainVM:OnReleaseViewModel()
end

---@type InModule MissionSystemModule
function TaskMainVM:InitMissionSystem(InModule)
    self.MissionSystemModule = InModule

    local MissionList = self.MissionSystemModule:GetMissionList()
    self:InitMissionTree(MissionList)
end

function TaskMainVM:ClearMissionTree(NotBroadcast)
    for _, v in pairs(self.tbUIMissionNode) do
        v.MissionNotifyField:ReleaseVMObj()
    end
    self.tbUIMissionNode = {}
    self.tbUIMissionIdList = {}

    self.CurrentSelectTaskField:SetFieldValue(self.INVALID_TASK_ID)
    self.CurrentTrackingTaskField:SetFieldValue(self.INVALID_TASK_ID)

    self:ClearMissionList(NotBroadcast)
end

function TaskMainVM:ClearMissionList(NotBroadcast)
    for TypeList in self.MissionTypeListField:Items_Iterator() do
        if not TypeList.ChapterListField and TypeList.MissionListField then
            return
        end
        if TypeList.ChapterListField then
            for v in TypeList.ChapterListField do
                v:GetFieldValue().TaskListField:ClearItems(NotBroadcast)
            end
        end
        TypeList:GetFieldValue().ChapterListField:ClearItems(NotBroadcast)
        TypeList:GetFieldValue().MissionListField:ClearItems(NotBroadcast)
    end
    self.MissionTypeListField:ClearItems(NotBroadcast)
end

function TaskMainVM:InitMissionTree(MissionList)
    self:ClearMissionTree(true)

    ---@param MissionObject MissionObject
    for _, MissionObject in ipairs(MissionList) do
        self:AddMissionNodeItem(MissionObject, true)
        self:AddMissionTreeNode(MissionObject:GetMissionID())
    end
    self.MissionTypeListField:BroadcastValueChanged()
    self.CurrentSelectTaskField:BroadcastValueChanged()
    self.CurrentTrackingTaskField:BroadcastValueChanged()
end

function TaskMainVM:InitMissionNodeTree()
    self:ClearMissionList(true)
    if not self.tbUIMissionIdList then
        return
    end

    ---@param MissionObject MissionObject
    for _, MissionID in pairs(self.tbUIMissionIdList) do
        local MissionObject = self.tbUIMissionNode[MissionID].MissionObject
        self:SetUpTaskTreeInField(MissionObject, true)
        self:AddMissionTreeNode(MissionObject:GetMissionID())
    end
    self.MissionTypeListField:BroadcastValueChanged()
    self.CurrentSelectTaskField:BroadcastValueChanged()
    self.CurrentTrackingTaskField:BroadcastValueChanged()
end

function TaskMainVM:AcceptTask(MissionID)
    self.MissionSystemModule:AcceptMission(MissionID)
end

function TaskMainVM:AbandonTask(MissionID)
    self.MissionSystemModule:AbandonMission(MissionID)
end

---@param MissionObject MissionObject
function TaskMainVM:SetTaskTracking(MissionObject, bTracking)
    if MissionObject:IsTrackable() and self:CheckMissionCanTracking(MissionObject:GetMissionID()) then
        self.MissionSystemModule:SetMissionTracking(MissionObject:GetMissionID(), bTracking)
    end
end

--防止新任务后立马接任务完成动画，在新任务出现瞬间追踪导致错误
function TaskMainVM:CheckMissionCanTracking(missionId)
    local states = self.tbMissionTrackAnimState[missionId]
    if states then
        for index, state in pairs(states) do
            if state == HudTrackingState.Finished then
                return false
            end
        end
        return true
    else
        return true
    end
end

---@param MissionObject MissionObject
function TaskMainVM:AddMission(MissionObject)
    if MissionObject then
        self:AddMissionNodeItem(MissionObject, false)
        self:AddMissionTreeNode(MissionObject:GetMissionID())
        self:InitMissionNodeTree()
    end
end

---@param MissionObject MissionObject
---removeMission只进行remove，不进行untracking，track所有事件由avatar中的属性同步触发
function TaskMainVM:RemoveMission(MissionObject)
    ---如果后续的动画中需要用到missionObject则缓存
    if TableUtil:Contains(self.tbMissionTrackId, MissionObject:GetMissionID()) then
        self.finishMissionObjectCache = MissionObject
    end
    self:RemoveTaskTreeInField(MissionObject)
end

--主动追踪以及自动追踪
function TaskMainVM:BindMission(MissionObject)
    if self.bShowingTrackAnim then
        self.HudTrackingMission.TrackingMissionID = MissionObject:GetMissionID()
        self:AddMissionTrackAnimMap(MissionObject:GetMissionID(), HudTrackingState.Tracked, true) --插入
        if self.HudTrackingMission.bWaitingForInteract then
            self:TaskTrackAnimFinished()
        end
    else
        self.HudTrackingMission:HudTracking(MissionObject)
    end
end

function TaskMainVM:UnbindMission()
    self.HudTrackingMission:HudUnTracking()
end

---@param MissionObject MissionObject
function TaskMainVM:UpdateMissionTrackState(MissionObject)
    if MissionObject then
        local MissionID = MissionObject:GetMissionID()
        if MissionObject:IsTracking() then
            self.CurrentTrackingTaskField:SetFieldValue(MissionID)
            if self.CurrentSelectTaskField:GetFieldValue() == self.INVALID_TASK_ID then
                self.CurrentSelectTaskField:SetFieldValue(MissionID)
            end
            return
        end
    end
    self.CurrentTrackingTaskField:SetFieldValue(self.INVALID_TASK_ID)
end

---@param MissionObject MissionObject
function TaskMainVM:UpdateMissionProgress(MissionObject)
    -- if not MissionObject or self.HudTrackingMission:GetTrackingMissionObject() == MissionObject then
    --     self.HudTrackingMission:OnMissionProgressUpdate()
    -- end
    self.CurrentUpdateMissionID = MissionObject:GetMissionID()
    if MissionObject then
        self:SetUIMissionObject(MissionObject)
        self.HudTrackingMission:OnMissionProgressUpdate()
    end
end

---@param MissionObject MissionObject
function TaskMainVM:UpdateMissionDistance(MissionObject)
    if not MissionObject or self.HudTrackingMission:GetTrackingMissionObject() == MissionObject then
        self.HudTrackingMission:OnMissionDistanceUpdate()
    end
    if MissionObject then
        self:SetUIMissionObject(MissionObject)
        local UIMissionNode = self:GetUIMissionNode(MissionObject:GetMissionID())
        if UIMissionNode then
            UIMissionNode.MissionNotifyField:SetFieldValue(MissionNotifyState.Distance)
            UIMissionNode.MissionNotifyField:BroadcastValueChanged()
        end
    end
end

---@param MissionObject MissionObject
function TaskMainVM:UpdateMission(MissionObject)
    if not MissionObject or self.HudTrackingMission:GetTrackingMissionObject() == MissionObject then
        self.HudTrackingMission:OnMissionProgressUpdate()
    end
    if MissionObject then
        local UIMissionNode = self:GetUIMissionNode(MissionObject:GetMissionID())
        if UIMissionNode then
            UIMissionNode.MissionNotifyField:SetFieldValue(MissionNotifyState.All)
            UIMissionNode.MissionNotifyField:BroadcastValueChanged()
            self.MissionTypeListField:BroadcastValueChanged()
            self.CurrentSelectTaskField:BroadcastValueChanged()
            self.CurrentTrackingTaskField:BroadcastValueChanged()
        end
    end
end

---@param MissionObject MissionObject
function TaskMainVM:OnMissionFinish(MissionObject)
    if self.HudTrackingMission.TrackingMissionID == MissionObject:GetMissionID() then
        self.HudTrackingMission.TrackingMissionID = 0
    end
end

---@param MissionObject MissionObject
function TaskMainVM:OnMissionSubmit(MissionObject)
    if self.HudTrackingMission:GetTrackingMissionObject() == MissionObject then
        self.HudTrackingMission:OnMissionSubmit()
    end
end

function TaskMainVM:OnMissionStateChange(MissionID, State)
    G.log:info("OnMissionStateChange", "missionID: %s  state: %s", MissionID, State)
    if State == Enum.EHiMissionState.Complete then
        local UIMissionNode = self:GetUIMissionNode(MissionID)
        if UIMissionNode then
            self:UpdateMissionTrackState(UIMissionNode.MissionObject)
            self:UpdateMission(UIMissionNode.MissionObject)
        end
        self:AddMissionTrackAnimMap(MissionID, HudTrackingState.Finished)
        if MissionID == self.currentTrackId then
            self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
            self:TaskTrackAnimFinished()
        elseif not self.bShowingTrackAnim then
            self:StartShowTrackAnimList()
        end
    elseif State == Enum.EHiMissionState.Start then
        local UIMissionNode = self:GetUIMissionNode(MissionID)
        if UIMissionNode then
            self:UpdateMissionTrackState(UIMissionNode.MissionObject)
            self:UpdateMission(UIMissionNode.MissionObject)
        end
        self:AddMissionTrackAnimMap(MissionID, HudTrackingState.Interact)
        if not self.bShowingTrackAnim then
            self:StartShowTrackAnimList()
        end
    end
end

function TaskMainVM:OnMissionEventStateChange(MissionEventID, State, MissionID)
    G.log:info("OnMissionEventStateChange", "MissionEventID: %s missionID: %s  state: %s",MissionEventID, MissionID, State)
    local UIMissionNode = self:GetUIMissionNode(MissionID)
    if UIMissionNode then
        self:UpdateMissionTrackState(UIMissionNode.MissionObject)
        self:UpdateMission(UIMissionNode.MissionObject)
        ---新的event如果已经在追踪了，则主动刷新小地图追踪图标(missionavatar不会重复设置追踪)
        if State == Enum.EHiMissionState.Start and MissionID == self.HudTrackingMission.TrackingMissionID then
            FirmUtil.NotifyMissionChanged(UIMissionNode.MissionObject)
        end
    end
    
end

--insert to table
function TaskMainVM:AddMissionTrackAnimMap(MissionID, State, bFirst)
    if self.tbMissionTrackAnimState[MissionID] then
        table.insert(self.tbMissionTrackAnimState[MissionID], State)
    elseif bFirst then
        local states = {}
        table.insert(states, State)
        self.tbMissionTrackAnimState[MissionID] = states

        table.insert(self.tbMissionTrackId,2 , MissionID)
    else
        local states = {}
        table.insert(states, State)
        self.tbMissionTrackAnimState[MissionID] = states
        table.insert(self.tbMissionTrackId, MissionID)
    end
end

function TaskMainVM:StartShowTrackAnimList()
    self.bShowingTrackAnim = true
    self.currentTrackId = self.tbMissionTrackId[1]
    self.currentTrackeAnimState = self.tbMissionTrackAnimState[self.currentTrackId][1]
    self:PlayTaskTrackStateAnim(self.currentTrackId, self.currentTrackeAnimState)
end

function TaskMainVM:PlayTaskTrackStateAnim(missionID, trackingState)
    self.bWaitingForInteract = false    --每次动画播放时都是false，只有当开启追踪动画结束 进入等待interact状态 为true
    self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
    self.HudTrackingMission.HudTrackingMissionField:SetFieldValue(missionID)
    self.HudTrackingMission.HudTrackStateField:SetFieldValue(trackingState)
    self.HudTrackingMission.HudTrackingMissionField:BroadcastValueChanged() -- 强行Broadcast，防止上个状态也是同一个missionid导致信息不更新

    local missionNode = self.tbUIMissionNode[missionID]
    ---missionNode为nil,任务完成被remove,只播任务完成动画，并移除该missionId的所有动画
    if missionNode then
        FirmUtil.NotifyMissionChanged(missionNode.MissionObject)
    end
end


--追踪面板动画播放完成，移除table，执行下一个追踪动画
function TaskMainVM:TaskTrackAnimFinished()
    if self.tbMissionTrackId and #self.tbMissionTrackId ~= 0 then
        local states = self.tbMissionTrackAnimState[self.currentTrackId]
        if states then
            for index, state in pairs(states) do
                if state == self.currentTrackeAnimState then
                    table.remove(self.tbMissionTrackAnimState[self.currentTrackId], index)
                    break
                end
            end
        end
        self.currentTrackeAnimState = 0
        local states2 = self.tbMissionTrackAnimState[self.currentTrackId]
        if states2 and #states2 == 0 then
            local missionIds = self.tbMissionTrackId
            if missionIds then
                for index, missionId in pairs(missionIds) do
                    if missionId == self.currentTrackId then
                        self.tbMissionTrackAnimState[missionId] = nil
                        table.remove(self.tbMissionTrackId, index)
                        if self.finishMissionObjectCache and missionId == self.finishMissionObjectCache:GetMissionID() then
                            self.finishMissionObjectCache = nil
                        end
                        break
                    end
                end
            end
        end
    end
    if self.tbMissionTrackId and #self.tbMissionTrackId ~= 0 then
        self:PlayLastTaskTrackStateAnim()
    else
        --全部播放完毕，如果最终追踪id非当前显示状态的id，则重置为最终追踪id
        self.bShowingTrackAnim = false
        if self.currentTrackId ~= self.HudTrackingMission.TrackingMissionID then
            self.currentTrackId = 0
            local missionid = self.HudTrackingMission.TrackingMissionID
            if missionid ~= 0 then
                --全部完成后 追踪当前追踪的任务
                self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Tracked)
                self.HudTrackingMission.HudTrackingMissionField:SetFieldValue(missionid)
                self.HudTrackingMission.HudTrackingMissionField:BroadcastValueChanged() -- 强行Broadcast，防止上个状态也是同一个missionid导致信息不更新
                local MissionObject = self.tbUIMissionNode[missionid].MissionObject
                FirmUtil.NotifyMissionChanged(MissionObject)
            else
                self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
                self.HudTrackingMission.HudTrackingMissionField:SetFieldValue(self.INVALID_TASK_ID)
            end
        elseif self.HudTrackingMission.HudTrackStateField:GetFieldValue() ~= HudTrackingState.Tracked then
            self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Tracked)
            self.HudTrackingMission.HudTrackingMissionField:BroadcastValueChanged() -- 强行Broadcast，防止上个状态也是同一个missionid导致信息不更新
        end
    end
end

--判断后一个mission的动画状态是否为正在追踪
--便于在等待interact过程中，直接切到正在追踪动画
function TaskMainVM:NextStateIsTracked()
    if #self.tbMissionTrackId ~= 0 then
        local states = self.tbMissionTrackAnimState[self.currentTrackId]
        for index, state in pairs(states) do
            if state == self.currentTrackeAnimState then
                local nextState = states[index + 1]
                if nextState and nextState == HudTrackingState.Tracked then
                    return true
                end
            end
        end
        local missionIds = self.tbMissionTrackId
        for index, missionId in pairs(missionIds) do
            if missionId == self.currentTrackId then
                local nextMissionId = missionIds[index + 1]
                if nextMissionId then
                    local nextState = self.tbMissionTrackAnimState[nextMissionId]
                    for index, state in pairs(nextState) do
                        if state == HudTrackingState.Tracked then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end
    return false
end


function TaskMainVM:PlayLastTaskTrackStateAnim()
    local states = self.tbMissionTrackAnimState[self.currentTrackId]
    --继续播放当前追踪id的其余动画表现
    if states then
        for _, state in pairs(states) do
            if state ~= self.currentTrackeAnimState then
                self.currentTrackeAnimState = state
                self:PlayTaskTrackStateAnim(self.currentTrackId, state)
                return
            end
        end
    end
   --下一个追踪id
    for idx, id in pairs(self.tbMissionTrackId) do
        if id ~= self.currentTrackId then
            self.currentTrackId = id
            self.currentTrackeAnimState = self.tbMissionTrackAnimState[self.currentTrackId][1]
            self:PlayTaskTrackStateAnim(self.currentTrackId, self.currentTrackeAnimState)
            return
        end
    end
end

---追踪界面恢复后，并播放隐藏这段时间内的追踪状态变化
function TaskMainVM:ShowTaskTrack()
    self.taskTrackHidden = false
    ---如果隐藏期间有任何追踪状态变化，则按队列播放
    if not self.bShowingTrackAnim and #self.tbMissionTrackId ~= 0 then
        self:StartShowTrackAnimList()
    elseif self.HudTrackingMission.TrackingMissionID ~= 0 then
        ---如果隐藏期间有任何追踪状态变化且存在默认追踪任务，则追踪动画
        self:AddMissionTrackAnimMap(self.HudTrackingMission.TrackingMissionID, HudTrackingState.Tracked)
        if not self.bShowingTrackAnim then
            self:StartShowTrackAnimList()
        end
    end
end

--防止界面隐藏 影响队列的播放
function TaskMainVM:ResetTaskTrackList()
    self.taskTrackHidden = true
    self.currentTrackId = 0
    self.bShowingTrackAnim = false
    self.tbMissionTrackId = {}
    self.tbMissionTrackAnimState = {}
    self.HudTrackingMission.HudTrackStateField:SetFieldValue(HudTrackingState.Hidden)
end

---------------------------------------------------
-------------------- 接口分割线 --------------------
---------------------------------------------------

---@param MissionObject MissionObject
function TaskMainVM:ToggleTaskTrack(MissionObject)
    if not MissionObject then
        return
    end

    if MissionObject:IsTracking() then
        self:SetTaskTracking(MissionObject, false)
    else
        self:SetTaskTracking(MissionObject, true)
    end
end

---@param MissionObject MissionObject
---@param NotBroadcast boolean
function TaskMainVM:AddMissionNodeItem(MissionObject, NotBroadcast)
    local MissionID = MissionObject:GetMissionID()
    ---@type UIMissionNode
    local UIMissionNode = {}
    UIMissionNode.OwnerVM = self
    UIMissionNode.Parent = self.INVALID_TASK_ID
    UIMissionNode.MissionObject = MissionObject
    UIMissionNode.MissionNotifyField = self:CreateVMField(MissionNotifyState.All)
    self.tbUIMissionNode[MissionID] = UIMissionNode

    for _, id in pairs(self.tbUIMissionIdList) do
        if id == MissionID then
            return
        end
    end
    if #self.tbUIMissionIdList > 0 then
        local insertIndex = self:FindIndexOfList(self.tbUIMissionIdList, MissionObject)
        table.insert(self.tbUIMissionIdList, insertIndex, MissionID)
    else
        table.insert(self.tbUIMissionIdList, MissionID)
    end
    table.sort(self.tbUIMissionIdList)
    self:SetUpTaskTreeInField(MissionObject, NotBroadcast)
end

function TaskMainVM:FindIndexOfList(list, MissionObject)
    local MissionType = MissionObject:GetMissionType()
    local MissionID = MissionObject:GetMissionID()
    local low, high = 1, #list
    while low <= high do
        local mid = math.floor( (low + high) / 2 )
        local missionId = list[mid]
        local missionObj = self.tbUIMissionNode[missionId].MissionObject
        local missionT = missionObj:GetMissionType()
        if missionT < MissionType or (missionT == MissionType and missionId < MissionID) then
            low = mid + 1
        else
            high = mid - 1
        end
    end
    return low
end

function TaskMainVM:RemoveMissionNodeItem(MissionId)
    for idx, Id in pairs(self.tbUIMissionIdList) do
        if Id == MissionId then
            table.remove(self.tbUIMissionIdList, idx)
            return
        end
    end
end

function TaskMainVM:SetUpTypeTreeInField(FoundTypeNode, MissionObject, NotBroadcast)
    local MissionType = MissionObject:GetMissionType()
    if not FoundTypeNode then
        ---@type MissionTypeNodeClass
        local tbMissionTypeTreeNode = {}
        tbMissionTypeTreeNode.OwnerVM = self
        tbMissionTypeTreeNode.ListType = MissionType
        tbMissionTypeTreeNode.MissionListField = self:CreateVMArrayField({})
        tbMissionTypeTreeNode.ChapterListField = self:CreateVMArrayField({})

        local AddedTypeField = self.MissionTypeListField:AddItem(tbMissionTypeTreeNode, NotBroadcast)
        if AddedTypeField then
            FoundTypeNode = AddedTypeField:GetFieldValue()
        end
    end
    return FoundTypeNode
end

function TaskMainVM:SetUpChapterTreeInField(FoundChapterNode, ChapterField, MissionObject, NotBroadcast)
    local ChapterID = MissionObject:GetMissionActID()
    local MissionType = MissionObject:GetMissionType()
    if not FoundChapterNode then
        ---@type ChapterTreeNode
        local tbChapterTreeNode = {}
        tbChapterTreeNode.TaskChapterID = ChapterID
        tbChapterTreeNode.ListType = MissionType
        tbChapterTreeNode.TaskChapterName = MissionObject:GetMissionActName()
        tbChapterTreeNode.TaskChapterActIndex = MissionObject:GetMissionActSubname() -- 测试中可能出现接取同一章不同幕的任务，正式环境任务有先后次序和接取条件，应该不会出现这种情况
        tbChapterTreeNode.TaskListField = self:CreateVMArrayField({})

        local AddedChapterField = ChapterField:AddItem(tbChapterTreeNode, NotBroadcast)
        if AddedChapterField then
            FoundChapterNode = AddedChapterField:GetFieldValue()
        end
    end
    return FoundChapterNode
end

function TaskMainVM:SetUpMissionTreeInField(FoundMissionNode, MissionField, MissionObject, NotBroadcast)
    local MissionID = MissionObject:GetMissionID()
    local IsTracking = MissionObject:IsTracking()
    if not FoundMissionNode then
        MissionField:AddItem(self.tbUIMissionNode[MissionID], NotBroadcast)
        if IsTracking then
            self.CurrentTrackingTaskField:SetFieldValue(MissionID)
        end
        if self.CurrentSelectTaskField:GetFieldValue() == self.INVALID_TASK_ID then
            self.CurrentSelectTaskField:SetFieldValue(MissionID)
        end
    end
end

function TaskMainVM:SetUpTaskTreeInField(MissionObject, NotBroadcast)
    local MissionID = MissionObject:GetMissionID()
    local MissionType = MissionObject:GetMissionType()
    local ChapterID = MissionObject:GetMissionActID()

    ---@type MissionTypeNodeClass
    local FoundTypeNode = self.MissionTypeListField:FindItemValueIf(function(TypeTreeNode)
        return TypeTreeNode.ListType == MissionType
    end)
    FoundTypeNode = self:SetUpTypeTreeInField(FoundTypeNode, MissionObject, NotBroadcast)

    if ChapterID == 0 then
        local FoundMissionListNode = FoundTypeNode.MissionListField:FindItemValueIf(function(UIMissionNode)
            return UIMissionNode.MissionObject:GetMissionID() == MissionID
        end)
        self:SetUIMissionObjectParent(MissionID, MissionParent.Type)
        self:SetUpMissionTreeInField(FoundMissionListNode, FoundTypeNode.MissionListField, MissionObject, NotBroadcast)
        return
    end

    local FoundChapterNode = FoundTypeNode.ChapterListField:FindItemValueIf(function(ChapterTreeNode)
        return ChapterTreeNode.TaskChapterID == ChapterID
    end)
    FoundChapterNode = self:SetUpChapterTreeInField(FoundChapterNode, FoundTypeNode.ChapterListField, MissionObject, NotBroadcast)

    local FoundedTaskNode = FoundChapterNode.TaskListField:FindItemValueIf(function(UIMissionNode)
        return UIMissionNode.MissionObject:GetMissionID() == MissionID
    end)
    self:SetUIMissionObjectParent(MissionID, MissionParent.Act)
    self:SetUpMissionTreeInField(FoundedTaskNode, FoundChapterNode.TaskListField, MissionObject, NotBroadcast)
end

---@param MissionObject MissionObject
function TaskMainVM:SetTrackingAndSelectedTaskState(MissionObject)
    local MissionObjID = MissionObject:GetMissionID()
    if self.CurrentTrackingTaskField:GetFieldValue() == MissionObjID then
        self.CurrentTrackingTaskField:SetFieldValue(self.INVALID_TASK_ID)
    end
    if self.CurrentSelectTaskField:GetFieldValue() == MissionObjID then
        local AnyUIMissionNode = self:GetAnyUIMissionNode()
        if AnyUIMissionNode then
            self.CurrentSelectTaskField:SetFieldValue(AnyUIMissionNode.MissionObject:GetMissionID())
        else
            self.CurrentSelectTaskField:SetFieldValue(self.INVALID_TASK_ID)
        end
    end
end

function TaskMainVM:RemoveMissionTreeInField(MissionListField, MissionObject)
    local MissionID = MissionObject:GetMissionID()

    local tbRemoved = MissionListField:RemoveItemIf(function(ItemField)
        ---@type UIMissionNode
        local UIMissionNode = ItemField:GetFieldValue()
        return UIMissionNode.MissionObject:GetMissionID() == MissionID
    end)
    for _, RemovedField in pairs(tbRemoved) do
        ---@type UIMissionNode
        local UIMissionNode = RemovedField:GetFieldValue()
        UIMissionNode.MissionNotifyField:ReleaseVMObj()
        self:SetTrackingAndSelectedTaskState(UIMissionNode.MissionObject)
    end
end

---@param MissionObject MissionObject
function TaskMainVM:RemoveTaskTreeInField(MissionObject)
    if not MissionObject then
        return
    end

    local ActID = MissionObject:GetMissionActID()
    local MissionID = MissionObject:GetMissionID()
    local MissionType = MissionObject:GetMissionType()
    self.tbUIMissionNode[MissionID] = nil
    self.tbMissionTreeNode[MissionID] = nil
    self:RemoveMissionNodeItem(MissionID)

    local FoundTypeNode, FoundTypeField = self.MissionTypeListField:FindItemValueIf(function(ChapterTreeNode)
        return ChapterTreeNode.ListType == MissionType
    end)

    if not FoundTypeNode then
        return
    end

    if ActID == 0 then
        local MissionListField = FoundTypeNode.MissionListField
        self:RemoveMissionTreeInField(MissionListField, MissionObject)

        if FoundTypeNode.MissionListField:GetItemNum() == 0 then
            self.MissionTypeListField:RemoveItem(FoundTypeField)
        end
        return
    end

    local FoundChapterNode, FounedChapterField = FoundTypeNode.ChapterListField:FindItemValueIf(function(ChapterTreeNode)
        return ChapterTreeNode.TaskChapterID == ActID
    end)

    if not FoundChapterNode then
        return
    end

    local TaskListField = FoundChapterNode.TaskListField
    self:RemoveMissionTreeInField(TaskListField, MissionObject)

    if TaskListField:GetItemNum() == 0 then
        FoundTypeNode.ChapterListField:RemoveItem(FounedChapterField)
    end
    if FoundTypeNode.ChapterListField:GetItemNum() == 0 then
        self.MissionTypeListField:RemoveItem(FoundTypeField)
    end
end

function TaskMainVM:GetPopUpMissionIdByActID(ActID)
    for _, missionId in pairs(self.tbUIMissionIdList) do
        local MissionObject = self.tbUIMissionNode[missionId].MissionObject
        local MissionActID = MissionObject:GetMissionActID()
        if MissionActID == ActID then
            return missionId
        end
    end
end

---@param MissionId number
function TaskMainVM:AddMissionTreeNode(MissionId)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(G.GameInstance:GetWorld(), 0)
    local MissionAvatarComponent = PlayerController.PlayerState.MissionAvatarComponent
    local MissionIdList = MissionUtil.GetBlockPreMissionList(MissionId, MissionAvatarComponent)
    local MissionActIdList = MissionUtil.GetBlockPreMissionActList(MissionId, MissionAvatarComponent)
    local tempMissionId = {}
    ---@type MissionItem
    local tempList = {}
    if #MissionActIdList > 0 then
        for _, actId in pairs(MissionActIdList) do
            tempMissionId = {}
            tempMissionId.ListType = MissionListType.Act
            tempMissionId.MissionId = actId
            table.insert(tempList, tempMissionId)
        end
    end
    if #MissionIdList > 0 then
        for _, id in pairs(MissionIdList) do
            tempMissionId = {}
            tempMissionId.ListType = MissionListType.Mission
            tempMissionId.MissionId = id
            table.insert(tempList, tempMissionId)
        end
    end

    self.tbMissionTreeNode[MissionId] = tempList
end

---@param MissionItem MissionItem
---@return table|nil
function TaskMainVM:GetMissionDependenciesNodes(MissionItem)
    if not MissionItem then
        return
    end
    local MissionID = MissionItem.MissionId
    if not self.tbMissionTreeNode[MissionID] then
        G.log:debug("wangyuexi: ", "self.tbMissionTreeNode[MissionID] not exist")
        return
    end
    -- self:AddMissionTreeNode(MissionID)
    return self.tbMissionTreeNode[MissionID]
end

---@param MissionObject MissionObject
---@return MissionItem
function TaskMainVM:GetPopUpMissionNode(MissionObject)
    ---@type MissionItem
    local MissionNode = {}
    MissionNode.ListType = MissionListType.Mission
    MissionNode.MissionId = MissionObject:GetMissionID()
    return MissionNode
end

---@param MissionId number
---@param MissionType number
---@return MissionItem
function TaskMainVM:GetMissionItem(MissionId, MissionType)
    ---@type MissionItem
    local MissionNode = {}
    MissionNode.ListType = MissionType
    MissionNode.MissionId = MissionId
    return MissionNode
end

---@param MissionItem MissionItem
---@return Mission|MissionAct, number, number
function TaskMainVM:GetPopUpMission(MissionItem)
    ---@type Mission|MissionAct
    local Mission
    local Type
    if MissionItem.ListType == MissionListType.Mission then
        Mission = MissionTable[MissionItem.MissionId]
        Type = MissionItem.ListType
    else
        Mission = MissionActTable[MissionItem.MissionId]
        Type = MissionItem.ListType
    end
    return Mission, Type, MissionItem.MissionId
end

---@return UIMissionNode
function TaskMainVM:GetUIMissionNode(MissionID)
    return self.tbUIMissionNode[MissionID]
end

function TaskMainVM:GetCurrentUpdateMissionId()
    return self.CurrentUpdateMissionID
end

---@param MissionObject MissionObject
function TaskMainVM:SetUIMissionObject(MissionObject)
    local MissionID = MissionObject:GetMissionID()
    self.tbUIMissionNode[MissionID].MissionObject = MissionObject
end

---@param MissionID number
---@param ParentID number
function TaskMainVM:SetUIMissionObjectParent(MissionID, ParentID)
    self.tbUIMissionNode[MissionID].Parent = ParentID
end

function TaskMainVM:GetAnyUIMissionNode()
    for _, UIMissionNode in pairs(self.tbUIMissionNode) do
        return UIMissionNode
    end
end

function TaskMainVM:GetTypeList(type)
    local tempTypeList = {}
    for _, value in pairs(self.tbUIMissionNode) do
        local Type = value.MissionObject:GetMissionType()
        if Type == type then
            table.insert(tempTypeList, value.MissionObject)
        end
    end
    return tempTypeList
end

function TaskMainVM:GetChapterList(ChapterID)
    local tempChapterList = {}
    for _, value in pairs(self.tbUIMissionNode) do
        local ActId = value.MissionObject:GetMissionActID()
        if ActId == ChapterID then
            table.insert(tempChapterList, value.MissionObject)
        end
    end
    return tempChapterList
end

function TaskMainVM:GetChapterHideListByType(Type)
    return self.tbUIChapterHideList[Type]
end

function TaskMainVM:GetMissionHideListByActID(ActID)
    return self.tbUIMissionHideList[ActID]
end

function TaskMainVM:SetMissionNodeHide(ActID, MissionID)
    if not self.tbUIMissionHideList[ActID] then
        self.tbUIMissionHideList[ActID] = {}
    end
    for _, v in pairs(self.tbUIMissionHideList[ActID]) do
        if v == MissionID then
            return
        end
    end
    table.insert(self.tbUIMissionHideList[ActID], MissionID)
end

---@param ListType number
---@param ActID number
function TaskMainVM:SetChapterNodeHide(ListType, ActID)
    if not self.tbUIChapterHideList[ListType] then
        self.tbUIChapterHideList[ListType] = {}
    end
    for _, v in pairs(self.tbUIChapterHideList[ListType]) do
        if v == ActID then
            return
        end
    end
    table.insert(self.tbUIChapterHideList[ListType], ActID)
end

---@param MissionID number
function TaskMainVM:SetMissionNodeShow(MissionID)
    for actId, v in pairs(self.tbUIMissionHideList) do
        for i, k in pairs(v) do
            if k == MissionID then
                self.tbUIMissionHideList[actId][i] = nil
                return
            end
        end
    end
end

---@param ActID number
function TaskMainVM:SetChapterNodeShow(ActID)
    for type, v in pairs(self.tbUIChapterHideList) do
        for i, k in pairs(v) do
            if k == ActID then
                self.tbUIChapterHideList[type][i] = nil
                return
            end
        end
    end
end

TaskMainVM.HudTrackingState = HudTrackingState
TaskMainVM.MissionListType = MissionListType
TaskMainVM.MissionParent = MissionParent
TaskMainVM.MissionBlockReason = MissionBlockReason

return TaskMainVM
