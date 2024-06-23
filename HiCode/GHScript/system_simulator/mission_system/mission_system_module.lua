
local MissionSample = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_sample')

---@class MissionSystemModule
---@field LastReceiveRewardMissionActID integer

---@type MissionSystemModule
local MissionSystemModule = {}

function MissionSystemModule:InitModule(InTaskMainVM)
    self.tbMissionList = {}
    self.TaskMainVM = InTaskMainVM
    self:MockMissionActDatas()
end

-- 以下是我期望的MissionSystemModule提供的接口
-- 这些接口会由VM去调用

-- 由玩家操作接取任务
function MissionSystemModule:AcceptMission(MissionID)
    local MissionObject = MissionSample:CreateMission(MissionID)
    MissionObject.ChildMissionList = MissionSample:AddMissionList(MissionID)
    table.insert(MissionSystemModule.tbMissionList, MissionObject)
    self.TaskMainVM:AddMission(MissionObject)
end

-- 由玩家操作放弃任务，也许不需要，仅供测试使用
function MissionSystemModule:AbandonMission(MissionID)
    ---@param MissionObject MissionObject
    for index, MissionObject in ipairs(self.tbMissionList) do
        if MissionObject:GetMissionID() == MissionID then
            table.remove(self.tbMissionList, index)
            self.TaskMainVM:RemoveMission(MissionObject)
            break
        end
    end
end

-- 由玩家操作追踪或取消追踪任务
function MissionSystemModule:SetMissionTracking(MissionID, bTracking)
    ---@param MissionObject MissionObject
    for _, MissionObject in ipairs(self.tbMissionList) do
        if MissionObject:GetMissionID() == MissionID then
            MissionObject.bTracking = bTracking
            self.TaskMainVM:UpdateMissionTrackState(MissionObject)
        else
            if bTracking == true and MissionObject.bTracking == true then
                MissionObject.bTracking = false
            end
        end
    end
end

function MissionSystemModule:OnTrackingMissionFinishAnimEnd()
    local TrackingMission
    ---@param MissionObject MissionObject
    for _, MissionObject in ipairs(self.tbMissionList) do
        if MissionObject:IsTrackable() then
            MissionObject.bTracking = true
            self.TaskMainVM:UpdateMissionTrackState(MissionObject)
            break
        end
    end
end

-- 初始化任务面板时需要
---@return MissionObject[]
function MissionSystemModule:GetMissionList()
    return self.tbMissionList
end


--- 以下是任务系统自动调用的接口，这里做填充展示
--- VM里也有同名接口，如果任务系统不需要做额外的处理，也可以直接调用VM的
--- VM里的接口参数是MissionObject

--- 任务进度发生变化
function MissionSystemModule:OnMissionProgressUpdate(MissionObject)
    self.TaskMainVM:UpdateMissionProgress(MissionObject)
end

--- 任务距离发生变化
function MissionSystemModule:OnMissionDistanceUpdate(MissionObject)
    self.TaskMainVM:UpdateMissionDistance(MissionObject)
end

--- 任务结束
function MissionSystemModule:OnMissionFinish(MissionObject)
    -- 删除AcceptedMission，仅供测试使用，实际的逻辑应该在类似 MissionSystemModule:DoMissionFinish 的接口中
    for i, obj in ipairs(self.tbMissionList) do
        if obj == MissionObject then
            table.remove(self.tbMissionList, i)
            break
        end
    end
    self.TaskMainVM:OnMissionFinish(MissionObject)
end

local function MockLoadStructMissionActRecord()
    local MissionActRecordPath = "/Game/Blueprints/Mission/MissionRecordData/MissionActRecord.MissionActRecord"
    return LoadObject(MissionActRecordPath)
end

local function MockCreateMissionAct(self, MissionActId, State)
    ---@type FMissionActRecord
    local ActRecord = MockLoadStructMissionActRecord()()

    ActRecord.MissionActID = MissionActId
    ActRecord.State = State
    ActRecord.InitTime = os.time() + math.random(1000)
    self.MissionActList:Add(ActRecord)
end

--- 以下是任务幕相关的mock接口
function MissionSystemModule:MockMissionActDatas()
    self.MissionActList = UE.TArray(MockLoadStructMissionActRecord()())
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    MockCreateMissionAct(self, 9001, EMissionActState.Initialize)
    MockCreateMissionAct(self, 9002, EMissionActState.Start)
    MockCreateMissionAct(self, 9003, EMissionActState.Initialize)
    MockCreateMissionAct(self, 9004, EMissionActState.Initialize)
    MockCreateMissionAct(self, 9005, EMissionActState.Start)
end

---@class MissionActData
---@field MissionActID integer
---@field State integer

---@return TArray<FMissionActRecord>
function MissionSystemModule:GetMissionActList()
    if self.MissionActList == nil then
        return UE.TArray(UE.FInt)
    end
    return self.MissionActList
end

function MissionSystemModule:Server_ReceiveMissionActRewards(MissionActID)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

    for i = 1, self.MissionActList:Length() do
        local Act = self.MissionActList:GetRef(i)
        if Act.MissionActID == MissionActID then
            Act.State = Enum.EMissionActState.RewardReceived
            break
        end
    end
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:OnNotifyMissionActStateChange(MissionActID, Enum.EMissionActState.RewardReceived)
end

function MissionSystemModule:Server_AcceptMissionAct(MissionActID)
    local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
    local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

    for i = 1, self.MissionActList:Length() do
        local Act = self.MissionActList:GetRef(i)
        if Act.MissionActID == MissionActID then
            Act.State = Enum.EMissionActState.Start
            break
        end
    end

    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    TaskActVM:OnNotifyMissionActStateChange(MissionActID, Enum.EMissionActState.Start)
end

return MissionSystemModule
