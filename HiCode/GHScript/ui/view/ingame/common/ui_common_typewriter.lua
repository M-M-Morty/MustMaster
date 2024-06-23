--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local G = require('G')
local ViewModelBinder = require('CP0032305_GH.Script.framework.mvvm.viewmodel_binder')
local WidgetProxys = require('CP0032305_GH.Script.framework.mvvm.ui_widget_proxy')
local UIDef = require('CP0032305_GH.Script.ui.ui_define')
local ViewModelBaseClass = require('CP0032305_GH.Script.framework.mvvm.viewmodel_base')
local InputDef = require('CP0032305_GH.Script.common.input_define')
local ViewModelCollection = require('CP0032305_GH.Script.framework.mvvm.viewmodel_collection')
local VMDef = require('CP0032305_GH.Script.viewmodel.vm_define')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local UIWidgetBase = require('CP0032305_GH.Script.framework.ui.ui_widget_base')
local utils = require("common.utils")

local ACC_SPEED = 4000

local TypeWriter_TypeDef = {
    Normal = 1,             -- 普通
    MerryGoRound = 2,       -- 走马灯
}

---@class TypeWriterVM : ViewModelBase
local TypeWriterVM = Class(ViewModelBaseClass)

function TypeWriterVM:ctor()
    Super(TypeWriterVM).ctor(self)

    self.TypeWriterItemsField = self:CreateVMArrayField({})
    self.bPlayTypingField = self:CreateVMField(false)
    self.tbFinishedEvent = {}
end

function TypeWriterVM:SetListItem(List)
    self.TypeWriterItemsField:ClearItems(true)

    for idx, item in pairs(List) do
        item.ContentField = self:CreateVMField('')
        self.TypeWriterItemsField:AddItem(item, true)    
    end
    self.TypeWriterItemsField:BroadcastValueChanged()
end

function TypeWriterVM:SetItemsContent(ContentList)
    for i = 1, self.TypeWriterItemsField:GetItemNum() do
        self.TypeWriterItemsField:GetItem(i):GetFieldValue().ContentField:SetFieldValue(ContentList[i])
    end
end

function TypeWriterVM:SetItemContentByIndex(Index, Content)
    self.TypeWriterItemsField:GetItem(Index):GetFieldValue().ContentField:SetFieldValue(Content)
end

function TypeWriterVM:MaskNext()
    for Item in self.TypeWriterItemsField:Items_Iterator() do
        if not Item:GetFieldValue().CanMask then
            Item:GetFieldValue().CanMask = true
            return
        end
    end
    self.bPlayTypingField:SetFieldValue(false)
    self:TriggerFinishedEvent()
end

function TypeWriterVM:RegisterFinishedEvent(EventName, EventFunction)
    if not self.tbFinishedEvent then
        self.tbFinishedEvent = {}
    end
    table.insert(self.tbFinishedEvent, {Event = EventFunction, name = EventName})
end

function TypeWriterVM:UnregisterFinishedEvent(name)
    TableUtil:ArrayRemoveIf(self.tbFinishedEvent, function(elm)
        return elm.name == name
    end)
end

function TypeWriterVM:TriggerFinishedEvent()
    -- to forbid infinite loop
    for i, v in ipairs(self.tbFinishedEvent) do
        v.Event()
    end
end

---@class WBP_TypeWriter: WBP_TypeWriter_C
---@field TypeWriter_Type TypeWriter_TypeDef 打字机功能枚举
---@field RichTextSize UE.FVector2D Widget成员变量
---@field ListItemValue table 列表数据
---@field DefaultPlaySpeed number
---@field CurrentPlaySpeed number
local WBP_TYPEWRITER = Class(UIWidgetBase)

---@param self WBP_TYPEWRITER
local function IsTypeWriterValid(self)
    if self.TypewriterList and UE.UKismetSystemLibrary.IsValid(self.TypewriterList) then
        return true
    else
        return false
    end
end

---@param self WBP_TYPEWRITER
---@param content string
local function IsPunct(self, content)
    if string.match(content, "[%p]") ~= nil then
        return true -- is english punctuation
    elseif self:IsChinesePunct(content) then
        return true -- is chinese punctuation
    end
    return false
end

---@param self WBP_TYPEWRITER
---@param content string 文本内容
---@param tag string 富文本的标签
local function FontMeasureByTag(self, content, tag)
    if tag == '' then
        local TagSize = self:Measure(UE.UKismetStringLibrary.GetCharacterArrayFromString(content), self.DefaultTextStyle.Font)
        return TagSize
    else
        local Font = self:GetFontSize(tag).TextStyle.Font
        local TagSize = self:Measure(UE.UKismetStringLibrary.GetCharacterArrayFromString(content), Font)
        return TagSize
    end
end

---@param self WBP_TYPEWRITER
---@param InStr string
---@return table
local function InitTags(self, InStr)
    local ArrTagContent = {}
    local s = InStr:gsub('(.-)<(%w+)>(.-)</>', function(a,b,c)
        table.insert(ArrTagContent, {content = a, tag = ''})
        table.insert(ArrTagContent, {content = c, tag = b})
        return ''
    end)
    if #s > 0 then
        table.insert(ArrTagContent, {content = s, tag = ''})
    end
    return ArrTagContent
end

---@param self WBP_TYPEWRITER
---@param ArrTagContent table
---@return table 
---@return number
local function CalcEachTagSizeInfo(self, ArrTagContent)
    self.FontSizeY = 0
    local SumRawCount = 0
    local Arr2DContent = {}
    local Arr1DContent = {}
    Arr1DContent.Size = 0
    -- content: '去去去去去去\n呀呀呀呀呀呀', tag: 'red'
    -- content: '突突突突突突', tag: 'blue'
    for _, Item in ipairs(ArrTagContent) do
        local CurContent = ''
        local ArrStr = UE.UKismetStringLibrary.GetCharacterArrayFromString(Item.content)
        for i = 1, ArrStr:Num() do
            if ArrStr:Get(i) ~= '\n' then
                -- table.insert(CurContent, ArrStr:Get(i))
                CurContent = CurContent .. ArrStr:Get(i)
            else
                -- CurContent: '去去去去去去'
                local TagSize = FontMeasureByTag(self, CurContent, Item.tag)
                self.FontSizeY = TagSize.Y > self.FontSizeY and TagSize.Y or self.FontSizeY
                Arr1DContent.Size = Arr1DContent.Size + TagSize.X
                Arr1DContent.RowCount = math.ceil(Arr1DContent.Size / self.RichTextSize.X)
                SumRawCount = SumRawCount + Arr1DContent.RowCount
                table.insert(Arr1DContent, {Content = CurContent, Tag = Item.tag, TagSize = TagSize.X})
                table.insert(Arr2DContent, Arr1DContent)
                CurContent = ''
                Arr1DContent = {}
                Arr1DContent.Size = 0
            end
             -- CurContent: '呀呀呀呀呀呀'
        end
        local TagSize = FontMeasureByTag(self, CurContent, Item.tag)
        Arr1DContent.Size = Arr1DContent.Size + TagSize.X
        table.insert(Arr1DContent, {Content = CurContent, Tag = Item.tag, TagSize = TagSize.X})
    end
    Arr1DContent.RowCount = math.ceil(Arr1DContent.Size / self.RichTextSize.X)
    table.insert(Arr2DContent, Arr1DContent)
    SumRawCount = SumRawCount + Arr1DContent.RowCount
    for i = 1, #Arr2DContent do
        local str = ''
        for j = 1, #Arr2DContent[i] do
            str = str .. Arr2DContent[i][j].Content
        end
    end
    return Arr2DContent, SumRawCount
end

-- 处理临界
local function DealCriticalTag(self, CurTagTable, CurRowIndex, PixelSize)
    local TagSize = CurTagTable.TagSize

    local ContentStringArray = UE.UKismetStringLibrary.GetCharacterArrayFromString(CurTagTable.Content)
    local FontInfo = CurTagTable.Tag == '' and self.DefaultTextStyle.Font or self:GetFontSize(CurTagTable.Tag).TextStyle.Font
    local LastTagTable = {Content = '', Tag = CurTagTable.Tag, TagSize = 0, RowIndex = CurRowIndex}
    local NextTagTable = {Content = '', Tag = CurTagTable.Tag, TagSize = 0, RowIndex = CurRowIndex + 1}
    local TmpArray = UE.TArray(UE.FString)
    local bFinish = false
    local HasDealPunct = false -- 多个临界标点仅处理一次

    for j = 1, ContentStringArray:Num() do
        if not bFinish then
            TmpArray:Add(ContentStringArray:Get(j))
            local OnlySize = self:Measure(TmpArray, FontInfo)
            PixelSize = PixelSize + OnlySize.X
            if PixelSize + 40 > self.RichTextSize.X and not self:IsEllipsis(ContentStringArray:Get(j)) and (not IsPunct(self, ContentStringArray:Get(j)) or HasDealPunct) then -- 判断临界
                -- 临界字符属于下一行
                PixelSize = PixelSize - OnlySize.X
                NextTagTable.Content = ContentStringArray:Get(j)
                bFinish = true
            else
                if PixelSize + 30 > self.RichTextSize.X and IsPunct(self, ContentStringArray:Get(j)) then
                    HasDealPunct = true
                end
                PixelSize = PixelSize - OnlySize.X
                LastTagTable.Content = LastTagTable.Content .. ContentStringArray:Get(j)
                LastTagTable.TagSize = OnlySize.X
            end
        else
            NextTagTable.Content = NextTagTable.Content .. ContentStringArray:Get(j)
        end
    end
    NextTagTable.TagSize = TagSize - LastTagTable.TagSize
    return LastTagTable, NextTagTable
end

---@param self WBP_TYPEWRITER
---@param Arr2D table
---@param RowCount number
---@param LimitSizeX number
local function SubdivideTagsByRowCount(self, Arr2D, RowCount, LimitSizeX)
    if RowCount <= 1 then
        for i = 1, #Arr2D[1] do
            Arr2D[1][i].RowIndex = 1
        end
    else
        local RowIndex = 1
        for _, Arr1D in ipairs(Arr2D) do
            local PixelSize = 0
            local WhileIndex = 1
            -- 最后一个tag的尺寸小于打字机尺寸, 或者最后一个tag没有被赋予上行索引
            while (Arr1D[#Arr1D].TagSize > LimitSizeX) or (not Arr1D[#Arr1D].RowIndex) do
                PixelSize = PixelSize + Arr1D[WhileIndex].TagSize
                if PixelSize < LimitSizeX then
                    -- 若加上这一句仍然没有满一行, 则可加上这一句
                    Arr1D[WhileIndex].RowIndex = RowIndex
                else
                    -- 若加上这一句满行, 则退回这一句
                    PixelSize = PixelSize - Arr1D[WhileIndex].TagSize
                    local LastTable, NextTable = DealCriticalTag(self, Arr1D[WhileIndex], RowIndex, PixelSize)
                    Arr1D[WhileIndex] = LastTable
                    table.insert(Arr1D, WhileIndex + 1, NextTable)
                    PixelSize = 0
                    RowIndex = RowIndex + 1
                end
                WhileIndex = WhileIndex + 1
            end
            RowIndex = RowIndex + 1
        end
    end
end

---@param self WBP_TYPEWRITER
---@param Arr2D table
local function SetAllContent(self, Arr2D)
    local tbText = {}
    for _, Arr1D in ipairs(Arr2D) do
        for _, Item in ipairs(Arr1D) do
            local Content = Item.Tag == '' and Item.Content or (table.concat({'<', Item.Tag, '>', Item.Content, '</>'}))
            if not tbText[Item.RowIndex] then
                tbText[Item.RowIndex] = ''
            end
            tbText[Item.RowIndex] = tbText[Item.RowIndex] .. Content
            if self.ListItemValue[Item.RowIndex] then
                self.ListItemValue[Item.RowIndex].ContentSize = self.ListItemValue[Item.RowIndex].ContentSize + Item.TagSize
            end
        end
    end
    self.LocalTypeWriterVM:SetItemsContent(tbText)

end

---@param self WBP_TYPEWRITER
local function BuildListItemData(self, RowCount)
    self.ListItemValue = {}
    for i = 1, RowCount do
        local ItemValue = {
            ItemIndex = i,                          -- 条目索引
            LineSpace = self.LineSpace,             -- 行间距
            InTextStyleSet = self.TextStyleSet,
            InDefaultTextStyle = self.DefaultTextStyle,
            InMinDesiredWidth = self.MinDesiredWidth,
            InJustification = self.Justification,
            InSizeToContent = true,
            RichTextSize = self.RichTextSize,
            bFinished = false,                      -- 打字机完成的标志
            bIsMerryGoRound = self.TypeWriter_Type == TypeWriter_TypeDef.MerryGoRound,
            TypeWriterVM = self.LocalTypeWriterVM,  -- 自己的VM
            PlayDuration = self.RichTextSize.X / self.CurrentPlaySpeed,
            ContentSize = 0,                        -- 这些文本的像素长度
            MerryGoRoundSpeed = self.MerryGoRoundSpeed
        }
        table.insert(self.ListItemValue, ItemValue)
    end
end

---@param self WBP_TYPEWRITER
---@param NewSizeY number
local function TriggerSizeYChangedEvent(self, NewSizeY)
    if not self.tbSizeYChangedEvent then
        return
    end
    for i, v in ipairs(self.tbSizeYChangedEvent) do
        v.Event(NewSizeY)
    end
end

---@param self WBP_TYPEWRITER
---@param InStr string
local function StartPlayTyping(self, InStr)
    local ArrTagContent = InitTags(self, InStr)
    local Arr2D, RowCount = CalcEachTagSizeInfo(self, ArrTagContent)
    BuildListItemData(self, RowCount)
    SubdivideTagsByRowCount(self, Arr2D, RowCount, self.RichTextSize.X)
    self.LocalTypeWriterVM.bPlayTypingField:SetFieldValue(true)
    -- 打字机尺寸是双倍的用RenderScale缩小的, 所以self.FontSizeY需要先缩小一半
    local TypeWriterDesiredSizeY = RowCount * (self.FontSizeY / 2) + (RowCount - 1) * self.LineSpace
    TriggerSizeYChangedEvent(self, TypeWriterDesiredSizeY)
    self.LocalTypeWriterVM:SetListItem(self.ListItemValue)
    SetAllContent(self, Arr2D)
    if #self.ListItemValue == 1 then
        self.ListItemValue[1].SizeX = self.ListItemValue[1].ContentSize
    end
    self.LocalTypeWriterVM:MaskNext()
end

---@param self WBP_TYPEWRITER
local function CreateNewList(self)
    local Class = UIManager:ClassRes("TypewriterListView")
    if not Class then
        G.log:debug("zys", "failed to call classres !!!")
    end
    local widget = UE.UWidgetBlueprintLibrary.Create(self, Class)
    self.TypewriterList = nil
    self.TypewriterList = widget
    self.CanvasPanel_0:AddChildToCanvas(self.TypewriterList)
    UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.TypewriterList):SetSize(self.RichTextSize)
end

---@param self WBP_TYPEWRITER
local function TriggerViewportSizeChangedEvent(self)
    if not IsTypeWriterValid(self) then
        G.log:debug('zys', "fetal: type writer list is invalid !!!")
        return
    end
    self.TypewriterList:RemoveFromParent()
    CreateNewList(self)
    self.ListViewProxy = WidgetProxys:CreateWidgetProxy(self.TypewriterList.ListView)
    ViewModelBinder:BindViewModel(self.ListViewProxy.ListField, self.LocalTypeWriterVM.TypeWriterItemsField, ViewModelBinder.BindWayToWidget)
    self.LocalTypeWriterVM.bPlayTypingField:SetFieldValue(false)

    if not self.tbViewportSizeChangedEvent then
        return
    end
    for i, v in ipairs(self.tbViewportSizeChangedEvent) do
        v.Event()
    end
end

---@param WBP_TYPEWRITER
local function TimerLoop(self)
    if not self.ViewportSize then
        self.ViewportSize = self:GetViewportSize()
    end
    if self.ViewportSize ~= self:GetViewportSize() then
        TriggerViewportSizeChangedEvent(self)
    end
    self.ViewportSize = self:GetViewportSize()
end

---@param self WBP_TYPEWRITER
local function InitWidget(self)
end

---@param self WBP_TYPEWRITER
local function BuildWidgetProxy(self)
    if IsTypeWriterValid(self) then
        ---@type UListViewProxy
        self.ListViewProxy = WidgetProxys:CreateWidgetProxy(self.TypewriterList.ListView)
    end
end

---@param self WBP_TYPEWRITER
local function InitViewModel(self)
    if not self.LocalTypeWriterVM then
        self.LocalTypeWriterVM = TypeWriterVM.new()
    end
    if self.ListViewProxy then
        ViewModelBinder:BindViewModel(self.ListViewProxy.ListField, self.LocalTypeWriterVM.TypeWriterItemsField, ViewModelBinder.BindWayToWidget)
    end
end

--function WBP_TYPEWRITER:Initialize(Initializer)
--end

-- function WBP_TYPEWRITER:PreConstruct(IsDesignTime)
-- end

function WBP_TYPEWRITER:OnConstruct()
    self.TypeWriter_Type = TypeWriter_TypeDef.Normal
    self.ListItemValue = {}
    if IsTypeWriterValid(self) then
        self.TypewriterList:RemoveFromParent()
    end
    CreateNewList(self)

    self.DefaultPlaySpeed = 2000
    self.CurrentPlaySpeed = 2000
    self.MerryGoRoundSpeed = 500

    InitWidget(self)
    BuildWidgetProxy(self)
    InitViewModel(self)

    ---@type FTimerHandle
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, TimerLoop}, 0.3, true)
end

function WBP_TYPEWRITER:OnDestruct()
    UE.UKismetSystemLibrary.K2_ClearAndInvalidateTimerHandle(self, self.TimerHandle)
end

-- function WBP_TYPEWRITER:Tick(MyGeometry, InDeltaTime)
-- end

--- `public` 设置打字机内容接口
function WBP_TYPEWRITER:SetText(InText)
    self.TypeWriter_Type = TypeWriter_TypeDef.Normal
    if not InText or InText == '' then
        if IsTypeWriterValid(self) then
            self.TypewriterList.ListView:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        return
    end
    self:ResetWidget()
    if IsTypeWriterValid(self) then
        self.TypewriterList.ListView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        G.log:debug('zys', 'failed to find self.TypewriterList !!!')
    end
    local InTextString = tostring(InText)
    if InTextString ~= self:GetText() then
        self.RawTextString = InTextString
    end
    StartPlayTyping(self, self.RawTextString)
end

function WBP_TYPEWRITER:GetText()
    return self.RawTextString
end

function WBP_TYPEWRITER:SetMerryGoRoundSpeed(PlaySpeed)
    self.MerryGoRoundSpeed = PlaySpeed
end

function WBP_TYPEWRITER:SetDefaultPlaySpeed(PlaySpeed)
    self.DefaultPlaySpeed = PlaySpeed
end

function WBP_TYPEWRITER:SetCurrentPlaySpeed(PlaySpeed)
    self.CurrentPlaySpeed = PlaySpeed
    if self:IsPlaying() then
        for i = 1, #self.ListItemValue do
            self.ListItemValue[i].PlayDuration = self.ListItemValue[i].PlayDuration * self.DefaultPlaySpeed / self.CurrentPlaySpeed
        end
    end
end

function WBP_TYPEWRITER:RegisterFinishedEvent(EventName, EventFunction)
    if not self.LocalTypeWriterVM then
        return
    end
    self.LocalTypeWriterVM:RegisterFinishedEvent(EventName, EventFunction)
end

function WBP_TYPEWRITER:UnregisterFinishedEvent(EventName)
    self.LocalTypeWriterVM:UnregisterFinishedEvent(EventName)
end

---`brief`注册打字机尺寸改变时的回调
function WBP_TYPEWRITER:RegisterSizeYChangedEvent(EventName, EventFunction)
    if not self.tbSizeYChangedEvent then
        self.tbSizeYChangedEvent = {}
    end
    table.insert(self.tbSizeYChangedEvent, {Event = EventFunction, Name = EventName})
end

function WBP_TYPEWRITER:UnregisterSizeYChangedEvent(EventName)
    if not self.tbSizeYChangedEvent then
        return
    end
    TableUtil:ArrayRemoveIf(self.tbSizeYChangedEvent, function(elm)
        return elm.Name == EventName
    end)
end

---`brief`游戏分辨率改变回调
function WBP_TYPEWRITER:RegisterViewportSizeChangedEvent(EventName, EventFunction)
    if not self.tbViewportSizeChangedEvent then
        self.tbViewportSizeChangedEvent = {}
    end
    table.insert(self.tbViewportSizeChangedEvent, {Event = EventFunction, Name = EventName})
end

function WBP_TYPEWRITER:UnregisterViewportSizeChangedEvent(EventName)
    if not self.tbViewportSizeChangedEvent then
        return
    end
    TableUtil:ArrayRemoveIf(self.tbViewportSizeChangedEvent, function(elm)
        return elm.Name == EventName
    end)
end

--- `public` 提前结束
---@param bImme boolean 全部显示或者加速
function WBP_TYPEWRITER:FinishPlayTyping(bImme)
    if self.LocalTypeWriterVM.bPlayTypingField:GetFieldValue() and bImme then
        self.LocalTypeWriterVM.bPlayTypingField:SetFieldValue(false)
        self.LocalTypeWriterVM:TriggerFinishedEvent()
    else
        self:SetCurrentPlaySpeed(ACC_SPEED)
    end
end

function WBP_TYPEWRITER:IsPlaying()
    return self.LocalTypeWriterVM.bPlayTypingField:GetFieldValue() and true or false
end

function WBP_TYPEWRITER:ResetWidget()
    self.ListItemValue = {}

    self.DefaultPlaySpeed = 2000
    self.CurrentPlaySpeed = 2000
    self.MerryGoRoundSpeed = 500
    if self.LocalTypeWriterVM then
        self.LocalTypeWriterVM.tbFinishedEvent = {}
        self.LocalTypeWriterVM.bPlayTypingField:SetFieldValue(false)
    else
        InitViewModel(self)
        if self.LocalTypeWriterVM then
            self.LocalTypeWriterVM.tbFinishedEvent = {}
            self.LocalTypeWriterVM.bPlayTypingField:SetFieldValue(false)
        end
    end

    if self.ListItemValue then
        for i = 1, #self.ListItemValue do
            self.ListItemValue[i].content = ''
        end
    end
    if IsTypeWriterValid(self) then 
        self.TypewriterList.ListView:ClearListItems()
    end
end

return WBP_TYPEWRITER