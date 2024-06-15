local G = require("G")
local MissionEventTable = require("common.data.event_description_data").data
local UIConstData = require("common.data.ui_const_data").data

local M = {}

local InteractItemBase = Class()

function InteractItemBase:ctor(Type)
    self.Type = Type
    self.SelectionTitle = nil
    self.DisplayIconPath = nil
    self.ShortcutKey = nil
    self.bLongPress = false
    self.LongPressTime = 0
end

-- 获取Item类型
--- return: Enum.Enum_InteractType
function InteractItemBase:GetType()
    return self.Type
end

function InteractItemBase:SetSelectionTitle(SelectionTitle)
    self.SelectionTitle = SelectionTitle
end
-- 获取Item显示的文字
--- return: string
function InteractItemBase:GetSelectionTitle()
    return self.SelectionTitle
end

-- 当前Item 使用禁用
function InteractItemBase:SetUsable(bUseable)
    self.bIconUseable = bUseable
end

function InteractItemBase:GetUsable()
    return self.bIconUseable
end

function InteractItemBase:SetDisplayIconPath(DisplayIconPath)
    self.DisplayIconPath = DisplayIconPath
end
-- 获取Item显示的图标资源路径
--- return: string
function InteractItemBase:GetDisplayIconPath()
    return self.DisplayIconPath
end

function InteractItemBase:SetShortcutKey(ShortcutKey)
    self.ShortcutKey = ShortcutKey
end
-- 获取Item的快捷键
--- return: UE.EKeys
function InteractItemBase:GetShortcutKey()
    return self.ShortcutKey
end

function InteractItemBase:SetLongPress(bLongPress, LongPressTime)
    self.bLongPress = bLongPress
    self.LongPressTime = LongPressTime
end
-- Item是否需要长按
--- return: bool
function InteractItemBase:IsLongPress()
    return self.bLongPress
end
-- Item长按时间
--- return: float
function InteractItemBase:GetLongPressTime()
    return self.LongPressTime
end

function InteractItemBase:SelectionAction()
    if self.SelectCallback then
        self.SelectCallback()
    end
end


local MissionDialogueItem = Class(InteractItemBase)

function MissionDialogueItem:ctor(DialogueID, MissionEventID, SelectCallback)
    Super(MissionDialogueItem).ctor(self, Enum.Enum_InteractType.Mission)
    self.DialogueID = DialogueID
    self.MissionEventID = MissionEventID
    local MissionEventTableData = MissionEventTable[MissionEventID]
    if MissionEventTableData == nil then
        G.log:error("MissionDialogueItem:ctor", "MissionEventID(%s) not exist", MissionEventID)
        self.SelectionTitle = tostring(DialogueID)
    else
        if MissionEventTableData.entrance_description ~= nil then
            self.SelectionTitle = MissionEventTableData.entrance_description
        else
            if string.find(MissionEventTableData.content, "%s") or string.find(MissionEventTableData.content, "%d") then
                self.SelectionTitle = string.format(MissionEventTableData.content, 0)
            else
                self.SelectionTitle = MissionEventTableData.content
            end
        end
    end
    self.SelectCallback = SelectCallback
    self:SetDisplayIconPath(UIConstData.Dialogue_Icon_Default_Task.StringValue)
end

local DefaultInteractEntranceItem = Class(InteractItemBase)

function DefaultInteractEntranceItem:ctor(Actor, NpcName, SelectCallback, InteractType)
    Super(DefaultInteractEntranceItem).ctor(self, InteractType)
    self.Actor = Actor
    self.SelectionTitle = NpcName
    self.SelectCallback = SelectCallback
end

function DefaultInteractEntranceItem:GetActor()
    return self.Actor
end

function DefaultInteractEntranceItem:GetItemID()
    -- 只有DropItem才会使用到，其他类型Actor的ItemID为nil
    if self.Actor then
        return self.Actor.ItemID
    end
    return nil
end

-- 带有距离参数，交互按钮需要按照距离来排序
local DistanceInteractEntranceItem = Class(DefaultInteractEntranceItem)

function DistanceInteractEntranceItem:ctor(Actor, NpcName, SelectCallback, InteractType, Distance)
    Super(DistanceInteractEntranceItem).ctor(self, Actor, NpcName, SelectCallback, InteractType)
    self.Distance = Distance
end

function DistanceInteractEntranceItem:GetDistance()
    return self.Distance
end


local DefaultDialogueItem = Class(InteractItemBase)

function DefaultDialogueItem:ctor(DialogueID, NpcName, SelectCallback, InteractIconPath)
    Super(DefaultDialogueItem).ctor(self, Enum.Enum_InteractType.Normal)
    self.DialogueID = DialogueID
    self.SelectionTitle = NpcName
    self.SelectCallback = SelectCallback
    if InteractIconPath then
        self:SetDisplayIconPath(InteractIconPath)
    end
end

local MissionChoiceItem = Class(InteractItemBase)

function MissionChoiceItem:ctor(DialogueID, Title, SelectCallback)
    Super(MissionChoiceItem).ctor(self, Enum.Enum_InteractType.Normal)
    self.DialogueID = DialogueID
    self.SelectionTitle = Title
    self.SelectCallback = SelectCallback
end


M.InteractItemBase = InteractItemBase
M.MissionDialogueItem = MissionDialogueItem
M.DefaultInteractEntranceItem = DefaultInteractEntranceItem
M.DistanceInteractEntranceItem = DistanceInteractEntranceItem
M.DefaultDialogueItem = DefaultDialogueItem
M.MissionChoiceItem = MissionChoiceItem

return M