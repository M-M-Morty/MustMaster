local MissionActUtils = {}

local G = require("G")
local MissionActTable = require("common.data.mission_act_data").data
local MissionTable = require("common.data.mission_data").data
local NpcBaseTable = require("common.data.npc_base_data").data
local EventDescriptionTable = require("common.data.event_description_data").data
local NoteData = require("common.data.note_data")
local MissionBoardTable = require("common.data.missionboard_data").data
local RandomUtil = require("CP0032305_GH.Script.common.utils.random_util")
local Utils = require("common.utils")
local Json = require("rapidjson")
local StringUtil = require('CP0032305_GH.Script.common.utils.string_utl')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local DialogueObjectModule = require("mission.dialogue_object")

local MAX_NPC_COMMENT = 3
local RANDOM_EVENT_MIN = 3
local RANDOM_EVENT_MAX = 4

---回顾界面需要每个项有个临时id来区分
local ID = 1

MissionActUtils.MISSION_RELATE_PATH = "Data/MissionRelate/"
MissionActUtils.DEFAULT_JSON_FILE = "default.json"
MissionActUtils.MISSION_FLOW_ROOT_PATH = "Data/MissionFlow/LV_WD_FAHN/DEMO"
MissionActUtils.FILE_NAME_SUFFIX_NORMAL = "_export"
MissionActUtils.FILE_NAME_SUFFIX_MAIN = "_mainExport"
MissionActUtils.GAME_PREFIX = "/Game/"
MissionActUtils.START_CLASS = "/Script/Flow.FlowNode_Start"
MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_SELF = "DialogSelf"
MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_NPC = "DialogNPC"
MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_SMS = "DialogSMS"

MissionActUtils.TYPE = {
    GROUP = 1,
    ACT = 2,
    MISSION = 3,
    NODE = 4
}

---@class MissionRelate
---@field MissionActID integer
---@field PreActIDs integer[]
---@field NextActIDs integer[]

---@type table<integer, MissionRelate>
MissionActUtils.ActRelateData = nil

MissionActUtils.TaskActType =
{
    Main = 1,     -- 主线任务
    Side = 2,     -- 支线任务
}

MissionActUtils.TaskNodeShowType =
{
    Normal = 1,   -- 非对话
    DialogueSelf = 2, -- 自己说话
    DialogueNpc = 3, -- 对话
}

MissionActUtils.TaskReviewDisplayType =
{
    Normal = 1,     -- 普通对话
    Chosen = 2,    -- 被选中的选项
    Option = 3,     -- 选项
}

---缓存任务的group json数据
MissionActUtils.AllMissionGroupData = {}
---缓存处理过的任务幕数据，用来显示任务回顾
MissionActUtils.ActDatas = {}

---@class CasePosData
---@field ID integer
---@field PositionX float
---@field PositionY float
---@field Rotation float

---@class CaseEditorResult
---@field AllCasePos CasePosData[]
---@field AllBoardPos CasePosData[]

---@class MissionActConfig
---@field Name string
---@field Descript string
---@field TitleIconResourceRef string
---@field ChapterDesc string
---@field FahnName string
---@field Type integer
---@field DefaultBegin boolean
---@field BeginLevel integer
---@field ActNpc integer
---@field ActPic string
---@field OpenCost integer[]
---@field NpcComment integer[]
---@field Mission_Act_Reward table<integer, integer>
---@field Mission_Act_Conclusion string
---@field MissionBoard_Pic string
---@field MissionBoard_Bg integer
---@field MissionBoard_Label integer

---@class MissionConfig
---@field Name string
---@field Descript string
---@field Type integer
---@field RewardItems integer[]

---@class NoteDataConfig
---@field Type integer
---@field Content string[]

---@class NpcBaseConfig
---@field name string
---@field resource_ref string
---@field icon_ref string
---@field bubble_id integer
---@field default_dialogue integer

---@class MissionBoardConfig
---@field Name string
---@field Content string

---@class MissionNpcComment
---@field NpcID integer
---@field NpcName string
---@field NpcIconKey string
---@field CommentKey string

---@class RandomEventData
---@field IconKey string
---@field TitleKey string
---@field ContentKey string


---@class MissionNodeExportData
---@field Guid string
---@field Type integer
---@field MissionEventID integer
---@field DialogueID integer

---@class MissionExportData
---@field MissionID integer
---@field Nodes MissionNodeExportData[]

---@class MissionActExportData
---@field MissionActID integer
---@field Missions MissionExportData[]

---@type RandomEventData[]
local AllRandomEventDatas = {}

local function InitRandomEventDatas()
    ---@type table<integer, NoteDataConfig>
    local NoteTable = NoteData.data
    for NoteID, v in pairs(NoteTable) do
        if v.Type == NoteData.RandomEvent then
            if #v.Content == 3 then
                ---@type RandomEventData
                local RandomEventData = {}
                RandomEventData.IconKey = v.Content[1]
                RandomEventData.TitleKey = v.Content[2]
                RandomEventData.ContentKey = v.Content[3]
                table.insert(AllRandomEventDatas, RandomEventData)
            else
                G.log:error("MissionActUtils", "InitRandomEventDatas NoteConfig error! %d", NoteID)
            end
        end
    end
end

---@param ID integer
---@return MissionActConfig
function MissionActUtils.GetMissionActConfig(ID)
    return MissionActTable[ID]
end

---@param ID integer
---@return MissionConfig
function MissionActUtils.GetMissionConfig(ID)
    return MissionTable[ID]
end

---@param NpcID integer
---@return NpcBaseConfig
function MissionActUtils.GetNpcConfig(NpcID)
    return NpcBaseTable[NpcID]
end

---@param ID integer
---@return MissionNpcComment[]
function MissionActUtils.GetMissionCompleteNpcComments(ID)
    ---@type MissionNpcComment[]
    local Comments = {}
    local MissionActConfig = MissionActUtils.GetMissionActConfig(ID)
    if MissionActConfig == nil then
        G.log:warn("MissionActUtils", "GetMissionCompleteNpcComments failed! Invalid act ID: %d", ID)
        return Comments
    end
    local NpcComment = MissionActConfig.NpcComment
    if NpcComment == nil or #NpcComment == 0 then
        return Comments
    end
    ---@type integer[]
    local RandomCommentIds = RandomUtil.randomArray(NpcComment, MAX_NPC_COMMENT)
    for _, NoteDataID in ipairs(RandomCommentIds) do
        ---@type NoteDataConfig
        local NoteConfig = NoteData.data[NoteDataID]
        if NoteConfig.Type == NoteData.Comment and #NoteConfig.Content == 2 then
            ---@type MissionNpcComment
            local Comment = {}
            Comment.NpcID = NoteConfig.Content[1]
            ---@type NpcBaseConfig
            local NpcBaseConfig = NpcBaseTable[tonumber(Comment.NpcID)]
            Comment.NpcName = NpcBaseConfig.name
            Comment.NpcIconKey = NpcBaseConfig.icon_ref
            Comment.CommentKey = NoteConfig.Content[2]
            table.insert(Comments, Comment)
        else
            G.log:error("MissionActUtils", "GetMissionCompleteNpcComments NoteConfig error! %d %d %d", ID, NoteDataID, #NoteConfig.Content)
        end
    end
    return Comments
end

---@return RandomEventData[]
function MissionActUtils.RandomEvent()
    if #AllRandomEventDatas == 0 then
        InitRandomEventDatas()
    end
    local RandomNum = math.random(RANDOM_EVENT_MIN, RANDOM_EVENT_MAX)
    ---@type RandomEventData[]
    local RandomEvents = RandomUtil.randomArray(AllRandomEventDatas, RandomNum)
    return RandomEvents
end

---@class EventDescriptionConfig
---@field content string
---@field review_content string

---@param ID integer
---@return EventDescriptionConfig
function MissionActUtils.GetEventDescriptionConfig(ID)
    return EventDescriptionTable[ID]
end

---@class CaseData
---@field ID integer
---@field Name string
---@field IconKey string
---@field BeforeMission integer[]
---@field NextMission integer[]

---@class BoardData
---@field ID integer
---@field Name string
---@field Content string

---@class CaseDatas
---@field Cases CaseData[]
---@field Boards BoardData[]

---@return CaseDatas
function MissionActUtils.GetAllCaseDatas()
    ---@type CaseDatas
    local Data = {}
    Data.Cases = {}
    Data.Boards = {}
    local MissionBoardIds = {}
    for ID, v in pairs(MissionActTable) do
        ---@type CaseData
        local Case = {}
        Case.ID = ID
        Case.Name = v.Name
        Case.IconKey = v.MissionBoard_Pic
        Case.BeforeMission = MissionActUtils.GetPreActIDs(ID)
        Case.NextMission = MissionActUtils.GetNextActIDs(ID)
        table.insert(Data.Cases, Case)
        if Utils.find(MissionBoardIds, v.MissionBoard_Label) == 0 then
            table.insert(MissionBoardIds, v.MissionBoard_Label)
        end
    end
    for _, MissionBoard_Label in ipairs(MissionBoardIds) do
        ---@type MissionBoardConfig
        local MissionBoard = MissionBoardTable[MissionBoard_Label]
        if MissionBoard then
            ---@type BoardData
            local Board = {}
            Board.ID = MissionBoard_Label
            Board.Name = MissionBoard.Name
            Board.Content = MissionBoard.Content
            table.insert(Data.Boards, Board)
        end
    end

    return Data
end

---@return MissionBoardConfig
function MissionActUtils.GetMissionBoardConfig(ID)
    return MissionBoardTable[ID]
end

local function LoadActRelateData()
    local Directory = UE.UKismetSystemLibrary.GetProjectContentDirectory() .. MissionActUtils.MISSION_FLOW_ROOT_PATH
    local JsonArray = UE.UHiEdRuntime.FindFilesRecursive(Directory, "*.json", true, false)
    local Path = nil
    for Ind = 1, JsonArray:Length() do
        local JsonFilePath = JsonArray:Get(Ind)
        local relative_path = JsonFilePath:sub(Directory:len() + 1)
        if string.find(relative_path, MissionActUtils.FILE_NAME_SUFFIX_MAIN) then
            Path = Directory .. relative_path
            break
        end
    end

    local File = UE.UHiEdRuntime.LoadFileToString(Path)
    if File:len() == 0 then
        return
    end
    local Data = Json.decode(File)
    if Data == nil then
        return
    end
    MissionActUtils.ActRelateData = {}
    for MissionActID, MissionData in pairs(Data) do
        ---@type MissionRelate
        local MAData = {}
        MAData.NextActIDs = {}
        MAData.PreActIDs = {}
        MAData.MissionActID = MissionActID
        local NextActIDs = MissionData.NextActIDs
        if NextActIDs ~= nil and #NextActIDs > 0 then
            for _, v in ipairs(NextActIDs) do
                table.insert(MAData.NextActIDs, tonumber(v))
            end
        end
        local PreActIDs = MissionData.PreActIDs
        if PreActIDs ~= nil and #PreActIDs > 0 then
            for _, v in ipairs(PreActIDs) do
                table.insert(MAData.PreActIDs, tonumber(v))
            end
        end
        MissionActUtils.ActRelateData[tonumber(MissionActID)] = MAData
    end
end

---@param MissionActID integer
---@return integer[]
function MissionActUtils.GetNextActIDs(MissionActID)
    if MissionActUtils.ActRelateData == nil then
        LoadActRelateData()
    end
    if MissionActUtils.ActRelateData == nil then
        return nil
    end
    local MissionActData = MissionActUtils.ActRelateData[MissionActID]
    if MissionActData == nil then
        return nil
    end
    return MissionActData.NextActIDs
end

---@param MissionActID integer
---@return integer[]
function MissionActUtils.GetPreActIDs(MissionActID)
    if MissionActUtils.ActRelateData == nil then
        LoadActRelateData()
    end
    if MissionActUtils.ActRelateData == nil then
        return nil
    end
    local MissionActData = MissionActUtils.ActRelateData[MissionActID]
    if MissionActData == nil then
        return nil
    end
    return MissionActData.PreActIDs
end

local function LoadMissionGroupData()
    local Directory = UE.UKismetSystemLibrary.GetProjectContentDirectory() .. MissionActUtils.MISSION_FLOW_ROOT_PATH
    local JsonArray = UE.UHiEdRuntime.FindFilesRecursive(Directory, "*.json", true, false)
    for Ind = 1, JsonArray:Length() do
        local JsonFilePath = JsonArray:Get(Ind)
        local relative_path = JsonFilePath:sub(Directory:len() + 1)
        if string.find(relative_path, MissionActUtils.FILE_NAME_SUFFIX_NORMAL) then
            local Path = Directory .. relative_path
            local File = UE.UHiEdRuntime.LoadFileToString(Path)
            if File:len() > 0 then
                local Data = Json.decode(File)
                if Data ~= nil then
                    local Nodes = Data.nodes
                    local bContainsAct = false
                    for _, NodeValue in pairs(Nodes) do
                        if NodeValue.MissionActID then
                            bContainsAct = true
                        end
                    end
                    if bContainsAct then
                        MissionActUtils.AllMissionGroupData[MissionActUtils.MISSION_FLOW_ROOT_PATH] = Data
                        return
                    end
                end
            end
        end
    end
end

local function GetRootMissionExportData()
    if MissionActUtils.AllMissionGroupData == nil then
        MissionActUtils.AllMissionGroupData = {}
    end
    if MissionActUtils.AllMissionGroupData[MissionActUtils.MISSION_FLOW_ROOT_PATH] == nil then
        LoadMissionGroupData()
    end
    return MissionActUtils.AllMissionGroupData[MissionActUtils.MISSION_FLOW_ROOT_PATH]
end

---@param Asset string
local function GetAssetExportData(Asset)
    local OriginActFilePath = StringUtil:Split(Asset:sub(MissionActUtils.GAME_PREFIX:len() + 2), ".")[1]
    local ExportActFilePath = UE.UKismetSystemLibrary.GetProjectContentDirectory() .. OriginActFilePath..MissionActUtils.FILE_NAME_SUFFIX_NORMAL..".json"
    local File = UE.UHiEdRuntime.LoadFileToString(ExportActFilePath)
    if File:len() == 0 then
        return nil
    end
    local Data = Json.decode(File)
    if Data == nil then
        return nil
    end
    return Data
end

local function GetStartNodeNextGuid(Data)
    local Nodes = Data.nodes
    for _, NodeData in pairs(Nodes) do
        if NodeData.Class == MissionActUtils.START_CLASS and type(NodeData.NextGuids) == "table" then
            return NodeData.NextGuids
        end
    end
    return nil
end

local function GetNodeByGuid(Data, Guid)
    local Nodes = Data.nodes
    for _, NodeData in pairs(Nodes) do
        if NodeData.NodeGuid == Guid then
            return NodeData
        end
    end
    return nil
end

local function FillAllMissionNodes(MissionData, Guids, Nodes)
    local NextGuids = {}
    if Guids and #Guids > 0 then
        for _, Guid in ipairs(Guids) do
            local NodeData = GetNodeByGuid(MissionData, Guid)
            if NodeData.Class then
                local Type = nil
                if string.find(NodeData.Class, MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_SELF) then
                    Type = MissionActUtils.TaskNodeShowType.DialogueSelf
                elseif string.find(NodeData.Class, MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_NPC) or string.find(NodeData.Class, MissionActUtils.MISSION_NODE_CLASS_DIALOGUE_SMS) then
                    Type = MissionActUtils.TaskNodeShowType.DialogueNpc
                elseif NodeData.MissionEventID then
                    Type = MissionActUtils.TaskNodeShowType.Normal
                end
                local bExist = false
                for _, v in ipairs(Nodes)  do
                    if v.Guid == Guid then
                        bExist = true
                        break
                    end
                end
                if Type ~= nil and not bExist then
                    if NodeData.MissionEventID == nil then
                        G.log:warn("mission_act_util", "FillAllMissionNodes invalid param.MissionEventID nil. guid: %s", Guid)
                    elseif (Type == MissionActUtils.TaskNodeShowType.DialogueNpc or Type == MissionActUtils.TaskNodeShowType.DialogueSelf) and NodeData.DialogueID == nil then
                        G.log:warn("mission_act_util", "FillAllMissionNodes invalid param.DialogueID nil.  guid: %s", Guid)
                    else
                        ---@type MissionNodeExportData
                        local Node = {}
                        Node.Guid = Guid
                        Node.Type = Type
                        Node.DialogueID = tonumber(NodeData.DialogueID)
                        Node.MissionEventID = tonumber(NodeData.MissionEventID)
                        table.insert(Nodes, Node)
                    end
                end
            end
            if NodeData.NextGuids and type(NodeData.NextGuids) == "table" then
                for _, v in ipairs(NodeData.NextGuids) do
                    table.insert(NextGuids, v)
                end
            end
        end
    end
    if #NextGuids > 0 then
        FillAllMissionNodes(MissionData, NextGuids, Nodes)
    end
end

local function FillMissionNodes(Asset, Nodes)
    local MissionData = GetAssetExportData(Asset)
    if not MissionData then
        return
    end
    ---@type string[]
    local NextGuids = GetStartNodeNextGuid(MissionData)
    FillAllMissionNodes(MissionData, NextGuids, Nodes)
end

local function FillAllMissionDatas(ActData, Guids, Missions)
    local NextGuids = {}
    if Guids and #Guids > 0 then
        for _, Guid in ipairs(Guids) do
            local MissionData = GetNodeByGuid(ActData, Guid)
            if MissionData.MissionID then
                local bExist = false
                for _, v in ipairs(Missions)  do
                    if v.MissionID == MissionData.MissionID then
                        bExist = true
                        break
                    end
                end
                if not bExist then
                    ---@type MissionExportData
                    local Mission = {}
                    Mission.MissionID = tonumber(MissionData.MissionID)
                    Mission.Nodes = {}
                    FillMissionNodes(MissionData.Asset, Mission.Nodes)
                    table.insert(Missions, Mission)
                end
            end
            if MissionData.NextGuids and type(MissionData.NextGuids) == "table" then
                for _, v in ipairs(MissionData.NextGuids) do
                    table.insert(NextGuids, v)
                end
            end
        end
    end
    if #NextGuids > 0 then
        FillAllMissionDatas(ActData, NextGuids, Missions)
    end
end

---@param MissionActID integer
---@return MissionActExportData
function MissionActUtils.GetMissionActExportData(MissionActID)
    if MissionActUtils.ActDatas[MissionActID] then
        return MissionActUtils.ActDatas[MissionActID]
    end
    local MissionGroupData = GetRootMissionExportData()
    if not MissionGroupData then
        G.log:warn("MissionActUtils", "GetMissionActExportData failed! Cannot find group data! actID:%d", MissionActID)
        return nil
    end
    local Nodes = MissionGroupData.nodes
    local MissionActAsset = nil
    for _, NodeValue in pairs(Nodes) do
        if NodeValue.MissionActID and tonumber(NodeValue.MissionActID) == MissionActID then
            MissionActAsset = NodeValue.Asset
        end
    end
    if not MissionActAsset then
        G.log:warn("MissionActUtils", "GetMissionActExportData failed! Cannot find act asset! actID:%d", MissionActID)
        return nil
    end
    local ActData = GetAssetExportData(MissionActAsset)
    if not ActData then
        G.log:warn("MissionActUtils", "GetMissionActExportData failed! Cannot find act data! actID:%d", MissionActID)
        return nil
    end
    ---@type MissionActExportData
    local MissionActExportData = {}
    MissionActExportData.MissionActID = MissionActID
    MissionActExportData.Missions = {}
    ---@type string[]
    local NextGuids = GetStartNodeNextGuid(ActData)
    FillAllMissionDatas(ActData, NextGuids, MissionActExportData.Missions)
    MissionActUtils.ActDatas[MissionActID] = MissionActExportData
    return MissionActExportData
end

---@param Content string
---@return MissionNodeDialogueStep
local function MockTalkStep(Content, NpcID)
    ---@type MissionNodeDialogueStep
    local Step = {}
    Step.Type = DialogueObjectModule.DialogueType.TALK
    Step.NpcID = NpcID
    Step.Content = Content
    Step.IDs = {}
    table.insert(Step.IDs, ID)
    ID = ID + 1
    return Step
end

---@param Index integer
---@return MissionNodeDialogueStep
local function MockChoiceStep(Index, ...)
    ---@type MissionNodeDialogueStep
    local Step = {}
    Step.Type = DialogueObjectModule.DialogueType.INTERACT
    Step.ChooseIndex = Index
    Step.Choices = {...}
    Step.IDs = {}
    table.insert(Step.IDs, ID)
    ID = ID + 1
    for _, _ in ipairs(Step.Choices) do
        table.insert(Step.IDs, ID)
        ID = ID + 1
    end
    return Step
end

function MissionActUtils.MockMissionNodeDialogueData(MissionActID, DialogueID)
    ---@type MissionNodeDialogueData
    local DialogueData = {}
    DialogueData.DialogueID = DialogueID
    DialogueData.Steps = {}
    table.insert( DialogueData.Steps, MockTalkStep("这是个对话呀11111"))
    table.insert( DialogueData.Steps, MockTalkStep("这是个npc对话呀11111", 30000))
    table.insert( DialogueData.Steps, MockTalkStep("这是个对话呀22222"))
    table.insert( DialogueData.Steps, MockTalkStep("这是个npc对话呀22222", 30000))
    table.insert( DialogueData.Steps, MockChoiceStep(1, "选项一111", "选项二222", "选项三333"))
    table.insert( DialogueData.Steps, MockTalkStep("这是个对话呀4444"))
    table.insert( DialogueData.Steps, MockChoiceStep(2, "选项一11111", "选项二22222", "选项三33333"))
    return DialogueData
end

---@class MissionNodeDialogueStep
---@field Type integer
---@field NpcID integer
---@field Content string
---@field Choices string[]
---@field ChooseIndex integer
---@field AudioPath string
---@field IDs integer

---@class MissionNodeDialogueData
---@field DialogueID integer
---@field Steps MissionNodeDialogueStep[]

---@param DialogueID integer
---@return MissionNodeDialogueData
function MissionActUtils.GetMissionNodeDialogueData(MissionActID, DialogueID)
    ---@type MissionNodeDialogueData
    local DialogueData = {}
    DialogueData.DialogueID = DialogueID
    DialogueData.Steps = {}
    ---@type TaskActVM
    local TaskActVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.TaskActVM.UniqueName)
    local MissionActRecord = TaskActVM:GetMissionAct(MissionActID)
    if MissionActRecord == nil then
        G.log:warn("MissionActUtils", "GetMissionNodeDialogueData failed! Cannot find act record! %d", MissionActID)
        return DialogueData
    end
    ---@type FDialogueRecord
    local FoundDialogueRecord = nil
    local dialogues = MissionActRecord.Dialogues:ToTable()
    for _, DialogueRecord in pairs(dialogues) do
        if DialogueRecord.MissionActID == MissionActID then
            if DialogueRecord.StepRecords and DialogueRecord.StepRecords:Length() > 0 then
                ---@type FDialogueStepRecord
                local FirstDialogueStepRecord = DialogueRecord.StepRecords:GetRef(1)
                if FirstDialogueStepRecord.DialogueID == DialogueID then
                    FoundDialogueRecord = DialogueRecord
                end
            end
        end
    end
    local MissionUtil = require("mission.mission_utils")

    if FoundDialogueRecord then
        for i = 1, FoundDialogueRecord.StepRecords:Length() do
            ---@type FDialogueStepRecord
            local StepRecord = FoundDialogueRecord.StepRecords:GetRef(i)
            local DialogueStep = MissionUtil.GetDialogueStepFromRecord(StepRecord)
            if DialogueStep:GetType() == DialogueObjectModule.DialogueType.TALK then
                ---@type MissionNodeDialogueStep
                local StepData = {}
                StepData.Type = DialogueStep:GetType()
                if DialogueStep:GetOwnerType() == DialogueObjectModule.DialogueStepOwnerType.NPC then
                    StepData.NpcID = FoundDialogueRecord.NpcID
                end
                StepData.Content = DialogueStep:GetContent()
                StepData.AudioPath = DialogueStep:GetAudio()
                StepData.IDs = {}
                table.insert(StepData.IDs, ID)
                ID = ID + 1
                table.insert(DialogueData.Steps, StepData)
            elseif DialogueStep:GetType() == DialogueObjectModule.DialogueType.INTERACT then
                ---@type MissionNodeDialogueStep
                local StepData = {}
                StepData.Type = DialogueStep:GetType()
                StepData.ChooseIndex = StepRecord.Index
                StepData.Choices = {}
                StepData.IDs = {}
                table.insert(StepData.IDs, ID)
                ID = ID + 1
                for _, v in pairs(DialogueStep:GetInteractItems()) do
                    table.insert(StepData.Choices, v.SelectionTitle)
                    table.insert(StepData.IDs, ID)
                    ID = ID + 1
                end
                table.insert(DialogueData.Steps, StepData)
            end
        end
    end

    return DialogueData
end

return MissionActUtils
