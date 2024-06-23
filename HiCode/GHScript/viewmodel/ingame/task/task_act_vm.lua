local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local MissionActUtil = require("CP0032305_GH.Script.mission.mission_act_utils")
local G = require("G")

---@alias ActStateChangeCallBackT fun(Owner:UObject, MissionActId:integer, State:integer)

---@class TaskActVM : ViewModelBase
---@field OnActStateChangeCallBacks table<UObject, ActStateChangeCallBackT>
---@field AlreadyMissionCompleted boolean

local TaskActVM = Class(ViewModelBaseClass)

local TaskActType = MissionActUtil.TaskActType

---当前完成的MissionId
local CurrentCompletedMissionId = 0
---上一次完成的MissionId
local LastCompletedMissionId = 0

function TaskActVM:ctor()
    Super(TaskActVM).ctor(self)
    local MissionSystemModule = require('CP0032305_GH.Script.system_simulator.mission_system.mission_system_module')
    self:InitMissionSystem(MissionSystemModule)
    self.OnActStateChangeCallBacks = {}
end

---这里可以替换MissionAvatarComponent的实现
function TaskActVM:InitMissionSystem(InModule)
    self.MissionSystemModule = InModule
end

---@return FMissionActRecord
function TaskActVM:GetMissionAct(MissionActID)
    local MissionActList = self.MissionSystemModule:GetMissionActList()
    for i = 1, MissionActList:Length() do
        local Act = MissionActList:GetRef(i)
        if Act.MissionActID == MissionActID then
            return Act
        end
    end
    return nil
end


---@param MissionA FMissionActRecord
---@param MissionB FMissionActRecord
---@return boolean
local function MissionSortFunction(MissionA, MissionB)
    local SortTable = {}
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    SortTable[EMissionActState.Start] = 0
    SortTable[EMissionActState.Initialize] = 1
    SortTable[EMissionActState.Complete] = 2
    SortTable[EMissionActState.RewardReceived] = -1
    if MissionA.State ~= MissionB.State then
        return SortTable[MissionA.State] > SortTable[MissionB.State]
    end
    if MissionA.InitTime ~= MissionB.InitTime then
        return MissionA.InitTime < MissionB.InitTime
    end
    return MissionA.MissionActID < MissionB.MissionActID
end

---@return integer
function TaskActVM:GetLastReceiveRewardMissionActID()
    return self.MissionSystemModule.LastReceiveRewardMissionActID
end

---@return FMissionActRecord[]
function TaskActVM:GetCurrentMainMissionActs()
    local CurrentMissionActs = {}
    ---@type TArray<FMissionActRecord>
    local MissionActList = self.MissionSystemModule:GetMissionActList()
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    for i = 1, MissionActList:Length() do
        local Act = MissionActList:GetRef(i)
        local MissionActConfig = MissionActUtil.GetMissionActConfig(Act.MissionActID)
        if MissionActConfig then
            if MissionActConfig.Type == TaskActType.Main then
                if Act.State == EMissionActState.Initialize or Act.State == EMissionActState.Start or Act.State == EMissionActState.Complete then
                    table.insert(CurrentMissionActs, Act)
                end
            end
        else
            G.log:warn("TaskActVM", "GetCurrentMainMissionActs invalid act id! %d", Act.MissionActID)
        end
    end
    table.sort(CurrentMissionActs, MissionSortFunction)
    return CurrentMissionActs
end

---@return FMissionActRecord[]
function TaskActVM:GetCaseWallMissionActs()
    local CurrentMissionActs = {}
    local MissionActList = self.MissionSystemModule:GetMissionActList()
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    for i = 1, MissionActList:Length() do
        local Act = MissionActList:GetRef(i)
        if Act.State == EMissionActState.RewardReceived or Act.State == EMissionActState.Start or Act.State == EMissionActState.Complete then
            table.insert(CurrentMissionActs, Act)
        end
    end
    return CurrentMissionActs
end

---@return boolean
function TaskActVM:HasInitializeMainAct()
    local MissionActList = self.MissionSystemModule:GetMissionActList()
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    for i = 1, MissionActList:Length() do
        local Act = MissionActList:GetRef(i)
        local MissionActConfig = MissionActUtil.GetMissionActConfig(Act.MissionActID)
        if MissionActConfig then
            if MissionActConfig.Type == TaskActType.Main then
                if Act.State == EMissionActState.Initialize then
                    return true
                end
            end
        else
            G.log:warn("TaskActVM", "HasInitializeMainAct invalid act id! %d", Act.MissionActID)
        end
    end
    return false
end

---@return boolean
function TaskActVM:HasCompleteMainAct()
    local MissionActList = self.MissionSystemModule:GetMissionActList()
    ---@type EMissionActState
    local EMissionActState = Enum.EMissionActState
    for i = 1, MissionActList:Length() do
        local Act = MissionActList:GetRef(i)
        local MissionActConfig = MissionActUtil.GetMissionActConfig(Act.MissionActID)
        if MissionActConfig then
            if MissionActConfig.Type == TaskActType.Main then
                if Act.State == EMissionActState.Complete then
                    CurrentCompletedMissionId = Act.MissionActID
                    ---当前已有完成的任务奖励，且再次接取任务时记录的Id
                    G.log:debug("TaskActVM", "TaskActVM:HasCompleteMainAct %d %d %d",CurrentCompletedMissionId,Act.MissionActID,LastCompletedMissionId)
                    if CurrentCompletedMissionId ~= LastCompletedMissionId then
                        LastCompletedMissionId = CurrentCompletedMissionId
                        self.AlreadyMissionCompleted = true
                    else
                        self.AlreadyMissionCompleted = false
                    end
                    return true
                end
            end
        else
            G.log:warn("TaskActVM", "HasCompleteMainAct invalid act id! %d", Act.MissionActID)
        end
    end
    return false
end



---@param MissionActID integer
---@param State integer
function TaskActVM:OnNotifyMissionActStateChange(MissionActID, State)
    for Object, CB in pairs(self.OnActStateChangeCallBacks) do
        CB(Object, MissionActID, State)
    end
end

---@param Object UObject
---@param Callback function
function TaskActVM:RegOnActStateChangeCallBack(Object, Callback)
    self.OnActStateChangeCallBacks[Object] = Callback
end

---@param Object UObject
---@param Callback function
function TaskActVM:UnRegOnActStateChangeCallBack(Object, Callback)
    self.OnActStateChangeCallBacks[Object] = nil
end

return TaskActVM