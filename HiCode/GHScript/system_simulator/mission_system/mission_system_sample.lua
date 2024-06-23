--
-- 任务系统UI界面接口定义和测试用例
--


-- 任务对象定义 ------------------------------------------
---@class MissionObject
local MissionObject = Class()

function MissionObject:New(MissionData)
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object:Initialize(MissionData)
    return Object
end
function MissionObject:Initialize(MissionData)
    for key, value in pairs(MissionData) do
        self[key] = value
    end
    self.bTracking = false
    self.bArriveMissionArea = false
    self.MissionDistance = math.random(50, 200)
    self.MissionVerticalDistance = math.random(-20, 20)
    self.TrackIconType = 1
    self.MissionTrackDesc = "需要完成其他任务以继续"
    self.MissionSubName = "MissionSubName"
    -- self.bShowPanel = true
    -- self.bBlock = true
    self.BlockReason = '需要完成其他任务以继续'
    self.ChildMissionList = {}
end


-- 获取任务所属章的ID
--- return: int
function MissionObject:GetMissionGroupID()
    return self.MissionGroupID
end

-- 获取任务所属幕的ID
--- return: int
function MissionObject:GetMissionActID()
    return self.MissionActID
end

-- 获取任务ID
--- return: int
function MissionObject:GetMissionID()
    return self.MissionID
end

-- 获取任务所属章的名称
--- return: string
function MissionObject:GetMissionGroupName()
    return self.MissionGroupName
end

-- 获取任务所属幕的名称
--- return: string
function MissionObject:GetMissionActName()
    return self.MissionActName
end

-- 获取任务子标题
--- return: string
function MissionObject:GetMissionActSubname()
    return self.MissionSubName
end

-- 获取任务所属幕的序号：第X章 第X幕
--- return: string
function MissionObject:GetMissionActIndex()
    return self.MissionActIndex
end

-- 获取任务名称
--- return: string
function MissionObject:GetMissionName()
    return self.MissionName
end

-- 获取任务类型
--- return: int
function MissionObject:GetMissionType()
    return self.MissionType
end

-- 获取任务追踪图标类型
--- return: int
function MissionObject:GetMissionTrackIconType()
    return self.TrackIconType
end

-- 获取任务当前节点描述
--- return: string
function MissionObject:GetMissionEventDesc()
    return self.MissionEventDesc
end

-- 获取任务当前节点详细描述
--- return: string
function MissionObject:GetMissionEventDetailDesc()
    return self.MissionEventDetailDesc
end

-- 获取任务状态描述
--- return: string
function MissionObject:GetMissionTrackDesc()
    return self.MissionTrackDesc
end

-- 获取任务所属区域
--- return: string
function MissionObject:GetMissionRegion()
    return self.MissionRegion
end

--- 获取任务奖励列表
--- return: array {Item}
function MissionObject:GetMissionAwards()
    return self.Awards
end


-- 任务是否需要AutoTrack
--- return: bool
function MissionObject:IsAutoTrack()
    return self.bAutoTrack
end

-- 任务是否能被追踪
--- return: bool
function MissionObject:IsTrackable()
    return self.bTrackable
end

-- 任务是否在追踪
--- return: bool
function MissionObject:IsTracking()
    return self.bTracking
end

-- 是否已经到达任务区域
--- return: bool
function MissionObject:IsArriveMissionArea()
    return self.bArriveMissionArea
end

-- 获取离目标任务的距离
--- return: int
function MissionObject:GetMissionDistance()
    return self.MissionDistance
end

-- 获取离目标任务的垂直距离
--- return: float
function MissionObject:GetMissionVerticalDistance()
    return self.MissionVerticalDistance
end

-- 获取能否显示在任务面板
--- return: bool
function MissionObject:IsHide()
    return self.bShowPanel
end

-- 任务是被阻塞
--- return: bool
function MissionObject:IsBlock()
    return self.bBlock
end

function MissionObject:GetList()
    return self.ChildMissionList
end

function MissionObject:GetBlockReason()
    return self.BlockReason
end

-- 任务互动区Item数据对象定义 -----------------------------------
local MissionInteractItem = Class()

function MissionInteractItem:New(InteractItemData)
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object:Initialize(InteractItemData)
    return Object
end
function MissionInteractItem:Initialize(InteractItemData)
    for key, value in pairs(InteractItemData) do
        self[key] = value
    end
end
-- 获取Item类型
--- return: MissionSystemSample.InteractType
function MissionInteractItem:GetType()
    return self.Type
end
-- 获取Item显示的文字
--- return: string
function MissionInteractItem:GetDisplayString()
    return self.DisplayString
end
-- 获取Item显示的图标资源路径
--- return: string
function MissionInteractItem:GetDisplayIconPath()
    return self.DisplayIconPath
end
-- 获取Item的快捷键
--- return: UE.EKeys
function MissionInteractItem:GetShortcutKey()
    return self.ShortcutKey
end

-- Item是否需要长按
--- return: bool
function MissionInteractItem:IsLongPress()
    return self.bLongPress
end

-- Item长按时间
--- return: float
function MissionInteractItem:GetLongPressTime()
    return self.LongPressTime
end


-- 物品数据对象定义 -----------------------------------
local Item = Class()

function Item:New(ItemData)
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object:Initialize(ItemData)
    return Object
end
function Item:Initialize(ItemData)
    for key, value in pairs(ItemData) do
        self[key] = value
    end
end

--- 获取物品的ID
--- return: int
function Item:GetItemID()
    return self.ID
end
--- 获取物品的名称
--- return: string
function Item:GetItemName()
    return self.Name
end
--- 获取物品的图标路径
--- return: string
function Item:GetIconPath()
    return self.IconPath
end
--- 获取物品的品质
-- ItemDef.Quality
function Item:GetQuality()
    return self.Quality
end
--- 获取物品的数量
--- return: int
function Item:GetNumber()
    return self.Number
end

-- 任务章节解锁完成提示数据定义 -----------------------------------
local MissionFinishInfo = Class()

function MissionFinishInfo:New(Title, Content, EnglishContent, State,TitleIcon)
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object.Title = Title
    Object.Content = Content
    Object.State = State
    Object.EnglishContent = EnglishContent
    Object.TitleIcon = TitleIcon

    return Object
end
--- 获取标题：XX章XX幕
--- return: string
function MissionFinishInfo:GetTitle()
    return self.Title
end
--- 获取文本内容：章节/任务名称
--- return: string
function MissionFinishInfo:GetContent()
    return self.Content
end
--- 获取任务状态: 已开启/已完成
--- return: string
function MissionFinishInfo:GetState()
    return self.State
end
--- 获取任务状态: 英文章节
--- return: string
function MissionFinishInfo:GetEnglishContent()
    return self.EnglishContent
end
--- 获取任务状态: 获取图片
--- return: string
function MissionFinishInfo:GetTitleIconKey()
    return self.TitleIcon
end

-- 对话 ---------------------------------------------------------
local Dialogues = Class()
function Dialogues:New()
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    Object.DialogueList = {}
    Object.CurrentIndex = 1
    return Object
end

--- 获取下一句对话内容
--- return: Dialogue
---@param CurrentChoice int 前一句对话的选择，如果是DialogueType.TALK传0；对于DialogueType.INTERACT传交互选项的index
function Dialogues:GetNextDialogue(CurrentChoice)
    local RetVal = self.DialogueList[self.CurrentIndex]
    self.CurrentIndex = self.CurrentIndex + 1
    return RetVal
end

--- 单句对话 ----------------------------------------------------
local Dialogue = Class()
function Dialogue:New()
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    return Object
end

--- 获取对话类型
--- return: MissionSystemSample.DialogueType
function Dialogue:GetType()
    return self.Type
end
--- 获取对话内容：对DialogueType.TALK有效
--- return: DialogueContent
function Dialogue:GetContent()
    return self.Content
end
--- 获取交互选项：对DialogueType.INTERACT有效
--- return: array {MissionInteractItem}
function Dialogue:GetInteract()
    return self.Interact
end

--- 对话内容 ----------------------------------------------------
local DialogueContent = Class()
function DialogueContent:New()
    local Object = {}
    setmetatable(Object, self)
    self.__index = self
    return Object
end

--- 获取发言者名字
--- return: string
function DialogueContent:GetTalkerName()
    return self.TalkerName
end
--- 获取发言内容
--- return string
function DialogueContent:GetContent()
    return self.Content
end
--- 能否跳过
--- return bool
function DialogueContent:CanSkip()
    return self.bCanSkip
end


local MissionSystemSample = {}

MissionSystemSample.InteractType = {
    NORMAL = 1,
    MISSION = 2
}

MissionSystemSample.DialogueType = {
    TALK = 1,               -- 普通对白
    INTERACT = 2,           -- 互动选项
    FINISHED = 3,           -- 对白结束
}

local ItemDef = require("CP0032305_GH.Script.item.ItemDef")

-- 初始化测试数据 --------------------------------------------------------------------------------------------------------------
function MissionSystemSample:Initialize()
    self.ItemTable = {
        {
            ID = 100001,
            Name = "测试物品1",
            IconPath = "/Game/CP0032305_GH/UI/Texture/Props/NoAtlas/Img_renwuzhujiemian_rightwupinImg.Img_renwuzhujiemian_rightwupinImg",
            Quality = ItemDef.Quality.WHITE,
            Number = 40,
        },
        {
            ID = 100002,
            Name = "测试物品2",
            IconPath = "/Game/CP0032305_GH/UI/Texture/Props/NoAtlas/T_Icon_Props_Ball.T_Icon_Props_Ball",
            Quality = ItemDef.Quality.GREEN,
            Number = 10,
        },
        {
            ID = 990010,
            Name = "测试物品3",
            IconPath = "/Game/CP0032305_GH/UI/Texture/Props/NoAtlas/T_Icon_Props_Coin.T_Icon_Props_Coin",
            Quality = ItemDef.Quality.BLUE,
            Number = 10,
        },
        {
            ID = 110001,
            Name = "测试物品4",
            IconPath = "/Game/CP0032305_GH/UI/Texture/Props/NoAtlas/T_Icon_Props_Fragments.T_Icon_Props_Fragments",
            Quality = ItemDef.Quality.PURPLE,
            Number = 1,
        },
        {
            ID = 110002,
            Name = "测试物品4",
            IconPath = "/Game/CP0032305_GH/UI/Texture/Common/Atlas/Frames/T_Icon_Props_Hat.T_Icon_Props_Hat",
            Quality = ItemDef.Quality.ORANGE,
            Number = 5,
        },
    }
    self.MissionDataTableIndex = {}
    self.MissionDataTable = {
        {
            MissionGroupID = 1,
            MissionActID = 100,
            MissionID = 1000,
            MissionName = "测试任务1000",
            MissionType = 1,
            MissionState = 1,
            MissionGroupName = "任务章12222",
            MissionActName = "任务幕12222222",
            MissionActIndex = "第一章 第一幕",
            MissionEventDesc = "测试任务1000 任务节点描述",
            MissionEventDetailDesc = "测试任务1000 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩",
            Awards = self:CreateItemList(1),
            bAutoTrack = true,
            bTrackable = false,
            bShowPanel = false,
            ChildMissionList = {},
            bBlock = true,
        },
        {
            MissionGroupID = 1,
            MissionActID = 100,
            MissionID = 10000,
            MissionName = "测试任务10000",
            MissionType = 1,
            MissionState = 1,
            MissionGroupName = "任务章1",
            MissionActName = "任务幕1",
            MissionActIndex = "第一章 第一幕",
            MissionEventDesc = "测试任务10000 任务节点描述",
            MissionEventDetailDesc = "测试任务10000 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩",
            Awards = self:CreateItemList(1),
            bAutoTrack = true,
            bTrackable = true,
            bShowPanel = false,
            bBlock = false,
        },
        {
            MissionGroupID = 1,
            MissionActID = 100,
            MissionID = 10001,
            MissionName = "测试任务10001",
            MissionType = 2,
            MissionState = 2,
            MissionGroupName = "任务章1",
            MissionActName = "任务幕1",
            MissionActIndex = "第一章 第一幕1",
            MissionEventDesc = "测试任务10001 任务节点描述",
            MissionEventDetailDesc = "测试任务10001 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩",
            Awards = self:CreateItemList(2),
            bAutoTrack = true,
            bTrackable = false,
            bShowPanel = false,
            bBlock = true,
        },
        {
            MissionGroupID = 1,
            MissionActID = 100,
            MissionID = 10002,
            MissionName = "测试任务10002",
            MissionType = 3,
            MissionState = 3,
            MissionGroupName = "任务章1",
            MissionActName = "任务幕1",
            MissionActIndex = "第一章 第一幕2",
            MissionEventDesc = "测试任务10002 任务节点描述",
            MissionEventDetailDesc = "测试任务10002 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩",
            Awards = self:CreateItemList(3),
            bAutoTrack = true,
            bTrackable = false,
            bShowPanel = false,
            ChildMissionList = {},
            bBlock = true,
        },
        {
            MissionGroupID = 1,
            MissionActID = 101,
            MissionID = 10100,
            MissionName = "测试任务10100",
            MissionType = 4,
            MissionState = 4,
            MissionGroupName = "任务章1",
            MissionActName = "任务幕2",
            MissionActIndex = "第一章 第二幕",
            MissionEventDesc = "测试任务10100 任务节点描述",
            MissionEventDetailDesc = "测试任务10100 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩2",
            Awards = self:CreateItemList(4),
            bAutoTrack = true,
            bTrackable = true,
            bShowPanel = false,
        },
        {
            MissionGroupID = 1,
            MissionActID = 101,
            MissionID = 10101,
            MissionName = "测试任务10101",
            MissionType = 1,
            MissionState = 4,
            MissionGroupName = "任务章1",
            MissionActName = "任务幕2",
            MissionActIndex = "第一章 第二幕",
            MissionEventDesc = "测试任务10101 任务节点描述",
            MissionEventDetailDesc = "测试任务10101 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩2",
            Awards = self:CreateItemList(5),
            bAutoTrack = false,
            bTrackable = false,
            bShowPanel = false,
        },
        {
            MissionGroupID = 2,
            MissionActID = 200,
            MissionID = 20000,
            MissionName = "测试任务20000",
            MissionType = 1,
            MissionState = 1,
            MissionGroupName = "任务章2",
            MissionActName = "任务幕1",
            MissionActIndex = "第二章 第一幕",
            MissionEventDesc = "测试任务20000 任务节点描述",
            MissionEventDetailDesc = "测试任务20000 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩4",
            Awards = self:CreateItemList(5),
            bAutoTrack = false,
            bTrackable = true,
            bShowPanel = false,
        },
        {
            MissionGroupID = 3,
            MissionActID = 300,
            MissionID = 30000,
            MissionName = "测试任务30000",
            MissionType = 1,
            MissionState = 1,
            MissionGroupName = "任务章3",
            MissionActName = "任务幕1",
            MissionActIndex = "第三章 第一幕",
            MissionEventDesc = "测试任务30000 任务节点描述",
            MissionEventDetailDesc = "测试任务30000 任务节点详细描述任务节点详细描述任务节点详细描述任务节点详细描述",
            MissionRegion = "法恩4",
            Awards = self:CreateItemList(5),
            bAutoTrack = false,
            bTrackable = true,
            bShowPanel = false,
        },
    }
    for _, MissionData in ipairs(self.MissionDataTable) do
        self.MissionDataTableIndex[MissionData["MissionID"]] = MissionData
    end

    self.MissionInteractItemTable = {
        {
            Type = MissionSystemSample.InteractType.NORMAL,
            DisplayString = "测试交互01",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.F,
            bLongPress = false,
            LongPressTime = 0.0,
        },
        {
            Type = MissionSystemSample.InteractType.MISSION,
            DisplayString = "测试交互02",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.F,
            bLongPress = false,
            LongPressTime = 0.0,
        },
        {
            Type = MissionSystemSample.InteractType.NORMAL,
            DisplayString = "测试交互03",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.F,
            bLongPress = true,
            LongPressTime = 5.0,
        },
        {
            Type = MissionSystemSample.InteractType.NORMAL,
            DisplayString = "测试交互04",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.Escape,
            bLongPress = false,
            LongPressTime = 0.0,
        },
        {
            Type = MissionSystemSample.InteractType.MISSION,
            DisplayString = "测试交互05",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.F,
            bLongPress = false,
            LongPressTime = 0.0,
        },
        {
            Type = MissionSystemSample.InteractType.MISSION,
            DisplayString = "测试交互06",
            DisplayIconPath = "",
            ShortcutKey = UE.EKeys.F,
            bLongPress = false,
            LongPressTime = 0.0,
        },
    }
end

function MissionSystemSample:CreateIndexMissionList(Size)
    local Items = {}
    for i = 1, Size do
        local ItemData = self.MissionDataTable[i]
        Items[i] = MissionObject:New(ItemData)
    end
    return Items
end

function MissionSystemSample:AddMissionList(MissionID)
    local list
    if MissionID == 10002 then
        list = self:CreateIndexMissionList(3)
    end
    if MissionID == 10001 then
        list = self:CreateIndexMissionList(1)
    end
    return list
end

function MissionSystemSample:CreateMission(MissionID)
    return MissionObject:New(self.MissionDataTableIndex[MissionID])
end

function MissionSystemSample:GetShortInteractItems()
    local Items = {}
    for i = 1, 4 do
        local InteractItemData = self.MissionInteractItemTable[i]
        Items[i] = MissionInteractItem:New(InteractItemData)
    end
    return Items
end

function MissionSystemSample:GetLongInteractItems()
    local Items = {}
    for i = 1, 6 do
        local InteractItemData = self.MissionInteractItemTable[i]
        Items[i] = MissionInteractItem:New(InteractItemData)
    end
    return Items
end

function MissionSystemSample:CreateItemList(Size)
    local Items = {}
    for i = 1, Size do
        local ItemData = self.ItemTable[i]
        Items[i] = Item:New(ItemData)
    end
    return Items
end

function MissionSystemSample:CreateMissionFinishInfo(Title, Content, EnglishContent, State,TitleIcon)
    return MissionFinishInfo:New(Title, Content, EnglishContent, State,TitleIcon)
end

local DialogueObjectModule = require("mission.dialogue_object")

function MissionSystemSample:CreateDialogue1()
    local DialogueObject = DialogueObjectModule.Dialogue.new()

    local DialogueStep1 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep1.TalkerName = 'NPC名字'
    DialogueStep1.Content = "NPC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</>NP\nC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</>NPC1<name>NPC说话1</>NPC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</><name>NPC说话1</>NPC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</>"
    -- DialogueStep1.Content = "NPC说话1<name>NPC说话1</>NPC说话1<name>NPC说话1</>NP"
    DialogueStep1.bCanSkip = true
    DialogueStep1.GetAudio = function()
        -- return '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
    end
    DialogueStep1.GetCanSkipTime = function()
        return 5
    end
    DialogueObject.EntryStep = DialogueStep1

    local DialogueStep2 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep2.TalkerName = '玩家名字'
    -- DialogueStep2.Content = "<name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</>"
    DialogueStep2.Content = "<name>玩家说话1</><name>玩家说话1</><name>玩家说话1</><name>玩家说话1</>"
    DialogueStep2.GetAudio = function()
        -- return '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
        ---- return '/Game/WwiseAudio/Events/Default_Work_Unit/Play_Doppler_Test.Play_Doppler_Test'
    end
    DialogueStep2.GetCanSkipTime = function()
        return 5
    end
    DialogueStep2.bCanSkip = true


    local DialogueStep3 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep3.TalkerName = 'NPC名字'
    DialogueStep3.Content = "NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2NPC说话2"
    DialogueStep3.GetAudio = function()
        -- return '/Game/WwiseAudio/Events/BattleMusic/BattleMusic_Test/Play_Battle_Win_Music_Test.Play_Battle_Win_Music_Test'
    end
    DialogueStep3.GetCanSkipTime = function()
        return 5
    end
    DialogueStep3.bCanSkip = false

    local DialogueStep4 = DialogueObjectModule.DialogueStep.new(MissionSystemSample.DialogueType.FINISHED)

    DialogueStep1.tbNextStep[1] = DialogueStep2
    DialogueStep2.tbNextStep[1] = DialogueStep3
    DialogueStep3.tbNextStep[1] = DialogueStep4

    return DialogueObject
end

local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')

local InteractItems = {}
InteractItems[1] =
{
    GetSelectionTitle = function()
        return '跳转对话一'
    end,
    SelectionAction = function()
        local DialogueObject = MissionSystemSample:CreateDialogue1()
        local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
        DialogueVM:OpenDialogInstance(DialogueObject)
    end,
    GetDisplayIconPath = function()
    end,
}
InteractItems[2] =
{
    GetSelectionTitle = function()
        return '循环对话二'
    end,
    SelectionAction = function()
        local DialogueObject = MissionSystemSample:CreateDialogue2()
        local DialogueVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
        DialogueVM:OpenDialogInstance(DialogueObject)
    end,
    GetDisplayIconPath = function()
    end,
}
InteractItems[3] =
{
    GetSelectionTitle = function()
        return '离开'
    end,
    SelectionAction = function()
    end,
    GetDisplayIconPath = function()
        return '/Game/CP0032305_GH/UI/Texture/Communication/Atlas/Frames/T_Icon_Interact_A_03_png.T_Icon_Interact_A_03_png'
    end,
}
InteractItems[4] =
{
    GetSelectionTitle = function()
        return 'qqq'
    end,
    SelectionAction = function()
    end,
}
InteractItems[5] =
{
    GetSelectionTitle = function()
        return 'qqq'
    end,
    SelectionAction = function()
    end,
}
InteractItems[6] =
{
    GetSelectionTitle = function()
        return 'qqq'
    end,
    SelectionAction = function()
    end,
}
InteractItems[7] =
{
    GetSelectionTitle = function()
        return 'qqq'
    end,
    SelectionAction = function()
    end,
}

function MissionSystemSample:CreateDialogue2()
    local DialogueObject = DialogueObjectModule.Dialogue.new()

    local DialogueStep1 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep1.TalkerName = 'NPC名字'
    DialogueStep1.Content = "NPC说话1 新华社北京8月10日电 题：有效推动中华优秀传统文化创造性转化创新性发展——各地各有关部门深入贯彻落实文化传承发展座谈会精神"
    DialogueStep1.bCanSkip = true
    DialogueObject.EntryStep = DialogueStep1


    local DialogueStep2 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep2.TalkerName = '玩家名字'
    DialogueStep2.Content = "玩家说话1  6月中旬启动的“平江九巷”城市更新项目及“古城保护更新伙伴计划”正在推进中。“居民、游客将可在此沉浸式体验‘食四时之鲜、居园林之秀、听昆曲之雅、用苏工之美’的‘苏式生活’。"
    DialogueStep2.bCanSkip = true


    local DialogueStep3 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.TALK)
    DialogueStep3.TalkerName = 'NPC名字'
    DialogueStep3.Content = "NPC说话2"
    DialogueStep3.bCanSkip = false
    

    local DialogueStep4 = DialogueObjectModule.DialogueStep.new(DialogueObjectModule.DialogueType.INTERACT)
    DialogueStep4.InteractItems = {}
    DialogueStep4.InteractItems[1] = MissionInteractItem:New(InteractItems[1])
    DialogueStep4.InteractItems[2] = MissionInteractItem:New(InteractItems[2])
    DialogueStep4.InteractItems[3] = MissionInteractItem:New(InteractItems[3])
    DialogueStep4.InteractItems[4] = MissionInteractItem:New(InteractItems[4])
    DialogueStep4.InteractItems[5] = MissionInteractItem:New(InteractItems[5])
    DialogueStep4.InteractItems[6] = MissionInteractItem:New(InteractItems[6])
    DialogueStep4.InteractItems[7] = MissionInteractItem:New(InteractItems[7])

    DialogueStep4.tbNextStep[1] = DialogueObjectModule.DialogueStep.new(MissionSystemSample.DialogueType.FINISHED)
    DialogueStep4.tbNextStep[1].fnCall = DialogueStep4.InteractItems[1].SelectionAction

    DialogueStep4.tbNextStep[2] = DialogueObjectModule.DialogueStep.new(MissionSystemSample.DialogueType.FINISHED)
    DialogueStep4.tbNextStep[2].fnCall = DialogueStep4.InteractItems[2].SelectionAction

    DialogueStep4.tbNextStep[3] = DialogueObjectModule.DialogueStep.new(MissionSystemSample.DialogueType.FINISHED)
    DialogueStep4.tbNextStep[3].fnCall = DialogueStep4.InteractItems[3].SelectionAction
    


    DialogueStep1.tbNextStep[1] = DialogueStep2
    DialogueStep2.tbNextStep[1] = DialogueStep3
    DialogueStep3.tbNextStep[1] = DialogueStep4

    return DialogueObject
end

---`brief`弹幕界面测试案例
function MissionSystemSample:Test_BrgSeq4()
    local Stag_First = {Content = {'666', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多'}}
    local Stage_Second = {Content = {'777', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多', '阿卡娅阿卡娅', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多', '里卡多里卡多里卡多阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '里卡多里卡多里卡多'}}
    local Stage_Third = {Content = {'888', '阿卡娅阿卡娅阿卡娅里', '阿卡娅里卡多阿卡娅里卡多', '阿卡娅阿卡娅', '里里里', '里卡多里卡多里卡多'}}
    local Stage_Fourth = {Content = {'999', '阿卡娅', '里卡多', '阿卡娅阿卡娅', '阿卡娅娅里卡多', '阿卡娅娅里', '阿卡娅里卡多阿卡', '里卡多里卡多'}}
    return Stag_First, Stage_Second, Stage_Third, Stage_Fourth
end

---`brief`演职员表界面测试案例
function MissionSystemSample:Test_ScreenCreditList()
    local tb = {
        {GroupName = '演员表_1', Content = {
            {Entry = '里卡多', Name = '名字_1'},
            {Entry = '卡萨亚', Name = '名字_2'},
            {Entry = '威尔杜呀龖', Name = '名字_3'},
            {Entry = '路边大妈', Name = '名字_4'}}
        },
        {GroupName = '演员表_2', Content = {{Entry = '便利店店员', Name = '名字_5'}, {Entry = '便利店店长', Name = '名字_6'}}},
        {GroupName = '制作团队_1', Content = {{Entry = '导演', Name = '名字_7'}, {Entry = '主策划', Name = '名字_8'}, {Entry = '执行策划', Name = '名字_9'}, {Entry = '执行策划', Name = '名字_10'}, {Entry = '执行策划', Name = '名字_11'}}},
        {GroupName = '制作团队_2', Content = {{Entry = '分镜', Name = '名字_12'}, {Entry = '动画', Name = '名字_13'}, {Entry = '特效', Name = '名字_14'}}},
        {GroupName = '演员表_1', Content = {{Entry = '里卡多', Name = '名字_1'}, {Entry = '卡萨亚', Name = '名字_2'}, {Entry = '威尔杜呀龖', Name = '名字_3'}, {Entry = '路边大妈', Name = '名字_4'}}},
        {GroupName = '演员表_2', Content = {{Entry = '便利店店员', Name = '名字_5'}, {Entry = '便利店店长', Name = '名字_6'}}},
        {GroupName = '制作团队_1', Content = {{Entry = '导演', Name = '名字_7'}, {Entry = '主策划', Name = '名字_8'}, {Entry = '执行策划', Name = '名字_9'}, {Entry = '执行策划', Name = '名字_10'}, {Entry = '执行策划', Name = '名字_11'}}},
        {GroupName = '制作团队_2', Content = {{Entry = '分镜', Name = '名字_12'}, {Entry = '动画', Name = '名字_13'}, {Entry = '特效', Name = '名字_14'}}},
        {GroupName = '演员表_1', Content = {{Entry = '里卡多', Name = '名字_1'}, {Entry = '卡萨亚', Name = '名字_2'}, {Entry = '威尔杜呀龖', Name = '名字_3'}, {Entry = '路边大妈', Name = '名字_4'}}},
        {GroupName = '演员表_2', Content = {{Entry = '便利店店员', Name = '名字_5'}, {Entry = '便利店店长', Name = '名字_6'}}},
        {GroupName = '制作团队_1', Content = {{Entry = '导演', Name = '名字_7'}, {Entry = '主策划', Name = '名字_8'}, {Entry = '执行策划', Name = '名字_9'}, {Entry = '执行策划', Name = '名字_10'}, {Entry = '执行策划', Name = '名字_11'}}},
        {GroupName = '制作团队_2', Content = {{Entry = '分镜', Name = '名字_12'}, {Entry = '动画', Name = '名字_13'}, {Entry = '特效', Name = '名字_14'}}}
    }
    return tb
end

-- function MissionSystemSample:CreateDialogue()
--     local DialoguesTest = Dialogues:New()

--     local DialogueTest = Dialogue:New()
--     DialoguesTest.Type = MissionSystemSample.DialogueType.TALK
--     local DialogueContentTest = DialogueContent:New()
--     DialogueContentTest.TalkerName = "NPC名字"
--     DialogueContentTest.Content = "NPC说话1"
--     DialogueContentTest.bCanSkip = true
--     DialoguesTest.Content = DialogueContentTest
--     DialoguesTest.DialogueList[1] = DialogueTest

--     DialogueTest = Dialogue:New()
--     DialoguesTest.Type = MissionSystemSample.DialogueType.TALK
--     DialogueContentTest = DialogueContent:New()
--     DialogueContentTest.TalkerName = "玩家名字"
--     DialogueContentTest.Content = "玩家说话1"
--     DialogueContentTest.bCanSkip = true
--     DialoguesTest.Content = DialogueContentTest
--     DialoguesTest.DialogueList[2] = DialogueTest

--     DialogueTest = Dialogue:New()
--     DialoguesTest.Type = MissionSystemSample.DialogueType.TALK
--     DialogueContentTest = DialogueContent:New()
--     DialogueContentTest.TalkerName = "NPC名字"
--     DialogueContentTest.Content = "NPC说话2"
--     DialogueContentTest.bCanSkip = false
--     DialoguesTest.Content = DialogueContentTest
--     DialoguesTest.DialogueList[3] = DialogueTest

--     DialogueTest = Dialogue:New()
--     DialoguesTest.Type = MissionSystemSample.DialogueType.INTERACT
--     DialoguesTest.Interact = self:GetShortInteractItems()
--     DialoguesTest.DialogueList[4] = DialogueTest


--     DialogueTest = Dialogue:New()
--     DialoguesTest.Type = MissionSystemSample.DialogueType.FINISHED
--     DialoguesTest.DialogueList[5] = DialogueTest

--     return DialoguesTest
-- end

function MissionSystemSample:CreateMissionList()
    local MissionList = {}
    for i = 1, #self.MissionDataTable do
        MissionList[i] = MissionObject:New(self.MissionDataTable[i])
    end

    return MissionList
end

MissionSystemSample:Initialize()

return MissionSystemSample