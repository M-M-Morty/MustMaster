local G = require("G")
local MissionActTable = require("common.data.mission_act_data").data
local ConstTextTable = require("common.data.const_text_data").data
local DialogueTable = require ("common.data.dialogue_data").data
local MissionTable = require("common.data.mission_data").data
local NpcInteractTable = require("common.data.npc_interact_data").data
local DialogueObjectModule = require ("mission.dialogue_object")
local EdUtils = require("common.utils.ed_utils")
local MissionConst = require('Script.mission.mission_const')

local MissionUtil = {}

function MissionUtil.IsMissionStateActive(State)
    return State == Enum.EHiMissionState.Start
end

function MissionUtil.UpdateTrackTargetList(TrackTargetList, RawEventID, NewTargetList)
    for i = TrackTargetList:Length(), 1, -1 do
        local TrackTarget = TrackTargetList:GetRef(i)
        if TrackTarget.RawEventID == RawEventID then
            TrackTargetList:Remove(i)
        end
    end
    for i = 1, NewTargetList:Length() do
        local TrackTarget = NewTargetList:GetRef(i)
        TrackTargetList:Add(TrackTarget)
    end
end

function MissionUtil.GetDialogueStepFromRecord(DialogueStepRecord)
    if DialogueStepRecord.StepType == DialogueObjectModule.DialogueType.TALK then
        -- 普通对话
        local DialogueID = DialogueStepRecord.DialogueID
        local StepIndex = DialogueStepRecord.Index
        local DialogueData = DialogueTable[DialogueID]
        if DialogueData == nil then
            G.log:error("hangyuewang", "Wrong DialogueID, DialogueID=%s", DialogueID)
            return nil
        end
        local DialogueStepData = DialogueData[StepIndex]
        if DialogueStepData == nil then
            G.log:error("hangyuewang", "Wrong StepIndex, DialogueID=%s, StepIndex=%s", DialogueID, StepIndex)
            return nil
        end
        return DialogueObjectModule.DialogueStepTalk.new(nil, DialogueStepData)
    elseif DialogueStepRecord.StepType == DialogueObjectModule.DialogueType.INTERACT then
        -- 交互对话(n选1)
        local BranchIDs = DialogueStepRecord.BranchIDs
        local ChoiceIndex = DialogueStepRecord.Index
        return DialogueObjectModule.DialogueStepDisplayBranch.new(BranchIDs, ChoiceIndex)
    end
    return nil
end

function MissionUtil.ResumeDialogue(DialogueID, DialogueRecord)
    local DialogueObject = DialogueObjectModule.Dialogue.new(DialogueID, nil)
    DialogueObject:SetEnableSaveHistory(true)
    DialogueObject:SetMissionActID(DialogueRecord.MissionActID)
    -- 根据数据恢复出之前DialogueObject的进度
    local StepRecords = DialogueRecord.StepRecords
    if StepRecords:Length() == 0 then
        -- 没有历史要恢复，直接返回
        return DialogueObject
    end
    -- TODO(hangyuewang): 根据LastStep快速恢复
    DialogueObject:GetNextDialogueStep(0)
    for i = 1, StepRecords:Length() do
        local StepData = StepRecords[i]
        if StepData.StepType == DialogueObjectModule.DialogueType.TALK then
            DialogueObject:GetNextDialogueStep(0)
        elseif StepData.StepType == DialogueObjectModule.DialogueType.INTERACT then
            DialogueObject:GetNextDialogueStep(StepData.Index)
        end
    end
    return DialogueObject
end

-- 任务被阻塞的原因
function MissionUtil.GetBlockReason(MissionId, MissionAvatarComponent)
    local MissionData = MissionTable[MissionId]
    if not MissionData then
        -- 空任务ID先通过
        return 0
    end
    if MissionData.PreMission and #MissionUtil.GetBlockPreMissionList(MissionId, MissionAvatarComponent) ~= 0 then
        return MissionConst.EMissionBlockReason.PreMissionBlock
    end
    if MissionData.PreMissionAct and #MissionUtil.GetBlockPreMissionActList(MissionId, MissionAvatarComponent) ~= 0 then
        return MissionConst.EMissionBlockReason.PreMissionBlock
    end
    return 0
end

-- 阻塞住此任务的前置任务数组
function MissionUtil.GetBlockPreMissionList(MissionId, MissionAvatarComponent)
    local PreMissionList = {}
    local MissionData = MissionTable[MissionId]
    if not MissionData.PreMission then
        return PreMissionList
    end
    for _, MissionId in ipairs(MissionData.PreMission) do
        local MissionRecord = MissionAvatarComponent.MissionRecordMap:FindRef(MissionId)
        if MissionRecord == nil or MissionRecord.State ~= Enum.EHiMissionState.Complete then
            table.insert(PreMissionList, MissionId)
        end
    end
    return PreMissionList
end

-- 阻塞住此任务的前置任务幕数组
function MissionUtil.GetBlockPreMissionActList(MissionId, MissionAvatarComponent)
    local PreMissionActList = {}
    local MissionData = MissionTable[MissionId]
    if not MissionData.PreMissionAct then
        return PreMissionActList
    end
    for _, MissionActId in ipairs(MissionData.PreMissionAct) do
        local MissionAct = MissionAvatarComponent:GetMissionActData(MissionActId)
        if not MissionAct or MissionAct.State < Enum.EMissionActState.Complete then
            table.insert(PreMissionActList, MissionActId)
        end
    end
    return PreMissionActList
end

-- 任务章节解锁完成提示数据定义 -----------------------------------
local MissionActDisplayInfo = Class()

function MissionActDisplayInfo:ctor(MissionActID, State)
    self.MissionActID = MissionActID
    self.State = State
end

--- 获取标题：XX章XX幕
--- return: string
function MissionActDisplayInfo:GetTitle()
    return MissionActTable[self.MissionActID].ChapterDesc
end
--- 获取文本内容：章节/任务名称
--- return: string
function MissionActDisplayInfo:GetContent()
    return MissionActTable[self.MissionActID].Name
end
--- 获取法恩语文本内容：章节/任务名称
--- return: string
function MissionActDisplayInfo:GetEnglishContent()
    return MissionActTable[self.MissionActID].FahnName
end

--- 获取任务状态: 已开启/已完成
--- return: string
function MissionActDisplayInfo:GetState()
    if self.State == Enum.EMissionActState.Start then
        return ConstTextTable.MISSION_GROUP_START_STATE.Content
    elseif self.State == Enum.EMissionActState.Complete then
        return ConstTextTable.MISSION_GROUP_COMPLETE_STATE.Content
    end
    assert(0)
end

--- 获取任务背景图key: 
--- return: string
function MissionActDisplayInfo:GetTitleIconKey()
    return MissionActTable[self.MissionActID].TitleIconResourceRef
end

MissionUtil.MissionActDisplayInfo = MissionActDisplayInfo

return MissionUtil
