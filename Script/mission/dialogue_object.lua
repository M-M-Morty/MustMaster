local G = require("G")

local DialogueTable = require ("common.data.dialogue_data").data
local BranchTable = require ("common.data.branch_data").data
local ConstTextTable = require("common.data.const_text_data").data
local NpcInteractTable = require("common.data.npc_interact_data").data
local NpcInteractDef = require("common.data.npc_interact_data")
local NpcInteractItemModule = require("mission.npc_interact_item")
local DataTableUtils = require("common.utils.data_table_utils")
local BPConst = require("common.const.blueprint_const")
local EdUtils = require("common.utils.ed_utils")
local LuaUtils = require("common.utils.lua_utils")
local GameConstData = require("common.data.game_const_data").data
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')

local M = {}

local Dialogue = Class()

local DialogueStepBase = Class()  -- DialogueStep基类，仅有显示功能
local DialogueStepInteractBase = Class(DialogueStepBase)    -- 增加了互动功能
local DialogueStepStart = Class(DialogueStepInteractBase)   -- 开始节点
local DialogueStepTalk = Class(DialogueStepInteractBase)    -- 对话节点
local DialogueStepBranch = Class(DialogueStepInteractBase)  -- 分支节点
local DialogueStepDisplayBranch = Class(DialogueStepBase)   -- 分支显示节点
local DialogueStepFinish = Class(DialogueStepInteractBase)  -- 结束节点

-- 对话节点类型，对应不同类型的DialogueStep
M.DialogueStepType = {
    START = 0,      -- 开始对话
    TALK = 1,       -- 普通对白
    INTERACT = 2,   -- 互动选项
    FINISHED = 3    -- 对白结束
}

-- 旧枚举，已废弃
M.DialogueType = {
    START = 0,      -- 开始对话
    TALK = 1,       -- 普通对白
    INTERACT = 2,   -- 互动选项
    FINISHED = 3    -- 对白结束
}

-- 对话title类型
M.DialogueStepTitleType = {
    NPC_TALK = 1,       -- NPC对话，说话者的名字使用owner id指定
    OTHER_TALK = 2      -- 其他对话，说话者的名字显示title字符串
}

M.DialogueStepOwnerType = {
    PLAYER = 0,
    NPC = 1
}

M.SystemCancelDialogueID = 0

function Dialogue:ctor(DialogueID, DialogueComponent)
    self.StartDialogueID = DialogueID
    self.CurrentDialogueID = DialogueID
    self.FinishDialogueID = 0
    self.CurrentStepList = {}
    self:UpdateCurrentStepList()
    self.CurrentStepIndex = 0
    self.CurrentDialogueStepObject = DialogueStepStart.new(self)
    self.DialogueComponent = DialogueComponent          -- can be nil, when DialogueTalkSteps all use OTHER_TALK type
    self.FinishCallback = nil
    self.bSaveHistoryStep = false  -- 是否保存历史步骤
    local DialogueRecordClass = EdUtils:GetUE5ObjectClass(BPConst.DialogueRecord, true)
    local DialogueRecord = DialogueRecordClass()
    self.HistoryRecord = DialogueRecord
    self.MissionActID = 0  -- 关联的任务幕ID
end

function Dialogue:SetFinishCallback(FinishCallback)
    self.FinishCallback = FinishCallback
end

function Dialogue:HookFinishCallback(HookCallback)
    local Callback = self.FinishCallback
    self.FinishCallback = HookCallback
    return Callback
end

function Dialogue:SetEnableSaveHistory(bSaveHistoryStep)
    self.bSaveHistoryStep = bSaveHistoryStep
end

function Dialogue:SetMissionActID(MissionActID)
    self.MissionActID = MissionActID
    self.HistoryRecord.MissionActID = MissionActID
end

function Dialogue:SetNpcID(NpcID)
    self.HistoryRecord.NpcID = NpcID
end

function Dialogue:GetStartDialogueID()
    return self.StartDialogueID
end

function Dialogue:GetFinishDialogueID()
    return self.FinishDialogueID
end

function Dialogue:UpdateCurrentStepList()
    if self.CurrentDialogueID == M.SystemCancelDialogueID then
        return
    end
    for StepID, _ in pairs(DialogueTable[self.CurrentDialogueID]) do
        table.insert(self.CurrentStepList, StepID)
    end
    table.sort(self.CurrentStepList)
end

function Dialogue:GetNextDialogueStep(CurrentChoice)
    self.CurrentDialogueStepObject = self.CurrentDialogueStepObject:HandleChoice(CurrentChoice)
    return self.CurrentDialogueStepObject
end

function Dialogue:GenerateNextStepObject()
    self.CurrentStepIndex = self.CurrentStepIndex + 1
    if self.CurrentStepIndex > #self.CurrentStepList then
        self:OnFinish()
        return DialogueStepFinish.new(self)
    end
    return DialogueStepTalk.new(self, self:GetCurrentStepData())
end

-- 生成选项对话
function Dialogue:GenerateBranchStepObject(BranchIDs)
    local BranchStep = DialogueStepBranch.new(self, BranchIDs)
    return BranchStep
end

function Dialogue:SwitchToDialogue(DialogueID)
    if DialogueID <= GameConstData.MAX_EXIT_DIALOGUE_ID.IntValue then
        -- 这个是用于Exit分支出口的参数，特殊处理
        self.CurrentDialogueID = DialogueID
        self.CurrentStepList = {}
        self.CurrentStepIndex = 0
        return        
    end
    self.CurrentDialogueID = DialogueID
    self.CurrentStepList = {}
    self:UpdateCurrentStepList()
    self.CurrentStepIndex = 0
end

function Dialogue:GetCurrentStepData()
    if self.CurrentStepIndex > #self.CurrentStepList or self.CurrentStepIndex == 0 then
        return nil
    end
    local StepID = self.CurrentStepList[self.CurrentStepIndex]
    return DialogueTable[self.CurrentDialogueID][StepID]
end

function Dialogue:OnFinish()
    self.FinishDialogueID = self.CurrentDialogueID
end

function Dialogue:IsFinished()
    return self.FinishDialogueID ~= 0
end

function Dialogue:FinishDialogue()
    if self.FinishCallback then
        self.FinishCallback()
    end
end

function Dialogue:GetTalkerName(TalkerID)
    assert(self.DialogueComponent ~= nil, "TalkerID specified, but DialogueComponent not set")
    return self.DialogueComponent:GetTalkerName(TalkerID)
end

function Dialogue:AddHistoryStep(DialogueData, StepType, Index)
    if not self.bSaveHistoryStep then
        return
    end
    local DialogueStepRecordClass = EdUtils:GetUE5ObjectClass(BPConst.DialogueStepRecord, true)
    local DialogueStepRecord = DialogueStepRecordClass()
    DialogueStepRecord.StepType = StepType
    DialogueStepRecord.Index = Index
    if StepType == M.DialogueType.TALK then
        DialogueStepRecord.DialogueID = DialogueData
    elseif StepType == M.DialogueType.INTERACT then
        for _, BranchID in ipairs(DialogueData) do
            DialogueStepRecord.BranchIDs:Add(BranchID)
        end
    end
    self.HistoryRecord.StepRecords:Add(DialogueStepRecord)
end


-- DialogueStepBase   ---------------------------------------------------------------------------------------------
function DialogueStepBase:ctor(StepType)
    self.StepType = StepType
end

function DialogueStepBase:GetType()
    return self.StepType
end

function DialogueStepBase:GetOwnerType()
    -- body
end

-- DialogueStepInteractBase   ---------------------------------------------------------------------------------------------
function DialogueStepInteractBase:ctor(DialogueObject, StepType)
    Super(DialogueStepInteractBase).ctor(self, StepType)
    self.DialogueObject = DialogueObject
end

function DialogueStepInteractBase:HandleChoice(CurrentChoice)
    -- body
end

-- DialogueStepStart   ---------------------------------------------------------------------------------------------
function DialogueStepStart:ctor(DialogueObject)
    Super(DialogueStepStart).ctor(self, DialogueObject, M.DialogueType.START)
end

function DialogueStepStart:HandleChoice(CurrentChoice)
    assert(self.DialogueObject.CurrentStepIndex == 0, "Dialogue not in initial state")
    return self.DialogueObject:GenerateNextStepObject()
end

-- DialogueStepTalk   ---------------------------------------------------------------------------------------------
function DialogueStepTalk:ctor(DialogueObject, StepData)
    Super(DialogueStepTalk).ctor(self, DialogueObject, M.DialogueType.TALK)
    self.StepData = StepData
end

function DialogueStepTalk:GetContent()
    return self.StepData.Detail
end

function DialogueStepTalk:GetTalkerName()
    if self.StepData.type == M.DialogueStepTitleType.NPC_TALK then
        return self.DialogueObject:GetTalkerName(self.StepData.owner)
    else
        return self.StepData.title
    end
end

function DialogueStepTalk:GetAudio()
    return DataTableUtils.GetAudioPathByDataTableID(self.StepData.audio_id)
end

function DialogueStepTalk:GetCanSkipTime()
    if self.StepData.can_skip then
        if self.StepData.can_skip_time == nil then
            return 0
        else
            return self.StepData.can_skip_time
        end
    else
        return nil
    end
end

function DialogueStepTalk:HandleChoice(CurrentChoice)
    local CurrentStepData = self.StepData
    assert(CurrentStepData ~= nil, "current step data is nil")
    self.DialogueObject:AddHistoryStep(self.DialogueObject.CurrentDialogueID, M.DialogueType.TALK, self.DialogueObject.CurrentStepIndex)
    if CurrentStepData.branch_id_new ~= nil then
        return self.DialogueObject:GenerateBranchStepObject(CurrentStepData.branch_id_new)
    end
    return self.DialogueObject:GenerateNextStepObject()
end

function DialogueStepTalk:GetOwnerType()
    if self.StepData.owner == 0 then
        return M.DialogueStepOwnerType.PLAYER
    else
        return M.DialogueStepOwnerType.NPC
    end
end

-- DialogueStepBranch   ---------------------------------------------------------------------------------------------
function DialogueStepBranch:ctor(DialogueObject, BranchIDs)
    Super(DialogueStepBranch).ctor(self, DialogueObject, M.DialogueType.INTERACT)
    self.BranchIDs = BranchIDs
    self.Items = {}

    for _, BranchID in ipairs(self.BranchIDs) do
        local BranchData = NpcInteractTable[BranchID]
        local Callback = nil
        if BranchData.Tpye == NpcInteractDef.Dialogue or BranchData.Tpye == NpcInteractDef.Exit then
            -- 对话类型
            Callback = function ()
                self.DialogueObject:SwitchToDialogue(BranchData.DialogueId)
                return self.DialogueObject:GenerateNextStepObject()
            end
        elseif BranchData.Tpye == NpcInteractDef.UIEvent then
            -- 打开对应UI
            Callback = function ()
                local Param = LuaUtils.DeepCopy(BranchData.Parm)
                local UIName = Param[1]
                local UIInfo = UIDef.UIInfo[UIName]
                table.remove(Param, 1)
                local DialogueInfo = {
                    DialogueObject = self.DialogueObject
                }

                -- 关闭对话
                self.DialogueObject:FinishDialogue()
                UIManager:OpenUI(UIInfo, Param, DialogueInfo)
            end
        end
        local Item = NpcInteractItemModule.MissionChoiceItem.new(BranchData.DialogueId, BranchData.Name, Callback)
        table.insert(self.Items, Item)
    end
end

function DialogueStepBranch:GetInteractItems()
    return self.Items
end

function DialogueStepBranch:HandleChoice(CurrentChoice)
    assert(self.Items[CurrentChoice] ~= nil, "HandleChoice:wrong choice")
    self.DialogueObject:AddHistoryStep(self.BranchIDs, M.DialogueType.INTERACT, CurrentChoice)
    return self.Items[CurrentChoice].SelectCallback()
end

function DialogueStepBranch:GetOwnerType()
    -- 交互选项对话只有Player才能进行
    return M.DialogueStepOwnerType.PLAYER
end

-- DialogueStepDisplayBranch   ---------------------------------------------------------------------------------------------
function DialogueStepDisplayBranch:ctor(BranchIDs, ChoiceIndex)
    Super(DialogueStepDisplayBranch).ctor(self, M.DialogueType.INTERACT)
    self.BranchIDs = BranchIDs
    self.ChoiceIndex = ChoiceIndex
    self.Items = {}

    for _, BranchID in ipairs(self.BranchIDs) do
        local BranchData = NpcInteractTable[BranchID]
        local Item = NpcInteractItemModule.MissionChoiceItem.new(BranchData.DialogueId, BranchData.Name, nil)
        table.insert(self.Items, Item)
    end
end

function DialogueStepDisplayBranch:GetInteractItems()
    return self.Items
end

function DialogueStepDisplayBranch:GetOwnerType()
    return M.DialogueStepOwnerType.PLAYER
end

-- DialogueStepFinish   ---------------------------------------------------------------------------------------------
function DialogueStepFinish:ctor(DialogueObject)
    Super(DialogueStepFinish).ctor(self, DialogueObject, M.DialogueType.FINISHED)
end


M.Dialogue = Dialogue
M.DialogueStepTalk = DialogueStepTalk
M.DialogueStepDisplayBranch = DialogueStepDisplayBranch

return M
