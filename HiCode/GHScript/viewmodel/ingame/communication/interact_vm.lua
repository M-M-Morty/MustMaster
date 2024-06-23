--
-- @COMPANY GHGame
-- @AUTHOR xuminjie
--

local G = require('G')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local ItemUtil = require("CP0032305_GH.Script.item.ItemUtil")

local NpcInteractDef = nil
pcall(function()
    NpcInteractDef = require('common.data.npc_interact_data')
end)

---@class InteractVM : ViewModelBase
local InteractVM = Class(ViewModelBaseClass)

---@class InteractItemType
InteractVM.InteractItemType = {
    Mutex    = 1,               -- 该选项与其他所有选项互斥, 交互一次后交互UI关闭, 此项为默认
    Once     = 2,               -- 该选项交互一次后移除
    Const    = 3,               -- 常驻选项可重复交互
}

function InteractVM:ctor()
    Super(InteractVM).ctor(self)

    -- 为以后交互和对话选项同时存在时处理，暂未实现
    self.CurrentDialogSelection = nil
    self.CurrentInteractSelection = nil
    self.InteractIncreaseQueue = {}
    self.InteractDecreaseQueue = {}
    self.BatchIndex = 0
end

function InteractVM:OpenDialogSelection(SelectionItems)
    local UI = UIManager:OpenUI(UIDef.UIInfo.UI_InteractPickup, SelectionItems, UIDef.InteractUIType.Dialogue, self.InteractItemType.Mutex)
    local Player = UE.UGameplayStatics.GetPlayerCharacter(G.GameInstance:GetWorld(), 0)
    UI:AsSituation(true, #SelectionItems)
end

function InteractVM:OpenSituationSelection(SelectionItems)
    -- 情景交互要求有序号
    for i = 1, #SelectionItems do
        SelectionItems[i].Prefix = tostring(i) .. '. '
    end
    self.CurrentInteractData = SelectionItems
    local UI = UIManager:OpenUI(UIDef.UIInfo.UI_InteractPickup, SelectionItems, UIDef.InteractUIType.Dialogue, self.InteractItemType.Mutex)
    UI:AsSituation(false, #SelectionItems)
end

function InteractVM:CloseDialogSelection()
    G.log:debug('zys', table.concat({'InteractVM:CloseDialogSelection', debug.traceback()}))
    UIManager:CloseUIByName(UIDef.UIInfo.UI_InteractPickup.UIName)
    -- 此处为DialogueVM调用, 打开dialogue的时候需要将情景界面关闭
    UIManager:CloseUIByName(UIDef.UIInfo.UI_Situation_Chat.UIName, true)
    self.CurNotSort = false
end

function InteractVM:OpenInteractSelection(InteractItems)
    G.log:debug('zys', table.concat({'InteractVM:OpenInteractSelection', debug.traceback()}))
    local DialogVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    if DialogVM then
        DialogVM:CloseDialog()
    end

    self.CurrentInteractData = InteractItems
    UIManager:OpenUI(UIDef.UIInfo.UI_InteractPickup, self.CurrentInteractData, UIDef.InteractUIType.Interact, self.InteractItemType.Mutex)
end

---@param InteractItems table
---@param bNotSort boolean @[opt] 是否不允许排序, 为电梯功能专设, 其他情况下一般不填
---@param ForceIndex number @[opt] 默认选择某个条目, 为电梯功能专设, 其他情况下一般不填
function InteractVM:OpenInteractSelectionForPickup(InteractItems, bNotSort, ForceIndex)
    local ForceIndex = ForceIndex and ForceIndex or 1
    local DialogVM = ViewModelCollection:FindUniqueViewModel(VMDef.UniqueVMInfo.DialogueVM.UniqueName)
    if DialogVM then
        -- DialogVM:CloseDialog()
        xpcall(function()
            DialogVM:CloseDialog()
        end, function(err)
            if err then
                G.log:error('关闭dialog出现了问题', debug.traceback())
            end
        end)
    end
    self.BatchIndex = self.BatchIndex + 1
    -- G.log:debug('zys', table.concat({'InteractVM:OpenInteractSelectionForPickup  BATACH: ', self.BatchIndex, ', bNotSort: ', tostring(bNotSort), ', ForceIndex: ', ForceIndex, ', count: ', #InteractItems}))
    local SortedNewList = self:SortInteractItems(InteractItems, bNotSort, ForceIndex)
    if self.CurrentInteractData and #self.CurrentInteractData > 0 then
        -- 多次的刷新流程
        -- '不允许排序'时不可刷新直到再次打开界面
        if not self.CurNotSort and not bNotSort then
            self:UpdateCurInteractData(SortedNewList)
        end
    else
        -- 首次的打开流程
        self.CurrentInteractData = SortedNewList -- InteractItems
        local UIPickup = UIManager:OpenUI(UIDef.UIInfo.UI_InteractPickup, self.CurrentInteractData, UIDef.InteractUIType.Interact, self.InteractItemType.Once)
        UIPickup:RawSetSelectionIndex(ForceIndex)
    end
    self.CurNotSort = bNotSort and true or false
end

function InteractVM:CloseInteractSelection()
    self.InteractIncreaseQueue = {}
    self.InteractDecreaseQueue = {}
    self.CurrentInteractData = {}
    if UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_InteractPickup.UIName) then
        G.log:debug('zys', table.concat({'InteractVM:CloseInteractSelection', debug.traceback()}))
    end
    UIManager:CloseUIByName(UIDef.UIInfo.UI_InteractPickup.UIName, true)

    self.CurNotSort = false
end

function InteractVM:InteractSelect(InteractIndex, bRemove)
    if self.CurrentInteractData then
        local InteractItem = self.CurrentInteractData[InteractIndex]
        if InteractItem and InteractItem.SelectionAction then
            if bRemove then
                table.remove(self.CurrentInteractData, InteractIndex)
            end
            local status, result = xpcall(function()
                InteractItem:SelectionAction()
            end, function(err)
                if err then
                    G.log:error('pickup运行回调出现了问题', debug.traceback())
                end
            end)
        end
    end
end

---`public`
function InteractVM:ContinuousInvokePickup()
    if not self.CurrentInteractData or not (#self.CurrentInteractData > 0) then
        G.log:debug('zys', 'failed to ContinuousInvokePickup')
        return
    end
    local UI = UIManager:GetUIInstanceIfVisible(UIDef.UIInfo.UI_InteractPickup.UIName)
    if not UI then
        G.log:debug('zys', 'pickup ui has closed')
        return
    end
    local Index = 1
    while Index <= #self.CurrentInteractData do
        local Item = self.CurrentInteractData[Index]
        if Item and Item.SelectionAction and Item.GetType and Item:GetType() == Enum.Enum_InteractType.DropItem then
            local status, result = xpcall(function()
                Item:SelectionAction()
            end, function(err)
                if err then
                    G.log:error('pickup运行回调出现了问题', debug.traceback())
                end
            end)
            if not status then
            end
            table.remove(self.CurrentInteractData, Index)
        else
            Index = Index + 1
        end
    end
end

---`public`
function InteractVM:RequestQueueMem()
    if (#self.InteractIncreaseQueue + #self.InteractDecreaseQueue) <= 0 then
        return false
    end
    local UI = UIManager:GetUIInstance(UIDef.UIInfo.UI_InteractPickup.UIName)
    if #self.InteractDecreaseQueue > 0 then
        local Index = -1
        local Item = self.InteractDecreaseQueue[1]
        for i = 1, #self.CurrentInteractData do
            if self:IsInteractItemSame(self.CurrentInteractData[i], Item) then
                Index = i
            end
        end
        if Index > 0 then
            UI:DecreaseItem(Index)
            table.remove(self.CurrentInteractData, Index)
            table.remove(self.InteractDecreaseQueue, 1)
            return true
        end
        return false
    end
    if #self.InteractIncreaseQueue > 0 then
        local Index = -1
        local Item = self.InteractIncreaseQueue[1]
        for i = 1, #self.CurrentInteractData do
            local CurrentItem = self.CurrentInteractData[i]
            local Type1 = Item.GetType and Item:GetType() or 0
            local Type2 = CurrentItem:GetType()
            if Type1 > Type2 then
                Index = i
                break
            end
            local Quality1 = -1
            local Quality2 = -1
            if Item.GetQuality then
                Quality1 = Item:GetQuality()
            end
            if Item.GetItemID and Item:GetItemID() ~= nil and Item:GetItemID() > 0 then
                local ItemConfig = ItemUtil.GetItemConfigByExcelID(Item:GetItemID())
                Quality1 = ItemConfig.quality
            end
            if CurrentItem.GetQuality then
                Quality2 = CurrentItem:GetQuality()
            end
            if CurrentItem.GetItemID and CurrentItem:GetItemID() ~= nil and CurrentItem:GetItemID() > 0 then
                local ItemConfig = ItemUtil.GetItemConfigByExcelID(CurrentItem:GetItemID())
                Quality2 = ItemConfig.quality
            end
            if Quality1 > Quality2 then
                Index = i
                break
            end
            local Dst_1 = Item.GetDistance and Item:GetDistance() or 1000
            local Dst_2 = CurrentItem.GetDistance and CurrentItem:GetDistance() or 1000
            if Dst_1 < Dst_2 then
                Index = i
                break
            end
        end
        if Index > 0 then
            UI:IncreaseItem(Index, Item)
            table.insert(self.CurrentInteractData, Index, Item)
        else
            local Idx = #self.CurrentInteractData + 1
            UI:IncreaseItem(#self.CurrentInteractData + 1, Item)
            table.insert(self.CurrentInteractData, Item)
        end
        table.remove(self.InteractIncreaseQueue, 1)
        return true
    end
end

---`private`
function InteractVM:UpdateCurInteractData(NewList)
    local IncreaseList = {}
    local DecreaseList = {}
    for i = 1, #NewList do
        IncreaseList[i] = NewList[i]
    --     local Title = NewList[i].GetSelectionTitle and NewList[i]:GetSelectionTitle() or (NewList[i].GetItemID and NewList[i]:GetItemID() or 'no title')
    --     G.log:debug('zys', table.concat({'vm new item content:', Title, NewList[i]:GetType(), tostring(NewList[i]:GetActor())}))
    end
    for i = 1, #self.CurrentInteractData do
        DecreaseList[i] = self.CurrentInteractData[i]
    --     local Title = DecreaseList[i].GetSelectionTitle and DecreaseList[i]:GetSelectionTitle() or (DecreaseList[i].GetItemID and DecreaseList[i]:GetItemID() or 'no title')
    --    G.log:debug('zys', table.concat({'vm old item content:', Title, (DecreaseList[i].GetType and DecreaseList[i]:GetType() or -1), ', ', tostring((NewList[i].GetActor) and NewList[i]:GetActor() or 'actor none')}))
    end
    -- local LogStr = ''
    -- 旧表与新表对照出删除和新增条目
    local IncreaseIndex = 1
    local Limit = 50
    while IncreaseIndex <= #IncreaseList do
        local DecreaseIndex = 1
        local bSame = false
        while DecreaseIndex <= #DecreaseList do
            local Title_1 = DecreaseList[DecreaseIndex].GetSelectionTitle and DecreaseList[DecreaseIndex]:GetSelectionTitle() or (DecreaseList[DecreaseIndex].GetItemID and DecreaseList[DecreaseIndex]:GetItemID() or 'no title')
            local Title_2 = IncreaseList[IncreaseIndex].GetSelectionTitle and IncreaseList[IncreaseIndex]:GetSelectionTitle() or (IncreaseList[IncreaseIndex].GetItemID and IncreaseList[IncreaseIndex]:GetItemID() or 'no title')
            -- LogStr = table.concat({LogStr, 'ITEM_1:', Title_1, (DecreaseList[DecreaseIndex].GetType and DecreaseList[DecreaseIndex]:GetType() or 'type nill'), ', ', tostring(DecreaseList[DecreaseIndex].GetActor and DecreaseList[DecreaseIndex]:GetActor() or 'none actor'), ', ITEM_2:', Title_2, ', ', IncreaseList[IncreaseIndex]:GetType(), ', ', tostring(IncreaseList[IncreaseIndex].GetActor and IncreaseList[IncreaseIndex]:GetActor() or 'none actor'), ';   '})
            if self:IsInteractItemSame(DecreaseList[DecreaseIndex], IncreaseList[IncreaseIndex]) then
                -- LogStr = table.concat({LogStr, 'find is same;         '})
                bSame = true
                table.remove(IncreaseList, IncreaseIndex)
                table.remove(DecreaseList, DecreaseIndex)
                break
            else
                -- LogStr = table.concat({LogStr, 'is NOT same;         '})
            end
            DecreaseIndex = DecreaseIndex + 1
            Limit = Limit - 1
            if Limit < 1 then
                G.log:debug('zys', '循环次数过多')
                break
            end
        end
        IncreaseIndex = IncreaseIndex + (bSame and 0 or 1)
    end
    -- for i = 1, math.ceil(#LogStr % 300) do
    --     LogStr = string.sub(LogStr, 1, i * 300) .. '\n' .. string.sub(LogStr, (i * 300) + 1)
    -- end
    -- G.log:debug('zys', table.concat({'对照内容:   ', LogStr}))

    -- 使用需求中有频繁的增删,考虑加队列
    -- 极端情况判断新增队列中有要移除的条目
    local QueueIndex = 1
    Limit = 50
    while QueueIndex <= #self.InteractDecreaseQueue do
        local ListIndex = 1
        local bSame = false
        while ListIndex <= #IncreaseList do
            if self:IsInteractItemSame(self.InteractDecreaseQueue[QueueIndex], IncreaseList[ListIndex]) then
                bSame = true
                table.remove(self.InteractDecreaseQueue, QueueIndex)
                table.remove(IncreaseList, ListIndex)
                break
            end
            ListIndex = ListIndex + 1
            Limit = Limit - 1
            if Limit < 1 then
                G.log:debug('zys', '循环次数过多')
                break
            end
        end
        QueueIndex = QueueIndex + (bSame and 0 or 1)
    end

    -- 判断删除队列中有无要新增的条目
    QueueIndex = 1
    Limit = 50
    while QueueIndex <= #self.InteractIncreaseQueue do
        local ListIndex = 1
        local bSame = false
        while ListIndex <= #DecreaseList do
            if self:IsInteractItemSame(self.InteractIncreaseQueue[QueueIndex], DecreaseList[ListIndex]) then
                bSame = true
                table.remove(self.InteractIncreaseQueue, QueueIndex)
                table.remove(DecreaseList, ListIndex)
                break
            end
            ListIndex = ListIndex + 1
            Limit = Limit - 1
            if Limit < 1 then
                G.log:debug('zys', '循环次数过多')
                break
            end
        end
        QueueIndex = QueueIndex + (bSame and 0 or 1)
    end

    -- 判断新增队列中已有需要新增的条目
    QueueIndex = 1
    while QueueIndex <= #IncreaseList do
        local bSame = false
        for i = 1, #self.InteractIncreaseQueue do
            if self:IsInteractItemSame(self.InteractIncreaseQueue[i], IncreaseList[QueueIndex]) then
                bSame = true
                break
            end
        end
        if bSame == true then
            table.remove(IncreaseList, QueueIndex)
        else
            QueueIndex = QueueIndex + 1
        end
    end

    -- 判断移除队列中已有需要移除的条目
    QueueIndex = 1
    while QueueIndex <= #DecreaseList do
        local bSame = false
        for i = 1, #self.InteractDecreaseQueue do
            if self:IsInteractItemSame(self.InteractDecreaseQueue[i], DecreaseList[QueueIndex]) then
                bSame = true
                break
            end
        end
        if bSame == true then
            table.remove(DecreaseList, QueueIndex)
        else
            QueueIndex = QueueIndex + 1
        end
    end

    -- 最后将真实需要增删的数据推进队列
    for i = 1, #IncreaseList do
        table.insert(self.InteractIncreaseQueue, IncreaseList[i])
    end
    for i = 1, #DecreaseList do
        table.insert(self.InteractDecreaseQueue, DecreaseList[i])
    end
    if (#IncreaseList + #DecreaseList) > 0 then
        local UI = UIManager:GetUIInstance(UIDef.UIInfo.UI_InteractPickup.UIName)
        UI:InteractListChange()
    end
end

---`private`
function InteractVM:SortInteractItems(InteractItems, bNotSort, ForceIndex)
    local NewList = {}
    for i = 1, #InteractItems do
        -- local Usable = InteractItems[i].GetUsable and InteractItems[i]:GetUsable() or 'nil'
        -- local Title = InteractItems[i].GetSelectionTitle and InteractItems[i]:GetSelectionTitle() or (InteractItems[i].GetItemID and InteractItems[i]:GetItemID() or 'no title')
        -- G.log:debug('zys',table.concat({'InteractItems[i], idx: ', i, '%i, title: ', Title, ', usable: ', tostring(Usable), ', bNotSort: ', tostring(bNotSort), ', ForceIndex: ', ForceIndex}))
        NewList[i] = InteractItems[i]
    end
    if bNotSort then
        return NewList
    end
    table.sort(NewList, function(a, b)
        local typeA = a:GetType()
        local typeB = b:GetType()
        if typeA ~= typeB then
            return typeA > typeB
        end
        local QualityA = -1
        local QualityB = -1
        if a.GetQuality then
            QualityA = a:GetQuality()
        end
        if a.GetItemID and a:GetItemID() ~= nil and a:GetItemID() > 0 then
            local ItemConfig = ItemUtil.GetItemConfigByExcelID(a:GetItemID())
            QualityA = ItemConfig.quality
        end
        if b.GetQuality then
            QualityB = b:GetQuality()
        end
        if b.GetItemID and b:GetItemID() ~= nil and b:GetItemID() > 0 then
            local ItemConfig = ItemUtil.GetItemConfigByExcelID(b:GetItemID())
            QualityB = ItemConfig.quality
        end
        if QualityA ~= QualityB then
            return QualityA > QualityB
        end
        local Dst_1 = a.GetDistance and a:GetDistance() or 1000
        local Dst_2 = b.GetDistance and b:GetDistance() or 1000
        return Dst_1 < Dst_2
    end)
    return NewList
end

---@private
---@param Item_1 table OldItem
---@param Item_2 table NewItem
function InteractVM:IsInteractItemSame(Item_1, Item_2)
    local Type_1 = Item_1.GetType and Item_1:GetType() or 0
    local Type_2 = Item_2.GetType and Item_2:GetType() or 0
    -- 为方便调试, 故先分开判断
    if Type_1 ~= Type_2 then
        return false
    end
    local Title_1 = Item_1.GetSelectionTitle and Item_1:GetSelectionTitle() or ''
    local Title_2 = Item_2.GetSelectionTitle and Item_2:GetSelectionTitle() or ''
    if Title_1 ~= Title_2 then
        return false
    end
    local Actor_1 = Item_1.GetActor and Item_1:GetActor() or 1
    local Actor_2 = Item_2.GetActor and Item_2:GetActor() or 1
    if Actor_1 ~= Actor_2 then
        return false
    end
    local ItemID_1 = Item_1.GetItemID and Item_1:GetItemID() or 1
    local ItemID_2 = Item_2.GetItemID and Item_2:GetItemID() or 1
    if ItemID_1 ~= ItemID_2 then
        return false
    end
    -- 2024.4.1 因情景交互条目动态增添时原vm中数据没有及时更新distance而已在条目中的NPC的distance为第一次数据而导致bug，
    -- 故在此处修复: 判断为distance条目则刷新distance属性
    if Item_1.Distance and Item_2.Distance then
        Item_1.Distance = Item_2.Distance
    end
    return true
end

return InteractVM
