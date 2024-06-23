--
-- @COMPANY GHGame
-- @AUTHOR lizhi
--

local G = require("G")
local TableUtil = require('CP0032305_GH.Script.common.utils.table_utl')
local UICommonObj = require('CP0032305_GH.Script.framework.ui.ui_common_obj')
local UICommonUtil = require('CP0032305_GH.Script.framework.ui.ui_common_utl')

---@class WidgetProxys
local WidgetProxys = {}
WidgetProxys.tbRegisteredWidgetClass = {}

---@param UMGWidget UWidget
function WidgetProxys:CreateWidgetProxy(UMGWidget)
    if not UMGWidget then
        return
    end

    local WidgetClass = UMGWidget:GetClass()
    local WidgetProxy = self:FindWidgetProxy(WidgetClass)
    if WidgetProxy then
        return WidgetProxy.new(UMGWidget)
    end
end

function WidgetProxys:FindWidgetProxy(InWidgetClass)
    local FoundedWidgetProxy
    for i = 1, #self.tbRegisteredWidgetClass do
        local WidgetClass = self.tbRegisteredWidgetClass[i][1]
        if InWidgetClass:IsChildOf(WidgetClass) then
            FoundedWidgetProxy = self.tbRegisteredWidgetClass[i][2]
            break
        end
    end
    return FoundedWidgetProxy
end

function WidgetProxys:SortWidgetProxy()
    -- 根据UEWidgetClass的继承结构排序
    -- 保证子类在父类前面
    -- 这样FindWidgetProxy的时候就能找到最接近的WidgetClass
    table.sort(self.tbRegisteredWidgetClass, function(v1, v2)
        local WidgetClass1 = v1[1]
        local WidgetClass2 = v2[1]
        if WidgetClass1 == WidgetClass2 then
            return false
        end
        return WidgetClass1:IsChildOf(WidgetClass2)
    end)

    ----[[
    for i = 1, #self.tbRegisteredWidgetClass do
        local WidgetClass = self.tbRegisteredWidgetClass[i][1]
        G.log:debug('gh_ui', 'registered widget class: %s', tostring(WidgetClass))
    end
    --]]
end

--[[
    WidgetProxy Definition Begin
]]
local function CreateProxyClass(UEWidgetClass, SuperClass)
    local ProxyClass = Class(SuperClass)
    table.insert(WidgetProxys.tbRegisteredWidgetClass, {UEWidgetClass, ProxyClass})
    return ProxyClass
end
local UIWidgetField = require('CP0032305_GH.Script.framework.mvvm.ui_widget_field')

---@class UWidgetProxy
---@field UMGWidget UWidget
local UWidgetProxy = CreateProxyClass(UE.UWidget)
WidgetProxys.UWidgetProxy = UWidgetProxy

function UWidgetProxy:ctor(InWidget)
    self.UMGWidget = InWidget
end

function UWidgetProxy:IsWidgetValid()
    return self.UMGWidget and self.UMGWidget:IsValid()
end

function UWidgetProxy:IsWidgetVisable()
    return self.UMGWidget and self.UMGWidget:IsValid() and self.UMGWidget:IsVisible()
end

function UWidgetProxy:GetUMGWidget()
    return self.UMGWidget
end


---@class UWidgetSwitcherProxy : UWidgetProxy
---@field UMGWidget UWidgetSwitcher
---@field IndexField UIWidgetField
local UWidgetSwitcherProxy = CreateProxyClass(UE.UWidgetSwitcher, UWidgetProxy)

function UWidgetSwitcherProxy:ctor(InWidget)
    Super(UWidgetSwitcherProxy).ctor(self, InWidget)

    self.IndexField = UIWidgetField.new(self)
    self.IndexField.Field_Getter = self.GetActiveWidgetIndex
    self.IndexField.Field_Setter = self.SetActiveWidgetIndex
end

function UWidgetSwitcherProxy:GetActiveWidgetIndex()
    return self.UMGWidget:GetActiveWidgetIndex()
end

function UWidgetSwitcherProxy:SetActiveWidgetIndex(Index)
    self.UMGWidget:SetActiveWidgetIndex(Index)
end


---@class UCheckBoxProxy : UWidgetProxy
---@field UMGWidget UCheckBox
---@field CheckedField UIWidgetField
local UCheckBoxProxy = CreateProxyClass(UE.UCheckBox, UWidgetProxy)

function UCheckBoxProxy:ctor(InWidget)
    Super(UCheckBoxProxy).ctor(self, InWidget)

    self.UMG_OnCheckStateChanged = function(UMGWidget, bIsChecked)
        self:OnCheckStateChanged(bIsChecked)
    end
    self.UMGWidget.OnCheckStateChanged:Add(self.UMGWidget, self.UMG_OnCheckStateChanged)

    self.CheckedField = UIWidgetField.new(self)
    self.CheckedField.Field_Getter = self.IsChecked
    self.CheckedField.Field_Setter = self.SetIsChecked
end

function UCheckBoxProxy:IsChecked()
    return self.UMGWidget:IsChecked()
end

function UCheckBoxProxy:SetIsChecked(bIsChecked)
    if bIsChecked ~= self:IsChecked() then
        self.UMGWidget:SetIsChecked(bIsChecked)
        self:OnCheckStateChanged(bIsChecked)
    end
end

function UCheckBoxProxy:OnCheckStateChanged(bIsChecked)
    self.CheckedField:BroadcastFieldChanged(bIsChecked)
end




---@class UImageProxy : UWidgetProxy
---@field UMGWidget UImage
---@field IamgeField UIWidgetField
local UImageProxy = CreateProxyClass(UE.UImage, UWidgetProxy)

function UImageProxy:ctor(InWidget)
    Super(UImageProxy).ctor(self, InWidget)

    self.ImageTextureField = UIWidgetField.new(self)
    self.ImageTextureField.TexturePath = ''
    self.ImageTextureField.Field_Getter = self.GetImageTexturePath
    self.ImageTextureField.Field_Setter = self.SetImageTexturePath
end

function UImageProxy:GetImageTexturePath()
    return self.ImageTextureField.TexturePath
end

function UImageProxy:SetImageTexturePath(TexturePath)
    local CurrentTexturePath = self:GetImageTexturePath()
    local Texture = UE.UObject.Load(TexturePath)
    if Texture then
        self.UMGWidget:SetBrushResourceObject(Texture)
        self.ImageTextureField.TexturePath = TexturePath
    end
    if TexturePath ~= CurrentTexturePath then
        self.ImageTextureField:BroadcastFieldChanged(TexturePath)
    end
end

---@class UTextBlockProxy : UWidgetProxy
---@field UMGWidget UTextBlock
---@field TextField UIWidgetField
local UTextBlockProxy = CreateProxyClass(UE.UTextBlock, UWidgetProxy)

function UTextBlockProxy:ctor(InWidget)
    Super(UTextBlockProxy).ctor(self, InWidget)

    self.TextField = UIWidgetField.new(self)
    self.TextField.Field_Getter = self.GetText
    self.TextField.Field_Setter = self.SetText
end

function UTextBlockProxy:GetText()
    return self.UMGWidget:GetText()
end

function UTextBlockProxy:SetText(InText)
    local InTextString = InText and tostring(InText) or ''
    if InTextString ~= self:GetText() then
        self.UMGWidget:SetText(InTextString)
        self.TextField:BroadcastFieldChanged(InTextString)
    end
end




---@class URichTextBlockProxy : UWidgetProxy
---@field UMGWidget URichTextBlock
---@field TextField UIWidgetField
local URichTextBlockProxy = CreateProxyClass(UE.URichTextBlock, UWidgetProxy)

function URichTextBlockProxy:ctor(InWidget)
    Super(URichTextBlockProxy).ctor(self, InWidget)

    self.TextField = UIWidgetField.new(self)
    self.TextField.Field_Getter = self.GetText
    self.TextField.Field_Setter = self.SetText
end

function URichTextBlockProxy:GetText()
    return self.UMGWidget:GetText()
end

function URichTextBlockProxy:SetText(InText)
    local InTextString = tostring(InText)
    if InTextString ~= self:GetText() then
        self.UMGWidget:SetText(InTextString)
        self.TextField:BroadcastFieldChanged(InTextString)
    end
end


---@class UTypewriterRichTextProxy : UWidgetProxy
---@field UMGWidget UTypewriterRichText
---@field TextField UIWidgetField
local UTypewriterRichTextProxy = CreateProxyClass(UE.UClass.Load('/Game/CP0032305_GH/UI/UMG/Ingame/Common/WBP_TypewriterRichText.WBP_TypewriterRichText_C'), URichTextBlockProxy)

function UTypewriterRichTextProxy:ctor(InWidget)
    Super(UTypewriterRichTextProxy).ctor(self, InWidget)
    self.tbFinishedEvent = {}

    self.bPlayTyping = false
    self.DefaultPlayInterval = 0.02
    self.CurrentPlayInterval = 0.02

    self.TextField = UIWidgetField.new(self)
    self.TextField.Field_Getter = self.GetText
    self.TextField.Field_Setter = self.SetText
end

function UTypewriterRichTextProxy:SetDefaultPlayInterval(PlayInterval)
    self.DefaultPlayInterval = PlayInterval
end

function UTypewriterRichTextProxy:SetCurrentPlayInterval(PlayInterval)
    self.CurrentPlayInterval = PlayInterval
end

function UTypewriterRichTextProxy:SetText(InText)
    local InTextString = tostring(InText)
    if InTextString ~= self:GetText() then
        self.RawTextString = InTextString
        self.TextField:BroadcastFieldChanged(InTextString)
    end
    self:ResetProxy()
    self:StartPlayTyping()
end

function UTypewriterRichTextProxy:GetText()
    return self.RawTextString
end

function UTypewriterRichTextProxy:RegisterFinishedEvent(EventName, EventFunction)
    table.insert(self.tbFinishedEvent, {Event = EventFunction, name = EventName})
end

function UTypewriterRichTextProxy:UnregisterFinishedEvent(name)
    TableUtil:ArrayRemoveIf(self.tbFinishedEvent, function(elm)
        return elm.name == name
    end)
end

function UTypewriterRichTextProxy:TriggerFinishedEvent()
    -- to forbid infinite loop
    for i, v in ipairs(self.tbFinishedEvent) do
        v.Event()
    end
end

function UTypewriterRichTextProxy:StartPlayTyping()
    self.TagArrayTable = {}
    self.ProcessedContent = ''
    self.CurrentTime = 0
    self.NextTime = 0

    local s = self.RawTextString:gsub('(.-)<(%w+)>(.-)</>', function(a,b,c)
        table.insert(self.TagArrayTable, {content = a, tag = ''})
        table.insert(self.TagArrayTable, {content = c, tag = b})
        return ''
    end)
    if #s > 0 then
        table.insert(self.TagArrayTable, {content = s, tag = ''})
    end

    self.TagIndex = 1
    if self:BuildCurrentTagData() then
        self.bPlayTyping = true
    end
end

function UTypewriterRichTextProxy:ResetProxy()
    self.bPlayTyping = false
    self.UMGWidget:SetText('')
end

function UTypewriterRichTextProxy:FinishPlayTyping(bImme)
    if bImme then
        self.UMGWidget:SetText(self.RawTextString)
        self.bPlayTyping = false
        self:TriggerFinishedEvent()
    else
        self.CurrentPlayInterval = 0.01
    end
end

function UTypewriterRichTextProxy:IsPlaying()
    return self.bPlayTyping
end

function UTypewriterRichTextProxy:BuildCurrentTagData()
    self.ContentIndex = 0
    self.CurrentTagContent = ''
    self.CurrentTagIndexData = self.TagArrayTable[self.TagIndex]
    if self.CurrentTagIndexData then
        self.CurrentTagCharArray = UE.UKismetStringLibrary.GetCharacterArrayFromString(self.CurrentTagIndexData.content)
        self.CurrentTagContentLength = self.CurrentTagCharArray:Length()
        return true
    end
end

function UTypewriterRichTextProxy:Tick(deltaTime)
    if not self.bPlayTyping then
        return
    end
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.CurrentTime > self.NextTime then
        self.NextTime = self.CurrentTime + self.CurrentPlayInterval

        self.ContentIndex = self.ContentIndex + 1
        if self.ContentIndex <= self.CurrentTagContentLength then
            local NextChar = self.CurrentTagCharArray:Get(self.ContentIndex)
            self.CurrentTagContent = self.CurrentTagContent .. NextChar
        end
        
        local ShowContent
        if self.CurrentTagIndexData.tag == '' then
            ShowContent = self.ProcessedContent .. self.CurrentTagContent
        else
            ShowContent = self.ProcessedContent .. "<" .. self.CurrentTagIndexData.tag .. ">" .. self.CurrentTagContent .. "</>"
        end

        self.UMGWidget:SetText(ShowContent)
        if self.ContentIndex >= self.CurrentTagContentLength then
            self.ProcessedContent = ShowContent
            self.TagIndex = self.TagIndex + 1
            if not self:BuildCurrentTagData() then
                self.bPlayTyping = false
                self.CurrentPlayInterval = self.DefaultPlayInterval
                self:TriggerFinishedEvent()
            end
        end
    end
end

---@class USliderProxy : UWidgetProxy
---@field UMGWidget USlider
---@field ValueField UIWidgetField
local USliderProxy = CreateProxyClass(UE.USlider, UWidgetProxy)

function USliderProxy:ctor(InWidget)
    Super(USliderProxy).ctor(self, InWidget)

    self.UMG_OnValueChanged = function(UMGWidget, ChangedValue)
        self:OnValueChanged(ChangedValue)
    end
    self.UMGWidget.OnValueChanged:Add(self.UMGWidget, self.UMG_OnValueChanged)

    self.ValueField = UIWidgetField.new(self)
    self.ValueField.Field_Getter = self.GetValue
    self.ValueField.Field_Setter = self.SetValue
end

function USliderProxy:GetValue()
    return self.UMGWidget:GetValue()
end

function USliderProxy:SetValue(InValue)
    local MinValue = self.UMGWidget.MinValue
    local MaxValue = self.UMGWidget.MaxValue
    local ClampedValue = UE.UKismetMathLibrary.FClamp(InValue, MinValue, MaxValue)
    if ClampedValue ~= self:GetValue() then
        self.UMGWidget:SetValue(ClampedValue)
        self:OnValueChanged(ClampedValue)
    end
end

function USliderProxy:OnValueChanged(InValue)
    self.ValueField:BroadcastFieldChanged(InValue)
end


---@class UListViewProxy : UWidgetProxy
---@field UMGWidget UListView
---@field ListField UIWidgetField
local UListViewProxy = CreateProxyClass(UE.UListView, UWidgetProxy)

function UListViewProxy:ctor(InWidget)
    Super(UListViewProxy).ctor(self, InWidget)

    self.ListField = UIWidgetField.new(self)
    self.ListField.Field_Getter = self.GetListItems
    self.ListField.Field_Setter = self.SetListItems
end

function UListViewProxy:GetListItems()
    local ItemValues = {}
    local ListItem = self.UMGWidget:GetListItems()
    for i = 1, ListItem:Length() do
        local obj = ListItem:Get(i)
        table.insert(ItemValues, obj.ItemValue)
    end
    return ItemValues
end

function UListViewProxy:GetNumItems()
    return self.UMGWidget:GetNumItems()
end

function UListViewProxy:AddItem(ItemValue)
    local ItemObjClass = UICommonObj.GetItemObjClass()
    if ItemObjClass then
        local obj = UE.NewObject(ItemObjClass, self.UMGWidget)
        obj.ItemValue = ItemValue
        self.UMGWidget:AddItem(obj)
    end
end

function UListViewProxy:RemoveItem(ItemValue)
    local ListItem = self.UMGWidget:GetListItems()
    for i = 1, ListItem:Length() do
        local obj = ListItem:Get(i)
        if obj.ItemValue == ItemValue then
            self.UMGWidget:RemoveItem(obj)
            break
        end
    end
end

function UListViewProxy:RemoveItems(ItemValues)
    local ListItem = self.UMGWidget:GetListItems()
    local tbRemoveItem = {}
    for i = 1, ListItem:Length() do
        local obj = ListItem:Get(i)
        if TableUtil:Contains(ItemValues, obj.ItemValue) then
            table.insert(tbRemoveItem, obj)
        end
    end
    for i, v in pairs(tbRemoveItem) do
        self.UMGWidget:RemoveItem(v)
    end
end

---@param tbItemData table
function UListViewProxy:SetListItems(tbItemData, OpCode, OpValue)
    local ItemObjClass = UICommonObj.GetItemObjClass()
    if not ItemObjClass then
        return
    end

    local ListItems = UE.TArray(UE.UObject)
    if type(tbItemData) == 'table' then
        if OpCode == 'AddItem' then
            self:AddItem(OpValue)
        elseif OpCode == 'RemoveItem' then
            self:RemoveItems(OpValue)
        else
            for i = 1, #tbItemData do
                local obj = UE.NewObject(ItemObjClass, self.UMGWidget)
                obj.ItemValue = tbItemData[i]
                ListItems:Add(obj)
            end
            self.UMGWidget:BP_SetListItems(ListItems)
        end
    end
end


---@class UTileViewProxy : UListViewProxy
---@field UMGWidget UTileView
---@field ListField UIWidgetField
local UTileViewProxy = CreateProxyClass(UE.UTileView, UListViewProxy)

function UTileViewProxy:ctor(InWidget)
    Super(UTileViewProxy).ctor(self, InWidget)
end

--[[
    WidgetProxy Definition End
]]

WidgetProxys:SortWidgetProxy()

return WidgetProxys