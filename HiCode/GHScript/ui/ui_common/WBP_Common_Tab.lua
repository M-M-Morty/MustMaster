--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@class CommonTabData
---@field TabIndex integer
---@field PidKey string
---@field NameKey string
---@field bHasRedDot boolean

---@alias OnSelectTabCallBackT fun(Owner:UObject, Index:integer)
---@alias OnRedDotCallBackT fun(Owner:UObject, Index:integer, bHasRedDot:boolean)

local UIWindowBase = require('CP0032305_GH.Script.framework.ui.ui_window_base')
local PathUtil = require("CP0032305_GH.Script.common.utils.path_util")
local UIManager = require('CP0032305_GH.Script.ui.ui_manager')
local InputDef = require('CP0032305_GH.Script.common.input_define')

---@class WBP_Common_Tab : WBP_Common_Tab_C
---@field SelectedIndex integer
---@field OnSelectTabCallBacks table<UObject, OnSelectTabCallBackT>
---@field OnRedDotChangedCallBacks table<UObject, OnRedDotCallBackT>
---@field TabCount integer

---@type WBP_Common_Tab_C
local WBP_Common_Tab = Class(UIWindowBase)

local MAX_SHOW_TAB = 6
local MAT_PARAM_NO_HIDE = 0
local MAT_PARAM_HIDE = 1.6

---@param self WBP_Common_Tab
local function SetNoHideTab(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
end

---@param self WBP_Common_Tab
local function SetHasLeftTab(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_NO_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

---@param self WBP_Common_Tab
local function SetHasRightTab(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_NO_HIDE)
end

---@param self WBP_Common_Tab
local function SetHasBothTab(self)
    local EffectMaterial = self.RetainerBoxShadow:GetEffectMaterial()
    EffectMaterial:SetScalarParameterValue("Power1", MAT_PARAM_HIDE)
    EffectMaterial:SetScalarParameterValue("Power2", MAT_PARAM_HIDE)
end

local function CheckShadow(self)
    local Offset = self.List_CommonTab:GetScrollOffset()
    if Offset < 0.1 then
        SetHasRightTab(self)
    elseif math.abs(self.TabCount - MAX_SHOW_TAB - Offset) < 0.1 then
        SetHasLeftTab(self)
    else
        SetHasBothTab(self)
    end
end

---@param self WBP_Common_Tab
---@param Widget WBP_Common_Tab_Item
local function OnEntryGenerated(self, Widget)
    CheckShadow(self)
end

---@param self WBP_Common_Tab
---@param Widget WBP_Common_Tab_Item
local function OnEntryReleased(self, Widget)
    CheckShadow(self)
end

function WBP_Common_Tab:Construct()
    self.OnSelectTabCallBacks = {}
    self.OnRedDotChangedCallBacks = {}
    self.SelectedIndex = 1
    self.List_CommonTab.BP_OnEntryGenerated:Add(self, OnEntryGenerated)
    self.List_CommonTab.BP_OnEntryReleased:Add(self, OnEntryReleased)
end

function WBP_Common_Tab:Destruct()
    self.List_CommonTab.BP_OnEntryGenerated:Remove(self, OnEntryGenerated)
    self.List_CommonTab.BP_OnEntryReleased:Remove(self, OnEntryReleased)
end

function WBP_Common_Tab:OnPressedKeyEvent(KeyName, bFromGame, ActionValue)
    if KeyName == InputDef.Keys.One then
        if self.SelectedIndex > 1 then
            self:SelectTab(self.SelectedIndex - 1)
        end
    elseif KeyName == InputDef.Keys.Three then
        if self.SelectedIndex < self.TabCount then
            self:SelectTab(self.SelectedIndex + 1)
        end
    end
end

function WBP_Common_Tab:RegisterKeyEvent()
    UIManager:RegisterPressedKeyDelegate(self, self.OnPressedKeyEvent)
end

function WBP_Common_Tab:UnRegisterKeyEvent()
    UIManager:UnRegisterPressedKeyDelegate(self)
end

---@param self WBP_Common_Tab
---@return BP_CommonTabItemObject_C
local function NewTabItemObject(self)
    local Path = PathUtil.getFullPathString(self.TabItemObjectClass)
    local CommonTabItemObject = LoadObject(Path)
    return NewObject(CommonTabItemObject)
end

---@param CommonTabDatas CommonTabData[]
---@param SelectedIndex integer
function WBP_Common_Tab:SetDatas(CommonTabDatas, SelectedIndex)
    self.SelectedIndex = SelectedIndex
    local Path = PathUtil.getFullPathString(self.TabItemObjectClass)
    local CommonTabItemObject = LoadObject(Path)
    local InListItems = UE.TArray(CommonTabItemObject)
    self.TabCount = #CommonTabDatas
    for _, Data in ipairs(CommonTabDatas) do
        local TabItem = NewTabItemObject(self)
        TabItem.OwnerWidget = self
        TabItem.Index = Data.TabIndex
        TabItem.NameKey = Data.NameKey
        TabItem.PicKey = Data.PidKey
        TabItem.bHasRedDot = Data.bHasRedDot
        TabItem.StyleKey = Data.StyleKey
        InListItems:Add(TabItem)
    end
    self.List_CommonTab:BP_SetListItems(InListItems)
    if self.TabCount > MAX_SHOW_TAB then
        SetHasRightTab(self)
    else
        SetNoHideTab(self)
    end
end

function WBP_Common_Tab:SelectTab(Index)
    self.SelectedIndex = Index
    for Owner, CB in pairs(self.OnSelectTabCallBacks) do
        CB(Owner, Index)
    end
    self.List_CommonTab:ScrollIndexIntoView(Index)
end

---@param Owner UObject
---@param CallBack OnSelectTabCallBackT
function WBP_Common_Tab:RegOnSelectTab(Owner, CallBack)
    self.OnSelectTabCallBacks[Owner] = CallBack
end

---@param Owner UObject
---@param CallBack OnSelectTabCallBackT
function WBP_Common_Tab:UnRegOnSelectTab(Owner, CallBack)
    self.OnSelectTabCallBacks[Owner] = nil
end

---@param Owner UObject
---@param CallBack OnRedDotCallBackT
function WBP_Common_Tab:RegOnRedDotChanged(Owner, CallBack)
    self.OnRedDotChangedCallBacks[Owner] = CallBack
end

---@param Owner UObject
---@param CallBack OnRedDotCallBackT
function WBP_Common_Tab:UnRegOnRedDotChanged(Owner, CallBack)
    self.OnRedDotChangedCallBacks[Owner] = nil
end

function WBP_Common_Tab:ChangeRedDot(Index, bHasRedDot)
    ---@type BP_CommonTabItemObject_C
    local ItemData = self.List_CommonTab:GetItemAt(Index)
    if ItemData then
        ItemData.bHasRedDot = bHasRedDot
    end
    for Owner, CB in pairs(self.OnRedDotChangedCallBacks) do
        CB(Owner, Index, bHasRedDot)
    end
end

return WBP_Common_Tab
